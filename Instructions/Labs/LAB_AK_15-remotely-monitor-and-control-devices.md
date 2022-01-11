---
lab:
    title: '实验室 15：使用 Azure IoT 中心远程监视和控制设备'
    module: '模块 8：设备管理'
---

# 使用 Azure IoT 中心远程监视和控制设备

## 实验室场景

Contoso 为其屡获殊荣的奶酪产品感到自豪，并在整个制造过程中都保持最佳的温度和湿度，但老化过程中的条件始终受到特别关注。

近年来，Contoso 使用环境传感器来记录其天然奶酪储藏室中发生老化的条件，并使用该数据来识别接近完美的环境。来自最成功（也称为获奖产品）位置的数据表明，老化奶酪的理想温度约为 50 华氏度 +/- 5 度（10 摄氏度 +/- 2.8 度）。以最大饱和度的百分比衡量的理想湿度值约为 85% +/- 10%。

这些理想的温度和湿度值适用于大多数类型的奶酪。但是，对于特别坚硬或特别软的奶酪，需要做出较小的调整。还必须在老化过程中的关键时间/阶段调整环境条件，以实现特定的结果，例如奶酪皮的理想条件。

Contoso 非常幸运，可以经营奶酪储藏室（在某些地理区域内），这些奶酪储藏室几乎全年都可以自然保持理想的条件。但是，即使在这些位置，老化过程中的环境管理也至关重要。同样，天然储藏室通常具有许多不同的洞室，每个洞室的环境可能略有不同。各种奶酪放置在符合其特定要求的洞室（区域）中。为了将环境条件保持在期望的限制内，Contoso 使用了同时控制温度和湿度的空气处理/调节系统。

当前，操作员监视储藏室设施每个区域内的环境条件，并在需要保持所需温度和湿度时调整空气处理系统设置。操作员能够每隔 4 小时访问每个区域并检查环境条件。在白天高温和夜间低温之间温度急剧变化的地方，条件可能会超出所需的限制。

Contoso 已责成你实现自动化系统，以使储藏室环境保持在控制范围内。

在本实验室中，你将为实现  IoT 设备的奶酪储藏室监控系统进行原型设计。每个设备都配备了温度和湿度传感器，并连接到空气处理系统，该系统控制设备所在区域的温度和湿度。

### 简化的实验室条件

遥测输出的频率是生产解决方案中的重要考虑因素。制冷单元中的温度传感器可能只需要每分钟报告一次，而飞机上的加速度传感器可能需要每秒报告十次。在某些情况下，必须发送遥测的频率取决于当前条件。例如，如果我们的奶酪储藏室环境温度总是在夜间快速下降，日落前两小时会开始更频繁地进行传感器读数。当然，更改遥测频率的要求不需要是可预测模式的一部分，让我们更改 IoT 设备设置的事件可能是不可预测的。

为了保持在本实验室的简单易行，我们将做出以下假设：

* 设备将每隔几秒向 IoT 中心发送遥测数据（温度和湿度值）。虽然这种频率对于奶酪储藏室来说是不现实的，但当我们需要经常看到变化时，而不是每 15 分钟一次，它对于实验室环境来说非常重要。
* 空气处理系统是一个风扇，可以处于以下三种状态之一：开、关或失败。
  * 风扇初始化为“关闭”状态。
  * 使用 IoT 设备上的直接方法来控制（打开/关闭）风扇的电源。
  * 设备孪生所需属性值用于设置风扇的所需状态。所需属性值将覆盖风扇/设备的任何默认设置。
  * 可以通过打开/关闭风扇来控制温度（打开风扇会降低温度）

本实验中的编码分为三个部分：发送和接收遥测，调用和运行直接方法，设置和读取设备孪生属性。

你将首先编写两个应用：一个用于发送遥测的设备，另一个用于后端服务（将在云中运行）以接收遥测。

将创建以下资源：

![实验室 15 基础结构](media/LAB_AK_15-architecture.png)

## 本实验室概览

在本实验室中，你将完成以下活动：

* 验证是否满足实验室先决条件（具有必需的 Azure 资源）

    * 该脚本将创建 IoT 中心（如果需要）。
    * 该脚本将创建本实验室所需的新设备标识。

* 创建模拟设备应用以将设备遥测发送到 IoT 中心
* 创建后端服务应用以侦听遥测数据
* 实现直接方法，以将设置传达给 IoT 设备
* 实现设备孪生功能，以管理 IoT 设备属性

## 实验室说明

### 练习 1：验证实验室先决条件

本实验室假定以下 Azure 资源可用：

| 资源类型 | 资源名称 |
| :-- | :-- |
| 资源组 | rg-az220 |
| IoT 中心 | iot-az220-training-{your-id} |
| IoT 设备 | sensor-th-0055 |

> **重要说明**： 运行设置脚本以创建所需设备。

若要创建任何缺少的资源和新设备，在开始练习 2 之前，需要先按照下面的说明运行 **lab15-setup.azcli** 脚本。脚本文件包含在本地克隆作为开发环境配置（实验室 3）的 GitHub 存储库中。

写入 **lab15-setup.azcli** 脚本，并在 **Bash** shell 环境中运行，执行此操作最简便的方法是在 Azure Cloud Shell 中。

>**备注：** 你将需要 **“sensor-th-0055”** 设备的连接字符串。如果你已经在 Azure IoT 中心注册了此设备，则可以通过在 Azure Cloud Shell 中运行以下命令来获取连接字符串
>
> ```bash
> az iot hub device-identity connection-string show --hub-name iot-az220-training-{your-id} --device-id sensor-th-0055 -o tsv
> ```

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
          * 15-使用 Azure IoT 中心远程监视和控制设备
            * 设置

    lab15-setup.azcli 脚本文件位于实验室 15 的 Setup 文件夹中。

1. 选择 **“lab15-setup.azcli”** 文件，然后单击 **“打开”**。

    文件上传完成后，系统将显示一条通知。

1. 若要验证在 Azure Cloud Shell 中已上传了正确文件，请输入以下命令：

    ```bash
    ls
    ```

    使用 `ls` 命令列出当前目录的内容。你应该会看到列出的 lab15-setup.azcli 文件。

1. 若要为此实验室创建一个包含安装脚本的目录，然后移至该目录，请输入以下 Bash 命令：

    ```bash
    mkdir lab15
    mv lab15-setup.azcli lab15
    cd lab15
    ```

