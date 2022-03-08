@description('The IoT Hub name')
param iotHubName string

@description('Specify the location of the resources.')
param location string = resourceGroup().location

@description('Specify the Group Name.')
param groupName string = resourceGroup().name

@description('The SKU to use for the IoT Hub.')
param scriptIdentity object

@description('The Device ID')
param deviceID string

@description('Used to uniquely identify the script instance')
param utcValue string = utcNow()

@description('Specify if the device is edge-enabled')
param isEdgeEnabled bool = false

@description('The optional parent device id')
param parentDeviceID string

var scriptName = 'createDevice${utcValue}'

resource devices 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: scriptName
  // Prefer PowerShell over CLI - more reliable
  kind: 'AzurePowerShell'
  location: location
  identity: scriptIdentity
  properties: {
    // Stick with an older version of PowerShell to ensure runtime image is available in all locations
    // It takes "at least" 1 month for new images to be published
    azPowerShellVersion: '6.0'
    retentionInterval: 'PT1H'
    cleanupPreference: 'Always'
    forceUpdateTag: utcValue
    timeout: 'PT10M'
    arguments: '${groupName} ${iotHubName} ${deviceID} ${(isEdgeEnabled ? 'isEdgeEnabled' : '')} ${parentDeviceID}'
    scriptContent: '''
param(
    [Parameter(Mandatory = $true)]
    [string]
    $resourceGroup,

    [Parameter(Mandatory = $true)]
    [string]
    $iotHub,

    [Parameter(Mandatory = $true)]
    [string]
    $deviceName,

    [Parameter(Mandatory = $false)]
    [switch]
    $isEdgeEnabled
)

$output = "Adding $($deviceName) to $($iotHub)"
Write-Output $output

$deviceDetails = (Get-AzIotHubDeviceConnectionString -ResourceGroupName $resourceGroup -IotHubName $iotHub -DeviceId $deviceName)

if ($null -eq $deviceDetails)
{
    if ($isEdgeEnabled -eq $true)
    {
        Add-AzIotHubDevice -ResourceGroupName $resourceGroup -IotHubName $iotHub -DeviceId $deviceName -AuthMethod "shared_private_key" -EdgeEnabled
    }
    else
    {
        Add-AzIotHubDevice -ResourceGroupName $resourceGroup -IotHubName $iotHub -DeviceId $deviceName -AuthMethod "shared_private_key"
    }
    $deviceDetails = (Get-AzIotHubDeviceConnectionString -ResourceGroupName $resourceGroup -IotHubName $iotHub -DeviceId $deviceName)
}
else
{
    Write-Output 'Device exists'
}

$DeploymentScriptOutputs = @{}
$DeploymentScriptOutputs['text'] = $output
$DeploymentScriptOutputs['date'] = (get-date -Format FileDate).toString()
$DeploymentScriptOutputs['deviceId'] = $deviceDetails.DeviceId
$DeploymentScriptOutputs['connectionString'] = $deviceDetails.ConnectionString
# primary key
$DeploymentScriptOutputs['primaryKey'] = ($deviceDetails.ConnectionString -replace ';', "`r`n" | ConvertFrom-StringData).SharedAccessKey

# secondary key
$deviceDetails = (Get-AzIotHubDeviceConnectionString -ResourceGroupName $resourceGroup -IotHubName $iotHub -KeyType secondary -DeviceId $deviceName)
$DeploymentScriptOutputs['secondaryKey'] = ($deviceDetails.ConnectionString -replace ';', "`r`n" | ConvertFrom-StringData).SharedAccessKey
'''
  }
}

output deviceConnectionString string = reference(scriptName).outputs.connectionString
output primaryKey string = reference(scriptName).outputs.primaryKey
output secondaryKey string = reference(scriptName).outputs.secondaryKey
