@description('Resource group location for the function app and storage account.')
param location string

@description('Prefix used for naming resources.')
param namePrefix string

@description('Source key vault name. Must already exist.')
param sourceVaultName string

@description('Target key vault name. Must already exist.')
param targetVaultName string

@description('Secret name prefix filter. Example: app-')
param secretFilterPrefix string = 'app-'

@description('Function App name')
param functionAppName string

@description('Storage account name for the Function App. Lowercase and globally unique.')
param storageAccountName string

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
  }
}

resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: '${namePrefix}-plan'
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: true
  }
}

resource functionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'Python|3.12'
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storage.id, storage.apiVersion).keys[0].value}'
        }
        {
          name: 'SOURCE_VAULT_URI'
          value: 'https://${sourceVaultName}.vault.azure.net'
        }
        {
          name: 'TARGET_VAULT_URI'
          value: 'https://${targetVaultName}.vault.azure.net'
        }
        {
          name: 'SECRET_FILTER_PREFIX'
          value: secretFilterPrefix
        }
      ]
    }
  }
}

var secretOfficerRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')

resource sourceKv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: sourceVaultName
}

resource targetKv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: targetVaultName
}

resource sourceRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(sourceKv.id, functionApp.name, 'secrets-officer-source')
  scope: sourceKv
  properties: {
    roleDefinitionId: secretOfficerRoleId
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource targetRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(targetKv.id, functionApp.name, 'secrets-officer-target')
  scope: targetKv
  properties: {
    roleDefinitionId: secretOfficerRoleId
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output functionAppName string = functionApp.name
output functionPrincipalId string = functionApp.identity.principalId