1. 为了保证 **lab15-setup.azcli** 具有执行权限，请输入以下命令：

    ```bash
    chmod +x lab15-setup.azcli
    ```

1. 在 Cloud Shell 工具栏上，请单击 **“打开编辑器”** （右侧的第二个按钮 - **{ }**）以启用对 lab15-setup.azcli 文件的访问。

1. 在 **“文件存储”** 列表中，展开 lab15 文件夹并打开脚本文件，单击 **“lab15”**，然后单击 **“lab15-setup.azcli”**。

    编辑器现在将显示 **lab15-setup.azcli** 文件的内容。

1. 在编辑器中，更新 `{your-id}` 和 `{your-location}` 分配的值。

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

    > **备注：** 可以使用 **Ctrl+S** 随时保存，使用 **Ctrl+Q** 关闭编辑器。

1. 要创建本实验室所需的资源，请输入以下命令：

    ```bash
    ./lab15-setup.azcli
    ```

    运行此脚本可能需要几分钟。每个步骤完成时，你都会看到输出。

    该脚本将首先创建一个名为 **rg-az220** 的资源组和一个名为 **iot-az220-training-{your-id}** 的 IoT 中心。如果它们已经存在，将显示相应的消息。然后，脚本会将 ID 为 **“sensor-th-0055”** 的设备添加到 IoT 中心并显示设备连接字符串。

1. 请注意，脚本完成后，将显示与你的 IoT 中心和设备有关的信息。

    脚本将显示类似于以下内容的信息：

    ```text
    Configuration Data:
    ------------------------------------------------
    iot-az220-training-{your-id} Service connectionstring:
    HostName=iot-az220-training-{your-id}.azure-devices.net;SharedAccessKeyName=iothubowner;SharedAccessKey=nV9WdF3Xk0jYY2Da/pz2i63/3lSeu9tkW831J4aKV2o=

    sensor-th-0055 device connection string:
    HostName=iot-az220-training-{your-id}.azure-devices.net;DeviceId=sensor-th-0055;SharedAccessKey=TzAzgTYbEkLW4nWo51jtgvlKK7CUaAV+YBrc0qj9rD8=

    iot-az220-training-{your-id} eventhub endpoint:
    sb://iothub-ns-iot-az220-training-2610348-5a463f1b56.servicebus.windows.net/

    iot-az220-training-{your-id} eventhub path:
    iot-az220-training-{your-id}

    iot-az220-training-{your-id} eventhub SaS primarykey:
    tGEwDqI+kWoZroH6lKuIFOI7XqyetQHf7xmoSf1t+zQ=
    ```

1. 将脚本显示的输出复制到文本文档中，以供本实验室稍后使用。

    将信息保存到可以轻松找到的位置后，就可以继续进行本实验。

### 练习 2：写入发送和接收遥测的代码

在本练习中，你将创建模拟设备应用（适用于 sensor-th-0055 设备），该应用将遥测发送到 IoT 中心。

#### 任务 1：打开生成遥测的模拟设备

1. 打开 **Visual Studio Code**。

1. 在 **“文件”** 菜单上，单击 **“打开文件夹”**

1. 在“打开文件夹”对话框中，导航到实验室 15 的 Starter 文件夹。

    在“实验室 3：_设置开发环境_，你可以通过下载 ZIP 文件并从本地提取内容来克隆包含实验室资源的 GitHub 存储库。提取的文件夹结构包括以下文件夹路径：

    * Allfiles
        * 实验室
            * 15-使用 Azure IoT 中心远程监视和控制设备
                * 入门
                    * cheesecavedevice
                    * CheeseCaveOperator

1. 单击 **“cheesecavedevice”**，然后单击 **“选择文件夹”**。

    你应该会在 Visual Studio Code 的资源管理器窗格中看到以下文件：

    * cheesecavedevice.csproj
    * Program.cs

1. 若要打开代码文件，请单击 **“Program.cs”**。

    粗略地看上一眼即可发现，此应用程序与你在之前的实验中使用过的模拟设备应用程序非常相似。此版本使用对称密钥身份验证，将遥测和日志记录消息发送到 IoT 中心，并且具有更复杂的传感器实现。

1. 在 **“终端”** 菜单中，单击 **“新建终端”**。

    注意命令提示符中指示的目录路径。你无需在上一个实验室项目的文件夹结构中开始构建此项目。

1. 在终端命令提示符下，请输入以下命令以验证应用程序版本：

    ```bash
    dotnet build
    ```

    输出结果会类似于：

    ```text
    > dotnet build
    Microsoft (R) Build Engine version 16.5.0+d4cbfca49 for .NET Core
    Copyright (C) Microsoft Corporation. All rights reserved.

    Restore completed in 39.27 ms for D:\Az220-Code\AllFiles\Labs\15-Remotely monitor and control devices with Azure IoT Hub\Starter\CheeseCaveDevice\CheeseCaveDevice.csproj.
    CheeseCaveDevice -> D:\Az220-Code\AllFiles\Labs\15-Remotely monitor and control devices with Azure IoT Hub\Starter\CheeseCaveDevice\bin\Debug\netcoreapp3.1\CheeseCaveDevice.dll

    Build succeeded.
        0 Warning(s)
        0 Error(s)

    Time Elapsed 00:00:01.16
    ```

在下一个任务中，你将配置连接字符串并查看应用程序。

#### 任务 2：配置连接并查看代码

你在此任务中构建的模拟设备应用将模拟监视温度和湿度的 IoT 设备。该应用将模拟传感器读数并每两秒钟传达一次传感器数据。

1. 在 **Visual Studio Code** 中，确保已打开 Program.cs 文件。

1. 在代码编辑器中，找到以下代码行：

    ```csharp
    private readonly static string deviceConnectionString = "<your device connection string>";
    ```

1. 将 **“\<your device connection string\>”** 替换为你之前保存的设备连接字符串。

    这是在将遥测发送到 IoT 中心之前唯一需要实现的更改。

1. 在 **“文件”** 菜单中，单击 **“保存”**。

