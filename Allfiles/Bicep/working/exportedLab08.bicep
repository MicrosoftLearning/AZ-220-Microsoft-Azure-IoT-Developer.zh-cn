@secure()
param IotHubs_iot_az220_training_dm062121_connectionString string

@secure()
param IotHubs_iot_az220_training_dm062121_containerName string
param streamingjobs_vibrationJob_name string = 'vibrationJob'
param IotHubs_iot_az220_training_dm062121_name string = 'iot-az220-training-dm062121'
param storageAccounts_vibrationstoredm062121_name string = 'vibrationstoredm062121'

resource IotHubs_iot_az220_training_dm062121_name_resource 'Microsoft.Devices/IotHubs@2021-03-31' = {
  name: IotHubs_iot_az220_training_dm062121_name
  location: 'eastus'
  sku: {
    name: 'S1'
    tier: 'Standard'
    capacity: 1
  }
  identity: {
    type: 'None'
  }
  properties: {
    ipFilterRules: []
    eventHubEndpoints: {
      events: {
        retentionTimeInDays: 1
        partitionCount: 4
      }
    }
    routing: {
      endpoints: {
        serviceBusQueues: []
        serviceBusTopics: []
        eventHubs: []
        storageContainers: [
          {
            connectionString: 'DefaultEndpointsProtocol=https;EndpointSuffix=core.windows.net;AccountName=vibrationstoredm062121;AccountKey=****'
            containerName: 'vibrationcontainer'
            fileNameFormat: '{iothub}/{partition}/{YYYY}/{MM}/{DD}/{HH}/{mm}'
            batchFrequencyInSeconds: 100
            maxChunkSizeInBytes: 104857600
            encoding: 'Avro'
            name: 'vibrationLogEndpoint'
            id: '8c2f2d86-6536-44d1-b43e-2ff0619504c8'
            subscriptionId: 'ae82ff3b-4bd0-462b-8449-d713dd18e11e'
            resourceGroup: 'rg-az220'
          }
        ]
      }
      routes: [
        {
          name: 'vibrationLoggingRoute'
          source: 'DeviceMessages'
          condition: 'sensorID = "VSLog"'
          endpointNames: [
            'vibrationLogEndpoint'
          ]
          isEnabled: true
        }
      ]
      fallbackRoute: {
        name: '$fallback'
        source: 'DeviceMessages'
        condition: 'true'
        endpointNames: [
          'events'
        ]
        isEnabled: true
      }
    }
    storageEndpoints: {
      '$default': {
        sasTtlAsIso8601: 'PT1H'
        connectionString: IotHubs_iot_az220_training_dm062121_connectionString
        containerName: IotHubs_iot_az220_training_dm062121_containerName
      }
    }
    messagingEndpoints: {
      fileNotifications: {
        lockDurationAsIso8601: 'PT1M'
        ttlAsIso8601: 'PT1H'
        maxDeliveryCount: 10
      }
    }
    enableFileUploadNotifications: false
    cloudToDevice: {
      maxDeliveryCount: 10
      defaultTtlAsIso8601: 'PT1H'
      feedback: {
        lockDurationAsIso8601: 'PT5S'
        ttlAsIso8601: 'PT1H'
        maxDeliveryCount: 10
      }
    }
    features: 'None'
  }
}

resource storageAccounts_vibrationstoredm062121_name_resource 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccounts_vibrationstoredm062121_name
  location: 'eastus'
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
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

resource streamingjobs_vibrationJob_name_resource 'Microsoft.StreamAnalytics/streamingjobs@2017-04-01-preview' = {
  name: streamingjobs_vibrationJob_name
  location: 'East US'
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
}

resource storageAccounts_vibrationstoredm062121_name_default 'Microsoft.Storage/storageAccounts/blobServices@2021-04-01' = {
  parent: storageAccounts_vibrationstoredm062121_name_resource
  name: 'default'
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      enabled: false
    }
  }
}

resource Microsoft_Storage_storageAccounts_fileServices_storageAccounts_vibrationstoredm062121_name_default 'Microsoft.Storage/storageAccounts/fileServices@2021-04-01' = {
  parent: storageAccounts_vibrationstoredm062121_name_resource
  name: 'default'
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  properties: {
    protocolSettings: {
      smb: {}
    }
    cors: {
      corsRules: []
    }
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource Microsoft_Storage_storageAccounts_queueServices_storageAccounts_vibrationstoredm062121_name_default 'Microsoft.Storage/storageAccounts/queueServices@2021-04-01' = {
  parent: storageAccounts_vibrationstoredm062121_name_resource
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource Microsoft_Storage_storageAccounts_tableServices_storageAccounts_vibrationstoredm062121_name_default 'Microsoft.Storage/storageAccounts/tableServices@2021-04-01' = {
  parent: storageAccounts_vibrationstoredm062121_name_resource
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource streamingjobs_vibrationJob_name_vibrationInput 'Microsoft.StreamAnalytics/streamingjobs/inputs@2017-04-01-preview' = {
  parent: streamingjobs_vibrationJob_name_resource
  name: 'vibrationInput'
  properties: {
    type: 'Stream'
    datasource: {
      type: 'Microsoft.Devices/IotHubs'
      properties: {
        iotHubNamespace: 'iot-az220-training-dm062121'
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
}

resource streamingjobs_vibrationJob_name_vibrationOutput 'Microsoft.StreamAnalytics/streamingjobs/outputs@2017-04-01-preview' = {
  parent: streamingjobs_vibrationJob_name_resource
  name: 'vibrationOutput'
  properties: {
    datasource: {
      type: 'Microsoft.Storage/Blob'
      properties: {
        storageAccounts: [
          {
            accountName: 'vibrationstoredm062121'
          }
        ]
        container: 'vibrationcontainer'
        pathPattern: 'output/'
        dateFormat: 'yyyy/MM/dd'
        timeFormat: 'HH'
        authenticationMode: 'ConnectionString'
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
}

resource storageAccounts_vibrationstoredm062121_name_default_vibrationcontainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  parent: storageAccounts_vibrationstoredm062121_name_default
  name: 'vibrationcontainer'
  properties: {
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }
  dependsOn: [
    storageAccounts_vibrationstoredm062121_name_resource
  ]
}