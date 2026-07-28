param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory = $true)]
    [string]$Location,

    [Parameter(Mandatory = $true)]
    [string]$NamePrefix,

    [Parameter(Mandatory = $true)]
    [string]$FunctionAppName,

    [Parameter(Mandatory = $true)]
    [string]$StorageAccountName,

    [Parameter(Mandatory = $true)]
    [string]$SourceVaultName,

    [Parameter(Mandatory = $true)]
    [string]$TargetVaultName,

    [string]$SecretFilterPrefix = "app-"
)

$ErrorActionPreference = "Stop"

Write-Host "Setting Azure subscription..."
az account set --subscription $SubscriptionId

Write-Host "Creating resource group if needed..."
az group create --name $ResourceGroup --location $Location | Out-Null

Write-Host "Deploying infrastructure..."
az deployment group create `
  --resource-group $ResourceGroup `
  --template-file ./main.bicep `
  --parameters `
    location=$Location `
    namePrefix=$NamePrefix `
    functionAppName=$FunctionAppName `
    storageAccountName=$StorageAccountName `
    sourceVaultName=$SourceVaultName `
    targetVaultName=$TargetVaultName `
    secretFilterPrefix=$SecretFilterPrefix

Write-Host "Deployment completed."
