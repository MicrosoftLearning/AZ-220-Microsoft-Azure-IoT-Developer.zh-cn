@description('Your unique ID - i.e. dm041221')
param yourID string
@description('Course ID - i.e. az220')
param courseID string

var iotHubName = 'iot-${courseID}-training-${yourID}'

module hub './modules/iotHub.bicep' = {
  name: 'deployHub'
  params: {
    iotHubName: iotHubName
  }
}

output connectionString string = hub.outputs.connectionString
