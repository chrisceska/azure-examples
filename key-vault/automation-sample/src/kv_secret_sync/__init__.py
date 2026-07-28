import datetime
import logging
import os
from typing import Optional

from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from azure.core.exceptions import ResourceNotFoundError, ServiceRequestError, HttpResponseError


def _list_from_csv(value: str) -> set[str]:
    return {item.strip() for item in value.split(",") if item.strip()}


def _should_replicate(secret_name: str, prefix: str, allowlist: set[str]) -> bool:
    if allowlist and secret_name not in allowlist:
        return False
    if prefix and not secret_name.startswith(prefix):
        return False
    return True


def _safe_get_target_secret(client: SecretClient, name: str):
    try:
        return client.get_secret(name)
    except ResourceNotFoundError:
        return None


def _is_drifted(source_secret, target_secret) -> bool:
    if target_secret is None:
        return True

    source_tags = source_secret.properties.tags or {}
    target_tags = target_secret.properties.tags or {}

    # Compare relevant metadata and current value to detect drift.
    return (
        source_secret.value != target_secret.value
        or source_secret.properties.enabled != target_secret.properties.enabled
        or source_secret.properties.content_type != target_secret.properties.content_type
        or source_tags != target_tags
    )


def _build_replicated_tags(source_tags: Optional[dict], tag_name: str, tag_value: str) -> dict:
    tags = dict(source_tags or {})
    tags[tag_name] = tag_value
    tags["synced-at-utc"] = datetime.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"
    return tags


def main(mytimer) -> None:
    if mytimer.past_due:
        logging.warning("Timer execution is late")

    source_uri = os.environ["SOURCE_VAULT_URI"]
    target_uri = os.environ["TARGET_VAULT_URI"]
    prefix = os.getenv("SECRET_FILTER_PREFIX", "")
    allowlist = _list_from_csv(os.getenv("ALLOWLIST_SECRETS", ""))
    disable_sync_tag = os.getenv("DISABLE_SYNC_TAG", "no-sync")
    sync_tag_name = os.getenv("SYNC_TAG_NAME", "synced-by")
    sync_tag_value = os.getenv("SYNC_TAG_VALUE", "kv-replicator")

    credential = DefaultAzureCredential()
    source_client = SecretClient(vault_url=source_uri, credential=credential)
    target_client = SecretClient(vault_url=target_uri, credential=credential)

    replicated = 0
    skipped = 0
    errors = 0

    for props in source_client.list_properties_of_secrets():
        if not _should_replicate(props.name, prefix, allowlist):
            continue

        source_secret = source_client.get_secret(props.name)
        source_tags = source_secret.properties.tags or {}

        if source_tags.get(disable_sync_tag, "").lower() == "true":
            skipped += 1
            continue

        target_secret = _safe_get_target_secret(target_client, props.name)

        if not _is_drifted(source_secret, target_secret):
            skipped += 1
            continue

        replicated_tags = _build_replicated_tags(source_tags, sync_tag_name, sync_tag_value)

        try:
            target_client.set_secret(
                name=source_secret.name,
                value=source_secret.value,
                enabled=source_secret.properties.enabled,
                content_type=source_secret.properties.content_type,
                tags=replicated_tags,
            )
            replicated += 1
        except (ServiceRequestError, HttpResponseError) as ex:
            errors += 1
            logging.exception("Failed to replicate secret %s: %s", source_secret.name, ex)

    logging.info(
        "Secret replication complete. replicated=%s skipped=%s errors=%s source=%s target=%s",
        replicated,
        skipped,
        errors,
        source_uri,
        target_uri,
    )
