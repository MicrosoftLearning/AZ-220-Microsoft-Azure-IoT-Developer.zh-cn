# 演示：创建并管理文件共享和快照

>**备注**：这些步骤需要一个存储帐户。 

## 创建文件共享并上传文件

1. 访问你的存储帐户，然后单击“**文件**”。
2. 单击 **+文件共享**，命 **名** 新文件共享并给予 **配额**。
3. 创建文件共享后，**上传**文件。 
4. 请注意“**添加目录**”、“**删除共享**”和编辑“**配额**”的能力。

## 管理快照

1. 访问文件共享。
1. 选择“**创建快照**”。
1. 选择“**查看快照**”并验证已创建快照。
1. 单击快照并验证其是否包含你上传的文件。
1. 单击属于快照的文件，并查看**文件属性**。 
1. 注意“**下载**”和“**恢复**”快照文件的选项。 
1. 访问文件共享并删除之前上传的文件。
1. 从快照**恢复**文件。 
 
## 创建文件共享 (PowerShell)

1. 为你的存储帐户和密钥创建背景。该背景涵盖了存储帐户名和帐户密钥。

    ```PowerShell
    $storageContext = New-AzStorageContext storage-account-name storage-account-key
    ```

2. 创建文件共享。文件共享的名称必须全部小写。

    ```PowerShell
    $share = New-AzStorageShare logs -Context $storageContext
    ```

## 装载文件共享 (PowerShell)

1. 从常规（即未提升的）PowerShell 会话运行以下命令，以装载 Azure 文件共享。记得使用适当的信息替换 **your-resource-group-name、your-storage-account-name、your-file-share-name** 和 **desired-drive-letter**。

    ```PowerShell
    $resourceGroupName = "your-resource-group-name"
    $storageAccountName = "your-storage-account-name"
    $fileShareName = "your-file-share-name"

    # These commands require you to be logged into your Azure account, run Login-AzAccount if you haven't
    # already logged in.
    $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName
    $storageAccountKeys = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName
    $fileShare = Get-AzStorageShare -Context $storageAccount.Context | Where-Object { 
        $_.Name -eq $fileShareName -and $_.IsSnapshot -eq $false
    }

    if ($fileShare -eq $null) {
        throw [System.Exception]::new("Azure file share not found")
    }

    # The value given to the root parameter of the New-PSDrive cmdlet is the host address for the storage account, 
    # storage-account.file.core.windows.net for Azure Public Regions. $fileShare.StorageUri.PrimaryUri.Host is 
    # used because non-Public Azure regions, such as sovereign clouds or Azure Stack deployments, will have different 
    # hosts for Azure file shares (and other storage resources).
    $password = ConvertTo-SecureString -String $storageAccountKeys[0].Value -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential -ArgumentList "AZURE\$($storageAccount.StorageAccountName)", $password
    New-PSDrive -Name desired-drive-letter -PSProvider FileSystem -Root "\\$($fileShare.StorageUri.PrimaryUri.Host)\$($fileShare.Name)" -Credential $credential -Persist
    ```

2. 完成后，可以通过运行以下命令卸除文件共享：

    ```PowerShell
    Remove-PSDrive -Name desired-drive-letter
    ```
