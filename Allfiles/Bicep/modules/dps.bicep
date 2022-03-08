@description('The DPS name')
param provisioningServiceName string

@description('Specify the location of the resources.')
param location string = resourceGroup().location

@description('The SKU to use for the IoT Hub.')
param skuName string = 'S1'

@description('The number of IoT Hub units.')
param skuUnits int = 1

@description('IoT Hub connection string.')
param iotHubConnectionString string

resource provisioningServiceName_resource 'Microsoft.Devices/provisioningServices@2020-01-01' = {
  name: provisioningServiceName
  location: location
  sku: {
    name: skuName
    capacity: skuUnits
  }
  properties: {
    iotHubs: [
      {
        connectionString: iotHubConnectionString
        location: location
      }
    ]
  }
}

output scopeId string = provisioningServiceName_resource.properties.idScope
