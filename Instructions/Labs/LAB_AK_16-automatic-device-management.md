---
lab:
  title: 实验室 16：使用 Azure IoT 中心自动化 IoT 设备管理
  module: 'Module 8: Device Management'
ms.openlocfilehash: 3b752cc477c664f1c44b754c49b2e20542de1f72
ms.sourcegitcommit: eec2943250f1cd1ad2c5202ecbb9c37af71e8961
ms.translationtype: HT
ms.contentlocale: zh-CN
ms.lasthandoff: 03/24/2022
ms.locfileid: "140872823"
---
# <a name="automate-iot-device-management-with-azure-iot-hub"></a>使用 Azure IoT 中心自动化 IoT 设备管理

IoT 设备通常使用优化的操作系统，甚至直接在芯片上运行代码（无需实际操作系统）。 为了更新在此类设备上运行的软件，最常用的方法是刷写全套新版软件包，包括 OS 以及在 OS 上运行的应用（称为“固件”）。

由于每个设备都有特定用途，因此其固件也非常具体，并针对设备用途以及可用受限资源进行了优化。

固件更新过程也可特定于硬件以及硬件制造商的制板方式。 这意味着部分固件更新过程不通用，你需要联系设备制造商以获取固件更新过程的详细信息（除非你正自行开发硬件，这意味着你很可能知道固件更新过程的详细信息） 。

尽管过去通常将固件更新手动应用于单个设备，但考虑到典型 IoT 解决方案中所使用的设备数量，这种做法不再适用。 现在，更为常见的做法是通过无线 (OTA) 方式，从云端远程管理新固件的部署来完成固件更新。

以下是 IoT 设备的所有无线固件更新的常见共同特征：

1. 固件版本使用唯一标识
1. 固件采用二进制文件格式，设备需从联机源获取固件
1. 固件是存储在本地的某种物理存储形式（ROM 存储器、硬盘驱动器...）
1. 设备制造商提供了更新固件所需设备操作的描述。

