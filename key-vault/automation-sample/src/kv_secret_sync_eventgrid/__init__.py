import datetime
import json
import logging
import os
from typing import Any

from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from azure.core.exceptions import ResourceNotFoundError, ServiceRequestError, HttpResponseError


def _extract_secret_name(data: dict[str, Any]) -> str | None:
    # Key Vault event schema carries object name in "ObjectName" for current events.
    object_name = data.get("ObjectName")
    if object_name:
        return object_name

    # Fallback parser for Subject values such as: .../secrets/<name>
    subject = data.get("subject") or data.get("Subject")
    if isinstance(subject, str) and "/secrets/" in subject:
        return subject.rsplit("/secrets/", 1)[-1]

    return None


def _is_supported_event(event_type: str) -> bool:
    supported = {
        "Microsoft.KeyVault.SecretNewVersionCreated",
        "Microsoft.KeyVault.SecretNearExpiry",
    }
    return event_type in supported


def main(event) -> None:
    event_body = event.get_json()
    if isinstance(event_body, str):
        event_body = json.loads(event_body)

    event_type = event_body.get("eventType", "")
    if not _is_supported_event(event_type):
        logging.info("Skipping unsupported event type: %s", event_type)
        return

    source_uri = os.environ["SOURCE_VAULT_URI"]
    target_uri = os.environ["TARGET_VAULT_URI"]
    secret_prefix = os.getenv("SECRET_FILTER_PREFIX", "")
    disable_sync_tag = os.getenv("DISABLE_SYNC_TAG", "no-sync")

    data = event_body.get("data", {})
    secret_name = _extract_secret_name(data)
    if not secret_name:
        logging.warning("Could not resolve secret name from event payload")
        return

    if secret_prefix and not secret_name.startswith(secret_prefix):
        logging.info("Secret %s not in prefix filter, skipping", secret_name)
        return

    credential = DefaultAzureCredential()
    source_client = SecretClient(vault_url=source_uri, credential=credential)
    target_client = SecretClient(vault_url=target_uri, credential=credential)

    try:
        source_secret = source_client.get_secret(secret_name)
    except ResourceNotFoundError:
        logging.warning("Secret %s no longer exists in source vault", secret_name)
        return

    source_tags = source_secret.properties.tags or {}
    if source_tags.get(disable_sync_tag, "").lower() == "true":
        logging.info("Secret %s has no-sync tag; skipping", secret_name)
        return

    replicated_tags = dict(source_tags)
    replicated_tags["synced-at-utc"] = datetime.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"
    replicated_tags["synced-by"] = "kv-replicator-eventgrid"

    try:
        target_client.set_secret(
            name=source_secret.name,
            value=source_secret.value,
            enabled=source_secret.properties.enabled,
            content_type=source_secret.properties.content_type,
            tags=replicated_tags,
        )
        logging.info("Replicated secret %s via event %s", secret_name, event_type)
    except (ServiceRequestError, HttpResponseError) as ex:
        logging.exception("Failed replicating secret %s: %s", secret_name, ex)
        raise
