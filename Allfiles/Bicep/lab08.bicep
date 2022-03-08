@description('Your unique ID - i.e. dm041221')
param yourID string
@description('Course ID - i.e. az220')
param courseID string

var location = resourceGroup().location
var iotHubName = 'iot-${courseID}-training-${yourID}'
var identityName = '${courseID}ID2'
// b24988ac-6180-42a0-ab88-20f7382dd24c is the Contributer role ID
var contributorRoleDefinitionId = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
var deviceID = 'sensor-v-3000'
var storageAccountName = 'vibrationstore${yourID}'
var storageContainerName = 'vibrationcontainer'
// var eventHubNamespace='vibrationNamespace$YourID'
// var eventHubName='vibrationeventhubinstance'

var jobName = 'vibrationJob'
var jobInputName = 'vibrationInput'
var jobOutputName = 'vibrationOutput'
var jobTransformationName = 'VibrationJobTransformation'

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
    // this ensures the role assignment is performed on the same AD node as the
    // identity creation - meaning it will always succeed
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
  name: storageAccountName
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  location: location
  properties: {
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource storageBlob 'Microsoft.Storage/storageAccounts/blobServices@2021-04-01' = {
  parent: storage
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      enabled: false
    }
  }
}

resource storageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  parent: storageBlob
  name: storageContainerName
  properties: {
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }
  dependsOn: [
    storage
  ]
}

resource streamingjob 'Microsoft.StreamAnalytics/streamingjobs@2017-04-01-preview' = {
  name: jobName
  location: location
  properties: {
    sku: {
      name: 'Standard'
    }
    eventsOutOfOrderPolicy: 'Adjust'
    outputErrorPolicy: 'Stop'
    eventsOutOfOrderMaxDelayInSeconds: 10
    eventsLateArrivalMaxDelayInSeconds: 5
    dataLocale: 'en-US'
    compatibilityLevel: '1.1'
    contentStoragePolicy: 'SystemAccount'
    jobType: 'Cloud'
  }
  dependsOn: [
    hub
    storageContainer
  ]
}

resource streamingjobsInput 'Microsoft.StreamAnalytics/streamingjobs/inputs@2017-04-01-preview' = {
  parent: streamingjob
  name: jobInputName
  properties: {
    type: 'Stream'
    datasource: {
      type: 'Microsoft.Devices/IotHubs'
      properties: {
        iotHubNamespace: iotHubName
        sharedAccessPolicyKey: hub.outputs.iothubownerKey
        sharedAccessPolicyName: 'iothubowner'
        endpoint: 'messages/events'
        consumerGroupName: '$Default'
      }
    }
    compression: {
      type: 'None'
    }
    serialization: {
      type: 'Json'
      properties: {
        encoding: 'UTF8'
      }
    }
  }
  dependsOn: [
    streamingjob
  ]
}

resource streamingjobsOutput 'Microsoft.StreamAnalytics/streamingjobs/outputs@2017-04-01-preview' = {
  parent: streamingjob
  name: jobOutputName
  properties: {
    datasource: {
      type: 'Microsoft.Storage/Blob'
      properties: {
        storageAccounts: [
          {
            accountKey: listkeys(storage.id, storage.apiVersion).keys[0].value
            accountName: storageAccountName
          }
        ]
        container: storageContainerName
        pathPattern: 'output/'
        dateFormat: 'yyyy/MM/dd'
        timeFormat: 'HH'
      }
    }
    serialization: {
      type: 'Json'
      properties: {
        encoding: 'UTF8'
        format: 'LineSeparated'
      }
    }
  }
  dependsOn: [
    streamingjob
  ]
}

resource streamingJobTransformation 'Microsoft.StreamAnalytics/streamingjobs/transformations@2016-03-01' = {
  parent: streamingjob
  name: jobTransformationName
  properties: {
    query: 'SELECT * INTO vibrationOutput FROM vibrationInput'
    streamingUnits: 1
  }
  dependsOn: [
    streamingjobsInput
    streamingjobsOutput
    streamingjob
  ]
}

output connectionString string = hub.outputs.connectionString
output deviceConnectionString string = createDevice.outputs.deviceConnectionString
output devicePrimaryKey string = createDevice.outputs.primaryKey
output eventHubEndPoint string = hub.outputs.eventHubEndPoint
output eventHubPath string = hub.outputs.eventHubPath
output serviceKey string = hub.outputs.serviceKey
