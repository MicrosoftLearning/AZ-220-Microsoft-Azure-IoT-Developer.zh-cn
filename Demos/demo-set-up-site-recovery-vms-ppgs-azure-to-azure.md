# 演示：在“邻近放置组”为虚拟机设置站点恢复 - Azure 到 Azure

> **备注：** 此功能目前通过 PowerShell 提供，并支持任何使用托管磁盘的 Azure VM。

## 先决条件

1. 确保拥有 Azure PowerShell Az 模块。如果需要安装或升级 Azure PowerShell，请按照以下步骤操作[安装和配置 Azure PowerShell 指南](https://docs.microsoft.com/powershell/azure/install-az-ps?view=azps-5.0.0)。
2. 最低的 Azure PowerShell Az 版本应为 4.1.0。要查看当前版本，请使用以下命令：

    ```azurepowershell
	Get-InstalledModule -Name Az
    ```

>**备注：** 确保你拥有可用的目标邻近放置组的唯一 ID。如果要创建新的邻近放置组，请查看[此处](https://docs.microsoft.com/azure/virtual-machines/windows/proximity-placement-groups#create-a-proximity-placement-group)的命令，如果使用的是现有邻近放置组，请使用[此处](https://docs.microsoft.com/azure/virtual-machines/windows/proximity-placement-groups#list-proximity-placement-groups)的命令。

## 登录到你的 Microsoft Azure 订阅

1. 使用 `Connect-AzAccount` cmdlet 登录到你的 Azure 订阅。

    ```azurepowershell
    Connect-AzAccount
    ```

1. 选择你的 Azure 订阅。使用 `Get-AzSubscription` cmdlet 获取有权访问的 Azure 订阅的列表。使用 `Set-AzContext` cmdlet 选择要使用的 Azure 订阅。

    ```azurepowershell
    Set-AzContext -SubscriptionId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    ```

## 获取要复制的虚拟机的详细信息

1. 在此演示中，将美国东部区域的虚拟机复制到美国西部 2 区域并进行恢复。要复制的虚拟机具有一个 OS 磁盘和一个数据磁盘。该示例中所用虚拟机的名称为 `AzureDemoVM`。

    ```azurepowershell
    # Get details of the virtual machine
    $VM = Get-AzVM -ResourceGroupName "A2AdemoRG" -Name "AzureDemoVM"

    Write-Output $VM
    ```

    ```Output
    ResourceGroupName  : A2AdemoRG
    Id                 : /subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/A2AdemoRG/providers/Microsoft.Compute/virtualMachines/AzureDemoVM
    VmId               : 1b864902-c7ea-499a-ad0f-65da2930b81b
    Name               : AzureDemoVM
    Type               : Microsoft.Compute/virtualMachines
    Location           : eastus
    Tags               : {}
    DiagnosticsProfile : {BootDiagnostics}
    HardwareProfile    : {VmSize}
    NetworkProfile     : {NetworkInterfaces}
    OSProfile          : {ComputerName, AdminUsername, WindowsConfiguration, Secrets}
    ProvisioningState  : Succeeded
    StorageProfile     : {ImageReference, OsDisk, DataDisks}
    ```

1. 获取虚拟机磁盘的磁盘详细信息。磁盘详细信息将在以后为虚拟机启动复制时使用。

    ```azurepowershell
    $OSDiskVhdURI = $VM.StorageProfile.OsDisk.Vhd
    $DataDisk1VhdURI = $VM.StorageProfile.DataDisks[0].Vhd
    ```

## 创建恢复服务保管库

1. 创建一个要在其中创建恢复服务保管库的资源组。

    > **重要说明：**
    > * 恢复服务保管库和受保护的虚拟机必须位于不同的 Azure 位置。
    > * 恢复服务保管库的资源组和受保护的虚拟机必须位于不同的 Azure 位置。
    > * 恢复服务保管库及其所属的资源组可以位于相同的 Azure 位置。

1. 在此演示中，受保护的虚拟机位于美国东部区域。选择用于灾难恢复的恢复区域是美国西部 2 区域。恢复服务保管库和保管库的资源组均位于美国西部 2 恢复区域。

    ```azurepowershell
    #Create a resource group for the recovery services vault in the recovery Azure region
    New-AzResourceGroup -Name "a2ademorecoveryrg" -Location "West US 2"
    ```

    ```Output
    ResourceGroupName : a2ademorecoveryrg
    Location          : westus2
    ProvisioningState : Succeeded
    Tags              :
    ResourceId        : /subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/a2ademorecoveryrg
    ```

1. 创建恢复服务保管库。在此示例中，在美国西部 2 区域创建了名为“a2aDemoRecoveryVault”的恢复服务保管库。

    ```azurepowershell
    #Create a new Recovery services vault in the recovery region
    $vault = New-AzRecoveryServicesVault -Name "a2aDemoRecoveryVault" -ResourceGroupName "a2ademorecoveryrg" -Location "West US 2"

    Write-Output $vault
    ```

    ```Output
    Name              : a2aDemoRecoveryVault
    ID                : /subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/a2ademorecoveryrg/providers/Microsoft.RecoveryServices/vaults/a2aDemoRecoveryVault
    Type              : Microsoft.RecoveryServices/vaults
    Location          : westus2
    ResourceGroupName : a2ademorecoveryrg
    SubscriptionId    : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    Properties        : Microsoft.Azure.Commands.RecoveryServices.ARSVaultProperties
    ```

## 设置保管库上下文

1. 设置要在 PowerShell 会话中使用的保管库上下文。设置保管库上下文之后，将在所选保管库的上下文中执行 PowerShell 会话中的 Azure Site Recovery 操作。

    ```azurepowershell
    #Setting the vault context.
    Set-AzRecoveryServicesAsrVaultContext -Vault $vault
    ```

    ```Output
    ResourceName         ResourceGroupName ResourceNamespace          ResourceType
    ------------         ----------------- -----------------          -----------
    a2aDemoRecoveryVault a2ademorecoveryrg Microsoft.RecoveryServices Vaults
    ```

    ```azurepowershell
    #Delete the downloaded vault settings file
    Remove-Item -Path $Vaultsettingsfile.FilePath
    ```

1. 对于 Azure 到 Azure 迁移，可以将保管库上下文设置为新创建的保管库：

    ```azurepowershell
    #Set the vault context for the PowerShell session.
    Set-AzRecoveryServicesAsrVaultContext -Vault $vault
    ```

## 准备保管库以开始复制 Azure 虚拟机

### 创建站点恢复结构对象以表示主要（源）区域

保管库中的结构对象表示 Azure 区域。创建主要结构对象以表示受保管库保护的虚拟机所属的 Azure 区域。在此演示中，受保护的虚拟机位于美国东部区域。

- 每个区域只能创建一个结构对象。
- 如果先前已在 Azure 门户中为 VM 启用了站点恢复复制，则站点恢复会自动创建一个结构对象。如果某个区域存在结构对象，则无法创建新的结构对象。

开始前，请了解站点恢复操作是异步执行的。启动操作时，将提交 Azure Site Recovery 作业，并返回作业跟踪对象。

1. 使用作业跟踪对象获取作业的最新状态 (`Get-AzRecoveryServicesAsrJob`)，并监视操作状态。

    ```azurepowershell
    #Create Primary ASR fabric
    $TempASRJob = New-AzRecoveryServicesAsrFabric -Azure -Location 'East US'  -Name "A2Ademo-EastUS"

    # Track Job status to check for completion
    while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
            #If the job hasn't completed, sleep for 10 seconds before checking the job status again
            sleep 10;
            $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
    }

    #Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
    Write-Output $TempASRJob.State

    $PrimaryFabric = Get-AzRecoveryServicesAsrFabric -Name "A2Ademo-EastUS"
    ```

1. 如果由同一保管库保护来自多个 Azure 区域的虚拟机，则要为每个源 Azure 区域创建一个结构对象。

### 创建站点恢复结构对象以表示恢复区域

恢复结构对象表示恢复 Azure 位置。如果发生故障转移，则虚拟机将被复制并恢复到由恢复结构表示的恢复区域。本示例中使用的恢复 Azure 区域是美国西部 2。

```azurepowershell
#Create Recovery ASR fabric
$TempASRJob = New-AzRecoveryServicesAsrFabric -Azure -Location 'West US 2'  -Name "A2Ademo-WestUS"

# Track Job status to check for completion
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

#Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
Write-Output $TempASRJob.State

$RecoveryFabric = Get-AzRecoveryServicesAsrFabric -Name "A2Ademo-WestUS"
```

## 创建站点恢复保护容器

### 在主结构中创建站点恢复保护容器

保护容器是用于将结构中复制的项分组的容器。

```azurepowershell
#Create a Protection container in the primary Azure region (within the Primary fabric)
$TempASRJob = New-AzRecoveryServicesAsrProtectionContainer -InputObject $PrimaryFabric -Name "A2AEastUSProtectionContainer"

#Track Job status to check for completion
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

Write-Output $TempASRJob.State

$PrimaryProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $PrimaryFabric -Name "A2AEastUSProtectionContainer"
```

### 在恢复结构中创建站点恢复保护容器

```azurepowershell
#Create a Protection container in the recovery Azure region (within the Recovery fabric)
$TempASRJob = New-AzRecoveryServicesAsrProtectionContainer -InputObject $RecoveryFabric -Name "A2AWestUSProtectionContainer"

#Track Job status to check for completion
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

#Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"

Write-Output $TempASRJob.State

$RecoveryProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $RecoveryFabric -Name "A2AWestUSProtectionContainer"
```

## 创建复制策略

```azurepowershell
#Create replication policy
$TempASRJob = New-AzRecoveryServicesAsrPolicy -AzureToAzure -Name "A2APolicy" -RecoveryPointRetentionInHours 24 -ApplicationConsistentSnapshotFrequencyInHours 4

#Track Job status to check for completion
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

#Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
Write-Output $TempASRJob.State

$ReplicationPolicy = Get-AzRecoveryServicesAsrPolicy -Name "A2APolicy"
```

## 创建保护容器映射

### 在主保护容器和恢复保护容器之间创建保护容器映射

保护容器映射将主保护容器与恢复保护容器和复制策略一起映射。为每个用于在保护容器对之间复制虚拟机的复制策略创建一个映射。

```azurepowershell
#Create Protection container mapping between the Primary and Recovery Protection Containers with the Replication policy
$TempASRJob = New-AzRecoveryServicesAsrProtectionContainerMapping -Name "A2APrimaryToRecovery" -Policy $ReplicationPolicy -PrimaryProtectionContainer $PrimaryProtContainer -RecoveryProtectionContainer $RecoveryProtContainer

#Track Job status to check for completion
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

#Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
Write-Output $TempASRJob.State

$EusToWusPCMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $PrimaryProtContainer -Name "A2APrimaryToRecovery"
```

### 创建用于故障回复的保护容器映射（故障转移后进行反向复制）

故障转移后，准备好将故障转移虚拟机带回原始 Azure 区域时，请执行故障回复。要进行故障回复，需要将故障转移虚拟机从故障转移区域反向复制到原始区域。为了实现反向复制，需要将原始区域和恢复区域的角色进行交换。原始区域现在变为新的恢复区域，而原来的恢复区域现在变为主要区域。用于反向复制的保护容器映射表示原始区域和恢复区域交换的角色。

```azurepowershell
#Create Protection container mapping (for fail back) between the Recovery and Primary Protection Containers with the Replication policy
$TempASRJob = New-AzRecoveryServicesAsrProtectionContainerMapping -Name "A2ARecoveryToPrimary" -Policy $ReplicationPolicy -PrimaryProtectionContainer $RecoveryProtContainer -RecoveryProtectionContainer $PrimaryProtContainer

#Track Job status to check for completion
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

#Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
Write-Output $TempASRJob.State

$WusToEusPCMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $RecoveryProtContainer -Name "A2ARecoveryToPrimary"
```

## 创建高速缓存存储帐户和目标存储帐户

高速缓存存储帐户是与要复制的虚拟机位于同一 Azure 区域中的标准存储帐户。缓存存储帐户用于在将复制更改移至恢复 Azure 区域之前临时保留这些更改。可以选择（但不是必须）为虚拟机的不同磁盘指定不同的缓存存储帐户。

```azurepowershell
#Create Cache storage account for replication logs in the primary region
$EastUSCacheStorageAccount = New-AzStorageAccount -Name "a2acachestorage" -ResourceGroupName "A2AdemoRG" -Location 'East US' -SkuName Standard_LRS -Kind Storage
```

对于**不使用托管磁盘**的虚拟机，目标存储帐户是要将虚拟机磁盘复制到的恢复区域中的存储帐户。目标存储帐户可以是标准存储帐户，也可以是高级存储帐户。根据磁盘的数据更改率（IO 写入率）和 Azure Site Recovery 支持的存储类型的流失限制，选择所需的存储帐户类型。

```azurepowershell
#Create Target storage account in the recovery region. In this case a Standard Storage account
$WestUSTargetStorageAccount = New-AzStorageAccount -Name "a2atargetstorage" -ResourceGroupName "a2ademorecoveryrg" -Location 'West US 2' -SkuName Standard_LRS -Kind Storage
```

## 创建网络映射

网络映射将主要区域中的虚拟网络映射到恢复区域中的虚拟网络。网络映射在主要虚拟网络中的虚拟机应故障转移到的恢复区域中指定 Azure 虚拟网络。一个 Azure 虚拟网络只能映射到一个恢复区域中的单个 Azure 虚拟网络。

1. 在恢复区域中创建一个 Azure 虚拟网络以故障转移到：

   ```azurepowershell
    #Create a Recovery Network in the recovery region
    $WestUSRecoveryVnet = New-AzVirtualNetwork -Name "a2arecoveryvnet" -ResourceGroupName "a2ademorecoveryrg" -Location 'West US 2' -AddressPrefix "10.0.0.0/16"

    Add-AzVirtualNetworkSubnetConfig -Name "default" -VirtualNetwork $WestUSRecoveryVnet -AddressPrefix "10.0.0.0/20" | Set-AzVirtualNetwork

    $WestUSRecoveryNetwork = $WestUSRecoveryVnet.Id
   ```

1. 检索主虚拟网络。虚拟机连接的 VNet：

   ```azurepowershell
    #Retrieve the virtual network that the virtual machine is connected to

    #Get first network interface card(nic) of the virtual machine
    $SplitNicArmId = $VM.NetworkProfile.NetworkInterfaces[0].Id.split("/")

    #Extract resource group name from the ResourceId of the nic
    $NICRG = $SplitNicArmId[4]

    #Extract resource name from the ResourceId of the nic
    $NICname = $SplitNicArmId[-1]

    #Get network interface details using the extracted resource group name and resource name
    $NIC = Get-AzNetworkInterface -ResourceGroupName $NICRG -Name $NICname

    #Get the subnet ID of the subnet that the nic is connected to
    $PrimarySubnet = $NIC.IpConfigurations[0].Subnet

    # Extract the resource ID of the Azure virtual network the nic is connected to from the subnet ID
    $EastUSPrimaryNetwork = (Split-Path(Split-Path($PrimarySubnet.Id))).Replace("\","/")
   ```

1. 在主虚拟网络和恢复虚拟网络之间创建网络映射：

   ```azurepowershell
    #Create an ASR network mapping between the primary Azure virtual network and the recovery Azure virtual network
    $TempASRJob = New-AzRecoveryServicesAsrNetworkMapping -AzureToAzure -Name "A2AEusToWusNWMapping" -PrimaryFabric $PrimaryFabric -PrimaryAzureNetworkId $EastUSPrimaryNetwork -RecoveryFabric $RecoveryFabric -RecoveryAzureNetworkId $WestUSRecoveryNetwork

    #Track Job status to check for completion
    while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
            sleep 10;
            $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
    }

    #Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
    Write-Output $TempASRJob.State
   ```

1. 创建反向（故障回复）网络映射：

    ```azurepowershell
    #Create an ASR network mapping for fail back between the recovery Azure virtual network and the primary Azure virtual network
    $TempASRJob = New-AzRecoveryServicesAsrNetworkMapping -AzureToAzure -Name "A2AWusToEusNWMapping" -PrimaryFabric $RecoveryFabric -PrimaryAzureNetworkId $WestUSRecoveryNetwork -RecoveryFabric $PrimaryFabric -RecoveryAzureNetworkId $EastUSPrimaryNetwork

    #Track Job status to check for completion
    while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
            sleep 10;
            $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
    }

    #Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
    Write-Output $TempASRJob.State
    ```

## 复制包含托管磁盘的 Azure 虚拟机

使用以下 PowerShell cmdlet，复制包含托管磁盘的 Azure 虚拟机：

    ```azurepowershell
    #Get the resource group that the virtual machine must be created in when it's failed over.
    $RecoveryRG = Get-AzResourceGroup -Name "a2ademorecoveryrg" -Location "West US 2"

    #Specify replication properties for each disk of the VM that will be replicated (create disk replication configuration).
    #Make sure to replace the variable $OSdiskName with the OS disk name.

    #OS Disk
    $OSdisk = Get-AzDisk -DiskName $OSdiskName -ResourceGroupName "A2AdemoRG"
    $OSdiskId = $OSdisk.Id
    $RecoveryOSDiskAccountType = $OSdisk.Sku.Name
    $RecoveryReplicaDiskAccountType = $OSdisk.Sku.Name

    $OSDiskReplicationConfig = New-AzRecoveryServicesAsrAzureToAzureDiskReplicationConfig -ManagedDisk -LogStorageAccountId $EastUSCacheStorageAccount.Id -DiskId $OSdiskId -RecoveryResourceGroupId $RecoveryRG.ResourceId -RecoveryReplicaDiskAccountType $RecoveryReplicaDiskAccountType -RecoveryTargetDiskAccountType $RecoveryOSDiskAccountType

    #Make sure to replace the variable $datadiskName with the data disk name.

    #Data disk
    $datadisk = Get-AzDisk -DiskName $datadiskName -ResourceGroupName "A2AdemoRG"
    $datadiskId1 = $datadisk[0].Id
    $RecoveryReplicaDiskAccountType = $datadisk[0].Sku.Name
    $RecoveryTargetDiskAccountType = $datadisk[0].Sku.Name

    $DataDisk1ReplicationConfig  = New-AzRecoveryServicesAsrAzureToAzureDiskReplicationConfig -ManagedDisk -LogStorageAccountId $EastUSCacheStorageAccount.Id -DiskId $datadiskId1 -RecoveryResourceGroupId $RecoveryRG.ResourceId -RecoveryReplicaDiskAccountType $RecoveryReplicaDiskAccountType -RecoveryTargetDiskAccountType $RecoveryTargetDiskAccountType

    #Create a list of disk replication configuration objects for the disks of the virtual machine that will be replicated.

    $diskconfigs = @()
    $diskconfigs += $OSDiskReplicationConfig, $DataDisk1ReplicationConfig

    #Start replication by creating a replication protected item. Use a GUID for the name of the replication protected item to ensure uniqueness of the name.

    $TempASRJob = New-AzRecoveryServicesAsrReplicationProtectedItem -AzureToAzure -AzureVmId $VM.Id -Name (New-Guid).Guid -ProtectionContainerMapping $EusToWusPCMapping -AzureToAzureDiskReplicationConfiguration $diskconfigs -RecoveryResourceGroupId $RecoveryRG.ResourceId -RecoveryProximityPlacementGroupId $targetPpg.Id
    ```

为多个数据磁盘启用复制时，请使用以下 PowerShell cmdlet：

    ```azurepowershell
    #Get the resource group that the virtual machine must be created in when it's failed over.
    $RecoveryRG = Get-AzResourceGroup -Name "a2ademorecoveryrg" -Location "West US 2"

    #Specify replication properties for each disk of the VM that will be replicated (create disk replication configuration).
    #Make sure to replace the variable $OSdiskName with the OS disk name.

    #OS Disk
    $OSdisk = Get-AzDisk -DiskName $OSdiskName -ResourceGroupName "A2AdemoRG"
    $OSdiskId = $OSdisk.Id
    $RecoveryOSDiskAccountType = $OSdisk.Sku.Name
    $RecoveryReplicaDiskAccountType = $OSdisk.Sku.Name

    $OSDiskReplicationConfig = New-AzRecoveryServicesAsrAzureToAzureDiskReplicationConfig -ManagedDisk -LogStorageAccountId $EastUSCacheStorageAccount.Id -DiskId $OSdiskId -RecoveryResourceGroupId $RecoveryRG.ResourceId -RecoveryReplicaDiskAccountType $RecoveryReplicaDiskAccountType -RecoveryTargetDiskAccountType $RecoveryOSDiskAccountType

    $diskconfigs = @()
    $diskconfigs += $OSDiskReplicationConfig

    #Data disk

    # Add data disks
    Foreach( $disk in $VM.StorageProfile.DataDisks)
    {
 	    $datadisk = Get-AzDisk -DiskName $datadiskName -ResourceGroupName "A2AdemoRG"
        $dataDiskId1 = $datadisk[0].Id
        $RecoveryReplicaDiskAccountType = $datadisk[0].Sku.Name
        $RecoveryTargetDiskAccountType = $datadisk[0].Sku.Name
        $DataDisk1ReplicationConfig  = New-AzRecoveryServicesAsrAzureToAzureDiskReplicationConfig -ManagedDisk -LogStorageAccountId $EastUSCacheStorageAccount.Id `
             -DiskId $dataDiskId1 -RecoveryResourceGroupId $RecoveryRG.ResourceId -RecoveryReplicaDiskAccountType $RecoveryReplicaDiskAccountType `
             -RecoveryTargetDiskAccountType $RecoveryTargetDiskAccountType
        $diskconfigs += $DataDisk1ReplicationConfig
    }

    #Start replication by creating a replication protected item. Use a GUID for the name of the replication protected item to ensure uniqueness of the name.

    $TempASRJob = New-AzRecoveryServicesAsrReplicationProtectedItem -AzureToAzure -AzureVmId $VM.Id -Name (New-Guid).Guid -ProtectionContainerMapping $EusToWusPCMapping -AzureToAzureDiskReplicationConfiguration $diskconfigs -RecoveryResourceGroupId $RecoveryRG.ResourceId -RecoveryProximityPlacementGroupId $targetPpg.Id
    ```

通过邻近放置组实现区域到区域复制时，启动复制的命令将将改为以下 PowerShell cmdlet：

    ```azurepowershell
    $TempASRJob = New-AzRecoveryServicesAsrReplicationProtectedItem -AzureToAzure -AzureVmId $VM.Id -Name (New-Guid).Guid -ProtectionContainerMapping $EusToWusPCMapping -AzureToAzureDiskReplicationConfiguration $diskconfigs -RecoveryResourceGroupId $RecoveryRG.ResourceId -RecoveryProximityPlacementGroupId $targetPpg.Id -RecoveryAvailabilityZone "2"
    ```

启动复制操作成功后，虚拟机数据将复制到恢复区域。

复制过程首先在恢复区域中初始植入虚拟机复制磁盘的副本。此阶段称为*初始复制*阶段。

初始复制完成后，复制将转移到*差异同步*阶段。此时，虚拟机受到保护，你可对其执行测试故障转移操作。初始复制完成后，表示虚拟机的复制项的复制状态将变为受保护状态。

通过获取虚拟机对应的复制保护项的详细信息，监视该虚拟机的复制状态和复制运行状况：

    ```azurepowershell
    Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryProtContainer | Select FriendlyName, ProtectionState, ReplicationHealth
    ```

## 执行、验证和清理测试故障转移

虚拟机复制进入受保护状态后，可以针对该虚拟机（针对虚拟机的复制保护项）执行测试故障转移操作。

```azurepowershell
#Create a separate network for test failover (not connected to my DR network)
$TFOVnet = New-AzVirtualNetwork -Name "a2aTFOvnet" -ResourceGroupName "a2ademorecoveryrg" -Location 'West US 2' -AddressPrefix "10.3.0.0/16"

Add-AzVirtualNetworkSubnetConfig -Name "default" -VirtualNetwork $TFOVnet -AddressPrefix "10.3.0.0/20" | Set-AzVirtualNetwork

$TFONetwork= $TFOVnet.Id
```

执行测试故障转移。

```azurepowershell
$ReplicationProtectedItem = Get-AzRecoveryServicesAsrReplicationProtectedItem -FriendlyName "AzureDemoVM" -ProtectionContainer $PrimaryProtContainer

$TFOJob = Start-AzRecoveryServicesAsrTestFailoverJob -ReplicationProtectedItem $ReplicationProtectedItem -AzureVMNetworkId $TFONetwork -Direction PrimaryToRecovery
```

等待测试故障转移操作完成。

```azurepowershell
Get-AzRecoveryServicesAsrJob -Job $TFOJob
```

```Output
Name             : 3dcb043e-3c6d-4e0e-a42e-8d4245668547
ID               : /Subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/a2ademorecoveryrg/providers/Microsoft.RecoveryServices/vaults/a2aDemoR
                   ecoveryVault/replicationJobs/3dcb043e-3c6d-4e0e-a42e-8d4245668547
Type             : Microsoft.RecoveryServices/vaults/replicationJobs
JobType          : TestFailover
DisplayName      : Test failover
ClientRequestId  : 1ef8515b-b130-4452-a44d-91aaf071931c ActivityId: 907bb2bc-ebe6-4732-8b66-77d0546eaba8
State            : Succeeded
StateDescription : Completed
StartTime        : 4/25/2018 4:29:43 AM
EndTime          : 4/25/2018 4:33:06 AM
TargetObjectId   : ce86206c-bd78-53b4-b004-39b722c1ac3a
TargetObjectType : ProtectionEntity
TargetObjectName : azuredemovm
AllowedActions   :
Tasks            : {Prerequisites check for test failover, Create test virtual machine, Preparing the virtual machine, Start the virtual machine}
Errors           : {}
```

测试故障转移作业成功完成后，可以连接到测试故障转移虚拟机，并验证测试故障转移。

对测试故障转移虚拟机完成测试后，通过启动清理测试故障转移操作来清理测试副本。此操作会删除测试故障转移创建的虚拟机测试副本。

```azurepowershell
$Job_TFOCleanup = Start-AzRecoveryServicesAsrTestFailoverCleanupJob -ReplicationProtectedItem $ReplicationProtectedItem

Get-AzRecoveryServicesAsrJob -Job $Job_TFOCleanup | Select State
```

```Output
State
-----
Succeeded
```

## 故障转移虚拟机

将虚拟机故障转移到特定的恢复点。

```azurepowershell
$RecoveryPoints = Get-AzRecoveryServicesAsrRecoveryPoint -ReplicationProtectedItem $ReplicationProtectedItem

#The list of recovery points returned may not be sorted chronologically and will need to be sorted first, in order to be able to find the oldest or the latest recovery points for the virtual machine.
"{0} {1}" -f $RecoveryPoints[0].RecoveryPointType, $RecoveryPoints[-1].RecoveryPointTime
```

```Output
CrashConsistent 4/24/2018 11:10:25 PM
```

```azurepowershell
#Start the fail over job
$Job_Failover = Start-AzRecoveryServicesAsrUnplannedFailoverJob -ReplicationProtectedItem $ReplicationProtectedItem -Direction PrimaryToRecovery -RecoveryPoint $RecoveryPoints[-1]

do {
        $Job_Failover = Get-AzRecoveryServicesAsrJob -Job $Job_Failover;
        sleep 30;
} while (($Job_Failover.State -eq "InProgress") -or ($JobFailover.State -eq "NotStarted"))

$Job_Failover.State
```

```Output
Succeeded
```

故障转移作业成功时，你可以提交故障转移操作。

```azurepowershell
$CommitFailoverJOb = Start-AzRecoveryServicesAsrCommitFailoverJob -ReplicationProtectedItem $ReplicationProtectedItem

Get-AzRecoveryServicesAsrJob -Job $CommitFailoverJOb
```

```Output
Name             : 58afc2b7-5cfe-4da9-83b2-6df358c6e4ff
ID               : /Subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/a2ademorecoveryrg/providers/Microsoft.RecoveryServices/vaults/a2aDemoR
                   ecoveryVault/replicationJobs/58afc2b7-5cfe-4da9-83b2-6df358c6e4ff
Type             : Microsoft.RecoveryServices/vaults/replicationJobs
JobType          : CommitFailover
DisplayName      : Commit
ClientRequestId  : 10a95d6c-359e-4603-b7d9-b7ee3317ce94 ActivityId: 8751ada4-fc42-4238-8de6-a82618408fcf
State            : Succeeded
StateDescription : Completed
StartTime        : 4/25/2018 4:50:58 AM
EndTime          : 4/25/2018 4:51:01 AM
TargetObjectId   : ce86206c-bd78-53b4-b004-39b722c1ac3a
TargetObjectType : ProtectionEntity
TargetObjectName : azuredemovm
AllowedActions   :
Tasks            : {Prerequisite check, Commit}
Errors           : {}
```

## 重新保护并故障恢复到源区域

使用以下 PowerShell cmdlet，重新保护并故障恢复到源区域：

```azurepowershell
#Create a cache storage account for replication logs in the primary region.
$WestUSCacheStorageAccount = New-AzStorageAccount -Name "a2acachestoragewestus" -ResourceGroupName "A2AdemoRG" -Location 'West US' -SkuName Standard_LRS -Kind Storage

#Use the recovery protection container, the new cache storage account in West US, and the source region VM resource group. 
Update-AzRecoveryServicesAsrProtectionDirection -ReplicationProtectedItem $ReplicationProtectedItem -AzureToAzure -ProtectionContainerMapping $WusToEusPCMapping -LogStorageAccountId $WestUSCacheStorageAccount.Id -RecoveryResourceGroupID $sourceVMResourcegroup.ResourceId -RecoveryProximityPlacementGroupId $vm.ProximityPlacementGroup.Id
```

## 禁用复制

可使用 `Remove-AzRecoveryServicesAsrReplicationProtectedItem` cmdlet 禁用复制。

```azurepowershell
Remove-AzRecoveryServicesAsrReplicationProtectedItem -ReplicationProtectedItem $ReplicationProtectedItem
```