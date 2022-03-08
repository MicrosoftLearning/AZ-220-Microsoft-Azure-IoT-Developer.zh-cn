param streamingjobs_vibrationJob_name string = 'vibrationJob'

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