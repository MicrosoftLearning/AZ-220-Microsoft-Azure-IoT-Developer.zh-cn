---
lab:
    title: '实验室 12：设置 IoT Edge 网关'
    module: '模块 6：Azure IoT Edge 部署过程'
---

# 设置 IoT Edge 网关

## 实验室场景

本实验室是理论性实验室，将带你逐步了解如何将 IoT Edge 设备用作网关。

可以通过以下三种模式将 IoT Edge 设备用作网关：透明、协议转换和标识转换：

**透明** - 理论上可以连接到 IoT 中心的设备可以改为连接到网关设备。下游设备具有其自己的 IoT 中心标识，并使用 MQTT、AMQP 或 HTTP 协议中的任何一种协议。网关只在设备与 IoT 中心之间传递通信。这些设备不知道它们正在通过网关与云进行通信，通过 IoT 中心与设备交互的用户觉察不到中间网关设备。因此，网关是透明的。请参阅“创建透明网关”，了解有关将 IoT Edge 设备用作透明网关的详细信息。

**协议转换** - 也称为不透明网关模式，不支持 MQTT、AMQP 或 HTTP 的设备可以使用网关设备代表它们将数据发送到 IoT 中心。网关了解下游设备使用的协议，并且是 IoT 中心内唯一具有标识的设备。所有信息好像都来自一台设备，即网关。如果云应用程序要基于每台设备分析数据，则下游设备必须在其消息中嵌入其他标识信息。此外，IoT 中心基元（如孪生和方法）仅适用于网关设备，而不适用于下游设备。

**标识转换** - 无法连接到 IoT 中心的设备可以改为连接到网关设备。网关以下游设备身份提供 IoT 中心标识和协议转换。网关非常智能，可以了解下游设备使用的协议，为其提供标识并转换 IoT 中心基元。下游设备在 IoT 中心中显示为具有孪生和方法的一类设备。用户可以与 IoT 中心中的设备进行交互，而同时不了解中间网关设备。

将创建以下资源：

![实验室 12 基础结构](media/LAB_AK_12-architecture.png)

## 本实验室概览

在本实验室中，你将完成以下活动：

* 验证是否满足实验室先决条件（具有必需的 Azure 资源）
* 将启用 Azure IoT Edge 的 Linux VM 部署为 IoT Edge 设备
* 生成和配置 IoT Edge 设备 CA 证书
* 使用 Azure 门户在 IoT 中心创建 IoT Edge 设备标识
* 设置 IoT Edge 网关主机名
* 将 IoT Edge 网关设备连接到 IoT 中心
* 打开 IoT Edge 网关设备端口进行通信
* 在 IoT 中心创建下游设备标识
* 将下游设备连接到 IoT Edge 网关
* 验证事件流

## 实验室说明

### 练习 1：验证实验室先决条件

本实验室假定以下 Azure 资源可用：

| 资源类型 | 资源名称 |
| :-- | :-- |
| 资源组 | rg-az220 |
| IoT 中心 | iot-az220-training-{your-id} |

如果这些资源不可用，请按照以下说明运行 **“lab12-setup.azcli”** 脚本，然后再前往练习 2。脚本文件包含在本地克隆作为开发环境配置（实验室 3）的 GitHub 存储库中。

> **备注：** 写入 **lab12-setup.azcli** 脚本，并在 **Bash** shell 环境中运行，执行此操作最简便的方法是在 Azure Cloud Shell 中。

