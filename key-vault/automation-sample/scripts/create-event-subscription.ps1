param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$SourceVaultResourceGroup,

    [Parameter(Mandatory = $true)]
    [string]$SourceVaultName,

    [Parameter(Mandatory = $true)]
    [string]$FunctionResourceGroup,

    [Parameter(Mandatory = $true)]
    [string]$FunctionAppName,

    [string]$EventSubscriptionName = "evsub-kv-secret-replication"
)

$ErrorActionPreference = "Stop"

az account set --subscription $SubscriptionId

$vaultId = az keyvault show `
  --resource-group $SourceVaultResourceGroup `
  --name $SourceVaultName `
  --query id -o tsv

# The endpoint format targets a specific EventGridTrigger function.
$endpoint = "/subscriptions/$SubscriptionId/resourceGroups/$FunctionResourceGroup/providers/Microsoft.Web/sites/$FunctionAppName/functions/kv_secret_sync_eventgrid"

az eventgrid event-subscription create `
  --name $EventSubscriptionName `
  --source-resource-id $vaultId `
  --endpoint-type azurefunction `
  --endpoint $endpoint `
  --included-event-types Microsoft.KeyVault.SecretNewVersionCreated Microsoft.KeyVault.SecretNearExpiry

Write-Host "Event subscription created: $EventSubscriptionName"
