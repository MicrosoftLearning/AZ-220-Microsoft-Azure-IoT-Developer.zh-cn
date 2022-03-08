@description('The IoT Hub name')
param iotHubName string

@description('Specify the location of the resources.')
param location string = resourceGroup().location


@description('The SKU to use for the IoT Hub.')
param skuName string = 'S1'

@description('The number of IoT Hub units.')
param skuUnits int = 1

resource hub 'Microsoft.Devices/IotHubs@2020-08-31' = {
  name: iotHubName
  location: location
  sku: {
    name: skuName
    capacity: skuUnits
  }
}

var iotHubKeyName = 'iothubowner'
var iotHubConnectionString = 'HostName=${hub.properties.hostName};SharedAccessKeyName=${iotHubKeyName};SharedAccessKey=${listkeys(resourceId('Microsoft.Devices/Iothubs/Iothubkeys', hub.name, iotHubKeyName), '2020-03-01').primaryKey}'

output connectionString string = iotHubConnectionString
output eventHubEndPoint string = hub.properties.eventHubEndpoints.events.endpoint
output eventHubPath string = hub.properties.eventHubEndpoints.events.path
output iothubownerKey string = listkeys(resourceId('Microsoft.Devices/Iothubs/Iothubkeys', iotHubName, 'iothubowner'), '2020-03-01').primarykey
output serviceKey string = listkeys(resourceId('Microsoft.Devices/Iothubs/Iothubkeys', iotHubName, 'service'), '2020-03-01').primarykey
// not presently used - exposed just in case
output deviceKey string = listkeys(resourceId('Microsoft.Devices/Iothubs/Iothubkeys', iotHubName, 'device'), '2020-03-01').primarykey
