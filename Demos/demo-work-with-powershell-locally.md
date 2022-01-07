# 演示：在本地使用 PowerShell

在本演示中，我们将安装 Azure Az PowerShell 模块。Az 模块可从名为“*PowerShell 库*”的全局存储库中获得。可通过 **Install-Module** 命令该将模块安装到本地计算机上。需要提升的 PowerShell Shell 提示符才能安装 PowerShell 库中的模块。 

## 安装 Az 模块

1. 打开“**开始**”菜单，然后键入“**Windows PowerShell**”。
2. 右键单击“**Windows PowerShell**”图标，然后选择“**以管理员身份运行**”。
3. 在“**用户帐户控制**”对话框中，选择“**是**”。
4. 键入以下命令，然后按 Enter。此命令会默认为所有用户安装模块。（由 scope 参数控制。）AllowClobber 会覆盖先前的 PowerShell 模块。 

    ```
    Install-Module -Name Az -AllowClobber
    ```

## 安装 NuGet（如果需要）

1. 根据安装的 NuGet 版本，可能会收到下载并安装最新版本的提示。
2. 如果出现提示，请安装并导入 NuGet 提供程序。

## 信任存储库

1. 默认情况下，PowerShell 库未配置为 PowerShellGet 的可信存储库。首次使用 PowerShell 库时，将看到以下提示：

    ```
    You are installing the modules from an untrusted repository. If you trust this repository, change its
    InstallationPolicy value by running the Set-PSRepository cmdlet. Are you sure you want to install the modules from
    'PSGallery'?
    ```

2. 根据提示安装模块。 

## 连接至 Azure 并查看订阅信息

1. 登录 Azure

    ```
    Login-AzAccount
    ```

2. 出现提示时，请提供凭据。
3. 验证订阅信息。

    ```
    Get-AzSubscription
    ```

## 创建资源

1. 创建新资源组。如果需要，请提供其他位置。订阅内的“*名称*”必须唯一。“*位置*”指定存储资源组元数据的地方。可使用“West US”、“North Europe”或“West India”等字符串指定位置；也可使用单字对等词，如 westus、northeurope 或 westindia。核心语法为：

    ```
    New-AzResourceGroup -name <name> -location <location>
    ```

2. 验证资源组。 
  
    ```
    Get-AzResourceGroup
    ```

3. 删除资源组。出现提示时，请确认。 

    ```
    Remove-AzResourceGroup -Name Test
    ```
