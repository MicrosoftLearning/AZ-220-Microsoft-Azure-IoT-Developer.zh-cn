@description('Determines whether or not a new Event Hub is provisioned.')
param eventHubNewOrExisting string = 'new'

@description('If you have an existing Event Hub provide the Resource Group name here.')
param eventHubResourceGroup string = resourceGroup().name

@description('The namespace of the source event hub.')
param eventHubNamespaceName string = 'tsiquickstartns'

@description('The name of the source event hub.')
param eventHubName string = 'tsiquickstarteh'

@description('The name of the consumer group that the Time Series Insights service will use to read the data from the event hub. NOTE: To avoid resource contention, this consumer group must be dedicated to the Time Series Insights service and not shared with other readers.')
param consumerGroupName string = 'tsiquickstart'

@maxLength(90)
@description('Name of the environment. The name cannot include:   \'<\', \'>\', \'%\', \'&\', \':\', \'\\\', \'?\', \'/\' and any control characters. All other characters are allowed.')
param environmentName string = 'tsiquickstart'

@maxLength(90)
@description('An optional friendly name to show in tooling or user interfaces instead of the environment name.')
param environmentDisplayName string = 'tsiquickstart'

@allowed([
  'S1'
  'S2'
])
@description('The name of the sku. For more information, see https://azure.microsoft.com/pricing/details/time-series-insights/')
param environmentSkuName string = 'S1'

@minValue(1)
@maxValue(10)
@description('The unit capacity of the Sku. For more information, see https://azure.microsoft.com/pricing/details/time-series-insights/')
param environmentSkuCapacity int = 1

@description('The minimum timespan the environment’s events will be available for query. The value must be specified in the ISO 8601 format, e.g. "P30D" for a retention policy of 30 days.')
param environmentDataRetentionTime string = 'P30D'

@maxLength(90)
@description('Name of the event source child resource. The name cannot include:   \'<\', \'>\', \'%\', \'&\', \':\', \'\\\', \'?\', \'/\' and any control characters. All other characters are allowed.')
param eventSourceName string = 'tsiquickstart'

@maxLength(90)
@description('An optional friendly name to show in tooling or user interfaces instead of the event source name.')
param eventSourceDisplayName string = 'tsiquickstart'

@maxLength(90)
@description('The event property that will be used as the event source\'s timestamp. If a value isn\'t specified for timestampPropertyName, or if null or empty-string is specified, the event creation time will be used.')
param eventSourceTimestampPropertyName string = ''

@description('The name of the shared access key that the Time Series Insights service will use to connect to the event hub.')
param eventSourceKeyName string = 'manage'

@description('A list of object ids of the users or applications in AAD that should have Reader access to the environment. The service principal objectId can be obtained by calling the Get-AzureRMADUser or the Get-AzureRMADServicePrincipal cmdlets. Creating an access policy for AAD groups is not yet supported.')
param accessPolicyReaderObjectIds array = []

@description('A list of object ids of the users or applications in AAD that should have Contributor access to the environment. The service principal objectId can be obtained by calling the Get-AzureRMADUser or the Get-AzureRMADServicePrincipal cmdlets. Creating an access policy for AAD groups is not yet supported.')
param accessPolicyContributorObjectIds array = []

@description('Location for all resources.')
param location string = resourceGroup().location

var environmentTagsOptions = [
  null
  {
    displayName: environmentDisplayName
  }
]
var environmentTagsValue = environmentTagsOptions[length(take(environmentDisplayName, 1))]
var eventSourceTagsOptions = [
  null
  {
    displayName: eventSourceDisplayName
  }
]
var eventSourceTagsValue = eventSourceTagsOptions[length(take(eventSourceDisplayName, 1))]
var eventSourceResourceId = resourceId(eventHubResourceGroup, 'Microsoft.EventHub/Namespaces/EventHubs', eventHubNamespaceName, eventHubName)

resource eventHubNamespaceName_resource 'Microsoft.EventHub/namespaces@2017-04-01' = if (eventHubNewOrExisting == 'new') {
  name: eventHubNamespaceName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    isAutoInflateEnabled: true
    maximumThroughputUnits: 20
  }
}

resource eventHubNamespaceName_eventHubName 'Microsoft.EventHub/namespaces/eventhubs@2017-04-01' = if (eventHubNewOrExisting == 'new') {
  parent: eventHubNamespaceName_resource
  name: '${eventHubName}'
  properties: {
    messageRetentionInDays: 7
    partitionCount: 4
  }
}

resource eventHubNamespaceName_eventHubName_eventSourceKeyName 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2017-04-01' = if (eventHubNewOrExisting == 'new') {
  parent: eventHubNamespaceName_eventHubName
  name: eventSourceKeyName
  location: location
  properties: {
    rights: [
      'Listen'
      'Send'
      'Manage'
    ]
  }
}

resource eventHubNamespaceName_eventHubName_consumerGroupName 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2017-04-01' = if (eventHubNewOrExisting == 'new') {
  parent: eventHubNamespaceName_eventHubName
  name: consumerGroupName
}

resource environmentName_resource 'Microsoft.TimeSeriesInsights/environments@2017-11-15' = {
  name: environmentName
  location: location
  properties: {
    dataRetentionTime: environmentDataRetentionTime
  }
  sku: {
    name: environmentSkuName
    capacity: environmentSkuCapacity
  }
  tags: environmentTagsValue
}

resource environmentName_eventSourceName 'Microsoft.TimeSeriesInsights/environments/eventsources@2017-11-15' = {
  parent: environmentName_resource
  name: '${eventSourceName}'
  location: location
  kind: 'Microsoft.EventHub'
  properties: {
    eventSourceResourceId: eventSourceResourceId
    eventHubName: eventHubName
    serviceBusNamespace: eventHubNamespaceName
    consumerGroupName: consumerGroupName
    keyName: eventSourceKeyName
    sharedAccessKey: listkeys(resourceId(eventHubResourceGroup, 'Microsoft.EventHub/Namespaces/EventHubs/AuthorizationRules', eventHubNamespaceName, eventHubName, eventSourceKeyName), '2017-04-01').primaryKey
    timestampPropertyName: eventSourceTimestampPropertyName
  }
  tags: eventSourceTagsValue
  dependsOn: [
    eventHubNamespaceName_resource
    eventHubNamespaceName_eventHubName_consumerGroupName
    eventHubNamespaceName_eventHubName_eventSourceKeyName
  ]
}

resource environmentName_readerAccessPolicy 'Microsoft.TimeSeriesInsights/environments/accessPolicies@2017-11-15' = [for i in range(0, (empty(accessPolicyReaderObjectIds) ? 1 : length(accessPolicyReaderObjectIds))): if (!empty(accessPolicyReaderObjectIds)) {
  name: '${environmentName}/readerAccessPolicy${i}'
  properties: {
    principalObjectId: accessPolicyReaderObjectIds[i]
    roles: [
      'Reader'
    ]
  }
  dependsOn: [
    environmentName_resource
  ]
}]

resource environmentName_contributorAccessPolicy 'Microsoft.TimeSeriesInsights/environments/accessPolicies@2017-11-15' = [for i in range(0, (empty(accessPolicyContributorObjectIds) ? 1 : length(accessPolicyContributorObjectIds))): if (!empty(accessPolicyContributorObjectIds)) {
  name: '${environmentName}/contributorAccessPolicy${i}'
  properties: {
    principalObjectId: accessPolicyContributorObjectIds[i]
    roles: [
      'Contributor'
    ]
  }
  dependsOn: [
    environmentName_resource
  ]
}]

output dataAccessFQDN string = environmentName_resource.properties.dataAccessFqdn