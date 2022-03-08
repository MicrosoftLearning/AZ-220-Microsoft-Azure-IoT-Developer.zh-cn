@description('Your unique ID - i.e. dm041221')
param yourID string
@description('Course ID - i.e. az220')
param courseID string

var location = resourceGroup().location
var iotHubName = 'iot-${courseID}-training-${yourID}'

module hub './modules/iotHub.bicep' = {
  name: 'hubDeploy'
  params: {
    iotHubName: iotHubName
    location: location
  }
}

output connectionString string = hub.outputs.connectionString
