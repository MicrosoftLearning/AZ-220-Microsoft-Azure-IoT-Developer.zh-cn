---
lab:
    title: '实验室 05：在 DPS 中单独注册设备'
    module: '模块 3：大规模设备预配'
---

# 在 DPS 中单独注册设备

## 实验室场景

Contoso 管理层正在推动更新其现有资产监视和跟踪解决方案。该项更新将使用 IoT 设备来减少当前系统下所需的手动数据输入工作，并在运输过程中提供更高级的监视。该解决方案依赖于在装载运输容器时预配 IoT 设备和在容器抵达目的地时解除预配设备的能力。要管理预配要求，最佳的方式似乎是 IoT 中心设备预配服务 (DPS)。

建议的系统将使用具有集成传感器的 IoT 设备来跟踪运输过程中运输容器的位置、温度和压力。IoT 设备将放在 Contoso 用于运输奶酪的现有运输容器中，并将使用车辆提供的 WiFi 连接到 Azure IoT 中心。新系统将提供对产品环境的连续监视，并在检测到问题时启用各种通知方案。遥测发送到 IoT 中心的速率必须是可配置的。

在 Contoso 的奶酪包装设施中，当一个空容器进入系统时，它将配备新的 IoT 设备，然后装载包装好的奶酪产品。IoT 设备将通过 DPS 自动预配到 IoT 中心。当容器到达目的地时，将检索 IoT 设备且必须完全解除预配（取消注册并撤销登记）。恢复的设备将被回收，按照相同的自动预配流程重新用于将来的运输。

你的任务是使用 DPS 验证设备的预配和解除预配过程。在初始测试阶段，将使用“单个注册”方法。

将创建以下资源：

![实验室 5 基础结构](media/LAB_AK_05-architecture.png)

## 本实验室概览

在本实验室中，你首先将查看实验室先决条件，并根据需要运行脚本来确保你的 Azure 订阅包含所需的资源。然后，你将在使用 DPS 中创建新的单个注册，它使用对称密钥证明并指定设备的初始设备孪生状态（遥测速率）设备注册保存后，你将回到注册，并获取设备证明所需的自动生成的主密钥和辅助密钥。接下来，需要创建模拟设备，并验证设备是否成功连接到 IoT 中心，以及设备是否按预期应用了初始设备孪生属性。最后，你将完成解除预配过程，它通过取消注册和撤销登记设备（分别从 DPS 和 IoT 中心）安全地从解决方案中删除设备。本实验室包括以下练习：

* 验证实验室先决条件
* 在 DPS 中创建新的单个注册（对称密钥）
* 配置模拟设备
* 测试模拟设备
* 解除预配设备

## 实验室说明

### 练习 1：验证实验室先决条件

本实验室假定以下 Azure 资源可用：

| 资源类型 | 资源名称 |
| :-- | :-- |
| 资源组 | rg-az220 |
| IoT 中心 | iot-az220-training-{your-id} |
| 设备预配服务 | dps-az220-training-{your-id} |

如果这些资源不可用，请按照以下说明运行 **“lab05-setup.azcli”** 脚本，然后再前往练习 2。脚本文件包含在本地克隆作为开发环境配置（实验室 3）的 GitHub 存储库中。

写入 **lab05-setup.azcli** 脚本，并在 **Bash** shell 环境中运行，执行此操作最简便的方法是在 Azure Cloud Shell 中。