1. 使用浏览器，打开 [Azure Cloud Shell](https://shell.azure.com/)，并使用本课程使用的 Azure 订阅登录。

1. 如果系统提示设置 Cloud Shell 的存储，请接受默认设置。

1. 验证 Cloud Shell 是否在使用 **Bash**。

    Azure Cloud Shell 页面左上角的下拉菜单用于选择环境。验证所选的下拉值是否为 **Bash**。

1. 在 Cloud Shell 工具栏上，单击 **“上传/下载文件”** （从右数第四个按钮）。

1. 在下拉菜单中，单击 **“上传”**。

1. 在“文件选择”对话框中，导航到配置开发环境时下载的 GitHub 实验室文件的文件夹位置。

    在本课程的实验室 3（“设置开发环境”）中，通过下载 ZIP 文件并在本地提取内容来克隆包含实验室资源的 GitHub 存储库。提取的文件夹结构包括以下文件夹路径：

    * Allfiles
      * 实验室
          * 12 - 设置 IoT Edge 网关
            * 设置

    lab12-setup.azcli 脚本文件位于实验室 12 的 Setup 文件夹中。

1. 选择 **“lab12-setup.azcli”** 文件，然后单击 **“打开”**。

    文件上传完成后，系统将显示一条通知。

1. 要验证是否上传了正确的文件，请输入以下命令：

    ```bash
    ls
    ```

    使用 `ls` 命令列出当前目录的内容。你应该会看到列出的 lab12-setup.azcli 文件。

1. 若要为此实验室创建一个包含安装脚本的目录，然后移至该目录，请输入以下 Bash 命令：

    ```bash
    mkdir lab12
    mv lab12-setup.azcli lab12
    cd lab12
    ```

    这些命令将为此实验室创建一个目录，将 **“lab12-setup.azcli”** 文件放入该目录，然后将当前工作目录更改为该新目录。

1. 为确保 **“lab12-setup.azcli”** 具有执行权限，请输入以下命令：

    ```bash
    chmod +x lab12-setup.azcli
    ```

1. 在 Cloud Shell 工具栏上，请单击 **“打开编辑器”** （右侧的第二个按钮 - **{ }**）以启用对 lab12-setup.azcli 文件的访问。

1. 在 **“文件”** 列表中，要展开 lab12 文件夹并打开脚本文件，请先单击 **“lab12”**，再单击 **“lab12-setup.azcli”**。

    编辑器现在将显示 **“lab12-setup.azcli”** 文件的内容。

1. 在编辑器中，更新 `{your-id}` 和 `{your-location}` 变量的值。

    以下面的示例为例，需要将 `{your-id}` 设置为在本课程开始时创建的唯一 ID（即 **cah191211**），然后将 `{your-location}` 设置为对你的资源有意义的位置。

    ```bash
    #!/bin/bash

    # Change these values!
    YourID="{your-id}"
    Location="{your-location}"
    ```

    > **备注：**  应将 `{your-location}` 变量设置为要部署所有资源的区域的短名称。输入以下命令，可以看到可用位置及其短名称的列表（**“名称”** 列）：

    ```bash
    az account list-locations -o Table

    DisplayName           Latitude    Longitude    Name
    --------------------  ----------  -----------  ------------------
    East Asia             22.267      114.188      eastasia
    Southeast Asia        1.283       103.833      southeastasia
    Central US            41.5908     -93.6208     centralus
    East US               37.3719     -79.8164     eastus
    East US 2             36.6681     -78.3889     eastus2
    ```

1. 要保存对文件所做的更改并关闭编辑器，请单击编辑器窗口右上角的 “**...**”，然后单击 **“关闭编辑器”**。

    如果提示保存，请单击 **“保存”**，编辑器将会关闭。

    > **备注：**  可以使用 **Ctrl+S** 随时保存，使用 **Ctrl+Q** 关闭编辑器。

1. 要创建本实验室所需的资源，请输入以下命令：

    ```bash
    ./lab12-setup.azcli
    ```

    运行将花费几分钟时间。每个步骤完成时，你都会看到输出。

脚本完成后，就可以继续实验室的内容。

### 练习 2：部署 Linux VM，并安装 IoT Edge 运行时

在本练习中，你将部署 Ubuntu Server VM。

1. 如有必要，请使用 Azure 帐户凭据登录到 Azure 门户。

    如果有多个 Azure 帐户，请确保使用与本课程要使用的订阅绑定的帐户登录。

1. 在 **“搜索资源、服务和文档”** 字段中，输入 **“虚拟机”**。

1. 在搜索结果的 **“服务”** 下，单击 **“虚拟机”**。

1. 在“**虚拟机**”页面上，单击“**+ 创建**”并选择“**虚拟机**”。

1. 在 **“创建虚拟机”** 边栏选项卡的 **“订阅”** 下拉菜单中，请确保已选择将用于本课程的订阅。

1. 在 **“资源组”** 下拉列表中，单击 **“rg-az220vm”**。

    > **备注：** 本课程中创建的所有虚拟机资源都使用一个资源组。如果 **rg-az220vm** 资源组还没有创建，请使用下面的说明立即创建：

    * 在 **“资源组”** 下拉列表中，选择 **“新建”**。
    * 在上下文菜单中的 **“名称”** 下，输入 **“rg-az220vm”**，然后单击 **“确定”**

    > **备注：** 你可能会遇到建议为每个 VM 创建一个单独的资源组的指导。在生产环境中，为每个 VM 创建一个单独的资源组可以帮助你管理添加到 VM 的任何额外资源。但由于在本课程中 VM 的使用方式比较简单，因此为每个 VM 建立单独的资源组是不必要的，也是不实际的。

1. 在 **“实例详细信息”** 的 **“虚拟机名称”** 文本框中，键入 **“vm-az220-training-gw0001-{your-id}”**

1. 在 **“区域”** 下拉菜单中，选择预配 Azure IoT 中心的区域。

1. 将 **“可用性选项”** 保留为 **“无需基础结构冗余”**。

1. 在 **“映像”** 字段，选择 **“Ubuntu Server 18.04 LTS - Gen1”** 映像。

1. 将 **“Azure Spot 实例”** 字段保留未勾选状态。

1. 在 **“大小”** 右侧，单击 **“改变大小”**。

1. 在 **“选择 VM 大小”** 边栏选项卡的 **“VM 大小”** 下，单击 **Standard_B1ms**，然后单击 **“选择”**。

    可能需要使用 **“清除筛选器”** 链接以在列表中提供此大小。

    > **备注：** 并非所有 VM 大小都可在所有区域中使用。如果在后续步骤中无法选择 VM 大小，请尝试其他区域。例如，如果 **“美国西部”** 没有可用的尺寸，请尝试 **“美国西部 2”**。

1. 在 **“管理员帐户”** 下的 **“身份验证类型”** 右侧，单击 **“密码”**。

1. 对于 VM 管理员帐户，输入**用户名**、**密码** 和**确认密码** 字段的值。

    > **重要说明：** 请勿遗失/忘记这些值 - 没有这些值就无法连接到 VM。

1. 请注意， **“入站端口规则”** 配置为启用入站 **SSH** 访问 VM 的权限。

    这将用于远程连接到 VM 进行配置/管理。

1. 单击 **“查看 + 创建”**。

1. 等待将显示在边栏选项卡顶部的 **“验证通过”** 消息，然后单击 **“创建”**。

    > **备注：** 部署最多可能需要 5 分钟才能完成。可以在部署时继续进行下一个练习。

### 练习 3：生成和配置 IoT Edge 设备 CA 证书

在本练习中，将使用 Linux 生成测试证书。你将使用刚才创建的 **“vm-az220-training-gw0001-{your-id}”** 虚拟机以及在本实验室的 **“Starter”** 文件夹中找到的帮助程序脚本来完成这一操作。

#### 任务 1：连接到 VM

1. 验证 IoT Edge 虚拟机是否已成功部署。

    可以查看 Azure 门户中的“通知”窗格。

1. 验证 **“rg-az220vm”** 资源组是否已固定到 Azure 仪表板。

    要将资源组固定到仪表板，请导航到 Azure 仪表板，然后完成以下操作：

    * 在 Azure 门户菜单上，单击 **“资源组”**。
    * 在 **“资源组”** 边栏选项卡上的 **“名称”** 下，找到 **“rg-az220vm”** 资源组。
    * 在 **“rg-az220vm”** 行，在边栏选项卡的右侧，单击 **...**，然后单击 **“固定到仪表板”**。

    你可能需要编辑仪表板，以使 RG 磁贴和列出的资源更易于访问。

1. 在 Azure 门户菜单上，单击 **“资源组”**。

1. 在 **“资源组”** 边栏选项卡上的 **“名称”** 下，找到 **“rg-az220vm”**。

1. 在边栏选项卡右侧的 **“rg-az220vm”** 中，单击 **“单击以打开上下文菜单”** （省略号图标 - **...**）

1. 在上下文菜单上，单击 **“固定到仪表板”** ，然后导航回仪表板。

    如果**编辑**仪表板来重新排列磁贴更易于访问资源，你可以对其进行编辑。

1. 在 **“rg-az220vm”** 资源组磁贴上，单击 **“vm-az220-training-gw0001-{your-id}”**，打开 Edge 网关虚拟机。

    > **备注：** 由于资源名称很长且有些相似，因此请确保选择 VM，而不是磁盘、公共 IP 地址或网络安全组。

1. 在 **“vm-az220-training-gw0001-{your-id}”** 边栏选项卡顶部，单击 **“连接”**，然后单击 **“SSH”**。

1. 在 **“连接”** 窗格的 **“运行以下示例命令以连接到 VM” 4.** 下，复制示例命令。

    这是一个示例 SSH 命令，可用于连接到包含 VM 的 IP 地址和管理员用户名的虚拟机。该命令的格式应类似于 `ssh username@52.170.205.79`。

    > **备注：** 如果示例命令包含 **i \<private key path\>**，使用文本编辑器删除命令的该部分，然后将更新的命令复制到剪贴板。

1. 在 Azure 门户工具栏上，单击 **“Cloud Shell”**

1. 在 Cloud Shell 命令提示符处，粘贴在文本编辑器中更新的 **ssh** 命令，然后按 **Enter**。

1. 当提示 **“确定要继续连接吗?”** 时，键入 **“yes”**，然后按 **Enter**。

    此提示是安全确认，因为用于保护与 VM 的连接的证书为自签名证书。系统将记住此提示的回答，以便用于后续连接，并且仅在第一次连接时提示。

1. 当提示输入密码时，请输入在预配 Edge 网关 VM 时创建的管理员密码。

1. 连接后，终端将更改为显示 Linux VM 的名称，如下所示。这会告诉你连接的是哪个 VM。

    ``` bash
    username@vm-az220-training-gw0001-{your-id}:~$
    ```

    > **重要说明**： 连接时，你可能会被告知 Edge VM 有未完成的 OS 更新。在本实验室活动过程中你可以忽略更新，但是在生产环境中，你始终需要确保 Edge 设备保持最新状态。

#### 任务 2：生成证书

1. 若要下载和配置一些 Azure IoT Edge 帮助程序脚本，请输入以下命令：

    ```bash
    git clone https://github.com/Azure/iotedge.git
    ```

    **Azure/IoTEdge** GitHub 项目包含用于生成**非生产**证书的脚本。这些脚本将帮助创建必要的脚本，以设置透明 IoT Edge 网关。

    > **备注：**  [Azure/iotedge](https://github.com/Azure/iotedge) 开放源代码项目是 Azure IoT Edge 的官方开放源代码项目。除了本单元中使用的帮助程序脚本以外，此项目还包含 Edge 代理、Edge 中心和 IoT Edge 安全性守护程序的源代码。

1. 请输入以下命令，创建一个名为“lab12”的工作目录，然后移动到该目录中：

    ```bash
    mkdir lab12
    cd lab12
    ```

    > **备注：** 你将使用网关 VM 上的“lab12”目录生成证书。若要生成证书，需要将帮助程序脚本复制到工作目录中。

1.  请输入以下命令，将帮助程序脚本复制到 lab12 目录中：

    ```bash
    cp ../iotedge/tools/CACertificates/*.cnf .
    cp ../iotedge/tools/CACertificates/certGen.sh .
    ```

    这些命令将仅复制运行帮助程序脚本以生成测试 CA 证书所需的文件。本实验室不需要 Azure/iotedge 存储库中的其余源文件。

1. 请输入以下命令，验证是否已正确复制帮助程序脚本文件：

    ```bash
    ls
    ```

    此命令应输出一个显示目录中有 2 个文件的文件列表。 **certGen.sh** 是帮助程序 Bash 脚本，**openssl_root_ca.cnf** 文件是通过使用 OpenSSL 的帮助程序脚本生成证书所需的配置文件。

    验证命令提示符是否包含 **~/lab12**，这表明你是否在正确的位置运行命令。这映射到 **/home/\<username\>/lab12** 目录，其中 **\<username\>** 是登录到 SSH 所使用的用户。稍后，在将 Azure IoT Edge 配置为使用生成的证书时，将需要使用此目录位置。

1. 请输入以下命令，生成根 CA 证书和一个中间证书：

    ```bash
    ./certGen.sh create_root_and_intermediate
    ```

    **certGen.sh** 帮助程序脚本使用 **create_root_and_intermediate** 参数生成根 CA 证书和一个中间证书。该脚本将创建几个证书和密钥文件。稍后，你将在本实验室中使用以下根 CA 证书文件：

    ```text
    # Root CA certificate
    ~/lab12/certs/azure-iot-test-only.root.ca.cert.pem
    ```

    根 CA 现已生成，接下来需要生成 IoT Edge 设备 CA 证书和私钥。

1. 请输入以下命令，生成 IoT Edge 设备 CA 证书：

    ```bash
    ./certGen.sh create_edge_device_ca_certificate "MyEdgeDeviceCA"
    ```

    生成的证书是用此命令指定的名称创建的。如果使用的名称不是 **MyEdgeDeviceCA**，则生成的证书将反映该名称。

    此脚本创建了多个证书和密钥文件。请记下以下文件，稍后将引用这些文件：

    ```text
    # Device CA certificate
    ~/lab12/certs/iot-edge-device-ca-MyEdgeDeviceCA-full-chain.cert.pem
    # Device CA private key
    ~/lab12/private/iot-edge-device-ca-MyEdgeDeviceCA.key.pem
    ```

    > **备注：** 现已生成 IoT Edge 设备 CA 证书，请勿重新运行之前的生成根 CA 证书的命令。这样将用新证书覆盖现有证书，新证书与刚生成的 **MyEdgeDeviceCA** IoT Edge 设备 CA 证书不再匹配。

#### 任务 3：将 Microsoft 安装包添加到包管理器中

1. 要将 VM 配置为访问 Microsoft 安装包，请运行以下命令：

    ```bash
    curl https://packages.microsoft.com/config/ubuntu/18.04/multiarch/prod.list > ./microsoft-prod.list
    ```

1. 要将下载的包列表添加到包管理器，请运行以下命令：

    ```bash
    sudo cp ./microsoft-prod.list /etc/apt/sources.list.d/
    ```

1. 若要安装包，必须安装 Microsoft GPG 公钥。运行以下命令：

    ```bash
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
    sudo cp ./microsoft.gpg /etc/apt/trusted.gpg.d/
    ```

    > **重要说明**： Azure IoT Edge 软件包受制于每个包中的许可条款 **（usr/share/doc/{package-name}** 或 **LICENSE** 目录）。使用包之前请阅读许可条款。安装和使用包即表示接受这些条款。如果不同意许可条款，则不要使用包。

#### 任务 4：安装容器引擎

Azure IoT Edge 依赖于 OCI 兼容的容器运行时。对于生产场景，建议使用 Moby 引擎。Moby 引擎是官方唯一支持用于 Azure IoT Edge 的容器引擎。Docker CE/EE 容器映像与 Moby 运行时兼容。

1. 要更新设备上的包列表，请运行以下命令：

    ```bash
    sudo apt-get update
    ```

    运行此命令可能需要几分钟。

1. 若要安装 **Moby** 引擎，请运行以下命令：

    ```bash
    sudo apt-get install moby-engine
    ```

    如果提示继续，请输入 **Y**。安装可能需要几分钟。

#### 任务 5：安装 IoT Edge

IoT Edge 安全守护程序提供和维护 IoT Edge 设备上的安全标准。守护程序在每次开机时启动，并通过启动 IoT Edge 运行时的其余部分来启动设备。

1. 通常，在安装新包之前更新包列表是一种很好的做法，但是在上一个任务中已更新了包。要更新设备上的包列表，请运行以下命令：

    ```bash
    sudo apt-get update
    ```

1. 要列出可用的 **IoT Edge 运行**时版本，请运行以下命令：

    ```bash
    apt list -a iotedge
    ```

    > **提示**： 如果需要安装运行时的早期版本，可以使用此命令。

1. 若要安装最新版本的 **IoT Edge 运行**时，请运行以下命令：

    ```bash
    sudo apt-get install iotedge
    ```

    如果提示继续，请输入 **Y**。安装可能需要几分钟。

    > **提示**： 如果要安装 `apt list -a iotedge` 命令的输出中出现的早期版本，例如 **1.0.9-1**，则可以使用以下命令：
    > ```bash
    > sudo apt-get install iotedge=1.0.9-1 libiothsm-std=1.0.9-1
    > ```

1. 若要确认 VM 上是否安装了 Azure IoT Edge 运行时，请运行以下命令：

    ```bash
    iotedge version
    ```

    此命令输出的 Azure IoT Edge 运行时版本是当前在虚拟机上安装的运行时版本。

#### 任务 6：配置 IoT Edge

1. 为确保能够配置 Azure IoT Edge，请输入以下命令：

    ```bash
    sudo chmod a+w /etc/iotedge/config.yaml
    ```

    要配置 Azure IoT Edge，需要修改 **/etc/iotedge/config.yaml** 配置文件以包含指向 IoT Edge 设备上的证书和密钥文件的完整路径。必须确保 **config.yaml** 文件不是只读文件，然后才能编辑文件。上述命令将 **config.yaml** 文件设置为可写。

1. 请输入以下命令，在 vi/vim 编辑器中打开 **config.yaml** 文件：

    ```bash
    sudo vi /etc/iotedge/config.yaml
    ```

    > **备注：** 如果你想使用其他编辑器，例如 **code**、**nano** 或 **emacs**，也没有问题。

1. 在 vi/vim 编辑器中，在文件中向下滚动，直到找到 **“证书设置”** 部分。

    > **备注：** 以下是在编辑 **config.yaml** 文件时使用 **vi** 的一些技巧：
    > * 按 **i** 键将使编辑器进入“插入”模式，然后即可进行更改。
    > * 按 **Esc** 键停止“插入”模式并返回到“普通”模式。
    > * 要“保存并退出”，请键入 **“x”**，然后按 **Enter**。
    > * 保存文件，键入 **“:w”**，然后按 **Enter**。
    > * 要退出 vi，请键入 **“退出”**，然后按 **Enter**。
    >
    > 必须先停止插入模式，然后才能保存或退出。

1. 若要更新 **certificates** 代码行，请删除前导 **“# ”** （井号和空格）字符并输入证书路径，如下所示：

    ```yaml
    certificates:
      device_ca_cert: "/home/<username>/lab12/certs/iot-edge-device-ca-MyEdgeDeviceCA-full-chain.cert.pem"
      device_ca_pk: "/home/<username>/lab12/private/iot-edge-device-ca-MyEdgeDeviceCA.key.pem"
      trusted_ca_certs: "/home/<username>/lab12/certs/azure-iot-test-only.root.ca.cert.pem"
    ```

    > **备注：** 请务必替换上述文件路径规范中的 `<username>` 占位符。需要指定连接到 SSH 的用户的**用户名**（在创建 VM 时指定的管理员用户）。

    > **重要说明**： YAML 将空格视为重要字符。在上面输入的行中，意味着 **certificates:** 前面不应有任何前导空格，并且在 **device_ca_cert:**、 **device_ca_pk:** 和 **trusted_ca_certs:** 之前应有两个前导空格。

    本节中配置的 X.509 证书用于以下目的：

    | 设置 | 用途 |
    | :--- | :--- |
    | **device_ca_cert** | 这是 IoT Edge 设备的设备 CA 证书。 |
    | **device_ca_pk** | 这是 IoT Edge 设备的设备 CA 私钥。 |
    | **trusted_ca_certs** | 这是根 CA 证书。此证书必须包含 Edge 模块通信所需的所有受信任的 CA 证书。|

1. 请键入 **“x”**，然后按 **Enter**，即可保存更改并退出编辑器。

    请记住，在保存或退出 vi/vim 编辑器之前，需要停止“插入”模式。

1. 在 Cloud Shell 命令提示符处，输入以下命令即可结束 SSH 会话：

    ```sh
    exit
    ```

    接下来，你需要从 **vm-az220-training-gw0001-{your-id}** 虚拟机中“下载” **MyEdgeDeviceCA** 证书，以便可以将其用于在 Azure IoT 中心设备预配服务中配置 IoT Edge 设备注册。

1. 在 Cloud Shell 命令提示符处，输入以下命令，从 **vm-az220-training-gw0001-{your-id}** 虚拟机下载 **~/lab12** 目录到 **Cloud Shell** 存储：

    ```bash
    mkdir lab12
    scp -r -p <username>@<ipaddress>:~/lab12 .
    ```

    > **备注：** 将 **<username>** 占位符替换为 VM 管理员用户的用户名，然后将 **<ipaddress>** 占位符替换为 VM 的 IP 地址。如有必要，请参阅你用来打开 SSH 会话的命令。

1. 出现提示时，请输入 VM 的管理员密码。

    执行该命令后，它会通过 SSH 将带有证书和密钥文件的 **~/lab12** 目录副本下载到 Cloud Shell 存储中。

1. 若要验证是否已下载文件，请输入以下命令：

    ```bash
    cd lab12
    ls
    ```

    你会看到列出的以下文件：

    ```bash
    certGen.sh  csr        index.txt.attr      index.txt.old  openssl_root_ca.cnf  serial
    certs       index.txt  index.txt.attr.old  newcerts       private              serial.old
    ```

    将文件从 **vm-az220-training-gw0001-{your-id}** 虚拟机复制到 Cloud Shell 存储后，你将可以根据需要将任一 IoT Edge 设备证书和密钥文件轻松下载到本地计算机。可以使用 `download <filename>` 命令从 Cloud Shell 中下载文件。你将稍后在实验室中执行此操作。

### 练习 4：使用 Azure 门户在 IoT 中心中创建 IoT Edge 设备标识

在本练习中，你将使用 Azure IoT 中心创建一个用于 IoT Edge 透明网关（你的 IoT Edge VM）的新的 IoT Edge 设备标识。

1. 如有必要，请使用 Azure 帐户凭据登录到 Azure 门户，然后导航到 Azure 仪表板。

1. 在 **“rg-az220”** 资源组磁贴上，打开 IoT 中心，单击 **“iot-az220-training-{your-id}”**。

1. 在 **“iot-az220-training-{your-id}”** 边栏选项卡上，在左侧导航菜单中的 **“自动设备管理”** 下，单击 **“IoT Edge”**。

    可通过 IoT Edge 窗格管理连接到 IoT 中心的 IoT Edge 设备。

1. 在窗格顶部，单击 **“添加 IoT Edge 设备”**。

1. 在 **“创建设备”** 边栏选项卡的 **“设备 ID”** 字段中，输入 **vm-az220-training-gw0001-{your-id}**。

    请务必将 {your-id} 替换为在该课程开始时创建的值。这是将用于身份验证和访问控制的设备标识。

1. 在 **“身份验证类型”** 处， 确保已选中 **“对称密钥”**，并保留选中 **“自动生成密钥”** 框。

    这将使 IoT 中心自动生成对设备进行身份验证的对称密钥。

1. 将其他设置保留为默认值，然后单击 **“保存”**。

    稍后，新的 IoT Edge 设备将添加到 IoT Edge 设备列表中。

1. 在 **“设备 ID”** 下，单击 **“vm-az220-training-gw0001-{your-id}”**。

1. 在 **“vm-az220-training-gw0001-{your-id}”** 边栏选项卡上，复制 **“主连接字符串”**。

    值的右侧提供一个“复制”按钮。

1. 将 **“主连接字符串”** 的值复制到文件，并记下与之关联的设备。

1. 在 **“vm-az220-training-gw0001-{your-id}”** 边栏选项卡处，请注意 **“模块”** 列表仅限于 **“\$edgeAgent”** 和 **“\$edgeHub”**。

    IoT Edge 代理 ($edgeAgent) 和 IoT Edge 中心 ($edgeHub) 模块是 IoT Edge 运行时的一部分。Edge 中心负责通信，而 Edge 代理部署和监视设备上的模块。

1. 在边栏选项卡顶部，单击 **“设置模块”**。

    **“在设备上设置模块”** 边栏选项卡可用于向 IoT Edge 设备添加其他模块。目前，将使用此边栏选项卡来确保为 IoT Edge 网关设备正确配置了消息路由。

1. 在 **“在设备上设置模块”** 边栏选项卡顶部，单击 **“路由”**。

    在 **“路由”** 处，编辑器将显示为 IoT Edge 设备配置的默认路由。此时，应配置将所有消息从所有模块发送到 Azure IoT 中心的路由。如果路由配置与此不匹配，请更新以匹配以下路由：

    * **名称**：`route`
    * **值**：`FROM /* INTO $upstream`

    消息路由的 `FROM /*` 部分将匹配所有设备到云的消息，或者来自任何模块或叶设备的孪生更改通知。然后，`INTO $upstream` 告诉路由将这些消息发送到 Azure IoT 中心。

    > **备注：** 若要详细了解如何在 Azure IoT Edge 中配置消息路由，请参阅[了解如何在 IoT Edge 中部署模块和建立路由](https://docs.microsoft.com/azure/iot-edge/module-composition#declare-routes#declare-routes)一文。

1. 在边栏选项卡底部，单击 **“查看 + 创建”**。

    **“在设备上设置模块”** 边栏选项卡的标签页上显示 Edge 设备的部署清单。你会在边栏选项卡顶部看到一条消息，显示“验证通过”

1. 请花费片刻时间查看部署清单。

1. 在边栏选项卡底部，单击 **“创建”**。

### 练习 5：设置 IoT Edge 网关主机名

在本练习中，你将为 **vm-az220-training-gw0001-{your-id}** 模拟 Edge 设备的公共 IP 地址配置 DNS 名称，并将该 DNS 名称配置为 IoT Edge 网关设备的 `hostname`。

1. 如有必要，请使用 Azure 帐户凭据登录到 Azure 门户，然后导航到仪表板。

1. 在 **“rg-az220vm”** 资源组磁贴上，单击 **“vm-az220-training-gw0001-{your-id}”**，打开 IoT Edge 虚拟机。

1. 在 **“vm-az220-training-gw0001-{your-id}”** 边栏选项卡上部，找到 **“DNS 名称”** 字段。

    如果“概述”边栏选项卡顶部的“软件包”部分已折叠，要展开，请单击 **“软件包”**。

1. 在 **“DNS 名称”** 字段右侧，单击 **“配置”**。

1. 在 **“vm-az220-training-gw0001-{your-id}-ip - Configuration”** 窗格的 **“DNS 名称标签”** 字段中，输入 **“vm-az220-training-gw0001-{your-id}”**

    此标签必须全局唯一，并且只能是小写字母、数字和连字符。

1. 在边栏选项卡顶部，单击 **“保存”**。

1. 留意位于 **“DNS 名称标签”** 字段下方和右侧的文本。

    虽然你的列表可能会列出其他区域，但它应该类似于以下内容 **：westus2.cloudapp.azure.com**。

    完整的 DNS 名称的构成如下 **vm-az220-training-gw0001-{your-id}** 值，其后缀为 **“DNS 名称标签”** 字段下方的文本。

    例如，完整的 DNS 名称可以是：

    ```text
    vm-az220-training-gw0001-cah191230.westus2.cloudapp.azure.com
    ```

    标准 Azure 商业云中的所有公共 IP 地址 DNS 名称都将位于 **.cloudapp.azure.com 域名中**。此示例适用于托管在 **westus2** Azure 区域中的 VM。此部分 DNS 名称将取决于 VM 托管在哪个 Azure 区域。

    为 **vm-az220-training-gw0001-{your-id}** 虚拟机的公共 IP 地址设置 DNS 名称将为下游设备提供一个 FQDN（完全限定的域名），作为与之连接的 **GatewayHostName**。在这种情况下，因为可以通过 Internet 访问 VM，因此需要 Internet DNS 名称。如果 Azure IoT Edge 网关托管在专用或混合网络中，则计算机名称将满足 **GatewayHostName** 供本地下游设备进行连接的要求。

1. 记录 **vm-az220-training-gw0001-{your-id}** 虚拟机的完整 DNS 名称，并保存供以后引用。

1. 导航回 **“vm-az220-training-gw0001-{your-id}”** 边栏选项卡，然后单击 **“刷新”**。

    > **备注：** 如果仍处于“IP 配置”边栏选项卡中，则可以使用页面顶部的痕迹导航跟踪快速返回 VM。  在这种情况下， 在 **“概述”** 窗格中，使用“刷新”按钮更新显示的 DNS 名称。

1. 在边栏选项卡顶部，单击 **“连接”**，然后单击 **“SSH”**。

1. 和以前一样，找到 **“运行以下示例命令以连接到 VM。” 4.** 的值。

1. 请注意，示例命令当前包含新的 DNS 名称，而不是之前包含的 IP 地址。

1. 在 **“运行以下示例命令以连接到 VM。” 4.** 选项下，要复制命令，请单击 **“复制到剪贴板”**。

    此示例 SSH 命令可用于连接到包含 VM 的 IP 地址和管理员用户名的虚拟机。在配置了 DNS 名称标签之后，该命令应类似于以下内容： **ssh demouser@vm-az220-training-gw0001-{your-id}.eastus.cloudapp.azure.com**

    > **备注：** 如果示例命令包含 **-i \<private key path\>**，使用文本编辑器删除命令的该部分，然后将更新的命令复制到剪贴板。

1. 在 Azure 门户工具栏上，单击 **“Cloud Shell”**。

    确保将 Cloud Shell 环境设置为使用 **Bash**。

1. 在 Cloud Shell 命令提示符后输入刚才构造的的 `ssh` 命令，然后按 **Enter**。

    如果看到警告询问是否确定要继续，请输入 **“是”**

1. 当系统提示输入密码时，请输入你在预配 VM 时指定的管理员密码。

1. 请输入以下命令，在 vi/vim 编辑器中打开 config.yaml 文件：

    ```bash
    sudo vi /etc/iotedge/config.yaml
    ```

    > **备注：** 同样，可以根据需要使用其他编辑器。

1. 在文件中向下滚动以找到 **“Edge 设备主机名”** 部分。

    > **备注：**  以下是在编辑 **config.yaml** 文件时使用 **vi** 的一些技巧：
    > * 按 **Esc**，然后输入 **“/”**，后跟搜索字符串，然后按 Enter 进行搜索
    > * 按 **n** 将循环浏览匹配项。
    > * 按 **i** 键将使编辑器进入“插入”模式，然后即可进行更改。
    > * 按 **Esc** 键停止“插入”模式并返回到“普通”模式。
    > * 要“保存并退出”，请键入 **“x”**，然后按 **Enter**。
    > * 保存文件，键入 **“:w”**，然后按 **Enter**。
    > * 要退出 vi，请键入 **“退出”**，然后按 **Enter**。

1. 将 **“主机名”** 的值设置为之前保存的 **“完整 DNS 名称”**。

    这是 **vm-az220-training-gw0001-{your-id}** 虚拟机的 **“完整 DNS 名称”**。

    > **备注：** 如果未保存名称，则可以在虚拟机的 **“概述”** 窗格找到该名称。  甚至可以在此复制它，并将其粘贴到 Cloud Shell 窗口中。

    生成的值将如下所示：

    ```yaml
    hostname: "vm-az220-training-gw0001-{your-id}.eastus.cloudapp.azure.com"
    ```

    `hostname` 设置用于配置 Edge 中心服务器主机名。无论此设置使用的是大写还是小写，都将使用小写值来配置 Edge 中心服务器。这也是下游 IoT 设备在连接到 IoT Edge 网关时需要使用的主机名，以使加密通信能够正常工作。

1. 使 **config.yaml** 在 vi/vim（或所使用的编辑器）中保持打开状态

### 练习 6：将 IoT Edge 网关设备连接到 IoT 中心

在本练习中，你将把 IoT Edge 设备连接到 Azure IoT 中心。

1. 返回 vi/vim 中的 **config.yaml** 文档：

1. 找到文件的 **“使用连接字符串手动预配配置”**，并取消注释“使用连接字符串手动预配配置”部分，如果它尚未取消删除注释，方法是删除前导 **‘# ‘** （井号和空格）并将 `<ADD DEVICE CONNECTION STRING HERE>` 替换为先前为 IoT Edge 设备复制的连接字符串：

    ```yaml
    # Manual provisioning configuration using a connection string
    provisioning:
      source: "manual"
      device_connection_string: "<ADD DEVICE CONNECTION STRING HERE>"
      dynamic_reprovisioning: false
    ```

    > **重要说明**： YAML 将空格视为重要字符。在上面输入的行中，意味着 **provisioning:** 前面不应有任何前导空格，并且在 **source:**、 **device_connection_string:** 和 **dynamic_reprovisioning:** 之前应有两个前导空格。

1. 请按 **Esc**，键入 **“x”**，然后按 **Enter**，即可保存更改并退出编辑器

1. 若要应用更改，必须使用以下命令重启 IoT Edge 守护程序：

    ```bash
    sudo systemctl restart iotedge
    ```

1. 要确保 IoT Edge 守护程序正常运行时，请输入以下命令：

    ```bash
    sudo systemctl status iotedge
    ```

    此命令将显示许多行内容，其中前三行指示服务是否正常运行。对于正常运行的服务，输出将类似于以下内容：

    ```bash
    ● iotedge.service - Azure IoT Edge daemon
       Loaded: loaded (/lib/systemd/system/iotedge.service; enabled; vendor preset: enabled)
       Active: active (running) since Fri 2021-03-19 18:06:16 UTC; 1min 0s ago
    ```

1. 要验证已连接的 IoT Edge 运行时，请运行以下命令：

    ```bash
    sudo iotedge check
    ```

    这将运行许多检查并显示结果。对于本实验室，请忽略 **“配置检查”** 警告/错误。 **“连接性检查”** 应该会成功，并且类似于以下内容：

    ```bash
    Connectivity checks
    -------------------
    √ host can connect to and perform TLS handshake with IoT Hub AMQP port - OK
    √ host can connect to and perform TLS handshake with IoT Hub HTTPS / WebSockets port - OK
    √ host can connect to and perform TLS handshake with IoT Hub MQTT port - OK
    √ container on the default network can connect to IoT Hub AMQP port - OK
    √ container on the default network can connect to IoT Hub HTTPS / WebSockets port - OK
    √ container on the default network can connect to IoT Hub MQTT port - OK
    √ container on the IoT Edge module network can connect to IoT Hub AMQP port - OK
    √ container on the IoT Edge module network can connect to IoT Hub HTTPS / WebSockets port - OK
    √ container on the IoT Edge module network can connect to IoT Hub MQTT port - OK
    ```

    如果连接失败，请仔细检查 **config.yaml** 中的连接字符串值。

1. 稍等片刻。

1. 要列出当前在 IoT Edge 设备上运行的所有**IoT Edge 模块**，请运行以下命令：

    ```sh
    iotedge list
    ```

    片刻之后，此命令将显示 `edgeAgent` 和 `edgeHub` 模块正在运行。输出如下所示：

    ```text
    root@vm-az220-training-gw0001-{your-id}:~# iotedge list
    NAME             STATUS           DESCRIPTION      CONFIG
    edgeHub          running          Up 15 seconds    mcr.microsoft.com/azureiotedge-hub:1.0
    edgeAgent        running          Up 18 seconds    mcr.microsoft.com/azureiotedge-agent:1.0
    ```

    如果报告了错误，则需要再次检查配置是否正确设置。为了排除故障，可以运行 **iotedge check --verbose** 命令来查看是否有任何错误。

1. 关闭 Cloud Shell。

### 练习 7：打开 IoT Edge 网关设备端口进行通信

为了使 Azure IoT Edge 网关正常工作，必须至少打开一个 IoT Edge 中心支持的协议，以允许来自下游设备的入站流量。支持的协议为 MQTT、AMQP 和 HTTPS。

Azure IoT Edge 支持的 IoT 通信协议具有以下端口映射：

| 协议 | 端口号 |
| --- | --- |
| MQTT | 8883 |
| AMQP | 5671 |
| HTTPS<br/>MQTT + WS (Websocket)<br/>AMQP + WS (Websocket) | 443 |

为设备选择的 IoT 通信协议将需要为防火墙打开相应的端口，以保护 IoT Edge 网关设备的安全。在此实验室中，将使用 Azure 网络安全组 (NSG) 来保护 IoT Edge 网关的安全，因此将在这些端口上打开 NSG 的入站安全规则。

在生产方案中，只需为设备打开最小数量的端口即可进行设备通信。如果使用的是 MQTT，则仅打开端口 8883 以允许入站通信。打开其他端口将引入攻击者可以利用的其他安全攻击途径。最佳安全做法是仅打开解决方案所需的最少端口数。

在本练习中，将配置网络安全组 (NSG)，以确保从 Internet 访问 Azure IoT Edge 网关的安全。需要打开进行 MQTT、AMQP 和 HTTPS 通信所需的端口，以便下游 IoT 设备可以与网关通信。

1. 如有必要，请使用 Azure 帐户凭据登录到 Azure 门户。

1. 在 Azure 仪表板上，找到 **“rg-az220vm”** 资源组磁贴。

    请注意，此资源组磁贴包括指向关联的网络安全组的链接。

1. 在 **“rg-az220vm”** 资源组磁贴上，单击 **“vm-az220-training-gw0001-{your-id}-nsg”**。

1. 在 **“网络安全组”** 边栏选项卡左侧菜单的 **“设置”** 下，单击 **“入站安全规则”**。

1. 在 **“入站安全规则”** 窗格顶部，单击 **“添加”**。

1. 在 **“添加入站安全规则”** 窗格的 **“目标端口范围”** 下，将值更改为 **“8883”**

1. 在 **“协议”** 下，单击 **“TCP”**。

1. 在 **“名称”** 下，将值更改为 **MQTT**

1. 将所有其他设置保留为默认值，并单击 **“添加”**。

    这将定义入站安全规则，该规则将允许 MQTT 协议到 IoT Edge 网关的通信。

1. 添加 MQTT 规则后，添加另外两个具有以下值的规则，即可打开 **AMQP** 和 **HTTPS** 通信协议的端口：

    | 目标端口范围 | 协议 | 名称 |
    | :--- | :--- | :--- |
    | 5671 | TCP | AMQP |
    | 443 | TCP | HTTPS |

   > **备注**：你可能需要使用窗格顶部工具栏中的 **“刷新”** 按钮来查看新规则的出现。

1. 通过在网络安全组 (NSG) 上打开这三个端口，下游设备将能够使用 MQTT、AMQP 或 HTTPS 协议连接到 IoT Edge 网关。

### 练习 8：在 IoT 中心中创建下游设备标识

在本练习中，将在 Azure IoT 中心为下游 IoT 设备创建一个新的 IoT 设备标识。你将配置此设备标识，以便 Azure IoT Edge 网关成为此下游设备的父设备。

1. 如有必要，请使用 Azure 帐户凭据登录到 Azure 门户。

1. 在 Azure 仪表板上，单击 **“iot-az220-training-{your-id}”** 即可打开 IoT 中心。

1. 在 **“iot-az220-training-{your-id}”** 边栏选项卡上，在左侧菜单中的 **“资源管理器”** 下，单击 **“IoT 设备”**。

    IoT 中心边栏选项卡的此窗格允许你管理连接到 IoT 中心的 IoT 设备。

1. 在窗格顶部，要开始配置新的 IoT 设备，请单击 **“+ 新建”**。

1. 在 **“创建设备”** 边栏选项卡的 **“设备 ID”** 下，输入 **sensor-th-0072**

    这是用于身份验证和访问控制的设备标识。

1. 确保在 **“身份验证类型”** 下，选中 **“对称密钥”**。

1. 在 **“自动生成密钥”** 下，保留此框的选中状态。

    这将使 IoT 中心自动生成对设备进行身份验证的对称密钥。

1. 在 **“父设备”** 选项下，单击 **“设置父设备”**。

    你将配置此下游设备，以便通过之前在本实验室创建的 IoT Edge 网关设备与 IoT 中心通信。

1. 在 **“将 Edge 设备设置为父设备”** 边栏选项卡的 **“设备 ID”** 选项下，单击 **“vm-az220-training-gw0001-{your-id}”**，然后单击 **“确定”**。

1. 在 **“创建设备”** 边栏选项卡上，单击 **“保存”**，即可创建下游设备的 IoT 设备标识。

1. 在 **“IoT 设备”** 窗格顶部，单击 **“刷新”**。

1. 在 **“设备 ID”** 下，单击 **“sensor-th-0072”**。

    这将打开该设备的详细信息视图。

1. 在“IoT 设备摘要”窗格中，在 **“主连接字符串”** 字段的右侧，单击 **“复制”**。

1. 保存连接字符串，以便以后引用。

    请务必注意，此是 sensor-th-0072 子设备的连接字符串。

### 练习 9：将下游设备连接到 IoT Edge 网关

在本练习中，你将配置预先构建的下游设备和 Edge 网关设备之间的连接。

1. 如有必要，请使用 Azure 帐户凭据登录到 Azure 门户。

    如果有多个 Azure 帐户，请确保使用与本课程要使用的订阅绑定的帐户登录。

1. 在 Azure 门户工具栏上，单击 **“Cloud Shell”**。

    确保将环境设置为 **Bash**。

    > **备注：** 如果 Cloud Shell 已打开，并且你仍然连接到 Edge 设备，请使用 **exit** 命令关闭 SSH 会话。

1. 在 Cloud Shell 命令提示符处，要下载 IoT Edge 网关虚拟机的根 CA X.509 证书，请输入以下命令：

    ```bash
    download lab12/certs/azure-iot-test-only.root.ca.cert.pem
    ```

    Azure IoT Edge 网关以前在 **/etc/iotedge/config.yaml** 文件中配置，以便使用此根 CA X.509 证书来加密与连接到网关的任何下游设备的通信。此 X.509 证书将需要复制到下游设备，以便下游设备可以使用该证书来加密与网关的通信。

1. 将 **azure-iot-test-only.root.ca.cert.pem X.509** 证书文件复制到下游 IoT 设备源代码所在的 **/Starter/DownstreamDevice** 目录中。

    > **重要说明**： 确保文件具有正确的名称。它的名称可能与以前的实验室不同，例如添加了 **(1)**，因此如有必要，请在复制后重命名。

1. 打开 Visual Studio Code。

1. 在 **“文件”** 菜单上，单击 **“打开文件夹”**。

1. 在“**打开文件夹**”对话框中，导航到实验室 12 的 Starter 文件夹，单击“**DownstreamDevice**”，然后单击“**选择文件夹**”。

    你会看到“资源管理器”窗格中列出的 azure-iot-test-only.root.ca.cert.pem 文件以及 Program.cs 文件。

    > **备注：** 如果看到有关还原 dotnet 和/或加载 C# 扩展的消息，则可以完成安装。

1. 在“资源管理器”窗格中，单击 **“Program.cs”**。

    大致回顾一下就会发现，此应用是你在之前的实验室中使用过的 **CaveDevice** 应用程序的变体。

1. 找到 **connectionString** 变量的声明，然后将占位符的值替换为 **sensor-th-0072 IoT** 设备的主连接字符串。

1. 将分配的 **connectionString** 值附加到 **GatewayHostName** 属性，然后将 GatewayHostName 的值设置为 IoT Edge 网关设备的完整 DNS 名称。

    Edge 网关设备的完整 DNS 名称是在设备 ID（即 **vm-az220-training-gw0001-{your-id}**）后附加指定的区域和 Azure 商业云域名，例如 **.westus2.cloudapp.azure.com**。

    完整的连接字符串值应为以下格式：

    ```text
    HostName=<IoT-Hub-Name>.azure-devices.net;DeviceId=sensor-th-0072;SharedAccessKey=<Primary-Key-for-IoT-Device>;GatewayHostName=<DNS-Name-for-IoT-Edge-Device>
    ```

    请务必使用适当的值替换上述占位符：

    * **\<IoT-Hub-Name\>**：Azure IoT 中心的名称。
    * **\<Primary-Key-for-IoT-Device\>**：Azure IoT 中心中 **sensor-th-0072** IoT 设备的主键。
    * **\<DNS-Name-for-IoT-Edge-Device\>**： **vm-az220-training-gw0001-{your-id}** Edge 设备的 DNS 名称。

    具有组合的连接字符串值的 **connectionString** 变量将类似于以下内容：

    ```csharp
    private readonly static string connectionString = "HostName=iot-az220-training-abc201119.azure-devices.net;DeviceId=sensor-th-0072;SharedAccessKey=ygNT/WqWs2d8AbVD9NAlxcoSS2rr628fI7YLPzmBdgE=;GatewayHostName=vm-az220-training-gw0001-{your-id}.westus2.cloudapp.azure.com";
    ```

1. 在 **“文件”** 菜单中，单击 **“保存”**。

1. 向下滚动以找到 **Main** 方法，然后花点时间查看代码。

    该方法包含使用配置的连接字符串实例化 **DeviceClient** 的代码，并将 `MQTT` 指定为用于与 Azure IoT Edge 网关通信的传输协议。

    ```csharp
    deviceClient = DeviceClient.CreateFromConnectionString(connectionString, TransportType.Mqtt);
    SendDeviceToCloudMessagesAsync();
    ```

    Main 方法还会：

    * 调用 **InstallCACert** 方法，该方法具有一些代码，可以将根 CA X.509 证书自动安装到本地计算机。
    * 调用可从模拟设备发送事件遥测数据的 **SendDeviceToCloudMessagesAsync** 方法。

1. 找到 **SendDeviceToCloudMessagesAsync** 方法，然后花点时间查看代码。

    此方法包含生成模拟设备遥测的代码，并将事件发送到 IoT Edge 网关。

1. 找到 **InstallCACert** 并浏览将根 CA X.509 证书安装到本地计算机证书存储的代码。

    > **备注：** 请记住，此证书用于确保设备与 Edge 网关之间的通信安全。设备使用连接字符串中的对称密钥向 IoT 中心进行身份验证。

    此方法中的初始代码负责确保 **azure-iot-test-only.root.ca.cert.pem** 文件可用。当然，在生产应用程序中，你可能会考虑使用替代机制来指定 X.509 证书的路径（例如环境变量）或使用 TPM。

    验证存在 X.509 证书之后，将使用 **X509Store** 类将证书加载到当前用户的证书存储中。然后，该证书将按需提供，以确保与网关的通信安全 - 这是在设备客户端中自动发生的，因此没有其他代码。

    > **信息**： 可以在 [此处](https://docs.microsoft.com/zh-cn/dotnet/api/system.security.cryptography.x509certificates.x509store?view=netcore-3.1)了解有关 **X509Store** 类的详细信息。

1. 在 **“终端”** 菜单中，单击 **“新建终端”**。

1. 在“终端”命令提示符下，输入以下命令：

    ```bash
    dotnet run
    ```

    此命令将为要开始发送设备遥测数据的 **sensor-th-0072** 模拟设备生成并运行代码。

    > **备注：** 当应用尝试在本地计算机上安装 X.509 证书（以便可以使用它来向 IoT Edge 网关进行身份验证）时，你可能会看到一个安全警告，询问有关安装证书的问题。需要单击 **“是”**，以允许该应用继续运行。

1. 如果询问你是否要安装证书，请单击 **“是”**。

1. 模拟设备运行后，控制台输出将显示发送到 Azure IoT Edge 网关的事件。

    终端输出类似于以下内容：

    ```text
    IoT Hub C# Simulated Cave Device. Ctrl-C to exit.

    User configured CA certificate path: azure-iot-test-only.root.ca.cert.pem
    Attempting to install CA certificate: azure-iot-test-only.root.ca.cert.pem
    Successfully added certificate: azure-iot-test-only.root.ca.cert.pem

    10/25/2019 6:10:12 PM > Sending message: {"temperature":27.714212817472504,"humidity":63.88147743599558}
    10/25/2019 6:10:13 PM > Sending message: {"temperature":20.017463779085066,"humidity":64.53511070671263}
    10/25/2019 6:10:14 PM > Sending message: {"temperature":20.723927165718717,"humidity":74.07808918230147}
    10/25/2019 6:10:15 PM > Sending message: {"temperature":20.48506045736608,"humidity":71.47250854944461}
    ```

    > **备注：** 如果设备发送在第一次发送时暂停的时间似乎超过了一秒，可能是你之前未正确添加 NSG 传入规则，因此 MQTT 流量被阻止了。  检查 NSG 配置。

1. 让模拟设备保持运行状态，同时继续进行下一个练习。

### 练习 10：验证事件流

在本练习中，将使用 Azure CLI 监视通过 IoT Edge 网关从下游 IoT 设备发送到 Azure IoT 中心的事件。这将验证一切是否正常运行。

1. 如有必要，请使用 Azure 帐户凭据登录到 Azure 门户。

    如果有多个 Azure 帐户，请确保使用与本课程要使用的订阅绑定的帐户登录。

1. 如果未运行 Cloud Shell，请在 Azure 门户工具栏上单击 **“Cloud Shell”**。

1. 如果仍通过 Cloud Shell 中的 SSH 连接连接到 Edge 设备，请退出该连接。

1. 在 Cloud Shell 命令提示符处，运行以下命令，即可监视流到 Azure IoT 中心的事件流：

    ```bash
    az iot hub monitor-events -n iot-az220-training-{your-id}
    ```

    务必将 `-n` 参数的 `{your-id}` 占位符替换为 Azure IoT 中心的名称。

    使用 `az iot hub monitor-events` 命令即可监视发送到 Azure IoT 中心的设备遥测数据和消息。这将验证 Azure IoT 中心是否已接收到来自模拟设备且发送到 IoT Edge 网关的事件。

1. 在一切正常运行的情况下，`az iot hub monitor-events` 命令的输出类似于以下内容：

    ```text
    chris@Azure:~$ az iot hub monitor-events -n iot-az220-training-1119
    Starting event monitor, use ctrl-c to stop...
    {
        "event": {
            "origin": "sensor-th-0072",
            "payload": "{\"temperature\":30.931512529929872,\"humidity\":78.70672198883571}"
        }
    }
    {
        "event": {
            "origin": "sensor-th-0072",
            "payload": "{\"temperature\":30.699204018199445,\"humidity\":78.04910910224966}"
        }
    }
    ```

完成本实验室并验证事件流后，请按 **CTRL+C**，退出控制台应用程序。