1. 花点时间查看一下应用程序的结构。

    请注意，该应用程序的结构与之前的实验室中使用的应用程序类似：

    * 使用语句
    * 命名空间定义
      * Program 类 - 负责连接到 Azure IoT 并发送遥测
      * CheeseCaveSimulator 类 -（代替 EnvironmentSensor）而不仅仅是生成遥测，该类还模拟了一个运行中的奶酪储藏室环境，该环境受冷却风扇运行的影响。
      * ConsoleHelper - 将编写不同彩色文本封装到控制台的类

1. 查看 **Main** 方法：

    ```csharp
    private static void Main(string[] args)
    {
        ConsoleHelper.WriteColorMessage("Cheese Cave device app.\n", ConsoleColor.Yellow);

        // 使用 MQTT 协议连接到 IoT 中心。
        deviceClient = DeviceClient.CreateFromConnectionString(deviceConnectionString, TransportType.Mqtt);

        // 创建奶酪储藏室模拟器实例
        cheeseCave = new CheeseCaveSimulator();

        // 在下方插入注册直接方法编码

        // 在下方插入注册所需属性更改处理程序代码

        SendDeviceToCloudMessagesAsync();
        Console.ReadLine();
    }
    ```

    与前面的实验室中一样，**Main** 方法用于建立与 IoT 中心的连接。你可能已经注意到，它将用于与设备孪生属性更改集成，在本例中，还将集成直接方法。

1. 简要查看一下 **SendDeviceToCloudMessagesAsync** 方法。

    请注意，它与你在之前的实验中创建的先前版本非常相似。

1. 看看 **CheeseCaveSimulator** 类。

   它由在之前的实验室中使用的 **EnvironmentSensor** 类演变而来。主要差异在于引入风扇 - 如果风扇处于 **“开启”** 状态，则温度和湿度将逐渐达到所需值，而如果风扇处于 **“关闭”** （或 **“故障”**）状态，则温度和湿度将逐渐靠近环境值。值得注意的是，在读取温度时，有 1% 可能性将风扇设置为 **“故障”** 状态。

#### 任务 3：测试你的代码以发送遥测

1. 在 Visual Studio Code 中，确保“终端”仍处于打开状态。

1. 在终端命令提示符下，输入以下命令以运行模拟设备应用：

    ```bash
    dotnet run
    ```

   此命令将在当前文件夹中运行 **“Program.cs”** 文件。

1. 注意输出已发送到终端。

    你应该很快就能看到控制台输出，类似于：

    ![控制台输出](media/LAB_AK_15-cheesecave-telemetry.png)

    > **备注：**  绿色文本表示一切正常。红色文本表示存在异常。如果你看到的屏幕与上图并不相似，请首先检查设备连接字符串。

1. 保持此应用持续运行。

    在本实验的后部分，你需要将遥测发送到 IoT 中心。

### 练习 3：创建第二个应用以接收遥测

现在，你已有将遥测发送到 IoT 中心的（模拟）奶酪储藏室设备，你需要创建一个后端应用，该应用可以连接到 IoT 中心并“侦听”该遥测。最终，此后端应用将用于自动控制奶酪储藏室中的温度。

#### 任务 1：创建一个应用以接收遥测

在此任务中，你将开始使用后端应用，该应用用于从 IoT 中心事件中心终结点接收遥测。

1. 打开一个新的 Visual Studio Code 实例。

    由于模拟设备应用正在已打开的 Visual Studio Code 窗口中运行，因此你需要为后端应用提供一个新的 Visual Studio Code 实例。

1. 在 **“文件”** 菜单上，单击 **“打开文件夹”**

1. 在 **“打开文件夹”** 对话框中，导航到实验室 15 的 Starter 文件夹。

1. 单击 **“CheeseCaveOperator”**，然后单击 **“选择文件夹”**。

    事先已准备好的 CheeseCaveOperator 应用程序是一个简单的控制台应用程序，其中包括几个 NuGet 包库和一些用于指导你完成构建代码的过程的注释。你需要先向项目添加代码块，然后才能运行应用程序。

1. 在 **“资源管理器”** 窗格中，单击 **“CheeseCaveOperator.csproj”** 打开应用程序项目文件。

    现在，**CheeseCaveOperator.csproj** 文件应该在代码编辑器窗格中打开。

