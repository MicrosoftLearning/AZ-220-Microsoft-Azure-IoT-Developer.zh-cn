@description('Your unique ID - i.e. dm041221')
param yourID string
@description('Course ID - i.e. az220')
param courseID string
@description('Resource Group for VM')
param vmResourceGroup string
@description('User name for the Virtual Machine.')
param adminUsername string
@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended for production.')
param authenticationType string = 'password'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

var location = resourceGroup().location
// var groupName = resourceGroup().name
var iotHubName = 'iot-${courseID}-training-${yourID}'
var identityName = '${courseID}ID'
// b24988ac-6180-42a0-ab88-20f7382dd24c is the Contributer role ID
var contributorRoleDefinitionId = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
var gatewayDeviceID = 'vm-az220-training-gw0002-${yourID}'
var deviceID = 'sensor-th-0084'

module vmRG './modules/createRG.bicep' = {
  name: 'vmRG'
  scope: subscription()
  params: {
    resourceGroupName: vmResourceGroup
    resourceGroupLocation: location
  }
}

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
//

var scriptIdentity = {
  type: 'UserAssigned'
  userAssignedIdentities: {
    '${uai.id}': {}
  }
}

module createDevices './modules/lab14Devices.bicep' = {
  name: 'createDevice'
  dependsOn: [
    hub
    uaiRole
  ]
  params: {
    iotHubName: iotHubName
    deviceID: deviceID
    parentDeviceID: gatewayDeviceID
    scriptIdentity: scriptIdentity
  }
}

module createVM './modules/lab14VM.bicep' = {
  name: 'createLab14VM'
  dependsOn: [
    createDevices
  ]
  params: {
    virtualMachineName: gatewayDeviceID
    deviceConnectionString: createDevices.outputs.gatewayConnectionString
    authenticationType: authenticationType
    adminUsername: adminUsername
    adminPasswordOrKey: adminPasswordOrKey
  }
  scope: resourceGroup(vmResourceGroup)
}

output connectionString string = hub.outputs.connectionString
output deviceConnectionString string = createDevices.outputs.deviceConnectionString
output gatewayConnectionString string = createDevices.outputs.gatewayConnectionString
output devicePrimaryKey string = createDevices.outputs.primaryKey

output publicFQDN string = createVM.outputs.PublicFQDN
output publicSSH string = createVM.outputs.PublicSSH
