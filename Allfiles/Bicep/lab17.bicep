@description('Your unique ID - i.e. dm041221')
param yourID string
@description('Course ID - i.e. az220')
param courseID string

var location = resourceGroup().location
var iotHubName = 'iot-${courseID}-training-${yourID}'
var storageName = 'sta${courseID}training${yourID}'
var deviceID = 'sensor-thl-2001'
var identityName = '${courseID}ID'
var contributorRoleDefinitionId = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'

module hub './modules/iotHub.bicep' = {
  name: 'deployHub'
  params: {
    iotHubName: iotHubName
    location: location
  }
}

// As the uai.id value is used below, the following cannot be moved to a module
resource uai 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  location: location
  name: identityName
}

resource uaiRole 'Microsoft.Authorization/roleAssignments@2018-09-01-preview' = {
  name: guid(subscription().subscriptionId, uai.id)
  dependsOn: [
    uai
  ]
  properties: {
    roleDefinitionId: contributorRoleDefinitionId
    principalId: reference(uai.id, '2018-11-30', 'Full').properties.principalId
    principalType:'ServicePrincipal'
  }
}

var scriptIdentity = {
  type: 'UserAssigned'
  userAssignedIdentities: {
    '${uai.id}': {}
  }
}

module createDevice './modules/device.bicep' = {
  name: 'createDevice'
  dependsOn: [
    hub
    uaiRole
  ]
  params: {
    iotHubName: iotHubName
    deviceID: deviceID
    scriptIdentity: scriptIdentity
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storageName
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  location: location
}

output connectionString string = hub.outputs.connectionString
output deviceConnectionString string = createDevice.outputs.deviceConnectionString
output devicePrimaryKey string = createDevice.outputs.primaryKey
output storageAccountName string = storageName

// note - lab requires "Microsoft.Insights" provider