1. 使用浏览器，打开 [Azure Cloud Shell](https://shell.azure.com/)，并使用本课程使用的 Azure 订阅登录。

    如果系统提示设置 Cloud Shell 的存储，请接受默认设置。

1. 验证 Cloud Shell 是否在使用 **Bash**。

    Azure Cloud Shell 页面左上角的下拉菜单用于选择环境。验证所选的下拉值是否为 **Bash**。

1. 在 Cloud Shell 工具栏上，单击 **“上传/下载文件”** （从右数第四个按钮）。

1. 在下拉菜单中，单击 **“上传”**。

1. 在“文件选择”对话框中，导航到配置开发环境时下载的 GitHub 实验室文件的文件夹位置。

    在“实验室 3：_设置开发环境_，你可以通过下载 ZIP 文件并从本地提取内容来克隆包含实验室资源的 GitHub 存储库。提取的文件夹结构包括以下文件夹路径：

    * Allfiles
      * 实验室
          * 05 - DPS 中设备的单个注册
            * 设置

    lab05-setup.azcli 脚本文件位于实验室 5 的 Setup 文件夹中。

1. 选择 **“lab05-setup.azcli”** 文件，然后单击 **“打开”**。

    文件上传完成后，系统将显示一条通知。

1. 要验证是否上传了正确的文件，请输入以下命令：

    ```bash
    ls
    ```

    使用 `ls` 命令列出当前目录的内容。你应该会看到列出的 lab05-setup.azcli 文件。

1. 若要为此实验室创建一个包含安装脚本的目录，然后移至该目录，请输入以下 Bash 命令：

    ```bash
    mkdir lab5
    mv lab05-setup.azcli lab5
    cd lab5
    ```

    这些命令将为此实验室创建一个目录，将 **“lab05-setup.azcli”** 文件放入该目录，然后将当前工作目录更改为该新目录。

1. 为了确保 **lab05-setup.azcli** 脚本具有执行权限，请输入以下命令：

    ```bash
    chmod +x lab05-setup.azcli
    ```

1. 在 Cloud Shell 工具栏上，请单击 **“打开编辑器”** （右侧的第二个按钮 - **{ }**）以启用对 lab05-setup.azcli 文件的访问。

1. 在 **“文件”** 列表中，要展开 lab5 文件夹并打开脚本文件，请先单击 **“lab5”**，再单击 **“lab05-setup.azcli”**。

    编辑器现在将显示 **“lab05-setup.azcli”** 文件的内容。

1. 在编辑器中，更新 `{your-id}` 和 `{your-location}` 变量的值。

    以下面的示例为例，需要将 `{your-id}` 设置为在本课程开始时创建的唯一 ID（即 **cah191211**），然后将 `{your-location}` 设置为对你的资源有意义的位置。

    ```bash
    #!/bin/bash

    # 更改这些值！
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
    ./lab05-setup.azcli
    ```

    运行将花费几分钟时间。每个步骤完成时，你都会看到输出。

    脚本完成后，就可以继续实验室的内容。

### 练习 2：在 DPS 中创建新的单个注册（对称密钥）

在本练习中，将使用_对称密钥证明_在设备预配服务 (DPS) 中为设备创建新的单个注册。你还将在注册中配置初始设备状态。保存注册后，你将返回并获取自动生成的证明密钥，它们是在保存注册时创建的。

#### 任务 1：创建注册

1. 如有必要，使用 Azure 帐户凭据登录到 [portal.azure.com](https://portal.azure.com)。

    如果有多个 Azure 帐户，请确保使用与本课程要使用的订阅绑定的帐户登录。

1. 请注意，已加载 **AZ-220** 仪表板且已显示你的“资源”磁贴。

    你会同时看到 IoT 中心和列出的 DPS 资源。

1. 在 **rg-az220** 资源组磁贴上，单击 **“dps-az220-training-{your-id}”**。

1. 在左侧菜单 **“设置”** 下，单击 **“管理注册”**。

1. 在 **“管理注册”** 窗格顶部，单击 **“+ 添加单个注册”**。

1. 在 **“添加注册”** 边栏选项卡的 **“机制”** 下拉菜单中，单击 **“对称密钥”**。

    这会将证明方法设置为使用对称密钥身份验证。

1. 在“机制”设置下方，请注意已选中 **“自动生成密钥”** 选项。

    这会将 DPS 设置为自动生成创建设备注册时设备注册的 **“主键”** 值和 **“次关键字”** 值。或者，取消选中此选项将允许手动输入自定义键。

    > **备注：** 主密钥值和辅助密钥值是在保存此记录后生成的。在下一个任务中，你将回到此记录来获取值，稍后在本实验室中的模拟设备应用中使用它们。

1. 在 **“注册 ID”** 字段中，若要指定用于 DPS 中的设备注册的注册 ID，请输入 **“sensor-thl-1000”**

    默认情况下，从注册中预配设备时，注册 ID 将用作 IoT 中心设备 ID。如果这些值需要不同，可在该字段中输入所需的 IoT 中心设备 ID。

1. **“IoT 中心设备 ID”** 字段留空。

    将该字段留白可确保 IoT 中心将注册 ID 用作设备 ID。如果在无法选择的字段中看到默认文本值，请不要担心 - 这是占位符文本，不会被视为输入值。

1. 将 **“IoT Edge 设备”** 字段设置为 **“假”**。

    新设备将不会是边缘设备。本课程稍后将讨论如何使用 IoT Edge 设备。

1. 将 **“选择要将设备分配给中心的方式”** 字段继续设置为 **“均衡加权分布”**。

    由于你只有一个与注册关联的 IoT 中心，因此此设置不是很重要。  在拥有多个分布式中心的较大环境中，此设置用来控制如何选择接收此设备注册的 IoT 中心。支持四种分配策略：

    * **最低延迟**： 将设备预配到具有最低延迟的 IoT 中心。
    * **均衡加权分布（默认）**： 链接的 IoT 中心等可能地获得预配到它们的设备。这是默认设置。如果只将设备预配到一个 IoT 中心，则可以保留此设置。 
    * **通过注册列表进行静态配置**： 注册列表中所需 IoT 中心的规范优先于设备预配服务级别的分配策略。
    * **自定义（使用 Azure 函数）**： 设备预配服务调用你的 Azure 函数代码，以提供有关设备和注册的所有相关信息。将执行函数代码并返回用于预配设备的 IoT 中心信息。

1. 请注意，**“选择可供此设备分配的 IoT 中心”** 下拉菜单指定了你创建的 IoT 中心 **iot-az220-training-{your-id}**。

    此字段用于指定可供你的设备分配的 IoT 中心。

1. 将 **“选择重新预配设备请求时如何处理设备数据”** 字段保留为 **“重新预配并迁移数据”** 的默认值。

    通过此字段，可以对重新预配行为进行高级控制。所谓重新预配，是指同一设备（由同一注册 ID 指示）在成功预配至少一次之后再次提交配置请求的行为。有三个选项可供使用：

    * **重新预配和迁移数据**： 此策略是新注册条目的默认策略。当与注册项关联的设备提交新的预配请求时，此策略将执行操作。根据注册项配置，可将设备重新分配给其他 IoT 中心。如果设备正在更改 IoT 中心，则将删除初始 IoT 中心内的设备注册。来自该初始 IoT 中心的所有设备状态信息都将迁移到新的 IoT 中心。
    * **重新预配并重设为初始配置**： 此策略通常用于恢复出厂设置而无需更改 IoT 中心。当与注册项关联的设备提交新的预配请求时，此策略将执行操作。根据注册项配置，可将设备重新分配给其他 IoT 中心。如果设备正在更改 IoT 中心，则将删除初始 IoT 中心内的设备注册。向新的 IoT 中心提供预配设备时预配服务实例接收到的初始配置数据。
    * **从不重新预配**： 设备从不重新分配到其他中心。此策略用于管理后向兼容性。

1. 在 **“初始设备孪生状态”** 字段中，若要使用值 `"2"` 指定名为 `telemetryDelay` 的属性，请如下更新 JSON 对象：

    最终的 JSON 如下所示：

    ```json
    {
        "tags": {},
        "properties": {
            "desired": {
                "telemetryDelay": "2"
            }
        }
    }
    ```

    此字段包含表示设备所需属性的初始配置的 JSON 数据。设备将使用输入的数据来设置读取传感器遥测数据并将事件发送到 IoT 中心的时间延迟。

1. 将 **“启用项”** 字段保留为 **“启用”**。

    通常需要启用新的注册项并保持启用状态。

1. 在 **“添加注册”** 边栏选项卡顶部，单击 **“保存”**。

#### 任务 2：查看注册并获取身份验证密钥

1. 在 **“管理注册”** 窗格上，单击 **“单个注册”** 以查看单个设备注册列表。

    回忆一下，你将使用注册记录来获取身份验证密钥。

1. 在 **“设备 ID”** 下，单击 **“sensor-thl-1000”**。

    通过此边栏选项卡，可查看刚才创建的单个注册的注册详细信息。

1. 找到 **“身份验证类型”** 部分。

    你已在创建注册时将身份验证类型指定为对称密钥，因此已创建了主密钥值和辅助密钥值。请注意，每个文本框右侧都有一个按钮，你可用它来复制这些值。

1. 针对此设备注册复**制主密钥值**和**辅助密钥**值，然后将它们保存到文件中供稍后参考。

    这些是设备向 IoT 中心服务进行身份验证的身份验证密钥。

1. 找到 **“初始设备孪生状态”**，注意设备孪生所需状态的 JSON 中包含属性值设为 `"2"` 的 `telemetryDelay`。

1. 关闭名为 **sensor-thl-1000** 的单个注册边栏选项卡。

### 练习 3：配置模拟设备

在本练习中，你将配置用 C# 写入的模拟设备，并使用在上一个练习中创建的单独注册连接到 Azure IoT。还要将代码添加到模拟设备中，才能基于 Azure IoT 中心内的设备孪生来读取和更新设备配置。

在本练习中创建的模拟设备代表将要放置于运输容器/运输盒中，并用于监视运输过程中 Contoso 产品情况的 IoT 设备。从设备发送到 Azure IoT 中心的传感器遥测数据包括容器的温度、湿度、压力和纬度/经度坐标。该设备是整体资产跟踪解决方案的一部分。

> **备注：** 你的印象可能是使用你在上一实验室中创建的内容创建此模拟设备有点多余，但你在此实验室中实现的证明机制与你之前操作的大不相同。在上一个实验室中，你使用共享访问密钥进行身份验证，这种方式尽管无需进行设备预配，但也没有预配管理的优势（例如使用设备孪生），而且还要对共享密钥进行大范围分配和管理。在本实验室中，你将通过设备预配服务来预配唯一的设备。

#### 任务 1：创建模拟设备

1. 在 **dps-az220-training-{your-id}** 边栏选项卡的左侧菜单中，单击 **“概述”**。

1. 在边栏选项卡的右上区域，将鼠标指针悬停在分配到 **ID 范围** 的值上，然后单击 **“复制到剪贴板”**。

    你很快将使用该值，因此，如果无法使用剪贴板，请记下该值。务必区分大写字母“O”和数字“0”。

    **ID 范围** 类似于此值：`0ne0004E52G`

1. 打开 **Visual Studio Code**。

1. 在 **“文件”** 菜单上，单击 **“打开文件夹”**，然后导航到实验室 5 的 Starter 文件夹。

    实验室 5 的 Starter 文件夹是你在实验室 3 中设置开发环境时下载的实验室资源文件的一部分。文件夹路径为：

    * Allfiles
      * 实验室
          * 05 - DPS 中设备的单个注册
            * 入门

1. 在 **“打开文件夹”** 对话框中，单击 **“启动程序”**，然后单击 **“选择文件夹”**。
 
    ContainerDevice 文件夹是实验室 5 的 Starter 文件夹的子文件夹。它包含一个 Program.cs 文件和一个 ContainerDevice.csproj 文件。

    > **备注：** 如果 Visual Studio Code 提示你加载必需的资产，可单击 **“是”** 进行加载。
 
1. 在 **“查看”** 菜单中，单击 **“终端”**。

    验证所选的终端 shell 是 Windows 命令提示符。

1. 在终端命令提示符下，若要还原所有应用程序 NuGet 包，请输入以下命令：

    ```cmd/sh
    dotnet restore
    ```

1. 在 Visual Studio Code 的 **“资源管理器”** 窗格中，单击 **“Program.cs”**。

1. 在代码编辑器中，在 Program 类顶部附近找到 **dpsIdScope** 变量。

1. 使用从设备预配服务复制的 ID 范围更新分配至 **dpsIdScope** 的值。

    > **备注：** 如果没有可用的 ID 范围值，可以在 DPS 服务的“概述”边栏选项卡中（在 Azure 门户中）找到。

1. 找到 **registrationId** 变量，并使用 **sensor-thl-1000** 更新所分配的值

    此变量代表你在设备预配服务中创建的单个注册**的注册 ID** 值。

1. 使用保存**的主密钥值**和**辅助密钥**值更新 **individualEnrollmentPrimaryKey** 和 **individualEnrollmentSecondaryKey** 变量。

    > **备注：** 如果没有可用的这些键值，则可以按以下说明从 Azure 门户复制 -
    >
    > 打开 **“管理注册”** 边栏选项卡，单击 **“单个注册”**，然后单击 **“sensor-thl-1000”**。复制值，然后按如上所述粘贴。

#### 任务 2：添加预配代码

在此任务中，你将实现相关代码，它通过 DPS 预配设备，并创建一个可用于连接到 IoT 中心的 DeviceClient 实例。

1. 花点时间扫描 **Program.cs** 文件的内容。 

    **ContainerDevice** 应用程序的总体布局与你在实验室 4 中创建的 **CaveDevice** 应用程序类似。请注意，这两个应用程序都包含以下项：

    * 使用语句
    * 命名空间定义
      * Program 类 - 负责连接到 Azure IoT 并发送遥测
      * EnvironmentSensor 类 - 负责生成传感器数据

1. 在代码编辑器中，找到注释 `// INSERT Main method below here`。

1. 若要为模拟设备应用程序创建 **Main** 方法，请输入以下代码：

    ```csharp
    public static async Task Main(string[] args)
    {

        using (var security = new SecurityProviderSymmetricKey(registrationId,
                                                                individualEnrollmentPrimaryKey,
                                                                individualEnrollmentSecondaryKey))
        using (var transport = new ProvisioningTransportHandlerAmqp(TransportFallbackType.TcpOnly))
        {
            ProvisioningDeviceClient provClient =
                ProvisioningDeviceClient.Create(GlobalDeviceEndpoint, dpsIdScope, security, transport);

            using (deviceClient = await ProvisionDevice(provClient, security))
            {
                await deviceClient.OpenAsync().ConfigureAwait(false);

                // 在下方插入设置 OnDesiredPropertyChanged 事件处理

                // 在下方插入加载设备孪生属性

                // 开始读取和发送设备遥测
                Console.WriteLine("开始读取和发送设备遥测数据...");
                await SendDeviceToCloudMessagesAsync(deviceClient);

                await deviceClient.CloseAsync().ConfigureAwait(false);
            }
        }
    }
    ```

    虽然此应用程序中的 Main 方法与你在上一实验室中创建的 CaveDevice 应用程序的 Main 方法用途类似，但它要稍微复杂一些。在 CaveDevice 应用中，你使用设备连接字符串来直接连接到 IoT 中心，而这次你需要先预配设备（或者为了后续连接，确认设备仍处于预配状态），然后检索适当的 IoT 中心连接详细信息。

    若要连接到 DPS，你不仅需要 **dpsScopeId** 和 **GlobalDeviceEndpoint** （在变量中定义），还需要指定以下项：

    * **security** - 用于对注册进行身份验证的方法你之前配置了单个注册来使用对称密钥，因此在逻辑上首选 **SecurityProviderSymmetricKey**。如你所料，还存在支持 X.509 和 TPM 的提供程序变体。

    * **transport** - 预配的设备使用的传输协议在此实例中，选择的是 AMQP 处理程序 (ProvisioningTransportHandlerAmqp)。当然，还提供 HTTP 和 MQTT 处理程序。

    填充 **security** 和 **transport** 变量后，会创建 **ProvisioningDeviceClient** 实例。你将使用该实例来注册设备，并在 **ProvisionDevice** 方法（稍后将添加它）中创建 **DeviceClient**。

    **Main** 方法的其余部分使用设备客户端的方式与你在 **CaveDevice** 中略有不同 - 这次，你将显式打开设备连接，使应用可使用设备孪生（在下一练习中了解详细信息），然后调用 **SendDeviceToCloudMessagesAsync** 方法来开始发送遥测数据。

    **SendDeviceToCloudMessagesAsync** 方法与你在 **CaveDevice** 应用程序中创建的方法非常相似。它会创建 **EnvironmentSensor** 类的实例（这也会返回压力和位置数据），生成一条消息并发送它。请注意，延迟通过 **telemetryDelay** 变量计算得出，而不是方法循环中的固定延迟 - 其中该变量是：`await Task.Delay(telemetryDelay * 1000);`。如果时间允许，请深入了解，将此项与在之前的实验室中使用的类进行比较。

    最后，回到 **Main** 方法，此时设备客户端已关闭。

    > **信息**： 可在[此处](https://docs.microsoft.com/zh-cn/dotnet/api/microsoft.azure.devices.provisioning.client.provisioningdeviceclient?view=azure-dotnet)找到 **ProvisioningDeviceClient** 的相关文档 - 从这里，可轻松导航到其他相关类。

1. 找到 `// INSERT ProvisionDevice method below here` 注释。

1. 若要创建 **ProvisionDevice** 方法，请输入以下代码：

    ```csharp
    private static async Task<DeviceClient> ProvisionDevice(ProvisioningDeviceClient provisioningDeviceClient, SecurityProviderSymmetricKey security)
    {
        var result = await provisioningDeviceClient.RegisterAsync().ConfigureAwait(false);
        Console.WriteLine($"ProvisioningClient AssignedHub: {result.AssignedHub}; DeviceID: {result.DeviceId}");
        if (result.Status != ProvisioningRegistrationStatusType.Assigned)
        {
            throw new Exception($"DeviceRegistrationResult.Status is NOT 'Assigned'");
        }

        var auth = new DeviceAuthenticationWithRegistrySymmetricKey(
            result.DeviceId,
            security.GetPrimaryKey());

        return DeviceClient.Create(result.AssignedHub, auth, TransportType.Amqp);
    }
    ```

    如你所见，此方法会接收你之前创建的预配设备客户端和安全实例。会调用 `provisioningDeviceClient.RegisterAsync()`，这会返回 **DeviceRegistrationResult** 实例。此结果中有大量属性，其中包含 **DeviceId**、**AssignedHub** 和 **Status**。

    > **信息**： 可在[此处](https://docs.microsoft.com/zh-cn/dotnet/api/microsoft.azure.devices.provisioning.client.deviceregistrationresult?view=azure-dotnet)找到 **DeviceRegistrationResult** 属性的完整详细信息。

    该方法随后会检查确保已设置预配状态，如果*未分配*设备，则引发异常  - 其他可能的结果包括 **“未分配”**、 **“正在分配”**、 **“失败”** 和 **“已禁用”**。

    * **Program.ProvisionDevice** 方法包含用于通过 DPS 注册设备的逻辑。
    * **Program.SendDeviceToCloudMessagesAsync** 方法还将遥测数据作为设备到云的消息发送到 Azure IoT 中心。
    * **EnvironmentSensor** 类包含用于生成温度、湿度、压力、纬度和经度的模拟传感器读数的逻辑。 

1. 找到 **SendDeviceToCloudMessagesAsync** 方法。

1. 在 **SendDeviceToCloudMessagesAsync** 方法的底部，留意 `Task.Delay()` 调用。

    在创建和发送下一个遥测消息之前，`Task.Delay()` 用于“暂停” `while` 循环一段时间。 **telemetryDelay** 变量用于定义在发送下一个遥测消息之前要等待的秒数。Contoso 要求延迟时间是可配置的。  

1. 在 **Program** 类顶部附近，找到 **telemetryDelay** 变量声明。

    注意，延迟的默认值设置为 **1** 秒。下一步是集成使用设备孪生值控制延迟时间的代码。

#### 任务 3：集成设备孪生属性

若要使用设备上的设备孪生属性（来自 Azure IoT 中心），需要创建访问和应用设备孪生属性的代码。在这种情况下，需要更新模拟设备代码以读取 telemetryDelay 设备孪生所需属性，然后将该值分配给代码中相应的 **telemetryDelay** 变量。可能还需要更新设备孪生报告的属性（由 IoT 中心进行维护），以记录当前在设备上实现的延迟值。

1. 在 Visual Studio Code 编辑器中，找到 **Main** 方法。

    要开始集成设备孪生属性，需要在设备孪生属性更新时通知用于启用模拟设备的代码。

    为了实现此目的，你将使用 `DeviceClient.SetDesiredPropertyUpdateCallbackAsync` 方法，并通过创建 `OnDesiredPropertyChanged` 方法来设置事件处理程序。

1. 找到 `// INSERT Setup OnDesiredPropertyChanged Event Handling below here` 注释。

1. 要为 OnDesiredPropertyChanged 事件设置 DeviceClient，请输入以下代码：

    ```csharp
    await deviceClient.SetDesiredPropertyUpdateCallbackAsync(OnDesiredPropertyChanged, null).ConfigureAwait(false);
    ```

    **SetDesiredPropertyUpdateCallbackAsync** 方法用于设置 **DesiredPropertyUpdateCallback** 事件处理程序来接收设备孪生所需的属性更改。当接收到设备孪生属性更改事件时，此代码将 **deviceClient** 配置为调用名为 **OnDesiredPropertyChanged** 的方法。

    现在已经有了 **SetDesiredPropertyUpdateCallbackAsync** 方法来设置事件处理程序，你需要创建它调用的 **OnDesiredPropertyChanged** 方法。

1. 找到 `// INSERT OnDesiredPropertyChanged method below here` 注释。

1. 若要创建 **OnDesiredPropertyChanged** 方法，请输入以下代码：

    ```csharp
    private static async Task OnDesiredPropertyChanged(TwinCollection desiredProperties, object userContext)
    {
        Console.WriteLine("Desired Twin Property Changed:");
        Console.WriteLine($"{desiredProperties.ToJson()}");

        // 读取所需孪生属性
        if (desiredProperties.Contains("telemetryDelay"))
        {
            string desiredTelemetryDelay = desiredProperties["telemetryDelay"];
            if (desiredTelemetryDelay != null)
            {
                telemetryDelay = int.Parse(desiredTelemetryDelay);
            }
            // 如果所需 TelemetryDelay 为 null 或未指定，请勿更改
        }

        // 报告孪生属性
        var reportedProperties = new TwinCollection();
        reportedProperties["telemetryDelay"] = telemetryDelay.ToString();
        await deviceClient.UpdateReportedPropertiesAsync(reportedProperties).ConfigureAwait(false);
        Console.WriteLine("Reported Twin Properties:");
        Console.WriteLine($"{reportedProperties.ToJson()}");
    }
    ```

    注意，**OnDesiredPropertyChanged** 事件处理程序接受类型为 **TwinCollection** 的 **desiredProperties** 参数。

    注意，如果 **desiredProperties** 参数的值包含 **telemetryDelay** （设备孪生所需属性），则代码会将设备孪生属性的值分配给 **telemetryDelay** 变量。你可能还记得，**SendDeviceToCloudMessagesAsync** 方法包括一个 **Task.Delay** 调用，它使用 **telemetryDelay** 变量来设置发送到 IoT 中心的消息之间的延迟时间。

    请注意，下一个代码块用于将设备的当前状态报告回 Azure IoT 中心。此代码会调用 **DeviceClient.UpdateReportedPropertiesAsync** 方法并将其传递给 **TwinCollection**，其中包含设备属性的当前状态。这是设备向 IoT 中心报告的方式，它已收到设备孪生期望属性更改事件，并且现在已相应更新其配置。请注意，它报告的是现在设置的属性，而不是所需属性的回显。如果从设备发送的报告属性不同于设备接收到的所需状态，则 IoT 中心将保持反映设备状态的准确设备孪生。

    既然设备可以从 Azure IoT 中心接收对设备孪生所需属性的更新，则还需要对其进行编码以在设备启动时配置其初始设置。为此，设备将需要从 Azure IoT 中心加载当前设备孪生所需属性，并进行相应的配置。

1. 在 **Main** 方法中，找到 `// INSERT Load Device Twin Properties below here` 注释。

1. 要读取设备孪生所需属性，并配置设备使其在设备启动时匹配，请输入以下代码：

    ```csharp
    var twin = await deviceClient.GetTwinAsync().ConfigureAwait(false);
    await OnDesiredPropertyChanged(twin.Properties.Desired, null);
    ```

    此代码调用 `DeviceTwin.GetTwinAsync` 方法来为模拟设备检索设备孪生。然后，它会访问 `Properties.Desired` 属性对象以检索设备的当前所需状态，并将其传递给用于配置模拟设备的 **telemetryDelay** 变量的 **OnDesiredPropertyChanged** 方法。

    请注意，此代码会重复使用已创建用于处理 **OnDesiredPropertyChanged**__ 事件的 OnDesiredPropertyChanged 方法。这有助于将读取设备孪生所需状态属性和在启动时配置该设备的代码保存在单一位置中。生成的代码更简单，更易于维护。

1. 在 Visual Studio Code 的 **“文件”** 菜单上，单击 **“保存”**。

    模拟设备当前将使用 Azure IoT 中心的设备孪生属性来设置遥测消息之间的延迟。

### 练习 4：测试模拟设备

在本练习中，你将运行模拟设备并验证其是否在向 Azure IoT 中心发送传感器遥测。你还将通过更新 Azure IoT 中心内部模拟设备的 telemetryDelay 设备孪生属性，更改将遥测数据发送到 Azure IoT 中心的速率。

#### 任务 1：生成并运行设备

1. 确保在 Visual Studio Code 中打开了代码项目。

1. 在 **“查看”** 菜单中，单击 **“终端”**。

1. 在“终端”窗格中，确保命令提示符会显示 `Program.cs` 文件的目录路径。

1. 在命令提示符处，要生成并运行模拟设备应用程序，请输入以下命令：

    ```cmd/sh
    dotnet run
    ```

    > **备注：** 模拟设备应用程序运行时，会首先将自身的详细状态信息写入控制台（终端窗格）。

1. 请注意，`Desired Twin Property Changed:` 行之后的 JSON 输出包含设备的 `telemetryDelay` 所需的值。

    可以在终端窗格中向上滚动查看输出。输出应类似于以下内容：

    ```text
    ProvisioningClient AssignedHub: iot-az220-training-{your-id}.azure-devices.net; DeviceID: sensor-thl-1000
    Desired Twin Property Changed:
    {"telemetryDelay":"2","$version":1}
    Reported Twin Properties:
    {"telemetryDelay":"2"}
    Start reading and sending device telemetry...
    ```

1. 请注意，模拟设备应用程序开始向 Azure IoT 中心发送遥测事件。

    遥测事件包括 `temperature`、`humidity`、`pressure`、`latitude` 和 `longitude` 值，并且应当类似于：

    ```text
    11/6/2019 6:38:55 PM > Sending message: {"temperature":25.59094770373355,"humidity":71.17629229611545,"pressure":1019.9274696347665,"latitude":39.82133964767944,"longitude":-98.18181981142438}
    11/6/2019 6:38:57 PM > Sending message: {"temperature":24.68789062681044,"humidity":71.52098010830628,"pressure":1022.6521258267584,"latitude":40.05846882452387,"longitude":-98.08765031156229}
    11/6/2019 6:38:59 PM > Sending message: {"temperature":28.087463226675737,"humidity":74.76071353757787,"pressure":1017.614206096327,"latitude":40.269273772972454,"longitude":-98.28354453319591}
    11/6/2019 6:39:01 PM > Sending message: {"temperature":23.575667940813894,"humidity":77.66409506912534,"pressure":1017.0118147748344,"latitude":40.21020096551372,"longitude":-98.48636739129239}
    ```

    注意遥测读数之间的时间戳差异。通过设备孪生配置的遥测消息之间的延迟应为 `2` 秒，而不是源代码中默认的 `1` 秒。

1. 保持模拟设备应用运行。

    你将在下一个活动中验证设备代码是否符合预期。

#### 任务 2：验证发送到 Azure IoT 中心的遥测数据流

在此任务中，你将使用 Azure CLI 验证 Azure IoT 中心正在接收由模拟设备发送的遥测。

1. 使用浏览器，打开 [Azure Cloud Shell](https://shell.azure.com/)，并使用本课程使用的 Azure 订阅登录。

1. 在 Azure Cloud Shell 中，输入以下命令：

    ```cmd/sh
    az iot hub monitor-events --hub-name {IoTHubName} --device-id sensor-thl-1000
    ```

    _请务必将 **“{IoTHubName}”** 占位符替换为 Azure IoT 中心的名称。_

1. 请注意，IoT 中心将从 sensor-thl-1000 设备接收遥测消息。

    继续让模拟设备应用程序运行以执行下一个任务。

#### 任务 3：通过孪生更改设备配置

在运行模拟设备的情况下，可以通过在 Azure IoT 中心内编辑设备孪生所需状态来更新 `telemetryDelay` 配置。这可以通过在 Azure 门户的 Azure IoT 中心中配置设备来完成。

1. 打开 Azure 门户（如果尚未打开），然后导航到 **Azure IoT 中心** 服务。

1. 在“IoT 中心”边栏选项卡上，在左侧菜单中的 **“资源管理器”** 下，单击 **“IoT 设备”**。

1. 在 **“设备 ID”** 下，单击 **“sensor-thl-1000”**。

    > **重要说明**： 确保为此实验室选择正在使用的设备。

1. 在 **sensor-thl-1000** 设备边栏选项卡的顶部单击 **“设备孪生”**。

    **“设备孪生”** 边栏选项卡为编辑器提供了设备孪生的完整 JSON。这使你能够直接在 Azure 门户中查看和/或编辑设备孪生状态。

1. 找到 `properties.desired` 对象的 JSON。

    这包含设备所需的状态。请注意，`telemetryDelay` 属性已经存在并设为 `"2"`，因为在基于 DPS 中的单个注册来预配设备时已配置该属性。

1. 要更新分配给 `telemetryDelay` 所需属性的值，请将该值更改为 `"5"`

    该值包括引号 ("")。

1. 在 **“设备孪生”** 边栏选项卡的顶部，单击 **“保存”**

    `OnDesiredPropertyChanged` 事件将在模拟设备的代码内自动触发，并且设备将更新其配置来体现设备孪生所需状态的更改。

1. 切换到用于运行模拟设备应用程序的 Visual Studio Code 窗口。

1. 在 Visual Studio Code 中，滚动到“终端”窗格的底部。

1. 请注意，设备可以识别设备孪生属性的更改。

    输出将显示一条消息：`Desired Twin Property Changed` 以及新 `telemetryDelay` 所需属性值的 JSON。设备选取设备孪生所需状态的新配置后，将自动更新，开始按当前配置每 5 秒钟发送一次传感器遥测。

    ```text
    Desired Twin Property Changed:
    {"telemetryDelay":"5","$version":2}
    Reported Twin Properties:
    {"telemetryDelay":"5"}
    4/21/2020 1:20:16 PM > Sending message: {"temperature":34.417625961088405,"humidity":74.12403526442313,"pressure":1023.7792049974805,"latitude":40.172799921919186,"longitude":-98.28591913777421}
    4/21/2020 1:20:22 PM > Sending message: {"temperature":20.963297521678403,"humidity":68.36916032636965,"pressure":1023.7596862048422,"latitude":39.83252821949164,"longitude":-98.31669969393461}
    ```

1. 切换到在 Azure Cloud Shell 中运行 Azure CLI 命令的浏览器页面。

    确保你仍在运行 `az iot hub monitor-events` 命令。如果该命令未在运行，请重新启动它。

1. 请注意，发送到 Azure IoT 中心的遥测事件正以 5 秒的新间隔接收。

1. 使用 **Ctrl-C** 停止 `az` 命令和“模拟设备”应用程序。

1. 切换到 Azure 门户的浏览器窗口。

1. 关闭 **“设备孪生”** 边栏选项卡。

1. 还是在 Azure 门户中，在 **sensor-thl-1000** 边栏选项卡上，单击 **“设备孪生”**。

1. 找到 `properties.reported` 对象的 JSON。

    这部分的 JSON 包含设备报告的状态。注意，`telemetryDelay` 属性也存在于此，并且也设置为 `5`。  还有一个 `$metadata` 值，显示所报告数据的上次更新时间以及所报告特定值的上次更新时间。

1. 关闭 **“设备孪生”** 边栏选项卡。

1. 关闭“模拟设备”边栏选项卡，然后关闭“IoT 中心”边栏选项卡。

### 练习 5：解除预配设备

在你的 Contoso 场景中，当运输容器抵达其最终目的地时，将从容器上取下 IoT 设备并寄回 Contoso 所在地。Contoso 将需要解除设备预配，然后才可测试并将其放入库存。在将来，该设备可预配至同一 IoT 中心，也可预配在不同区域的 IoT 中心。彻底解除设备预配是 IoT 解决方案中 IoT 设备生命周期中的重要一步。

在此练习中，你将执行从设备预配服务 (DPS) 和 Azure IoT 中心解除设备预配所需的任务。要从 Azure IoT 解决方案中完全解除 IoT 设备预配，必须将其从这两项服务中删除。 

#### 任务 1：从 DPS 取消注册设备

1. 如有必要，请使用 Azure 帐户凭据登录到 Azure 门户。

    如果有多个 Azure 帐户，请确保使用与本课程要使用的订阅绑定的帐户登录。

1. 在“资源组”磁贴上，若要打开设备预配服务，请单击 **“dps-az220-training-{your-id}”**。

1. 在左侧菜单 **“设置”** 下，单击 **“管理注册”**。

1. 在 **“管理注册”** 窗格上，单击 **“单个注册”** 以查看单个设备注册列表。

1. 单击 **sensor-thl-1000** 左侧的复选框。

    > **备注：** 无需打开 sensor-thl-1000 单个设备注册，只需选择它即可。

1. 在边栏选项卡顶部，单击 **“删除”**。

    > **备注：** 删除 DPS 中的单个注册将永久删除该注册。要暂时禁用注册，可以在单个注册的 **“注册详细信息”** 中将 **“启用项”** 设置为 **“禁用”**。

1. 在 **“删除注册”** 提示符处，单击 **“是”**。

    单个注册当前已从设备预配服务 (DPS) 中删除。要完成解除预配过程，还必须从 **Azure IoT 中心** 服务中删除模拟设备的**设备 ID**。

#### 任务 2：从 IoT 中心撤销设备登记

1. 在 Azure 门户中，导航回仪表板。

1. 在“资源组”磁贴上，若要打开 **“Azure IoT 中心”边栏选项卡，请单击“iot-az220-training-{your-id}”**。

1. 在左侧菜单的 **“资源管理器”** 下，单击 **“IoT 设备”**。

1. 单击 **sensor-thl-1000** 左侧的复选框。

    > **重要说明**： 确保所选设备能够代表用于本实验室的模拟设备。

1. 在边栏选项卡顶部，单击 **“删除”**。

1. 在 **“确定要删除选定设备吗”** 提示符处，单击 **“是”**。

    > **备注：** 从 IoT 中心删除设备 ID 将永久删除设备注册。要暂时禁止设备连接到 IoT 中心，可以在设备属性中将 **“启用与 IoT 中心的连接”** 设为 **“禁用”**。

既然设备注册已从设备预配服务中删除，与之匹配的设备 ID 也已从 Azure IoT 中心中删除，模拟设备在解决方案中就完全停用了。
