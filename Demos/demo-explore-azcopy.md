# 演示：探索 AzCopy

## 下载 AzCopy

首先，将 AzCopy V10 可执行文件下载到计算机上的任意目录。AzCopy V10 只是一个可执行文件，因此无需安装任何内容。

- [Windows 64-bit](https://aka.ms/downloadazcopy-v10-windows) (zip)
- [Windows 32-bit](https://aka.ms/downloadazcopy-v10-windows-32bit) (zip)
- [Linux x86-64](https://aka.ms/downloadazcopy-v10-linux) (tar)
- [macOS](https://aka.ms/downloadazcopy-v10-mac) (zip)

这些文件压缩为一个 zip 文件（Windows 和 Mac）或 tar 文件 (Linux)。要在 Linux 上下载并解压缩 tar 文件，请参阅 Linux 分发文档。

## 运行 AzCopy

为方便使用，请考虑将 AzCopy 可执行文件的目录位置添加到系统路径。这样，就可以在系统上的任何目录中键入 `azcopy`。

如果选择不将 AzCopy 目录添加到路径，则必须将目录更改为 AzCopy 可执行文件所在的位置，然后在 Windows PowerShell 命令提示符中键入 `azcopy` 或 `.\azcopy`。

作为 Azure 存储帐户的所有者，系统不会自动向你分配数据访问权限。需要先确定向存储服务提供身份验证凭据的方式，然后才可使用 AzCopy 执行任何有意义的操作。 

## 授权 AzCopy

可以使用 Azure Active Directory (AD) 或共享访问签名 (SAS) 令牌来提供授权凭据。

使用此表作为指南：

| 存储类型 | 当前支持的授权方法 |
|--|--|
|**Blob 存储** | Azure AD 和 SAS |
|**Blob 存储（分层命名空间）** | Azure AD 和 SAS |
|**文件存储** | 仅限 SAS |

### 选项 1：使用 Azure Active Directory

此选项目前仅适用于 Blob 存储。通过使用 Azure Active Directory，可以只提供一次凭据，而无需向每个命令追加 SAS 令牌。  

> **备注：** 在当前版本中，如果你打算在存储帐户之间复制 Blob，必须向每个源 URL 追加一个 SAS 令牌。只能省略目标 URL 中的 SAS 令牌。有关示例，请参阅[在存储帐户之间复制 Blob](https://docs.microsoft.com/azure/storage/common/storage-use-azcopy-v10#transfer-data)。

若要使用 Azure AD 授予访问权限，请参阅[使用 AzCopy 和 Azure Active Directory (Azure AD) 授予对 Blob 的访问权限](https://docs.microsoft.com/azure/storage/common/storage-use-azcopy-authorize-azure-active-directory)。

### 选项 2：使用 SAS 令牌

可将 SAS 令牌追加到在 AzCopy 命令中使用的每个源或目标 URL。

此示例命令以递归方式将本地目录中的数据复制到 Blob 容器。将一个虚构的 SAS 令牌追加到容器 URL 的末尾。

```azcopy
azcopy copy "C:\local\path" "https://account.blob.core.windows.net/mycontainer1/?sv=2018-03-28&ss=bjqt&srt=sco&sp=rwddgcup&se=2019-05-01T05:01:17Z&st=2019-04-30T21:01:17Z&spr=https&sig=MGCXiyEzbtttkr3ewJIh2AR8KrghSy1DGM9ovN734bQF4%3D" --recursive=true
```

若要详细了解 SAS 令牌及其获取方式，请参阅[使用共享访问签名 (SAS) 授予对 Azure 存储资源的受限访问权限](https://docs.microsoft.com/azure/storage/common/storage-sas-overview)。

> **备注：** 存储帐户的“[需要安全传输](storage-require-secure-transfer.md)”设置决定了与存储帐户的连接是否通过传输层安全性 (TLS) 进行保护。默认情况下，此设置处于启用状态。   

## 浏览帮助内容

1. 若要查看命令列表，请键入 `azcopy -h`，然后按 Enter 键。
2. 若要了解特定命令，请包含命令的名称（例如：`azcopy list -h`），然后按 Enter 键。

![内联帮助](Images/azcopy-inline-help.png)

## 将 Blob 存储中的 Blob 下载到文件系统

>**备注：**
>- 此示例需要一个具有 Blob 容器和 Blob 文件的 Azure 存储帐户。还需要在记事本等文本编辑器中获取参数。
>- 此示例用单引号 ('') 括住了路径参数。在除 Windows 命令 Shell (cmd.exe) 之外的所有命令 Shell 中使用单引号。如果使用的是 Windows 命令 Shell (cmd.exe)，请使用双引号 ("") 而非单引号 ('') 将路径参数括起来。

1. 访问 Azure 门户。
2. 访问包含要下载的 Blob 的存储帐户。
3. 深入查看相关 blob，然后查看文件“**属性**”。
4. 复制 **URL** 信息。这是源路径 *https://<storage-account-name>.<blob or dfs>.core.windows.net/<container-name>/<blob-path>*。
5. 找到本地目标目录。这是 *<local-file-path>* 值。文件名也是必需的。
6. 使用你的值构造命令：

    ```
    azcopy copy 'https://<storage-account-name>.<blob or dfs>.core.windows.net/<container-name>/<blob-path>' '<local-file-path>'
    ```
    
7. 如果出现错误，请仔细阅读并进行更正。
8. 验证 blob 是否已下载到本地目录。 

## 将文件上传到 Azure Blob 存储

>**备注：**
>- 此示例延续上一个示例，并需要一个包含文件的本地目录。
>- 此示例用单引号 ('') 括住了路径参数。在除 Windows 命令 Shell (cmd.exe) 之外的所有命令 Shell 中使用单引号。如果使用的是 Windows 命令 Shell (cmd.exe)，请使用双引号 ("") 而非单引号 ('') 将路径参数括起来。

1. 该命令的 *<local-file-path>* 源是一个包含文件的本地目录。 
2. 该命令的 *https://<storage-account-name>.<blob or dfs>.core.windows.net/<container-name>/<blob-name>* 目标是上一个示例中使用的 Blob URL。请务必删除文件名，只包含存储帐户和容器。 
3. 使用你的值构造命令。

    ```
    azcopy copy '<local-file-path>' 'https://<storage-account-name>.<blob or dfs>.core.windows.net/<container-name>/<blob-name>'
    ```

5. 如果出现错误，请仔细阅读并进行更正。
6. 确认本地文件已复制到 Azure 容器。 
7. 请注意，有些交换机可以递归子目录和模式匹配。
