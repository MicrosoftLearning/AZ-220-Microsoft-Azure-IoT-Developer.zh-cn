param resourceGroupName string
param resourceGroupLocation string

targetScope = 'subscription'
resource rg 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: resourceGroupName
  location: resourceGroupLocation
}

output resourceGroupName string = rg.name
