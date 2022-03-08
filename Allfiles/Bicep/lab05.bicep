@description('Your unique ID - i.e. dm041221')
param yourID string
@description('Course ID - i.e. az220')
param courseID string

var location = resourceGroup().location
var iotHubName = 'iot-${courseID}-training-${yourID}'
var provisioningServiceName = 'dps-${courseID}-training-${yourID}'

module hubAndDps './modules/hubAndDps.bicep' = {
  name: 'iotHubAndDpsDeploy'
  params: {
    iotHubName: iotHubName
    provisioningServiceName: provisioningServiceName
    skuName: 'S1'
    skuUnits: 1
    location: location
  }
}

output connectionString string = hubAndDps.outputs.iotHubConnectionString
output dpsScopeId string = hubAndDps.outputs.dpsScopeId
