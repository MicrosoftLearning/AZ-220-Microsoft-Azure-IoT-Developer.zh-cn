# 演示：使用 Azure Bastion 与 Linux VM 建立 SSH 连接

在本演示中，你将使用 Azure 门户以及你的用户名和密码与位于 Azure 虚拟网络中的 Linux VM 建立 SSH 连接。如果使用 Azure Bastion，则 VM 不需要客户端、代理或其他软件。

## 先决条件

为完成本演示，需要用到包含 Linux VM 的 Azure 虚拟网络。有关如何创建 Azure VM 的详细信息，请参阅[演示：在门户中创建虚拟机](https://github.com/MicrosoftLearning/AZ-120ZH-Planning-and-Administering-Microsoft-Azure-for-SAP-Workloads/blob/master/Demos/demo-create-virtual-machine-portal.md)，或[演示：使用 PowerShell 创建虚拟机](https://github.com/MicrosoftLearning/AZ-120ZH-Planning-and-Administering-Microsoft-Azure-for-SAP-Workloads/blob/master/Demos/demo-create-virtual-machine-powershell.md)。

确保已为 VM 所在的虚拟网络设置 Azure Bastion 主机。有关详细信息，请参阅[创建 Azure Bastion 主机](https://docs.microsoft.com/azure/bastion/tutorial-create-host-portal)。在虚拟网络中预配和部署 Bastion 服务后，就可以使用它连接到此虚拟网络中的任何 VM。 

### 必需的角色

需要使用以下角色进行连接：

* 虚拟机上的读取者角色
* NIC 上的读取者角色（使用虚拟机的专用 IP）
* Azure Bastion 资源上的读取者角色

### 端口

若要通过 SSH 连接到 Linux VM，必须在 VM 上打开以下端口：

* 入站端口：SSH (22) ***或***
* 入站端口：自定义值（然后，通过 Azure Bastion 连接到 VM 时，需要指定此自定义端口）

> **备注：** 如果要指定自定义端口值，必须使用标准 SKU 配置 Azure Bastion。使用基本 SKU 不能指定自定义端口。标准 SKU 目前为预览版。

## 连接：使用用户名和密码

1. 打开 [Azure 门户](https://portal.azure.com)。导航到要连接的虚拟机，选择“**连接**”，然后从下拉列表中选择“**Bastion**”。

    ![屏幕截图显示 Azure 门户中虚拟机的概述，其中已选中“连接”](Images/azure-bastion-connect.png)

1. 选择“**使用 Bastion**”。如果尚未针对虚拟网络预配 Bastion，请参阅[配置 Bastion](https://docs.microsoft.com/azure/bastion/quickstart-host-portal)。
1. 在“**使用 Azure Bastion 连接**”页的“**用户名**”和“**密码**”处输入相应值。

    ![屏幕截图显示密码验证](Images/azure-bastion-password.png)

1. 选择“**连接**”以连接到 VM。