1. 花点时间查看 **“CaveDevice.csproj”** 文件的内容。

    文件内容应如下所示：

    ```xml
    <Project Sdk="Microsoft.NET.Sdk">

    <PropertyGroup>
        <OutputType>Exe</OutputType>
        <TargetFramework>netcoreapp3.1</TargetFramework>
    </PropertyGroup>

    <ItemGroup>
        <PackageReference Include="Microsoft.Azure.Devices" Version="1.*" />
        <PackageReference Include="Microsoft.Azure.EventHubs" Version="4.*" />
    </ItemGroup>

    </Project>
    ```

    > **备注：** 文件中的包版本号可以高于上面显示的版本号。

    项目文件 (.csproj) 是一个 XML 文档，用于指定要使用的项目的类型。在本例中，项目是一个 **SDK** 样式的项目。

    正如你所见，项目定义包含两个部分 - **PropertyGroup** 和 **ItemGroup**。

    **PropertyGroup** 定义构建此项目将产生的输出的类型。在本例中，你将构建面向.NET Core 3.1 的可执行文件。

    **ItemGroup** 指定应用程序所需的任何外部库。这些特定的引用适用于 NuGet 包，每个包引用都指定了包名称和版本。

    > **备注：** 可通过在命令提示符（例如 Visual Studio Code 终端命令提示符）处输入命令 `dotnet add package` 来手动添加 NuGet 库（例如上面的 ItemGroup 中列出的库）。输入 `dotnet restore` 命令可确保下载所有依赖项。例如，若要下载上面的库并确保在代码项目中提供这些库，可输入以下命令：
    >
    >   dotnet add package Microsoft.Azure.EventHubs
    >   dotnet add package Microsoft.Azure.Devices
    >   dotnet restore
    >
    > **信息**： 可以在[此处](https://docs.microsoft.com/zh-cn/nuget/what-is-nuget)详细了解 NuGet。

#### 任务 3：添加遥测接收方代码

1. 在 **“资源管理器”** 窗格中，单击 **“Program.cs”**。

    **Program.cs** 文件应如下所示：

    ```csharp
    // 版权所有 (c) Microsoft。保留所有权利。
    // 已获得 MIT License 颁发的许可证。有关完整的许可信息，请参阅项目根目录中的许可文件。

    // 在下方插入 using 语句

    namespace CheeseCaveOperator
    {
        class Program
        {
            // 在下方插入变量

            // 在下方插入 Main 方法

            // 在下方插入 ReceiveMessagesFromDeviceAsync 方法

            // 在下方插入 InvokeMethod 方法

            // 在下方插入设备孪生部分
        }

        internal static class ConsoleHelper
        {
            internal static void WriteColorMessage(string text, ConsoleColor clr)
            {
                Console.ForegroundColor = clr;
                Console.WriteLine(text);
                Console.ResetColor();
            }
            internal static void WriteGreenMessage(string text)
            {
                WriteColorMessage(text, ConsoleColor.Green);
            }

            internal static void WriteRedMessage(string text)
            {
                WriteColorMessage(text, ConsoleColor.Red);
            }
        }
    }
    ```

    此代码概述了操作员应用的结构。

1. 找到注释 `// 在下方插入 using 语句`。

1. 若要指定应用程序代码将使用的命名空间，请输入以下代码：

    ```csharp
    using System;
    using System.Threading.Tasks;
    using System.Text;
    using System.Collections.Generic;
    using System.Linq;

    using Microsoft.Azure.EventHubs;
    using Microsoft.Azure.Devices;
    using Newtonsoft.Json;
    ```

    请注意，除了指定 **System** 之外，你还声明了代码将使用的其他命名空间，例如用于编码字符串的 **System.Text**、用于异步任务的 **System.Threading.Tasks** 和用于之前添加的两个包的命名空间。

    > **提示**： 插入代码时，代码布局可能不理想。通过在代码编辑器窗格中右键单击，然后单击 **“设置文档格式”**，可以让 Visual Studio Code 为你设置文档格式。可以通过打开 **“任务”** 窗格（按 **F1**），键入 **“设置文档格式”**，然后按 **Enter** 来获得相同的结果。在 Windows 上，此任务的快捷方式是 **Shift+Alt+F**。

1. 找到注释 `// 在下方插入变量`。

1. 若要指定程序正在使用的变量，请输入以下代码：

    ```csharp
    // 全局变量。
    // 与事件中心兼容的终结点。
    private readonly static string eventHubsCompatibleEndpoint = "<your event hub endpoint>";

    // 与事件中心兼容的名称。
    private readonly static string eventHubsCompatiblePath = "<your event hub path>";
    private readonly static string iotHubSasKey = "<your event hub SaS key>";
    private readonly static string iotHubSasKeyName = "service";
    private static EventHubClient eventHubClient;

    // 在下方插入服务客户端变量

    // 在下方插入注册表管理器变量

    // IoT 中心的连接字符串。
    private readonly static string serviceConnectionString = "<your service connection string>";

    private readonly static string deviceId = "sensor-th-0055";
    ```

1. 花点时间检查你刚刚输入的代码（和代码注释）。

    **eventHubsCompatibleEndpoint** 变量用于存储 IoT 中心面向服务的内置终结点（消息/事件）的 URI，该终结点与事件中心兼容。

    **eventHubsCompatiblePath** 变量包含事件中心实体的路径。

    **iotHubSasKey** 变量包含命名空间或实体的相应共享访问策略规则的密钥名称。

    **iotHubSasKeyName** 变量包含命名空间或实体的相应共享访问策略规则的密钥。

    **eventHubClient** 变量包含将用于从 IoT 中心接收消息的事件中心客户端实例。

    **serviceClient** 变量包含将用于从应用向 IoT 中心（以及从 IoT 中心向目标设备等）发送消息的服务客户端实例。

    **serviceConnectionString** 变量包含用于支持操作员应用连接到 IoT 中心的连接字符串。

    **deviceId** 变量包含 **CheeseCaveDevice** 应用程序使用的设备 ID。

1. 找到用于分配服务连接字符串的代码行

    ```csharp
    private readonly static string serviceConnectionString = "<your service connection string>";
    ```

1. 将 **“\<your service connection string\>”** 替换为你之前在本实验室中保存的 IoT 中心服务连接字符串。

    你应该已经保存 iothubowner 共享访问策略主要连接字符串，该字符串由你之前在练习 1 中运行的 lab15-setup.azcli 设置脚本生成。

    > **备注：** 你可能会好奇为什么使用 **iothubowner**  共享策略而不是使用**服务**共享策略。答案与分配给每个策略的 IoT 中心权限有关。**服务**策略具有 **ServiceConnect** 权限，通常由后端云服务使用。它具有以下权利：
    >
    > * 授予对面向云服务的通信和监视终结点的访问权限。
    > * 授予接收设备到云消息、发送云到设备消息和检索相应传送确认的权限。
    > * 授予检索文件上传的传送确认的权限。
    > * 授予访问孪生以更新标记和所需属性、检索报告属性和运行查询的权限。
    >
    > 在实验室的第一部分中，**serviceoperator** 应用程序调用直接方法来切换风扇状态，**服务** 策略具有足够的权限。但在实验室的后半部分，将查询设备注册表。这是通过 **“RegistryManager”** 类实现的。为了使用 **“RegistryManager”** 类查询设备注册表，用于连接到 IoT 中心的共享访问策略必须具有 **“注册表读取”** 权限，并授予了以下权限：
    >
    > * 授予对标识注册表的读取访问权限。
    >
    > 由于 **iothubowner** 策略已被授予 **“注册表写入”** 权限，同时它还继承了 **“注册表读取”** 权限，因此它适合你的需要。
    >
    > 在生产方案中，你可以考虑添加一个新的仅具有**服务连接**和**注册读取**权限的共享访问策略。

1. 将 **“\<your event hub endpoint\>”**、 **“\<your event hub path\>”** 和 **“\<your event hub SaS key\>”** 替换为你之前在本实验室中保存的值。

1. 找到注释 `// 在下方插入 Main 方法`。

1. 要实现 **Main** 方法，请输入以下代码：

    ```csharp
    public static void Main(string[] args)
    {
        ConsoleHelper.WriteColorMessage("Cheese Cave Operator\n", ConsoleColor.Yellow);

        // 创建一个 EventHubClient 实例以连接到 IoT 中心与事件中心兼容的终结点。
        var connectionString = new EventHubsConnectionStringBuilder(new Uri(eventHubsCompatibleEndpoint), eventHubsCompatiblePath, iotHubSasKeyName, iotHubSasKey);
        eventHubClient = EventHubClient.CreateFromConnectionString(connectionString.ToString());

        // 为中心上的每个分区创建一个 PartitionReceiver。
        var runtimeInfo = eventHubClient.GetRuntimeInformationAsync().GetAwaiter().GetResult();
        var d2cPartitions = runtimeInfo.PartitionIds;

        // 在下方插入注册所需属性更改处理程序代码

        // 在下方插入创建服务客户端实例

        // 创建接收方以侦听消息。
        var tasks = new List<Task>();
        foreach (string partition in d2cPartitions)
        {
            asks.Add(ReceiveMessagesFromDeviceAsync(partition));
        }

        // 等待所有 PartitionReceivers 完成。
        Task.WaitAll(tasks.ToArray());
    }
    ```

1. 花点时间检查你刚刚输入的代码（和代码注释）。

    请注意，此处使用了 **EventHubsConnectionStringBuilder** 类（这实际上是一个帮助程序类，可将多个值连接为正确的格式）来构造 **EventHubClient** 连接字符串。此类随后用于连接到事件中心终结点，并填充 **eventHubClient** 变量。

    然后，**eventHubClient** 用于检索事件中心的运行时信息。此信息中包含：

    * **CreatedAt** - 创建事件中心的日期/时间
    * **PartitionCount** - 分区数（大多数 IoT 中心配置有 4 个分区）
    * **PartitionIds** - 包含分区 ID 的字符串数组
    * **Path** - 事件中心实体路径

    分区 ID 数组存储在 **d2cPartitions** 变量中，该变量将在短期内用于创建将从每个分区接收消息的任务列表。

    > **信息**： 可在[此处](https://docs.microsoft.com/zh-cn/azure/iot-hub/iot-hub-scaling#partitions)详细了解分区用途。

    由于从设备向 IoT 中心发送的消息可能由任意分区处理，因此应用必须从每个分区中检索消息。代码的下一部分创建异步任务列表 - 每个任务将接收来自特定分区的消息。最后一行将等待所有任务完成 - 由于每个任务将进去无限循环，此行可阻止应用程序退出。

1. 找到注释 `在下方插入 ReceiveMessagesFromDeviceAsync 方法`。

1. 要实现 **ReceiveMessagesFromDeviceAsync** 方法，请输入以下代码：

    ```csharp
    // 异步为分区创建 PartitionReceiver，然后开始读取从模拟客户端发送的所有消息。
    private static async Task ReceiveMessagesFromDeviceAsync(string partition)
    {
        // 使用默认使用者组创建接收方。
        var eventHubReceiver = eventHubClient.CreateReceiver("$Default", partition, EventPosition.FromEnqueuedTime(DateTime.Now));
        Console.WriteLine("Created receiver on partition: " + partition);

        while (true)
        {
            // 检查 EventData - 如果没有要检索的内容，此方法将超时。
            var events = await eventHubReceiver.ReceiveAsync(100);

            // 如果批处理中有数据，请对其进行处理。
            if (events == null) continue;

            foreach (EventData eventData in events)
            {
                string data = Encoding.UTF8.GetString(eventData.Body.Array);

                ConsoleHelper.WriteGreenMessage("Telemetry received: " + data);

                foreach (var prop in eventData.Properties)
                {
                    if (prop.Value.ToString() == "true")
                    {
                        ConsoleHelper.WriteRedMessage(prop.Key);
                    }
                }
                Console.WriteLine();
            }
        }
    }
    ```

    如你所见，此方法包含用于定义目标分区的参数。回想一下，对于指定了 4 个分区的默认配置，调用 4 次此方法，每次调用异步并行运行，每个分区一个。

    此方法的第一部分创建事件中心接收方。该代码指定使用 **$Default** 使用者组（但常常创建自定义使用者组）、分区以及最终从事件分区的哪个位置开始接收数据。在本例中，接收方仅关注从当前时间开始排队的消息 - 还可使用其他选项提供数据流开头，数据流结尾或特定偏移量。

    > **信息**：可在[此处](https://docs.microsoft.com/zh-cn/azure/event-hubs/event-hubs-features#consumer-groups)详细了解使用者组

    创建接收方后，应用即会进入无限循环，并等待接收事件。

    > **备注：** `eventHubReceiver.ReceiveAsync(100)` 代码指定可一次性接收的最大事件数，但它并不会等待接收该数量的事件，而是在有至少一个可用事件后立即返回。如果未返回任何事件（因为超时），则将继续循环，并且代码会等待更多事件。

    如果接收到一个或多个事件，则每个事件数据主体将从字节数组转换为字符串，并写入控制台。然后循环访问事件数据属性，并且在本例中，应检查事件数据属性以查看值是否为 true - 在当前场景中，这表示警报。如果发现警报，则将其写入控制台。

1. 在 **“文件”** 菜单，将你的更改保存到 Program.cs 文件，单击 **“保存”**。

#### 任务 3：测试你的代码以接收遥测

此测试很重要，请检查后端应用是否正在接收模拟设备发送的遥测数据。请记住，设备应用仍在运行，且仍在发送遥测数据。

1. 要在终端中运行 **“CheeseCaveOperator”** 后端应用，请打开“终端”窗格，然后输入以下命令：

    ```bash
    dotnet run
    ```

   此命令将在当前文件夹中运行 **“Program.cs”** 文件。

   > **备注：**  你可以忽略有关未使用的变量 **“serviceConnectionString”** 的警告 - 我们很快就将添加代码来使用该变量。

1. 花一分钟时间观察到终端的输出。

    你应该快速看到控制台输出，如果该应用成功连接到 IoT 中心，该应用将几乎立即显示遥测消息数据。

    如果没有，请仔细检查你的 IoT 中心服务连接字符串，注意该字符串应该是服务连接字符串，而不是任何其他字符串：

    ![控制台输出](media/LAB_AK_15-cheesecave-telemetry-received.png)

    > **备注：**  绿色文本表示一切正常，红色文本表示存在异常。如果屏幕上未出现类似图像，请首先检查设备连接字符串。

1. 让此应用运行更长的时间。

1. 在操作员应用和设备应用都运行的情况下，验证前者显示的遥测与后者发送的遥测同步。

    直观地比较正在发送的遥测与正在接收的遥测。

    * 是否有确切的数据匹配？
    * 从发送数据到接收数据之间是否有很大的延迟？

1. 在验证遥测数据后，停止运行应用并关闭两个 VS Code 实例中的“终端”窗格，但不关闭 Visual Studio Code 窗口。

你现在有一个应用从设备发送遥测数据，还有一个后端应用确认收到数据。在下一个练习中，你将开始执行处理控制端的步骤 - 数据出现问题时该怎么办。

### 练习 4：编写代码以调用直接方法

用于从后端应用调用直接方法的调用可以在有效负载中包含多个参数。直接方法通常用于打开和关闭设备功能或指定设备的设置。

在 Contoso 场景中，你将在设备上实现一种直接方法来控制奶酪储藏室中风扇的运行（通过打开或关闭风扇模拟控制温度和湿度）。操作员应用程序将与 IoT 中心通信，以调用设备上的直接方法。

当奶酪储藏室设备收到运行直接方法的指令时，需要检查一些错误条件。其中一项检查是在风扇处于故障状态时响应错误。需要进行报告的另一个错误条件是接收到无效参数。考虑到设备的潜在远程性，清晰的错误报告非常重要。

直接方法要求后端应用准备参数，然后进行调用，以指定在其上调用方法的单个设备。然后，后端应用将等待并报告响应。

设备应用包含直接方法的函数代码。函数名称已注册到设备的 IoT 客户端。此过程可确保客户端知道当调用来自 IoT 中心时所要运行的函数（可能涉及许多直接方法）。

在本练习中，将通过添加直接方法的代码来更新设备应用，该方法将模拟在奶酪储藏室中打开风扇。接下来，将代码添加到后端服务应用以调用此直接方法。

#### 任务 1：添加代码以在设备应用中定义直接方法

1. 返回到包含 **cheesecavedevice** 应用程序的 Visual Studio Code 实例。

    > **备注：** 如果应用仍在运行，请使用“终端”窗格退出应用（在“终端”窗格内单击以设置焦点，然后按 **CTRL+C** 退出正在运行的应用程序）。

1. 确保 **Program.cs**  在代码编辑器中打开。

1. 找到注释 `在下方插入注册直接方法代码`。

1. 要注册直接方法，请输入以下代码：

    ```csharp
    // 为直接方法调用创建处理程序
    deviceClient.SetMethodHandlerAsync("SetFanState", SetFanState, null).Wait();
    ```

    请注意，**SetFanState** 直接方法处理程序也由此代码设置。正如你所见，deviceClient 的 **SetMethodHandlerAsync** 方法将远程方法名称 `"SetFanState"`，以及要调用的实际本地方法和用户上下文对象（在本例中为 null）作为参数。

1. 找到注释 `在下方插入 SetFanState 方法`。

1. 要实现 **SetFanState** 直接方法，请输入以下代码：

    ```csharp
    // 处理直接方法调用
    private static Task<MethodResponse> SetFanState(MethodRequest methodRequest, object userContext)
    {
        if (cheeseCave.FanState == StateEnum.Failed)
        {
            // 通过 400 错误消息确认直接方法调用结果。
            string result = "{\"result\":\"Fan failed\"}";
            ConsoleHelper.WriteRedMessage("Direct method failed: " + result);
            return Task.FromResult(new MethodResponse(Encoding.UTF8.GetBytes(result), 400));
        }
        else
        {
            try
            {
                var data = Encoding.UTF8.GetString(methodRequest.Data);

                // 从数据中删除引号。
                data = data.Replace("\"", "");

                // Parse the payload, and trigger an exception if it's not valid.
                cheeseCave.UpdateFan((StateEnum)Enum.Parse(typeof(StateEnum), data));
                ConsoleHelper.WriteGreenMessage("Fan set to: " + data);

                // 通过 200 成功消息确认直接方法调用结果。
                string result = "{\"result\":\"Executed direct method: " + methodRequest.Name + "\"}";
                return Task.FromResult(new MethodResponse(Encoding.UTF8.GetBytes(result), 200));
            }
            catch
            {
                // 通过 400 错误消息确认直接方法调用结果。
                string result = "{\"result\":\"Invalid parameter\"}";
                ConsoleHelper.WriteRedMessage("Direct method failed: " + result);
                return Task.FromResult(new MethodResponse(Encoding.UTF8.GetBytes(result), 400));
            }
        }
    }
    ```

    这是在通过 IoT 中心调用关联的远程方法（也称为 **SetFanState**）时，设备上运行的方法。请注意，除了接收 **MethodRequest** 实例之外，它还接收在注册直接消息回叫时定义的 **userContext** 对象（在本例中为 null）。

    此方法的第一行确定奶酪储藏室风扇当前是否处于 **“故障”** 状态 - 奶酪储藏室模拟器制定的假设是，一旦风扇处于故障状态，任何后续命令都将自动失败。因此，将创建一个 **“result”** 属性设置为 **“Fan Failed”** 的 JSON 字符串。然后会构造一个新的 **MethodResponse** 对象，该对象的结果字符串编码为一个字节数组和一个 HTTP 状态代码 - 本例中使用 **400**，在 REST API 的上下文中表示发生一般性客户端错误。由于需要直接方法回叫才可返回 **Task\<MethodResponse\>**，因此将创建和返回新任务。

    > **信息**： 可在[此处](https://restfulapi.net/http-status-codes/)详细了解如何在 REST API 中使用 HTTP 状态代码。

    如果风扇状态并非 **“故障”**，则代码将继续处理在方法请求中发送的数据。 **“methodRequest.Data”** 属性中包含字节数组形式的数据，因此它首先转换为字符串。在此场景中，该数据应为以下两个值（包括引号）：

    * "On"
    * "Off"

    假定接收的数据映射到 **StateEnum** 的成员：

    ```csharp
    internal enum StateEnum
    {
        Off,
        On,
        Failed
    }
    ```

    为了分析数据，必须先去除引号，然后使用 **Enum.Parse** 方法来查找匹配的枚举值。如果此操作失败（数据需要完全匹配），则会引发异常，下面捕获了该异常。请注意，异常处理程序创建并返回的错误方法响应与为风扇故障状态创建的响应类似。

    如果在 **StateEnum** 中发现了匹配的值，则会调用奶酪储藏室模拟器 **UpdateFan** 方法。在本例中，该方法仅仅将 **“FanState”** 属性设置为提供的值 - 实际实现将与风扇交互，以更改状态并确定状态更改是否成功。但在本场景中，假定状态更改成功，并创建和返回相应的 **result** 和 **MethodResponse** - 此次使用 HTTP 状态代码 **200** 来指示操作成功。

1. 在 **“文件”** 菜单中，单击 **“保存”**，保存 Program.cs 文件。

现在即已经完成了设备端所需的编码。接下来，需要将代码添加到将调用直接方法的后端操作员应用程序。

#### 任务 2：添加代码以调用直接方法

1. 返回到包含 **CheeseCaveOperator** 应用程序的 Visual Studio Code 实例。

    > **备注：** 如果应用仍在运行，请使用“终端”窗格退出应用（在“终端”窗格内单击以设置焦点，然后按 **CTRL+C** 退出正在运行的应用程序）。

1. 确保 **Program.cs** 在代码编辑器中打开。

1. 找到注释 `在下方插入服务客户端变量`。

1. 要添加用于保存服务客户端实例的全局变量，请输入以下代码：

    ```csharp
    private static ServiceClient serviceClient;
    ```

1. 找到注释 `在下方插入创建服务客户端实例`。

1. 要添加创建服务客户端实例并调用直接方法的代码，请输入以下代码：

    ```csharp
    // 创建 ServiceClient 与中心上面向服务的终结点进行通信。
    serviceClient = ServiceClient.CreateFromConnectionString(serviceConnectionString);
    InvokeMethod().GetAwaiter().GetResult();
    ```

1. 找到注释 `在下方插入 InvokeMethod 方法`。

1. 要添加调用直接方法的代码，请输入以下代码：

    ```csharp
    // 处理调用直接方法。
    private static async Task InvokeMethod()
    {
        try
        {
            var methodInvocation = new CloudToDeviceMethod("SetFanState") { ResponseTimeout = TimeSpan.FromSeconds(30) };
            string payload = JsonConvert.SerializeObject("On");

            methodInvocation.SetPayloadJson(payload);

            // 异步调用直接方法，并从模拟设备获取响应。
            var response = await serviceClient.InvokeDeviceMethodAsync(deviceId, methodInvocation);

            if (response.Status == 200)
            {
                ConsoleHelper.WriteGreenMessage("Direct method invoked: " + response.GetPayloadAsJson());
            }
            else
            {
                ConsoleHelper.WriteRedMessage("Direct method failed: " + response.GetPayloadAsJson());
            }
        }
        catch
        {
            ConsoleHelper.WriteRedMessage("Direct method failed: timed-out");
        }
    }
    ```

    此代码用于调用设备应用上的 **SetFanState** 直接方法。

1. 在 **“文件”** 菜单中，单击 **“保存”**，保存 Program.cs 文件。

现在已经完成了代码更改，以支持 **SetFanState** 直接方法。

#### 任务 3：测试直接方法

若要测试直接方法，需要以正确的顺序启动应用。你不能调用尚未注册的直接方法！

1. 切换到包含 **cheesecavedevice** 设备应用的 Visual Studio Code 实例。

1. 要启动 **cheesecavedevice** 设备应用，请打开“终端”窗格，然后输入 `dotnet run` 命令。

    它将开始写入终端，并且将显示遥测消息。

1. 切换到包含 **CheeseCaveOperator** 后端应用的 Visual Studio Code 实例。

1. 要启动 **CheeseCaveOperator** 后端应用，请打开“终端”窗格，然后输入 `dotnet run` 命令。

    > **备注：**  如果看到 `Direct method failed: timed-out` 消息，请仔细检查是否已将更改保存在 **CheeseCaveDevice** 中并启动了该应用。

    CheeseCaveOperator 后端应用将立即调用直接方法。

    请注意，输出如下所示：

    ![控制台输出](media/LAB_AK_15-cheesecave-direct-method-sent.png)

1. 现在检查 **cheesecavedevice** 设备应用的控制台输出，你会看到风扇已打开。

   ![控制台输出](media/LAB_AK_15-cheesecave-direct-method-received.png)

现在，你已成功监视和控制远程设备。已在设备上实现了可从云中调用的直接方法。在 Contoso 场景中，直接方法用于打开风扇，这将使储藏室中的环境达到我们所需的设置。你应注意到，温度和湿度读数会随着时间的推移而降低，最终会消除警报（除非风扇故障）。

但如果你希望远程指定奶酪储藏室环境的所需设置，该怎么办？也许你想在老化过程中的某个时刻为奶酪储藏室设置特定的目标温度。可以使用直接方法（这是一种有效方法）指定所需的设置，也可以使用 IoT 中心专为此目的设计的另一个功能：设备孪生。在下一个练习中，你将在解决方案中实现设备孪生属性。

### 练习 5：实现设备孪生功能

提醒一下，一对设备孪生包含四种类型的信息：

* **标签**： 设备上不可见的设备信息。
* **所需属性**： 后端应用指定的所需设置。
* **报告的属性**： 设备上报告的设置值。
* **设备标识属性**： 标识设备的只读信息。

通过 IoT 中心管理的设备孪生专为查询而设计，并且它们与真实的 IoT 设备同步。可随时通过后端应用查询设备孪生。该查询可以返回设备的当前状态信息。获取此数据不涉及对设备的调用，因为设备和孪生将同步。设备孪生的许多功能由 Azure IoT 中心提供，因此无需编写太多代码即可使用它们。

孪生设备的功能和直接方法之间存在一些重叠。可以使用直接方法设置设备属性，这似乎是一种直观的处理方式。但是，如果需要访问设置，使用直接方法就会要求后端应用对这些设置进行显式记录。如果使用设备孪生，默认情况下会存储和维护此信息。

在本练习中，将向设备应用和后端服务应用添加一些代码，以显示运行中的设备孪生同步。

#### 任务 1：添加代码以使用设备孪生同步设备属性

1. 返回到正在运行 **CheeseCaveOperator** 后端应用的 Visual Studio Code 实例。

1. 如果应用仍在运行，请将输入焦点放在终端上，然后按 **Ctrl+C** 退出应用。

1. 确保 **Program.cs** 打开。

1. 找到注释 `在下方插入注册表管理器变量`。

1. 要插入注册表管理器便利，请输入以下代码：

    ```csharp
    private static RegistryManager registryManager;
    ```

1. 找到注释 `在下方插入注册所需属性更改处理程序代码`。

1. 要添加创建注册表管理器实例并设置孪生属性的功能，请输入以下代码：

    ```csharp
    // 注册表管理器用于访问数字孪生。
    registryManager = RegistryManager.CreateFromConnectionString(serviceConnectionString);
    SetTwinProperties().Wait();
    ```

1. 找到注释 `在下方插入设备孪生部分`。

1. 要添加更新设备孪生所需属性的功能，请输入以下代码：

    ```csharp
    // 设备孪生部分。

    private static async Task SetTwinProperties()
    {
        var twin = await registryManager.GetTwinAsync(deviceId);
        var patch =
            @"{
                tags: {
                    customerID: 'Customer1',
                    cheeseCave: 'CheeseCave1'
                },
                properties: {
                    desired: {
                        patchId: 'set values',
                        temperature: '50',
                        humidity: '85'
                    }
                }
            }";
        await registryManager.UpdateTwinAsync(twin.DeviceId, patch, twin.ETag);

        var query = registryManager.CreateQuery(
            "SELECT * FROM devices WHERE tags.cheeseCave = 'CheeseCave1'", 100);
        var twinsInCheeseCave1 = await query.GetNextAsTwinAsync();
        Console.WriteLine("Devices in CheeseCave1: {0}",
            string.Join(", ", twinsInCheeseCave1.Select(t => t.DeviceId)));
    }
    ```

    > **备注：**  **SetTwinProperties** 方法创建一段 JSON，用于定义将添加到设备孪生的标记和属性，然后更新孪生。该方法的下一部分演示如何执行查询以列出 **cheeseCave** 标记设置为 **“CheeseCave1”** 的设备。此查询要求连接具有 **“注册表读取”** 权限。

1. 在 **“文件”** 菜单中，单击 **“保存”**，保存 Program.cs 文件。

#### 任务 2：添加代码以同步设备的设备孪生设置

1. 返回到包含 **cheesecavedevice** 应用的 Visual Studio Code 实例。

1. 如果应用仍在运行，请将输入焦点放在终端上，然后按 **Ctrl+C** 退出应用。

1. 确保 **Program.cs** 文件在“代码编辑器”窗格中打开。

1. 找到注释 `在下方插入注册所需属性更改处理程序代码`。

1. 要注册所需属性更改处理程序，请添加以下代码：

    ```csharp
    // Get the device twin to report the initial desired properties.
    Twin deviceTwin = deviceClient.GetTwinAsync().GetAwaiter().GetResult();
    ConsoleHelper.WriteGreenMessage("Initial twin desired properties: " + deviceTwin.Properties.Desired.ToJson());

    // Set the device twin update callback.
    deviceClient.SetDesiredPropertyUpdateCallbackAsync(OnDesiredPropertyChanged, null).Wait();
    ```

1. 找到注释 `在下方插入 OnDesiredPropertyChanged 方法`。

1. 要添加响应设备孪生属性更改的功能，请输入以下代码：

    ```csharp
    private static async Task OnDesiredPropertyChanged(TwinCollection desiredProperties, object userContext)
    {
        try
        {
            // 更改奶酪储藏室模拟器属性
            cheeseCave.DesiredHumidity = desiredProperties["humidity"];
            cheeseCave.DesiredTemperature = desiredProperties["temperature"];
            ConsoleHelper.WriteGreenMessage("Setting desired humidity to " + desiredProperties["humidity"]);
            ConsoleHelper.WriteGreenMessage("Setting desired temperature to " + desiredProperties["temperature"]);

            // 将属性报告回 IoT 中心。
            var reportedProperties = new TwinCollection();
            reportedProperties["fanstate"] = cheeseCave.FanState.ToString();
            reportedProperties["humidity"] = cheeseCave.DesiredHumidity;
            reportedProperties["temperature"] = cheeseCave.DesiredTemperature;
            await deviceClient.UpdateReportedPropertiesAsync(reportedProperties);

            ConsoleHelper.WriteGreenMessage("\nTwin state reported: " + reportedProperties.ToJson());
        }
        catch
        {
            ConsoleHelper.WriteRedMessage("Failed to update device twin");
        }
    }
    ```

    此代码定义在设备孪生中所需属性更改时调用的处理程序。请注意，然后将新值报告回 IoT 中心以确认更改。

1. 在 **“文件”** 菜单中，单击 **“保存”**，保存 Program.cs 文件。

    > **备注：** 现在，你已经在应用中添加了对设备孪生的支持，可以重新考虑使用显式变量，例如 **desiredHumidity**。你可以改用设备孪生对象中的变量。

#### 任务 3：测试设备孪生

要测试管理设备孪生所需属性更改的代码，请按正确的顺序启动应用，先启动设备应用程序，然后启动后端应用程序。

1. 切换到包含 **cheesecavedevice** 设备应用的 Visual Studio Code 实例。

1. 要启动 **cheesecavedevice** 设备应用，请打开“终端”窗格，然后输入 `dotnet run` 命令。

    它将开始写入终端，并且将显示遥测消息。

1. 切换到包含 **CheeseCaveOperator** 后端应用的 Visual Studio Code 实例。

1. 要启动 **CheeseCaveOperator** 后端应用，请打开“终端”窗格，然后输入 `dotnet run` 命令。

1. 切换回包含 **cheesecavedevice** 设备应用的 Visual Studio Code 实例。

1. 检查控制台输出，并确认设备孪生已正确同步。

    ![控制台输出](media/LAB_AK_15-cheesecave-device-twin-received.png)

    如果让风扇工作，则最终可看到红色警报关闭（除非风扇故障）

    ![控制台输出](media/LAB_AK_15-cheesecave-device-twin-success.png)

1. 对于这两个 Visual Studio Code 实例，请停止应用，然后关闭“Visual Studio Code”窗口。

在本实验室中实现的代码并未达到生产质量要求，但确实演示了使用直接方法和设备孪生属性的组合来监视和控制 IoT 设备的基础知识。你应该认识到，在此实现中，仅在首次运行后端服务应用时才发送操作员控制消息。通常，后端服务应用需要浏览器界面，以便操作员在需要时发送直接方法或设置设备孪生属性。