Azure IoT 中心提供高级支持，用于在单个设备和设备集合上实现设备管理操作。 [自动设备管理](https://docs.microsoft.com/azure/iot-hub/iot-hub-auto-device-config)功能使你可以方便地配置和触发一组操作，然后监视其进度。

## <a name="lab-scenario"></a>实验室场景

你在 Contoso 的奶酪储藏室中实现的自动化空气处理系统帮助该公司在原本的高标准基础上进一步提高了质量标准。 该公司因此产出了更多优质奶酪。

你的基本解决方案包括与传感器和气候控制系统集成的 IoT 设备，以对多室储藏室系统中的温度和湿度进行实时控制。 你还开发了一个简单的后端应用，用来演示使用直接方法和设备孪生属性管理设备的能力。

Contoso 对你的初始解决方案中的简单后端应用进行了扩展，以包含一个操作员可用来监视和远程管理储藏室环境的在线门户。 借助新门户，操作员甚至可以根据奶酪类型或奶酪老化过程中的特定阶段自定义储藏室内的温度和湿度。 储藏室内的每个房间或区域都可以单独控制。

IT 部门将维护他们为操作员开发的后端门户，而你的经理已同意管理该解决方案的设备端。

对你来说，这意味着两件事：

1. Contoso 运营团队一直在寻找改进方法。 通常，这些改进意味着为设备软件开发更多新功能的请求。

1. 部署到储藏室位置的 IoT 设备需要最新的安全补丁，以确保隐私并防止黑客控制系统。 为了维护系统安全性，你需要通过远程更新固件来使设备保持最新状态。

你计划实现 IoT 中心功能，以便能够实现自动设备管理和大规模设备管理。

将创建以下资源：

![实验室 16 基础结构](media/LAB_AK_16-architecture.png)

## <a name="in-this-lab"></a>本实验室概览

在本实验室中，你将完成以下活动：

* 配置实验室先决条件（所需的 Azure 资源）
* 为实现固件更新的模拟设备写入代码
* 使用 Azure IoT 中心自动设备管理在单个设备上测试固件更新过程

## <a name="lab-instructions"></a>实验室说明

### <a name="exercise-1-configure-lab-prerequisites"></a>练习 1：配置实验室先决条件

本实验室假定以下 Azure 资源可用：

| 资源类型 | 资源名称 |
| :-- | :-- |
| 资源组 | rg-az220 |
| IoT 中心 | iot-az220-training-{your-id} |
| IoT 设备 | sensor-th-0155 |

若要确保这些资源可用，请完成以下步骤。

1. 在虚拟机环境中，打开 Microsoft Edge 浏览器窗口，然后导航到以下 Web 地址：
 
    +++https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FMicrosoftLearning%2FAZ-220-Microsoft-Azure-IoT-Developer%2Fmaster%2FAllfiles%2FARM%2Flab16.json+++

    > 注意：每当看到绿色的“T”符号（例如 +++输入此文本+++）时，可以单击关联的文本，信息将键入到虚拟机环境内的当前字段中。

1. 如果系统提示登录到 Azure 门户，请输入你在本课程中使用的 Azure 凭据。

    将显示“自定义部署”页。

1. 在“项目详细信息”下的“订阅”下拉列表中，确保你打算在本课程中使用的 Azure 订阅已选中 。

1. 在“资源组”下拉列表中，选择“rg-az220” 。

    > 注意：如果未列出 rg-az220：
    >
    > 1. 在“资源组”下拉列表中，选择“新建”。
    > 1. 在“名称”下，输入 rg-az220 。
    > 1. 单击“确定”  。

1. 在“实例详细信息”下的“区域”下拉列表中，选择离你最近的区域 。

    > 注意：如果 rg-az220 组已存在，则“区域”字段将设置为资源组使用的区域，并且为只读 。

1. 在“你的 ID”字段中，输入在练习 1 中创建的唯一 ID。

1. 在“课程 ID”字段中，输入 az220 。

1. 若要验证模板，请单击“查看和创建”。

1. 验证通过后，单击“创建”。

    将启动部署。

1. 部署完成后，在左侧导航区域中，若要查看模板的任何输出值，请单击“输出”。

    记下输出供稍后使用：

    * connectionString
    * deviceConnectionString
    * devicePrimaryKey

现已创建资源。

### <a name="exercise-2-examine-code-for-a-simulated-device-that-implements-firmware-update"></a>练习 2：检查实现固件更新的模拟设备的代码

在本练习中，你将查看一个负责管理设备孪生所需属性更改的简单模拟器，还将触发一个模拟固件更新的本地过程。 这一要实现的用于启动固件更新的过程与在实际设备上用于启动固件更新的过程相似。 这一下载新固件版本、安装固件更新和重新启动设备的过程是模拟的过程。

你将通过 Azure 门户，使用设备孪生属性配置和执行固件更新。 你将配置设备孪生属性，以便将配置更改请求传输到设备并监视进度。

#### <a name="task-1-examine-the-device-simulator-app"></a>任务 1：检查设备模拟器应用

在此任务中，你将使用 Visual Studio Code 查看控制台应用。

1. 打开 **Visual Studio Code**。

1. 在“文件”菜单上，单击“打开文件夹”

1. 在“打开文件夹”对话框中，导航到实验室 16 的 Starter 文件夹。

    在“实验室 3:设置开发环境”中，你可以通过下载 ZIP 文件并从本地提取内容来克隆包含实验室资源的 GitHub 存储库。 提取的文件夹结构包括以下文件夹路径：

    * Allfiles
      * 实验室
          * 16-使用 Azure IoT 中心实现自动化 IoT 设备管理
            * 初学者
              * FWUpdateDevice

1. 单击“FWUpdateDevice”，然后单击“选择文件夹” 。

    你应该会在 Visual Studio Code 的资源管理器窗格中看到以下文件：

    * FWUpdateDevice.csproj
    * Program.cs

1. 在“资源管理器”窗格中，单击“FWUpdateDevice.csproj”文件以打开该文件，并注意引用的 NuGet 包 ：

    * Microsoft.Azure.Devices.Client - 适用于 Azure IoT 中心的设备 SDK
    * Microsoft.Azure.Devices.Shared - 适用于 Azure IoT 设备和服务 SDK 的常用代码
    * Newtonsoft.Json - Json.NET 是适用于 .NET 的常用高性能 JSON 框架

1. 在“资源管理器”窗格中，单击“Program.cs”。

#### <a name="task-2-review-the-application-code"></a>任务 2：查看应用程序代码

在此任务中，你将查看用于在设备上模拟固件更新的代码，以响应 IoT 中心生成的请求。

1. 确保 **Program.cs** 文件在 Visual Studio Code 中处于打开状态。

1. 找到 `Global Variables` 注释。

    在此简单示例中，将跟踪设备连接字符串、设备 ID 和当前固件版本。

1. 在代码编辑器中，找到以下代码行：

    ```csharp
    private readonly static string deviceConnectionString = "<your device connection string>";
    ```

1. 将 \<your device connection string\> 替换为之前保存的设备连接字符串。

    这是唯一需要更改的代码。

1. 找到 Main 方法。

    此方法类似于前面使用的设备模拟器 - 使用 deviceConnectionString 创建连接到 IoT 中心等的 DeviceClient 实例，并配置设备孪生属性更改回调 。

    InitDevice 方法是新方法，仅模拟设备的启动周期，并通过 UpdateFWUpdateStatus 方法更新设备孪生来报告当前固件 。

    然后，应用会循环，等待将触发固件更新的设备孪生更新。

1. 查找 UpdateFWUpdateStatus 方法并查看代码：

    This method creates a new **TwinCollection** instance, populates it with the provided values, and then updates the device twin.

1. 查找 OnDesiredPropertyChanged 方法并查看代码：

    当设备接收到设备孪生更新时，此方法作为回调调用。 如果检测到固件更新，则调用 UpdateFirmware 方法。 此方法模拟固件的下载，更新固件，然后重启设备。

### <a name="exercise-3-test-firmware-update-on-a-single-device"></a>练习 3：测试单个设备上的固件更新

在本练习中，将使用 Azure 门户新建设备管理配置，并将其应用于单个模拟设备。

#### <a name="task-1-start-device-simulator"></a>任务 1：启动设备模拟器

1. 如有必要，请在 Visual Studio Code 中打开 FWUpdateDevice 项目。

1. 确保已打开“终端”窗格。

    命令提示符的文件夹位置为 `FWUpdateDevice` 文件夹。

1. 要运行 `FWUpdateDevice` 应用，请输入以下命令：

    ``` bash
    dotnet run "<device connection string>"
    ```

    > **注意**：记得将占位符替换为实际的设备连接字符串，并确保将连接字符串置于英文双引号 "" 中间。
    >
    > 例如：`"HostName=iot-az220-training-{your-id}.azure-devices.net;DeviceId=sensor-th-0155;SharedAccessKey={}="`

1. 查看“终端”窗格的内容。

    终端中应会显示以下输出：

    ``` bash
        sensor-th-0155: Device booted
        sensor-th-0155: Current firmware version: 1.0.0
    ```

#### <a name="task-2-create-the-device-management-configuration"></a>任务 2：创建设备管理配置

1. 如有必要，请使用 Azure 帐户凭据登录到 [Azure 门户](https://portal.azure.com/learn.docs.microsoft.com?azure-portal=true)。

    如果有多个 Azure 帐户，请确保使用与本课程要使用的订阅绑定的帐户登录。

1. 在 Azure 门户仪表板上，单击“iot-az220-training-{your-id}”。

    现在应显示 IoT 中心边栏选项卡。

1. 在左侧导航菜单的“设备管理”下，单击“配置” 。

1. 在“IoT 设备配置”窗格中，单击“+添加设备配置”。

1. 在“创建设备孪生配置”边栏选项卡的“名称”下，输入“firmwareupdate”

    确保你在配置的必填字段“名称”处，而不是在“标签”处输入“`firmwareupdate`” 。

1. 在边栏选项卡底部，单击“下一步:孪生设置 >”。

1. 在“设备孪生设置”下的“设备孪生属性”字段中，输入“properties.desired.firmware”

1. 在“设备孪生属性内容”字段中，输入以下内容：

    ``` json
    {
        "fwVersion":"1.0.1",
        "fwPackageURI":"https://MyPackage.uri",
        "fwPackageCheckValue":"1234"
    }
    ```

1. 在边栏选项卡底部，单击“下一步:指标 >”。

    你将使用自定义指标来跟踪固件更新是否有效。

1. 在“指标”选项卡的“指标名称”下，输入“fwupdated”

1. 在“指标条件”下，输入以下内容：

    ``` SQL
    SELECT deviceId FROM devices
        WHERE properties.reported.firmware.currentFwVersion='1.0.1'
    ```

1. 在边栏选项卡底部，单击“下一步:目标设备 >”。

1. 在“目标设备”选项卡上的“优先级”下的“优先级（更高的值 ...）”字段中，输入“10”。

1. 在“目标条件”的“目标条件”字段中，输入以下查询：

    ``` SQL
    deviceId='<your device id>'
    ```

    > **注意**：请务必将 `'<your device id>'` 替换为你用来创建设备的设备 ID。 例如：`'sensor-th-0155'`

1. 在边栏选项卡底部，单击“下一步:审阅并创建 >”

    在“查看 + 创建”选项卡打开后，你应该会看到新配置“已通过验证”的消息。

1. 在“查看 + 创建”选项卡上，如果显示“通过验证”消息，请单击“创建”。

    如果显示“通过验证”消息，则需要先返回并检查工作，然后才能创建配置。

1. 在“IoT 设备配置”窗格上的“配置名称”下，确认已列出新“firmwareupdate”配置。

    创建新配置后，IoT 中心将查找与配置的目标设备标准匹配的设备，并将自动应用固件更新配置。

1. 切换到 Visual Studio Code 窗口，然后查看“终端”窗格的内容。

    “终端”窗格应包括你的应用生成的新输出，其中列出了触发的固件更新过程的进度。

1. 停止模拟应用，然后关闭 Visual Studio Code。

    你只需按下终端中的 Enter 键即可停止设备模拟器。
