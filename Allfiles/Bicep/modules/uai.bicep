@description('Identity name')
param identityName string

// b24988ac-6180-42a0-ab88-20f7382dd24c is the Contributer role ID
var contributorRoleDefinitionId = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'

resource uai 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  location: resourceGroup().location
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

var scriptIdentity = {
  type: 'UserAssigned'
  userAssignedIdentities: {
    '${uai.id}': {}
  }
}

output uaiIdentity object = scriptIdentity
