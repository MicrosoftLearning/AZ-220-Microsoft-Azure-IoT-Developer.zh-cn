# 演示：在本地使用 Azure CLI

在本演示中，将安装并使用 CLI 来创建资源。

## 在 Windows 上安装 CLI

使用 MSI 安装程序在 Windows 操作系统上安装 Azure CLI：

1. 下载 [MSI installer](https://aka.ms/installazurecliwindows)，在浏览器安全对话框中，单击“**运行**”。
2. 在安装程序中，接受许可条款，然后单击“**安装**”。
3. 在“**用户帐户控制**”对话框中，选择“**是**”。

## 验证 Azure CLI 安装

打开 Bash shell（Linux 或 macOS）或从命令提示符或 PowerShell（Windows）中运行 Azure CLI。

启动 Azure CLI 并通过运行版本检查来验证安装：

```azurecli
az --version
 ```

>**备注**：从 PowerShell 运行 Azure CLI 比从 Windows 命令提示符运行 Azure CLI 更有优势。PowerShell 提供了比命令提示符更多的 Tab 键补全功能。

## 登录 Azure

由于正在进行本地 Azure CLI 安装，所以执行 Azure 命令前，需要进行身份验证。要做到这一点，可使用 Azure CLI 的 **login** 命令：

```azurecli
az login
```

Azure CLI 通常会启动默认浏览器来打开 Azure 登录页面。如果不成功，请按照命令行说明操作，然后在 [https://aka.ms/devicelogin](https://aka.ms/devicelogin) 中输入授权代码。

成功登录后，将连接到 Azure 订阅。

## 创建资源组

在创建新的 Azure 服务之前，通常需要创建新的资源组，因此我们将使用资源组作为示例来说明如何通过 CLI 创建 Azure 资源。

Azure CLI 的 **group create** 命令用于创建资源组。必须指定名称和位置。订阅内的“*名称*”必须唯一。“*位置*”指定存储资源组元数据的地方。可使用“West US”、“North Europe”或“West India”等字符串指定位置；也可使用单字对等词，如 westus、northeurope 或 westindia。核心语法为：

```azurecli
az group create --name <name> --location <location>
```

## 验证资源组

对于许多 Azure 资源，Azure CLI 提供一个 **list** 子命令来查看资源详细信息。例如，Azure CLI 的 **group list** 命令列出 Azure 资源组。这有助于验证资源组是否创建成功：

```azurecli
az group list
```

要获得更简洁的视图，可将输出格式设置为一个简单表：

```azurecli
az group list --output table
```

如果组列表中有多个项目，可通过添加 **query** 选项筛选返回值。尝试运行以下命令：

```azurecli
az group list --query "[?name == '<rg name>']"
```

>**备注：** 使用 **JMESPath** 设置查询格式，这是 JSON 请求的标准查询语言。若要了解有关此功能强大的筛选器语言的更多信息，请访问 [http://jmespath.org/](http://jmespath.org/)。
