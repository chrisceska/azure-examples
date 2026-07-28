# Key Vault Replication Automation Sample

Created: 2026-07-28

## What this sample does

This sample deploys an Azure Function timer trigger that replicates selected secrets from a source Key Vault to a target Key Vault using Managed Identity and Azure RBAC.

It includes:

- Python Function code for secret replication.
- Python Event Grid-triggered function for near-real-time replication.
- Bicep template for Function App, storage account, and RBAC role assignments.
- PowerShell scripts to deploy infrastructure and publish function code.
- PowerShell scripts for Event Grid subscription and key/certificate replication.

## Folder structure

- `src/kv_secret_sync/__init__.py`: Timer function logic.
- `src/kv_secret_sync/function.json`: Timer trigger schedule.
- `src/kv_secret_sync_eventgrid/__init__.py`: Event Grid trigger logic.
- `src/kv_secret_sync_eventgrid/function.json`: Event Grid trigger binding.
- `deploy/main.bicep`: Infrastructure baseline.
- `deploy/deploy.ps1`: Resource deployment script.
- `deploy/publish-function.ps1`: Function code publish script.
- `scripts/create-event-subscription.ps1`: Event Grid subscription setup.
- `scripts/replicate-keys-and-certs.ps1`: Backup/restore replication for keys and certificates.
- `local.settings.sample.json`: Local development settings sample.

## Prerequisites

- Azure CLI installed and signed in.
- Azure Functions Core Tools installed.
- Python 3.12.
- Existing source and target Key Vaults with soft delete and purge protection enabled.
- Permissions to deploy resources and assign RBAC roles.

## Deploy

1. Open a terminal in this sample folder.
2. Deploy infrastructure:

```powershell
cd deploy
./deploy.ps1 `
  -SubscriptionId <subscription-id> `
  -ResourceGroup <resource-group> `
  -Location <function-location> `
  -NamePrefix kvsync `
  -FunctionAppName func-kv-sync-prod-001 `
  -StorageAccountName stkvsyncprod001 `
  -SourceVaultName kv-app-prod-eastus2-001 `
  -TargetVaultName kv-app-prod-mexicocentral-001 `
  -SecretFilterPrefix app-
```

3. Publish function code:

```powershell
./publish-function.ps1 -FunctionAppName func-kv-sync-prod-001 -ResourceGroup <resource-group>
```

## Local run

1. Copy `local.settings.sample.json` to `local.settings.json`.
2. Update values for your vault URIs and filters.
3. Install dependencies and run:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
func start
```

## Validation

Run these checks after deployment:

1. Create or update a secret in source vault with your prefix.
2. Wait for timer execution, then verify target vault secret exists and matches.
3. Confirm tags include replication metadata.
4. Review Function logs for replication summary and errors.

## Enable near-real-time sync with Event Grid

After publishing the function app, create an Event Grid subscription from source vault to the `kv_secret_sync_eventgrid` function:

```powershell
cd scripts
./create-event-subscription.ps1 `
  -SubscriptionId <subscription-id> `
  -SourceVaultResourceGroup <source-vault-rg> `
  -SourceVaultName kv-app-prod-eastus2-001 `
  -FunctionResourceGroup <function-rg> `
  -FunctionAppName func-kv-sync-prod-001
```

Event types included by default:

- `Microsoft.KeyVault.SecretNewVersionCreated`
- `Microsoft.KeyVault.SecretNearExpiry`

## Replicate keys and certificates with backup/restore

Use the script below for key and certificate replication when secret-value sync is not the right fit:

```powershell
cd scripts
./replicate-keys-and-certs.ps1 `
  -SubscriptionId <subscription-id> `
  -SourceVaultName kv-app-prod-eastus2-001 `
  -TargetVaultName kv-app-prod-mexicocentral-001
```

Optional switches:

- `-SkipKeys`
- `-SkipCertificates`

## Security notes

- Uses `DefaultAzureCredential` and Managed Identity in Azure.
- Uses least-privilege role assignment: `Key Vault Secrets Officer` on source and target vaults.
- Avoid broad filters in production; use allowlist or strict naming conventions.
- Consider private endpoints and network-restricted vault access for production workloads.

## Next extensions

- Add Event Grid trigger for near-real-time sync on secret changes.
- Add retry/backoff policy and dead-letter queue for failures.
- Add key and certificate replication runbook using backup and restore commands.
- Add alert rules for replication failures and drift detection.

## References

- Azure Key Vault overview: https://learn.microsoft.com/azure/key-vault/general/overview
- Azure RBAC for Key Vault: https://learn.microsoft.com/azure/key-vault/general/rbac-guide
- Azure Functions timer trigger: https://learn.microsoft.com/azure/azure-functions/functions-bindings-timer
- Azure Identity for Python: https://learn.microsoft.com/python/api/overview/azure/identity-readme
- Azure Key Vault Secrets SDK for Python: https://learn.microsoft.com/python/api/overview/azure/keyvault-secrets-readme
