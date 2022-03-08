param(
    [Parameter(Mandatory = $true)]
    [string]
    $resourceGroup,

    [Parameter(Mandatory = $true)]
    [string]
    $iotHub,

    [Parameter(Mandatory = $true)]
    [string]
    $deviceName
)

$output = "Adding $($deviceName) to $($iotHub)"
Write-Output $output

$deviceDetails = (Get-AzIotHubDeviceConnectionString -ResourceGroupName $resourceGroup -IotHubName $iotHub -DeviceId $deviceName)

if ($null -eq $deviceDetails) {
    Add-AzIotHubDevice -ResourceGroupName $resourceGroup -IotHubName $iotHub -DeviceId $deviceName -AuthMethod "shared_private_key"
    $deviceDetails = (Get-AzIotHubDeviceConnectionString -ResourceGroupName $resourceGroup -IotHubName $iotHub -DeviceId $deviceName)
}
else {
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
