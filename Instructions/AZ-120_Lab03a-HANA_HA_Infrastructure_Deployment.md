# AZ 120 模块 3：实施 Azure 上的 SAP
# 实验室 3a: 在运行 Linux 的 Azure VM 上实施 SAP 体系结构

预计用时：100 分钟

本实验室中的所有任务都是从 Azure 门户执行的（包括 Bash Cloud Shell 会话）  

   > **备注**：如果不使用 Cloud Shell，则实验室虚拟机必须安装 Azure CLI [**https://docs.microsoft.com/zh-cn/cli/azure/install-azure-cli-windows**](https://docs.microsoft.com/zh-cn/cli/azure/install-azure-cli-windows)。

实验室文件：无

## 应用场景
  
为准备在 Azure 上部署 SAP NetWeaver，Adatum Corporation 希望实施一个演示，演示在运行 Linux SUSE 发行版的 Azure VM 上实施高度可用的 SAP NetWeaver 过程。

## 目标
  
完成本实验室后，你将能够：

-   预配支持高可用性 SAP NetWeaver 部署所需的 Azure 资源

-   配置运行 Linux 的 Azure VM 操作系统，以支持高可用性 SAP NetWeaver 部署

-   在运行 Linux 的 Azure VM 上配置群集，以支持高可用性 SAP NetWeaver 部署

## 要求

-   在支持可用性区域的 Azure 区域中，具有数量充足的可用 Dsv3 vCPU（4 个 Standard_D2s_v3 VM，每个 VM 2 个 vCPU；2 个 Standard_D4s_v3 VM，每个 VM 4 个 vCPU）的 Microsoft Azure 订阅

-   安装了兼容 Azure Cloud Shell 的 Web 浏览器且具有 Azure 访问权限的实验室计算机


## 练习 1：预配支持高可用性 SAP NetWeaver 部署所需的 Azure 资源

持续时间：30 分钟

在本练习中，你将部署配置 Linux 群集所必需的 Azure 基础结构计算组件。这将涉及在同一可用性集中创建一对运行 Linux SUSE 的 Azure VM。

### 任务 1：创建将托管高可用性 SAP NetWeaver 部署的虚拟网络。

1.  从实验室计算机中启动网页浏览器，并导航到 Azure 门户网站：https://portal.azure.com

1.  如果出现提示，请使用你在本实验室中使用的 Azure 订阅的所有者或参与者角色以及与你的订阅关联的 Azure AD 租户中的全局管理员角色登录工作或学校或个人 Microsoft 帐户。

1.  从 Azure 门户，在 Cloud Shell 启动 Bash 会话。 

    > **注意**： 如果这是你第一次在当前 Azure 订阅中启动 Cloud Shell，则会要求你创建 Azure 文件共享以保留 Cloud Shell 文件。如果是，请接受默认值，将在自动生成的资源组中创建存储帐户。

1.  在 Cloud Shell 窗格中运行以下命令，指定你要在其中为此实验室创建资源且支持可用性区域的 Azure 区域（用支持可用性区域的 Azure 区域的名称替换 `<region>`）：

    ```cli
    LOCATION='<region>'
    ```

    > **注意**： 请考虑使用**美国东部**或**美国东部 2** 区域来部署资源。 

    > **备注：** 确保为 Azure 区域使用正确的表示法（简称不包含空格，例如是 **eastus** 而不是 **US East**）

    > **备注：** 要确定支持可用性区域的 Azure 区域，请参阅 [https://docs.microsoft.com/zh-cn/azure/availability-zones/az-region](https://docs.microsoft.com/zh-cn/azure/availability-zones/az-region)

1. 在 Cloud Shell 窗格中运行以下命令，将变量 `RESOURCE_GROUP_NAME` 的值设置为你在上一个任务中预配的资源所在的资源组的名称：

    ```cli
    RESOURCE_GROUP_NAME='az12003a-sap-RG'
    ```

1.  在 Cloud Shell 窗格中，运行以下命令以创建指定区域的资源组：

    ```cli
    az group create --resource-group $RESOURCE_GROUP_NAME --location $LOCATION
    ```

1.  在 Cloud Shell 窗格中，运行以下命令以在你创建的资源组中创建具有单个子网的虚拟网络：

    ```cli
    VNET_NAME='az12003a-sap-vnet'

    VNET_PREFIX='10.3.0.0/16'

    SUBNET_NAME='sapSubnet'

    SUBNET_PREFIX='10.3.0.0/24'

    az network vnet create --resource-group $RESOURCE_GROUP_NAME --location $LOCATION --name $VNET_NAME --address-prefixes $VNET_PREFIX --subnet-name $SUBNET_NAME --subnet-prefixes $SUBNET_PREFIX
    ```

1.  在 Cloud Shell 窗格中，运行以下命令以标识新创建的虚拟网络的子网资源 ID：

    ```cli
    az network vnet subnet list --resource-group $RESOURCE_GROUP_NAME --vnet-name $VNET_NAME --query "[?name == '$SUBNET_NAME'].id" --output tsv
    ```

1.  将生成的值复制到剪贴板。需要在下一个任务中使用它。

### 任务 2：部署预配运行 Linux SUSE 的 Azure VM 的 Azure 资源管理器模板，该 VM 将托管高可用性 SAP NetWeaver 部署

1.  在实验室计算机上，启动浏览器并浏览[**https://github.com/Azure/azure-quickstart-templates/tree/master/application-workloads/sap/sap-3-tier-marketplace-image-md**](https://github.com/Azure/azure-quickstart-templates/tree/master/application-workloads/sap/sap-3-tier-marketplace-image-md)

    > **注意**： 确保使用 Microsoft Edge 或第三方浏览器。请勿使用 Internet Explorer。

1.  在标题为**使用市场映像的 SAP NetWeaver 3 层兼容模板 - MD**的页面上，单击**部署到 Azure**。这将自动将你的浏览器重定向到 Azure 门户并显示 **SAP NetWeaver 3 层（托管磁盘）** 边栏选项卡。

1.  在 **“SAP NetWeaver 3 层(托管磁盘)”** 边栏选项卡上，选择 **“编辑模板”**。

1.  在 **“编辑模板”** 边栏选项卡上，应用以下更改并选择 **“保存”**：

    -   在第 **197** 行，将 `"dbVMSize": "Standard_E8s_v3",` 替换为 `"dbVMSize": "Standard_D4s_v3",`

1.  在 **“SAP NetWeaver 3 层(托管磁盘)”** 边栏选项卡上，使用以下设置启动部署：

    -   订阅： *你的 Azure 订阅名称*

    -   资源组： *在先前任务中使用的资源组名称*

    -   位置： *你在本练习的第一个任务中指定的 Azure 区域*

    -   SAP 系统 ID： **I20**

    -   堆栈类型： **ABAP**

    -   Os 类型： **TCP 12**

    -   Dbtype： **HANA**

    -   SAP 系统大小： **演示**

    -   系统可用性： **HA**

    -   管理员用户名： **student**

    -   验证类型： **密码**

    -   管理员密码或密钥： **Pa55w.rd1234**

    -   子网 ID： *你在上一个任务中复制到剪贴板的值*

    -   可用性区域： **1,2**

    -   位置： **[resourceGroup().location]**

    -   _artifacts 位置：**https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/application-workloads/sap/sap-3-tier-marketplace-image-md/**

    -   _artifacts 位置 Sas 令牌： *留空*

1.  不要等待部署完成，而是继续执行下一个任务。 

    > **备注：** 如果在 CustomScriptExtension 组件部署期间，部署失败并出现 **“冲突”** 错误消息，请按以下步骤修正此问题：

       - 在 Azure 门户中的 **“部署”** 边栏选项卡上，查看部署详细信息并确定 CustomScriptExtension 安装失败的 VM

       - 在 Azure 门户中，导航到上一步中确定的 VM 的边栏选项卡，选择 **“扩展”**，从 **“扩展”** 边栏选项卡中删除 CustomScript 扩展

       - 在 Azure 门户中，导航到 **“az12003a-sap-RG”** 资源组边栏选项卡，选择 **“部署”**，选择指向失败部署的链接，然后选择 **“重新部署”**，选择目标资源组 (**az12003a-sap-RG**) 并提供根帐户的密码 (**Pa55w.rd1234**)。


### 任务 3：部署跳转主机

   > **注意**：由于无法从 Internet 访问你在上一个任务中部署的 Azure VM，因此你将部署运行 Windows Server 2019 Datacenter 的 Azure VM 作为跳转主机。 

1.  在实验室计算机的 Azure 门户中，单击 **“+ 创建资源”**。

1.  在 **新建** 边栏选项卡中，基于 **Windows Server 2019 Datacenter** 图像，开始创建新的 Azure VM。

1.  通过以下设置预配 Azure VM（所有其他设置保留默认值）：

    -   订阅： *你的 Azure 订阅名称*

    -   资源组： *新资源组名为* **az12003a-dmz-RG**

    -   虚拟机名称： **az12003a-vm0**

    -   区域： *在本练习的上一个任务中部署 Azure VM 的相同 Azure 区域*

    -   可用性选项： **无需基础结构冗余**

    -   映像： **Windows Server 2019 Datacenter - Gen 1**

    -   大小：**标准 D2s_v3 或类似大小**

    -   用户名称： **Student**

    -   密码： **Pa55w.rd1234**

    -   公共入站端口： **允许选定的端口**

    -   选择入站端口： **RDP (3389)**

    -   是否已拥有 Windows 许可证？： **否**

    -   OS 磁盘类型： **标准 HDD**

    -   虚拟网络： **az12003a-sap-vnet**

    -   子网： 名为 **bastionSubnet (10.3.255.0/24)** 的新子网

    -   公共 IP： *新 IP 地址名为* **az12003a-vm0-ip**

    -   NIC 网络安全组： **基本**

    -   公共入站端口： **允许选定的端口**

    -   选择入站端口： **RDP (3389)**

    -   加速网络： **关闭**

    -   将此虚拟机置于现有负载均衡解决方案之后： **否**

    -   启动诊断：**禁用**

    -   OS 来宾诊断：**关闭**

    -   系统分配的托管标识：**关闭**

    -   使用 AAD 凭据登录（预览）：**关闭**

    -   启用自动关闭：**关闭**

    -   启用备份：**关闭**

    -   修补业务流程选项“**手动更新**”

    -   扩展：**无**

    -   标签：**无**

1.  等待预配完成。这可能需要几分钟。

> **结果**： 完成本练习后，你已配置了支持高可用性 SAP NetWeaver 部署所需的 Azure 资源


## 练习 2：配置运行 Linux 的 Azure VM，以支持高可用性 SAP NetWeaver 部署

持续时间：30 分钟

在本练习中，你将配置运行 SUSE Linux Enterprise Server 的 Azure VM，以适应高可用性 SAP NetWeaver 部署。

### 任务 1：配置数据库层 Azure VM 的网络。

   > **注意**： 在开始此任务之前，请确保你在之前练习中启动的模板部署已完成。 

1.  在实验室计算机的 Azure 门户中，导航到 **i20-db-0** Azure VM 的边栏选项卡。

1.  从 **“i20-db-0”** 边栏选项卡，导航到 **“网络”** 边栏选项卡。 

1.  从 **“i20-db-0 - 网络”** 边栏选项卡，导航到 i20-db-0 的网络接口。 

1.  从 i20-db-0 的网络接口边栏选项卡，导航到其“IP 配置”边栏选项卡，其中显示其 **“ipconfig1”** 边栏选项卡。

1.  在 **“ipconfig1”** 边栏选项卡上，将专用 IP 地址设置为 **“10.3.0.20”**，将其分配更改为 **“静态”**，然后保存更改。

1.  在 Azure 门户中，导航到 **i20-db-1** Azure VM 的边栏选项卡。

1.  从 **“i20-db-1”** 边栏选项卡，导航到 **“网络”** 边栏选项卡。 

1.  从 **“i20-db-1 - 网络”** 边栏选项卡，导航到 i20-db-1 的网络接口。 

1.  从 i20-db-1 的网络接口边栏选项卡，导航到其“IP 配置”边栏选项卡，其中显示其 **“ipconfig1”** 边栏选项卡。

1.  在 **“ipconfig1”** 边栏选项卡上，将专用 IP 地址设置为 **“10.3.0.21”**，将其分配更改为 **“静态”**，然后保存更改。


### 任务 2：连接到数据库层 Azure VM。

1.  在实验室计算机的 Azure 门户中，导航到 **az12003a-vm0** 边栏选项卡。

1.  在**az12003a-vm0** 边栏选项卡中，使用远程桌面连接到 Azure VM az12003a-vm0。 

1.  在与 az12003a-vm0 的 RDP 会话中，在服务器管理器中，导航到**本地服务器**视图并关闭 **IE 增强安全配置**。

1.  在与 az12003a-vm0 的 RDP 会话中，从 [**https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html**](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) 下载并安装 PuTTY。

1.  使用 PuTTY 通过 SSH 连接 **i20-db-0** Azure VM。确认安全警报，并在出现提示时提供以下凭据：

    -   登录身份： **student**

    -   密码： **Pa55w.rd1234**

1.  使用 PuTTY 通过 SSH 连接 **i20-db-1** 具有相同凭据的 Azure VM。


### 任务 3：检查 Azure VM 的数据库层的存储配置。

1.  在 i20-db-0 Azure VM 的 PuTTY SSH 会话中，运行以下命令以提升权限： 

    ```
    sudo su -
    ```

1.  如果提示输入密码，请键入 **“Pa55w.rd1234”** 并按 **Enter** 键。 

1.  在与 i20-db-0 的 SSH 会话中运行以下命令，验证所有与 SAP HANA 相关的卷（包括 **/usr/sap**、 **/hana/shared**、 **/hana/backup**、 **/hana/data** 和 **/hana/logs**）均正确安装：

    ```
    df -h
    ```

1.  在 i20-db-1 Azure VM 上重复上述步骤。


### 任务 4：启用跨节点无密码 SSH 访问

1.  在与 i20-db-0 的 SSH 会话中，通过运行以下命令生成无密码的 SSH 密钥：

    ```
    ssh-keygen
    ```

1.  出现提示时，按 **回车键** 三次，然后通过运行以下命令显示密钥： 

    ```
    cat /root/.ssh/id_rsa.pub
    ```

1.  将密钥值复制到剪贴板中。

1.  在与 i20-db-1 的 SSH 会话中运行以下命令，在 vi 编辑器中创建 **/root/.ssh/authorized\_keys** 文件：

    ```
    vi /root/.ssh/authorized_keys
    ```

1.  在 vi 编辑器中，粘贴你在 i20-db-0 上生成的密钥。

1.  保存更改并关闭编辑器。

1.  在 i20-db-1 的 SSH 会话中，通过运行以下命令生成无密码的 SSH 密钥：

    ```
    ssh-keygen
    ```

1.  出现提示时，按 **回车键** 三次，然后通过运行以下命令显示密钥： 

    ```
    cat /root/.ssh/id_rsa.pub
    ```

1.  将密钥值复制到剪贴板中。

1.  在与 i20-db-0 的 SSH 会话中运行以下命令，在 vi 编辑器中创建 **/root/.ssh/authorized\_keys** 文件：

    ```
    vi /root/.ssh/authorized_keys
    ```

1.  在 vi 编辑器中，从新行开始，粘贴你在 i20-db-1 上生成的密钥。

1.  保存更改并关闭编辑器。

1.  要验证配置是否成功，请在与 i20-db-0 的 SSH 会话中，通过运行以下命令建立从 i20-db-0 到 i20-db-1 的 SSH 会话，作为 **“根”**： 

    ```
    ssh root@i20-db-1
    ```

1.  当系统提示你是否确定要继续连接时，请键入 `yes` 并按**Enter**。 

1.  确保未提示你输入密码。

1.  通过运行以下命令，关闭从 i20-db-0 到 i20-db-1 的 SSH 会话： 

    ```
    exit
    ```

1.  在与 i20-db-1 的 SSH 会话中，通过运行以下命令建立从 i20-db-1 到 i20-db-0 的 SSH 会话，作为 **“根”**： 

    ```
    ssh root@i20-db-0
    ```

1.  当系统提示你是否确定要继续连接时，请键入 `yes` 并按**Enter**。 

1.  确保未提示你输入密码。

1.  通过运行以下命令，关闭从 i20-db-1 到 i20-db-0 的 SSH 会话： 

    ```
    exit
    ```

### 任务 5：添加 YaST 包，更新 Linux 操作系统、安装 HA 扩展

1.  在 i20-db-0 的 SSH 会话中，运行以下命令以启动 YaST：

    ```
    yast
    ```

1.  在 **YaST 控制中心**，选择**软件 - \> 附加产品**并按 **Enter**。将加载**包管理器**。

1.  在 **“已安装的附加产品”** 屏幕上，验证是否已安装 **“公有云模块”**。然后，按两次 **F9** 返回到 shell 提示符。

1.  在与 i20-db-0 的 SSH 会话中，运行以下命令更新操作系统（出现提示时，键入 **y** 并按下 **Enter**）：

    ```
    zypper update
    ```

1.  在与 i20-db-0 的 SSH 会话中运行以下命令，安装群集资源所需的包（出现提示时，键入 **“y”** 并按 **Enter** 键）：

    ```
    zypper in socat
    ```

1.  在与 i20-db-0 的 SSH 会话中运行以下命令，安装群集资源所需的 azure-lb 组件：

    ```
    zypper in resource-agents
    ```

1.  在与 i20-db-0 的 SSH 会话中运行以下命令，在 vi 编辑器中打开 **/etc/systemd/system.conf** 文件：

    ```
    vi /etc/systemd/system.conf
    ```

1.  在 vi 编辑器中，将 `#DefaultTasksMax=512` 替换为 `DefaultTasksMax=4096`。 

    > **备注：** 在某些情况下，Pacemaker 可能会创建许多进程，达到默认数量限制并触发故障转移。此更改增加了允许的最大进程数。

1.  保存更改并关闭编辑器。

1.  在与 i20-db-0 的 SSH 会话中运行以下命令，启动配置更改：

    ```
    systemctl daemon-reload
    ```

1. 在与 i20-db-0 的 SSH 会话中运行以下命令，安装隔离代理包：

    ```
    zypper install fence-agents
    ```

1. 在与 i20-db-0 的 SSH 会话中运行以下命令，安装隔离代理所需的 Azure Python SDK（出现提示时，键入 **“y”** 并按 **Enter** 键）：

    ```
    SUSEConnect -p sle-module-public-cloud/12/x86_64
    zypper install python-azure-mgmt-compute
    ```

1. 在 i20-db-1 上重复此任务中的上述步骤。

> **结果：** 完成本练习后，你将拥有运行 Linux 的 Azure VM 的 onfigured 操作系统，以支持高可用性的 SAP NetWeaver 部署

## 练习 3：在运行 Linux 的 Azure VM 上配置群集，以支持高可用性 SAP NetWeaver 部署

持续时间：30 分钟

在本练习中，你将在运行 Linux 的 Azure VM 上配置群集，以支持高可用性 SAP NetWeaver 部署。

### 任务 1：配置群集

1.  在与 az12003a-vm0 的 RDP 会话中，在基于 PuTTY 的与 i20-db-0 的 SSH 会话中，运行以下命令以在 i20-db-0 上启动 HA 群集的配置：

    ```
    ha-cluster-init -u
    ```

1.  出现提示时，请提供以下回答：

    -   是否仍要继续 (y/n)?： **y**

    -   ring0 的地址 [10.3.0.20]： **ENTER**

    -   ring0 的端口 [5405]： **ENTER**

    -   你想使用 SBD 吗 (y/n)?： **n**

    -   是否希望配置虚拟 IP 地址 (y/n)?： **n**

    > **注意**： 群集设置生成一个 **hacluster** 帐户，且其密码设置为 **linux**。你将在此任务后面部分更改它。

1.  在与 az12003a-vm0 的 RDP 会话中，在与 i20-db-1 的基于 PuTTY 的 SSH 会话中运行以下命令，从 i20-db-1 加入 i20-db-0 上的 HA 群集：

    ```
    ha-cluster-join
    ```

1.  出现提示时，请提供以下回答：

    -   你想继续吗 (y/n)? **y**

    -   现有节点的 IP 地址或主机名（例如：192.168.1.1) \[\]: **i20-db-0**

    -   ring0 的地址 [10.3.0.21]： **ENTER**

1.  在与 i20-db-0 的基于 PuTTY 的 SSH 会话中运行以下命令，将 **hacluster** 帐户的密码设置为 **Pa55w.rd1234** （出现提示时键入新密码）： 

    ```
    passwd hacluster
    ```

1.  在 i20-db-1 上重复上述步骤。

### 任务 2：查看 corosync 配置

1.  在与 az12003a-vm0 的 RDP 会话中，在与 i20-db-0 的基于 PuTTY 的 SSH 会话中运行以下命令，打开 **/etc/corosync/corosync.conf** 文件：

    ```
    vi /etc/corosync/corosync.conf
    ```

1.  在 vi 编辑器中，注意 `transport: udpu` 条目和 `nodelist` 部分：
    ```
    [...]
       interface { 
           [...] 
       }
       transport:      udpu
    } 
    nodelist {
       node {
         ring0_addr:     10.3.0.20
         nodeid:     1
       }
       node {
         ring0_addr:     10.3.0.21
         nodeid:     2
       } 
    }
    logging {
        [...]
    ```

1.  在 vi 编辑器中，将条目 `token: 5000` 替换为 `token: 30000`。

    > **备注：** 此更改可以维护内存预留。如需了解详情，请参考[关于在 Azure 中维护虚拟机的 Microsoft 文档](https://docs.microsoft.com/zh-cn/azure/virtual-machines/maintenance-and-updates#maintenance-that-doesnt-require-a-reboot)

1.  保存更改并关闭编辑器。

1.  在 i20-db-1 上重复上述步骤。


### 任务 3：确定 Azure 订阅 ID 和 Azure AD 租户 ID 的值

1.  从实验室计算机的浏览器窗口中，进入 Azure 门户网站： **https://portal.azure.com** 确保你使用与订阅关联的 Azure AD 租户中具有全局管理员角色的用户帐户登录。

1.  从 Azure 门户，在 Cloud Shell 启动 Bash 会话。 

1.  在 Cloud Shell 窗格中，运行以下命令以标识 Azure 订阅 ID 以及相应 Azure AD 租户的 ID：

    ```cli
    az account show --query '{id:id, tenantId:tenantId}' --output json
    ```

1.  将结果值复制到记事本。需要在下一个任务中使用它。


### 任务 4：为 STONITH 设备创建 Azure AD 应用程序

1.  在 Azure 门户中，导航到 Azure Active Directory 边栏选项卡。

1.  从 Azure Active Directory 边栏选项卡，导航到**应用注册**边栏选项卡，然后单击**新建注册**：

1.  在**注册应用程序**边栏选项卡，指定以下设置并单击**注册**：

    -   名称：**Stonith app**

    -   支持的帐户类型：**仅限该组织目录中的帐户**

1.  在 **Stonith app** 边栏选项卡，复制 **应用程序（客户端）ID** 的值到记事本。之后在本练习中称为 **login_id** ：

1.  在 **Stonith app** 边栏选项卡，单击 **证书和密钥**。

1.  在 **Stonith app - 证书和密钥** 边栏选项卡，单击 **新建客户端密钥**。

1.  在“**添加客户端密码**”窗格的“**说明**”文本框中，键入“**STONITH 应用密钥**”，在“**过期时间**”部分，保留默认值“**建议:6 个月**”，然后单击“**添加**”。

1.  将结果“**值**”复制到 Notepad（单击“**添加**”后，此条目仅显示一次）。本练习的后面部分将其称为“**密码**”：


### 任务 5：将 Azure VM 的权限授予 STONITH 应用的服务主体 

1.  在 Azure 门户中，导航到 **i20-db-0** Azure VM 的边栏选项卡

1.  从 **i20-db-0** 边栏选项卡进入，显示 **i20-db-0 - 访问控制 (IAM)** 边栏选项卡。

1.  在 **i20-db-0 - 访问控制 (IAM)** 边栏选项卡中，添加具有以下设置的角色分配：

    -   角色： **虚拟机参与者**

    -   将访问权限分配给： **Azure AD 用户、组或服务主体**

    -   选择： **Stonith app**

1.  重复前面的步骤，将 **i20-db-1** Azure VM 的“虚拟机参与者”角色分配给 Stonith 应用


### 任务 6：配置 STONITH 群集设备 

1.  在与 az12003a-vm0 的 RDP 会话中，切换到与 i20-db-0 的基于 PuTTY 的 SSH 会话。

1.  在与 az12003a-vm0 的 RDP 会话中，在与 i20-db-0 的基于 PuTTY 的 SSH 会话中运行以下命令（确保将 `subscription_id`、`tenant_id`、`login_id` 和 `password` 占位符替换为你在练习 3 任务 4 中确定的值）：

    ```
    crm configure property stonith-enabled=true

    crm configure property concurrent-fencing=true

    crm configure primitive rsc_st_azure stonith:fence_azure_arm \
      params subscriptionId="subscription_id" resourceGroup="az12003a-sap-RG" tenantId="tenant_id" login="login_id" passwd="password" \
      pcmk_monitor_retries=4 pcmk_action_limit=3 power_timeout=240 pcmk_reboot_timeout=900 \
      op monitor interval=3600 timeout=120

    sudo crm configure property stonith-timeout=900
    ```

### 任务 7：使用 Hawk 查看在运行 Linux 的 Azure VM 上的群集配置

1.  在与 az12003a-vm0 的 RDP 会话中，启动 Internet Explorer 并导航到： **https://i20-db-0:7630** 这将显示 SUSE Hawk 的登录页面。

   > **注意**：忽略 **“此站点不安全”** 的消息。

1.  在 SUSE Hawk 登录页面上，使用以下凭据登录：

    -   用户名： **hacluster**

    -   密码： **Pa55w.rd1234**

1.  验证群集状态是否正常。如果你看到一条消息，指示两个群集节点中之一不干净，请从 Azure 门户重启该节点。

> **结果**： 完成本练习后，你已在运行 Linux 的 Azure VM 上配置群集，以支持高可用性 SAP NetWeaver 部署


## 练习 4：删除实验室资源

持续时间：10 分钟

在本练习中，你将删除本实验室中预配的所有资源。

#### 任务 1：打开 Cloud Shell

1. 在门户顶部，单击 **“Cloud Shell”** 图标以打开 Cloud Shell 窗格，然后选择“Bash”作为 Shell。

1. 在 Cloud Shell 窗格中运行以下命令，将变量 `RESOURCE_GROUP_PREFIX` 的值设置为你在本实验室中预配的资源所在的资源组的名称前缀：

    ```cli
    RESOURCE_GROUP_PREFIX='az12003a-'
    ```

1. 在 Cloud Shell 窗格中运行以下命令，列出你在本实验室中创建的所有资源组：

    ```cli
    az group list --query "[?starts_with(name,'$RESOURCE_GROUP_PREFIX')]".name --output tsv
    ```

1. 验证输出中是否仅包含你在本实验室中创建的资源组。在下一个任务中，将删除该资源组及其所有资源。

#### 任务 2：删除资源组

1. 在 Cloud Shell 窗格中运行以下命令，删除该资源组及其资源。

    ```cli
    az group list --query "[?starts_with(name,'$RESOURCE_GROUP_PREFIX')]".name --output tsv | xargs -L1 bash -c 'az group delete --name $0 --no-wait --yes'
    ```

1. 关闭“Cloud Shell”窗格。

> **结果：** 完成本练习后，你已经删除了本实验中使用的资源。
