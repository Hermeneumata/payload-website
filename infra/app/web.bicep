param name string
param location string = resourceGroup().location
param tags object = {}

param identityName string
param applicationInsightsName string
param containerAppsEnvironmentName string
param containerRegistryHostSuffix string
param containerRegistryName string
param keyVaultName string
param serviceName string = 'web'
param exists bool
param databaseName string
param storageContainerName string
param storageAccountName string

@secure()
param payloadSecret string
@secure()
param storageConnectionString string
@secure()
param cosmosConnectionString string

resource webIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

// Give the website access to KeyVault
module websiteKeyVaultAccess '../core/security/keyvault-access.bicep' = {
  name: 'website-keyvault-access'
  params: {
    keyVaultName: keyVaultName
    principalId: webIdentity.properties.principalId
  }
}

module app '../core/host/container-app-upsert.bicep' = {
  name: '${serviceName}-container-app'
  params: {
    name: name
    location: location
    tags: union(tags, { 'azd-service-name': serviceName })
    identityType: 'UserAssigned'
    identityName: identityName
    exists: exists
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryName: containerRegistryName
    containerRegistryHostSuffix: containerRegistryHostSuffix
    targetPort: 3000
    env: [
      {
        name: 'AZURE_CLIENT_ID'
        value: webIdentity.properties.clientId
      }
      {
        name: 'AZURE_KEY_VAULT_ENDPOINT'
        value: keyVault.properties.vaultUri
      }
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: applicationInsights.properties.ConnectionString
      }
      {
        name: 'PAYLOAD_SECRET'
        secretRef: 'payload-secret'
      }
      {
        name: 'DATABASE_NAME'
        value: databaseName
      }
      {
        name: 'DATABASE_URI'
        secretRef: 'cosmos-connection-string'
      }
      {
        name: 'AZURE_STORAGE_CONNECTION_STRING'
        secretRef: 'storage-connection-string'
      }
      {
        name: 'AZURE_STORAGE_CONTAINER_NAME'
        value: storageContainerName
      }
      {
        name: 'AZURE_STORAGE_BASE_URL'
        value: 'https://${storageAccountName}.blob.core.windows.net'
      }
    ]
    secrets: {
      'payload-secret': payloadSecret
      'cosmos-connection-string': cosmosConnectionString
      'storage-connection-string': storageConnectionString
    }
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

output SERVICE_WEB_IDENTITY_PRINCIPAL_ID string = webIdentity.properties.principalId
output SERVICE_WEB_NAME string = app.outputs.name
output SERVICE_WEB_URI string = app.outputs.uri
output SERVICE_WEB_IMAGE_NAME string = app.outputs.imageName
