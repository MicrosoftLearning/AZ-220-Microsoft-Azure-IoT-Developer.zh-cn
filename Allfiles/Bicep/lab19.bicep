@description('Your unique ID - i.e. dm041221')
param yourID string
@description('Course ID - i.e. az220')
param courseID string
@description('Current User Object ID - run "az ad signed-in-user show --query objectId -o tsv" in cloud shell')
param objectID string

var location = resourceGroup().location
// var groupName = resourceGroup().name
var iotHubName = 'iot-${courseID}-training-${yourID}'
var identityName = '${courseID}ID'
// b24988ac-6180-42a0-ab88-20f7382dd24c is the Contributer role ID
var contributorRoleDefinitionId = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
var deviceID = 'sensor-th-0055'
var storageName = 'sta${courseID}training${yourID}'
var tsiName= 'tsi-${courseID}-training-${yourID}'

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
    principalId: reference(uai.id, uai.apiVersion, 'Full').properties.principalId
    principalType:'ServicePrincipal'
  }
}
//

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

resource tsi 'Microsoft.TimeSeriesInsights/environments@2020-05-15' = {
  kind: 'Gen2'
  location: location
  name: tsiName
  sku: {
    capacity: 1
    name: 'L1'
  }
  properties: {
    storageConfiguration: {
      accountName: storage.name
      managementKey: listkeys(storage.id, storage.apiVersion).keys[0].value
    }
    timeSeriesIdProperties: [
      {
        name: '$dtId'
        type: 'String'
      }
    ]
  }
}

resource tsiAccess 'Microsoft.TimeSeriesInsights/environments/accessPolicies@2020-05-15' = {
  name: '${tsiName}/access'
  dependsOn: [
    tsi
  ]
  properties: {
    principalObjectId: objectID
    description: 'ADT Access Policy'
    roles: [
      'Contributor'
      'Reader'
    ]
  }

}

output connectionString string = hub.outputs.connectionString
output deviceConnectionString string = createDevice.outputs.deviceConnectionString
output devicePrimaryKey string = createDevice.outputs.primaryKey
output storageAccountName string = storageName

// lab requires the following resource providers
// az provider register --namespace "Microsoft.EventGrid" --accept-terms
// az provider register --namespace "Microsoft.EventHub" --accept-terms
// az provider register --namespace "Microsoft.TimeSeriesInsights" --accept-terms
