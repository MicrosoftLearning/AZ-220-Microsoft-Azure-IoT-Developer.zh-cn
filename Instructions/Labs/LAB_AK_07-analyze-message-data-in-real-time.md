---
lab:
    title: '实验室 07：设备消息路由'
    module: '模块 4：消息处理和分析'
---

# 设备消息路由

## 实验室场景

你使用 DPS 来实现自动设备注册给 Contoso 管理层留下了深刻的印象。他们现在希望你开发一种与产品包装和运输有关的基于 IoT 的解决方案。

打包和运输奶酪所产生的成本值得注意。为了最大程度地提高成本效率，Contoso 运营了一个本地包装设备。工作流程简单直接 - 奶酪切块打包、包裹组装到运输容器中，容器运输到与其目的地关联的特定运输箱中。传送带系统用于在此过程中传送产品。运输成功的衡量标准是在给定时间段（通常是工作班次）内离开传送带系统的包裹数量。

传送带系统是此过程中的关键环节，它会被直观监控，确保工作流程以最高效率推进。该系统具有三种操作员可控速度：停止、慢速和快速。当然，以低速运输的包裹的数量比以更快速度运输的包裹数量要少。不过，需要考虑很多其他因素：

* 速度较慢时，传送带系统的振动水平要小得多
* 振动水平高可能导致包裹从传送带上掉落
* 振动水平高已知会加快系统的磨损
* 当振动水平超过阈值限制时，必须停止传送带来进行检查（目的是避免更严重的故障）。

除了将吞吐量最大化，你的自动化 IoT 解决方案还将根据振动水平实施一种预防性维护，它将用于在出现严重系统损坏之前检测是否有早期警告迹象。 

> **备注：** **预防性维护**有时称为防止性维护或预测性维护，它是一种设备维护程序，用于计划在设备正常运行时执行的维护活动。这种方法的目的是避免意外故障，这些故障通常会导致代价高昂的设备中断。

操作员直观检测异常振动级别并不总是很容易。因此，你正在寻求一种 Azure IoT 解决方案，该解决方案将有助于测量振动水平和数据异常。振动传感器将连接到传送带的各个位置，你将使用 IoT 设备将遥测发送到 IoT 中心。IoT 中心将使用 Azure 流分析和内置的机器学习 (ML) 模型来实时提醒你提防振动异常。你还计划将所有遥测数据存档，以便将来可开发内部机器学习模型。

你可以使用来自单个 IoT 设备的模拟遥测技术来进行解决方案的原型设计。

为了以逼真的方式模拟振动数据，你可与一位运营部门的工程师一起工作，来稍微了解一下导致振动的原因。事实证明，有多种不同类型的振动会影响整体振动级别。例如，“强制振动”可能是由损坏的导轮或者传送带过载引起的。当超出系统设计限制（例如速度或重量）时，也会引入“持续增加的振动”。工程师团队同意帮助你为模拟的 IoT 设备开发代码，该设备将生成可接受的振动数据描述（包括异常）。

将创建以下资源：

![实验室 7 基础结构](media/LAB_AK_07-architecture.png)

## 本实验室概览

在本实验室中，你首先将查看实验室先决条件，并根据需要运行脚本来确保你的 Azure 订阅包含所需的资源。然后，你将创建一个将振动遥测数据发送到 IoT 中心的模拟设备。在模拟设备到达 IoT 中心后，你将实施一项“IoT 中心消息路由和 Azure 流分析”作业，它可用于将数据存档。本实验室包括以下练习：

* 验证实验室先决条件

  * 将使用脚本来创建任何缺少的资源，并为此实验室创建一个新的设备标识 (sensor-v-3000)

* 编写代码来生成振动遥测数据
* 创建到 Azure Blob 存储的消息路由
* 日志记录路由 Azure 流分析作业

## 实验室说明

### 练习 1：验证实验室先决条件

本实验室假定以下 Azure 资源可用：

| 资源类型 | 资源名称 |
| :-- | :-- |
| 资源组 | rg-az220 |
| IoT 中心 | iot-az220-training-{your-id} |
| 设备 ID | sensor-v-3000 |

> **重要说明**： 运行设置脚本以创建所需设备。

若要创建任何缺少的资源和新设备，在开始练习 2 之前，需要先按照下面的说明运行 **lab07-setup.azcli** 脚本。脚本文件包含在本地克隆作为开发环境配置（实验室 3）的 GitHub 存储库中。

写入 **lab07-setup.azcli** 脚本，并在 **Bash** shell 环境中运行，执行此操作最简便的方法是在 Azure Cloud Shell 中。

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
          * 07 - 设备消息路由
            * 设置

    lab07-setup.azcli 脚本文件位于实验室 7 的 Setup 文件夹中。

1. 选择 **“lab07-setup.azcli”** 文件，然后单击 **“打开”**。

    文件上传完成后，系统将显示一条通知。

1. 若要验证在 Azure Cloud Shell 中已上传了正确文件，请输入以下命令：

    ```bash
    ls
    ```

    使用 `ls` 命令列出当前目录的内容。你应该会看到列出的 lab07-setup.azcli 文件。

1. 若要为此实验室创建一个包含安装脚本的目录，然后移至该目录，请输入以下 Bash 命令：

    ```bash
    mkdir lab7
    mv lab07-setup.azcli lab7
    cd lab7
    ```

1. 为了保证 **lab07-setup.azcli** 具有执行权限，请输入以下命令：

    ```bash
    chmod +x lab07-setup.azcli
    ```

1. 在 Cloud Shell 工具栏上，请单击 **“打开编辑器”** （右侧的第二个按钮 - **{ }**）以启用对 lab07-setup.azcli 文件的访问。

1. 在 **“文件”** 列表中，要展开“lab7”文件夹并打开脚本文件，请单击 **“实验室 7”**，然后单击 **“lab07-setup.azcli”**。

    编辑器现在将显示 **“lab07-setup.azcli”** 文件的内容。

1. 在编辑器中，更新 `{your-id}` 和 `{your-location}` 分配的值。

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

1. 要保存对文件所做的更改并关闭编辑器，请单击编辑器窗口右上角的“**...**”，然后单击 **“关闭编辑器”**。

    如果提示保存，请单击 **“保存”**，编辑器将会关闭。

    > **备注：**  可以使用 **Ctrl+S** 随时保存，使用 **Ctrl+Q** 关闭编辑器。

1. 要创建本实验室所需的资源，请输入以下命令：

    ```bash
    ./lab07-setup.azcli
    ```

    运行此脚本可能需要几分钟。每个步骤完成时，你都会看到输出。

    该脚本将首先创建一个名为 **rg-az220** 的资源组和一个名为 **iot-az220-training-{your-id}** 的 IoT 中心。如果它们已经存在，将显示相应的消息。然后，脚本会将 ID 为 **sensor-v-3000** 的设备添加到 IoT 中心并显示设备连接字符串。

1. 请注意，脚本完成后，将显示设备的连接字符串。

    连接字符串以 "HostName=" 开头

1. 将连接字符串复制到文本文档中，请注意，该字符串适用于 **sensor-v-3000** 设备。

    将连接字符串保存到容易找到的位置后，就可以继续进行本实验室了。

### 练习 2：编写代码来生成振动遥测数据

要自动监视 Contoso 的传送带系统并启用预防性维护，同时需要长期数据分析和实时数据分析。由于没有历史数据，因此首先将生成以逼真的方式模拟振动数据和数据异常的模拟数据。Contoso 工程师开发了一种算法来模拟一段时间内的振动情况，并将该算法嵌入到了你将实现的代码类中。工程师同意对调整该算法所需的任何未来更新提供支持。

在初始原型阶段，你将实现单个 IoT 设备来生成遥测数据。除了振动数据，你的设备将创建一些额外的值（运输的包裹、环境温度和类似指标），它们将发送至 Blob 存储。此额外数据将模拟要用于为预防性维护开发机器学习模型的数据。

在本练习中，你将：

* 加载模拟设备项目
* 为模拟设备上传连接字符串，并查看项目代码
* 测试模拟设备连接和遥测通信
* 确保遥测数据到达你的 IoT 中心

#### 任务 1：打开模拟设备项目

1. 打开 **Visual Studio Code**。

1. 在 **“文件”** 菜单上，单击 **“打开文件夹”**。

1. 在 **“打开文件夹”** 对话框中，导航到 **07-Device Message Routing** 文件夹。

    在“实验室 3：_设置开发环境_，你可以通过下载 ZIP 文件并从本地提取内容来克隆包含实验室资源的 GitHub 存储库。提取的文件夹结构包括以下文件夹路径：

    * Allfiles
        * 实验室
            * 07 - 设备消息路由
                * 入门
                    * VibrationDevice

1. 导航到实验室 7 的 **Starter** 文件夹。

1. 单击 **“VibrationDevice”**，然后单击 **“选择文件夹”**。

    你应该会在 Visual Studio Code 的资源管理器窗格中看到以下文件：

    * Program.cs
    * VibrationDevice.csproj

    > **备注：** 如果系统提示加载所需的资产，可现在进行加载。
 
1. 在 **“资源管理器”** 窗格中，单击 **“Program.cs”**。

    粗略地看一下就会发现，**VibrationDevice** 应用程序与前面的实验室中使用的应用程序非常相似。此版本的应用程序使用对称密钥身份验证，将遥测和日志记录消息发送到 IoT 中心，并且具有更复杂的传感器实现。

1. 在 **“终端”** 菜单中，单击 **“新建终端”**。

    检查指示为命令提示符一部分的目录路径，确保你在正确的位置。你无需在上一个实验室项目的文件夹结构中开始构建此项目。
  
1. 在终端命令提示符下，请输入以下命令以验证应用程序版本没有错误：

    ```cmd
    dotnet build
    ```

    输出结果会类似于：

    ```text
    ❯ dotnet build
    Microsoft (R) Build Engine version 16.5.0+d4cbfca49 for .NET Core
    Copyright (C) Microsoft Corporation. All rights reserved.

    Restore completed in 39.27 ms for D:\Az220-Code\AllFiles\Labs\07-Device Message Routing\Starter\VibrationDevice\VibrationDevice.csproj.
    VibrationDevice -> D:\Az220-Code\AllFiles\Labs\07-Device Message Routing\Starter\VibrationDevice\bin\Debug\netcoreapp3.1\VibrationDevice.dll

    Build succeeded.
        0 Warning(s)
        0 Error(s)

    Time Elapsed 00:00:01.16
    ```

在下一个任务中，你将配置连接字符串并查看应用程序。

#### 任务 2：配置连接并查看代码

你在此任务中构建的模拟设备应用将模拟监视传送带的 IoT 设备。该应用将模拟传感器读数并每两秒钟报告一次振动传感器数据。

1. 确保 **Program.cs** 文件已在 Visual Studio Code 中打开。

1. 在 **Program** 类顶部附近，找到 `deviceConnectionString` 变量的声明：

    ```csharp
    private readonly static string deviceConnectionString = "<your device connection string>";
    ```

1. 将 `<your device connection string>` 替换为你之前保存的设备连接字符串。

    > **备注：** 这是你需要对此代码进行的唯一更改。

1. 在 **“文件”** 菜单中，单击 **“保存”**。

1. 花一分钟查看一下项目的结构。

    请注意，该应用程序的结构与之前的模拟设备项目类似：

    * 使用语句
    * 命名空间定义
      * Program 类 - 负责连接到 Azure IoT 并发送遥测
      * ConveyorBeltSimulator 类 -（取代 EnvironmentSensor）该类不仅会生成遥测数据，才会模拟正在运转的传送带。
      * ConsoleHelper - 将编写不同彩色文本封装到控制台的一个新类

1. 花一分钟来查看 **Main** 方法。

    ```csharp
    private static void Main(string[] args)
    {
        ConsoleHelper.WriteColorMessage("Vibration sensor device app.\n", ConsoleColor.Yellow);

        // Connect to the IoT hub using the MQTT protocol.
        deviceClient = DeviceClient.CreateFromConnectionString(deviceConnectionString, TransportType.Mqtt);

        SendDeviceToCloudMessagesAsync();
        Console.ReadLine();
    }
    ```

    看看使用 **deviceConnectionString** 变量创建 **DeviceClient** 的实例是多么的简单。由于 `deviceClient` 对象是在 **Main** 之外声明的（在上述代码的项目级别），因此它是全局的，进而可在与 IoT 中心通信的方法内部使用。

1. 花一分钟来查看 **SendDeviceToCloudMessagesAsync** 方法。

    ```csharp
    private static async void SendDeviceToCloudMessagesAsync()
    {
        var conveyor = new ConveyorBeltSimulator(intervalInMilliseconds);

        // Simulate the vibration telemetry of a conveyor belt.
        while (true)
        {
            var vibration = conveyor.ReadVibration();

            await CreateTelemetryMessage(conveyor, vibration);

            await CreateLoggingMessage(conveyor, vibration);

            await Task.Delay(intervalInMilliseconds);
        }
    }
    ```

    首先，请注意该方法将用于建立无限程序循环，这先是获取振动读数，然后按定义的时间间隔发送消息。 

    更仔细查看可看出 ConveyorBeltSimulator 类用于创建一个名为 `conveyor` 的 ConveyorBeltSimulator 实例。`conveyor`对象先用于捕获振动读数（放置在本地变量`vibration`中），然后与在时间间隔开始时捕获的 `vibration` 值一起传递到两个“创建消息”方法中。 

1. 花一分钟来查看 **CreateTelemetryMessage** 方法。

    ```csharp
    private static async Task CreateTelemetryMessage(ConveyorBeltSimulator conveyor, double vibration)
    {
        var telemetryDataPoint = new
        {
            vibration = vibration,
        };
        var telemetryMessageString = JsonConvert.SerializeObject(telemetryDataPoint);
        var telemetryMessage = new Message(Encoding.ASCII.GetBytes(telemetryMessageString));

        // Add a custom application property to the message. This is used to route the message.
        telemetryMessage.Properties.Add("sensorID", "VSTel");

        // Send an alert if the belt has been stopped for more than five seconds.
        telemetryMessage.Properties.Add("beltAlert", (conveyor.BeltStoppedSeconds > 5) ? "true" : "false");

        Console.WriteLine($"Telemetry data: {telemetryMessageString}");

        // Send the telemetry message.
        await deviceClient.SendEventAsync(telemetryMessage);
        ConsoleHelper.WriteGreenMessage($"Telemetry sent {DateTime.Now.ToShortTimeString()}");
    }
    ```

    在更早的实验室中，此方法会创建一个 JSON 消息字符串，并使用 **Message** 类将消息连同额外的属性一起发送。注意 **sensorID** 属性 - 这将用于在 IoT 中心适当地路由 **VSTel** 值。还要注意 **beltAlert** 属性 - 如果传送带已停止超过 5 分钟，则该属性设置为 true。

    像往常一样，消息是通过设备客户端的 **SendEventAsync** 方法发送的。

1. 花一分钟来查看 **CreateLoggingMessage** 方法。

    ```csharp
    private static async Task CreateLoggingMessage(ConveyorBeltSimulator conveyor, double vibration)
    {
        // Create the logging JSON message.
        var loggingDataPoint = new
        {
            vibration = Math.Round(vibration, 2),
            packages = conveyor.PackageCount,
            speed = conveyor.BeltSpeed.ToString(),
            temp = Math.Round(conveyor.Temperature, 2),
        };
        var loggingMessageString = JsonConvert.SerializeObject(loggingDataPoint);
        var loggingMessage = new Message(Encoding.ASCII.GetBytes(loggingMessageString));

        // Add a custom application property to the message. This is used to route the message.
        loggingMessage.Properties.Add("sensorID", "VSLog");

        // Send an alert if the belt has been stopped for more than five seconds.
        loggingMessage.Properties.Add("beltAlert", (conveyor.BeltStoppedSeconds > 5) ? "true" : "false");

        Console.WriteLine($"Log data: {loggingMessageString}");

        // Send the logging message.
        await deviceClient.SendEventAsync(loggingMessage);
        ConsoleHelper.WriteGreenMessage("Log data sent\n");
    }
    ```

    请注意，此方法与 **CreateTelemetryMessage** 方法很相似。需要注意下面几个要点：

    * **loggingDataPoint** 包含的信息比遥测对象的要多。它通常包含尽可能多的信息来进行日志记录，从而协助将来的任何故障诊断活动或更详细的分析。
    * 日志记录消息包含 **sensorID** 属性，此时设置为 **VSLog**。同样如上所述，这将用于在 IoT 中心适当地路由 **VSLog** 值。

1. （可选）花点时间查看一下 **ConveyorBeltSimulator** 类和 **ConsoleHelper** 类。

    实际上，你不需要了解其中任一类如何发挥作用来实现本实验室的全部价值，它们都以自己的方式为结果提供支持。**ConveyorBeltSimulator** 类会模拟传送带的操作，从而对大量速度和相关状态建模来生成振动数据。 **ConsoleHelper** 用于将不同颜色的文本写入控制台来突出显示不同的数据和值。

#### 任务 3：测试你的代码以发送遥测

1. 在终端命令提示符下，请输入以下命令运行该应用：

    ```bash
    dotnet run
    ```

   此命令将在当前文件夹中运行 **“Program.cs”** 文件。

1. 显示的控制台输出应类似于以下内容：

    ```text
    Vibration sensor device app.

    Telemetry data: {"vibration":0.0}
    Telemetry sent 10:29 AM
    Log data: {"vibration":0.0,"packages":0,"speed":"stopped","temp":60.22}
    Log data sent

    Telemetry data: {"vibration":0.0}
    Telemetry sent 10:29 AM
    Log data: {"vibration":0.0,"packages":0,"speed":"stopped","temp":59.78}
    Log data sent
    ```

    > **备注：**  在“终端”窗口中，绿色文本表示工作正常，红色文本表示工作异常。如果收到错误消息，请先检查设备连接字符串。

1. 让此应用继续运行下一个任务。

    如果你不会继续执行下一个任务，则可以在终端窗口中输入 **Ctrl-C** 停止该应用。你可以稍后使用 `dotnet run` 命令再次启动它。

#### 任务 4：验证 IoT 中心正在接收遥测

在本任务中，你将使用 Azure 门户来验证 IoT 中心是否在接收遥测数据。

1. 打开 “Azure 门户”[](https://portal.azure.com)

1. 在“资源”磁贴上，单击 **“iot-az220-training-{your-id}”**。

1. 在 **“概述”** 窗格中，向下滚动以查看指标磁贴。

1. 毗邻 **“显示最后的数据”**，将时间范围更改为一小时。 

    **“设备到云消息”** 磁贴应该正在绘制一些当前活动。如果未显示任何活动，请稍等片刻，因为存在一些延迟。

    设备发出遥测数据且中心接收它后，下一步是将消息路由到正确的终结点。

### 练习 3：创建到 Azure Blob 存储的消息路由

IoT 解决方案通常要求传入的消息数据根据数据类型或出于业务理由被发送到多个终结点位置。Azure IoT 中心提供了消息路由__功能，它可用它来将传入的数据定向到你的解决方案所需的位置。

我们的系统的体系结构要求将数据发送到两个目标：用于存档数据的存储位置和用于更直接分析的位置。 

Contoso 的振动监视方案要求你创建两条消息路由：

* 第一条路由将指向 Azure Blob 存储位置进行数据存档
* 第二条路由将指向 Azure 流分析作业进行实时分析

一次应生成和测试一条消息路由，因此本练习将重点介绍存储路由。此路由将被称为“日志记录”路由，它涉及到较深入地了解如何创建 Azure 资源。

消息路由的一个重要特征是能够在路由到终结点之前筛选传入的数据。仅当满足某些条件时，编写为 SQL 查询的筛选器才会沿路由定向输出。

要筛选数据，最简单的方法之一是评估消息属性。你可能记得在上一练习中向你的设备消息添加了消息属性。你当时添加的代码如下所示：

```csharp
...
telemetryMessage.Properties.Add("sensorID", "VSTel");
...
loggingMessage.Properties.Add("sensorID", "VSLog");
```

现在，你可在使用 `sensorID` 作为路由条件的消息路径中嵌入一个 SQL 查询。在本例中，当分配给 `sensorID` 的值为 `VSLog` （振动传感器日志），则消息用于存储存档。

在本练习中，你将创建并测试日志记录路由。

#### 任务 1：定义消息路由终结点

1. 在 [Azure 门户](https://portal.azure.com/)中，确保 IoT 中心边栏选项卡已打开。

1. 在左侧菜单上的 **“消息传递”** 下，单击 **“消息路由”**。

1. 在 **“消息路由”** 窗格中，确保选择 **“路线”** 选项卡。

1. 若要添加新路由，请单击 **“+ 添加”**。

    现在应会显示 **“添加路由”** 边栏选项卡。

1. 在 **“添加路由”** 边栏选项卡的 **“名称”** 下，输入 **“vibrationLoggingRoute”**

1. 在 **“终结点”** 的右侧，单击 **“+ 添加终结点”**，然后在下拉列表中单击 **“存储”**。

    现在应会显示 **“添加存储终结点”** 边栏选项卡。

1. 在 **“添加存储终结点”** 边栏选项卡的 **“终结点名称”** 下，输入 **“vibrationLogEndpoint”**

1. 若要显示与你的订阅关联的存储帐户列表，请单击 **“选择容器”**。

    已列出 Azure 订阅中已存在的存储帐户列表。此时，你可以选择现有的存储帐户和容器，但对于本实验室，你将创建新的帐户和容器。

1. 若要开始创建存储帐户，请单击 **“+ 存储帐户”**。

    此时应会显示 **“创建存储帐户”** 边栏选项卡。

1. 在 **“创建存储帐户”** 边栏选项卡的 **“名称”** 下，输入 **“vibrationstore{your-id}”**

    例如： **vibrationstorecah191211**

    > **备注：**  此字段只能包含小写字母和数字，必须介于 3-24 个字符之间，并且必须是唯一的。

1. 在 **“帐户类型”** 下拉列表中，选择 **“StorageV2 (常规用途 v2)”**。

1. 在 **“性能”** 列表中选中 **“标准”**。

    这样可以降低成本，但整体性能会减弱。

1. 在 **“复制”** 选项下，确保 **“本地 - 冗余存储 (LRS)”** 已选定。

    这样可以降低成本，但有降低缓解灾难恢复能力的风险。在生产中，你的解决方案可能需要更强大的复制策略。

1. 在 **“位置”** 列表中，选择用于本课程中的实验的区域。

1. 若要创建存储帐户终结点，请单击 **“确定”**。

1. 等待直到请求通过验证并且存储帐户部署已完成。

    验证和创建可能需要一两分钟。

    完成后，**“创建存储帐户”** 边栏选项卡将关闭，并将显示 **“存储帐户”** 边栏选项卡。“存储帐户”边栏选项卡应该已自动更新为显示刚刚创建的存储帐户。

#### 任务 2：定义存储帐户容器

1. 在 **“存储帐户”** 边栏选项卡上，单击 **“vibrationstore{your-id}”**。

    此时应会显示 **“容器”** 边栏选项卡。这是一个新的存储帐户，因此未列出任何容器。

1. 要创建容器，请单击 **“+ 容器”**。

    此时应会显示 **“新建容器”** 对话框。

1. 在 **“新建容器”** 对话框的 **“名称”** 下，输入 **vibrationcontainer**

   同样，仅接受小写字母和数字。

1. 在 **“公共访问级别”** 下，确保选择 **“专用(不允许匿名访问)”**。

1. 要创建容器，请单击 **“创建”**。

    稍后，容器的 **“租用状态”** 将更新显示 **“可用”**。

1. 要为你的解决方案选择此容器，请单击 **“vibrationcontainer”**，然后单击 **“选择”**。

    你应会返回到 **“添加存储终结点”** 边栏选项卡。请注意，**Azure 存储容器** 已设置为你刚刚创建的存储帐户和容器的 URL。

1. 将 **“批处理频率”** 和 **“块大小窗口”** 字段保留为默认值 **100**。

1. 在 **“编码”** 下，注意有两个选项，并且已选中 **“AVRO”**。

    > **备注：**  默认情况下，IoT 中心以 Avro 格式写入内容，该格式同时具有消息正文属性和消息属性。Avro 格式不用于任何其他终结点。尽管 Avro 格式可用于保存数据和消息，但将其用于查询数据将是一项挑战。比较而言，JSON 或 CSV 格式更容易用来查询数据。IoT 中心现在支持使用 JSON 和 AVRO 格式将数据写入 Blob 存储。

1. 花点时间检查一下 **“文件名格式”** 字段中指定的值。

    **“文件名格式”** 字段指定用于将数据写入存储中的文件中的模式。创建文件时，将各个令牌替换为值。

1. 在边栏选项卡的底部，单击 **“创建”** 可创建存储终结点。

    验证和后续创建将需要一些时间。完成后，你应会回到 **“添加路由”** 边栏选项卡。

#### 任务 3：定义路由查询

1. 在 **“添加路由”** 边栏选项卡的 **“数据源”** 下，确保选中 **“设备遥测消息”**。

1. 在 **“启用路由”** 选项下， 确保 **“启用”** 已选定。

1. 在 **“路由查询”** 下，将 **true** 替换为以下查询：

    ```sql
    sensorID = 'VSLog'
    ```

    此查询确保只有应用程序属性 `sensorID` 设置为 `VSLog` 的消息将路由到存储终结点。

1. 要保存此路由，请单击 **“保存”**。

    等待成功消息。完成后，**“消息路由”** 窗格上应会列出该路由。

1. 导航回到 Azure 门户仪表板。

#### 任务 4：验证数据存档

1. 确保你在 Visual Studio Code 中创建的设备应用仍在运行。 

    如果未运行，请使用 `dotnet run` 在 Visual Studio Code 终端运行它。

1. 在“资源”磁贴上，单击 **vibrationstore{your-id}** 打开存储帐户边栏选项卡。

    如果“资源”磁贴没有列出你的存储帐户，请单击资源组磁贴顶部的 **“刷新”** 按钮，然后按照上述说明打开你的存储帐户。

1. 在 **vibrationstore{your-id}** 边栏选项卡的左侧菜单中，单击 **“存储资源管理器(预览版)”**。

    可使用存储资源管理器来验证数据是否正在添加到存储帐户。 

    > **备注：**  存储资源管理器当前处于预览模式，因此其确切的操作模式可能会更改。

1. 在 **“存储资源管理器(预览版)”** 窗格中，展开 **“BLOB 容器”**，然后单击 **“vibrationcontainer”**。

    要查看数据，你需要向下浏览文件夹的层次结构。第一个文件夹将针对 IoT 中心进行命名。 

1. 在右侧窗格的 **“名称”** 下，双击 **iot-az220-training-{your-id}**，然后双击向下导航到层次结构。

    在“IoT 中心”文件夹下，你将看到关于分区的文件夹，再是关于年份、月份和日期数字值的文件夹。最后一个文件夹表示“小时”，它按 UTC 时间列出。“小时”文件夹中将有大量的块 Blob，其中包含日志记录消息数据。 

1. 双击块 Blob可查看具有最早时间戳的数据。

    URL 链接将在新的浏览器标签页中打开。虽然数据的格式使得它不容易阅读，但你应能够将它识别为你的振动消息。 

1. 关闭包含你的数据的浏览器标签页，然后导航回到你的 Azure 门户仪表板。

### 练习 4：日志记录路由 Azure 流分析作业

在此练习中，你将创建一个流分析作业来将日志记录消息输出到 Blob 存储。然后，你将使用 Azure 门户中的存储资源管理器来查看存储的数据。

这样，你将能够验证你的路由是否包括以下设置：

* **名称** - 振动日志记录路由
* **数据源** - 设备消息
* **路由查询** - sensorID = 'VSLog'
* **终结点** - vibrationLogEndpoint
* **已启用** - true

> **备注：** 在本实验室中，你将数据路由到存储，然后再通过 Azure 流分析将数据发送到存储，这似乎很奇怪。在生产场景中，这两条路径不会长期存在。事实上，我们在此处创建的第二条路径很可能不存在。在实验室环境中，你将使用这种方法来验证你的路由是否正常工作，并展示 Azure 流分析的简单实现。

#### 任务 1：创建流分析作业

1. 在 Azure 门户菜单上，单击 **“+ 创建资源”**。

1. 在 **“新建”** 边栏选项卡上的 **“搜索市场”** 文本框中，键入 **“流分析”**，然后单击 **“流分析作业”**。

1. 在 **“流分析作业”** 边栏选项卡上，单击 **“创建”**。

    显示 **“新建流分析作业”** 窗格。

1. 在 **“新建流分析作业”** 窗格的 **“名称”** 下，输入 **“vibrationJob”**。

1. 在 **“订阅”** 下，选择将在本实验室中使用的订阅。

1. 在 **“资源组”** 下，选择 **rg-az220**。

1. 在 **“位置”** 列表中，选择用于本课程中的实验的区域。

1. 在 **“托管环境”** 下，确保选中 **“云”**。

    Edge 托管将在本课程的后面部分讨论。

1. 在 **“流单元数”** 下，将数量从 **3** 减少到 **1**。

    本实验室不需要 3 个单元，此操作可降低成本。

1. 要创建流分析作业，请单击 **“创建”**。

1. 等待 **“部署成功”** 消息，然后打开新资源。

    > **提示：** 如果你错过了转到新资源的消息，或者需要随时查找资源，请选择 **“主页/所有资源”**。输入充分的资源名称，使其显示在资源列表中。

1. 花点时间检查新的流分析作业。

    请注意，你有一个不显示任何输入或输出的空作业以及一个框架查询。下一步是填充这些条目。

1. 在左侧菜单的 **“作业拓扑”** 下，单击 **“输入”**。

    这将显示 **“输入”** 窗格。

1. 在 **“输入”** 窗格中，单击 **“+ 添加流输入”**，然后单击 **“IoT 中心”**。

    这将显示 **“IoT 中心 - 新输入”** 窗格。

1. 在 **“IoT 中心 - 新输入”** 窗格的 **“输入别名”** 中输入 `vibrationInput`。

1. 选中 **“从你的订阅中选择 IoT 中心”**。

1. 请确保在 **“订阅”** 中选中你先前用于创建 IoT 中心的订阅。

1. 在 **“IoT 中心”** 下，确保已选择 IoT 中心 **iot-az220-training-{your-id}**。

1. 在“**使用者组**”下，确保选择 **$Default**。

1. 在 **“共享访问策略名称”** 中，确保选中 **iothubowner**。

    > **备注：** **“共享访问策略密钥”** 已填充且为只读。

1. 在“**终结点**”中选中“**消息传送**”。

1. 在 **“事件序列化格式”** 选项下， 确保 **“JSON”** 已选定。

1. 在 **“编码”** 选项下， 确保 **“UTF-8”** 已选定。

    你可能需要向下滚动才能看到某些字段。

1. 在 **“事件压缩类型”** 下，确保选择 **“无”**。

1. 要保存新输入，请单击 **“保存”**，然后等待输入创建完毕。

   **“输入”** 列表应更新为显示新输入。

1. 要创建输出，请在左侧菜单的 **“作业拓扑”** 选项下，单击 **“输出”**。

    将显示 **“输出”** 窗格。

1. 在“**输出**”窗格，单击“**+ 添加**”，然后单击“**Blob 存储/ADLS Gen2**”。

    “**Blob 存储/ADLS Gen2 - 新输出**”窗格随即显示。

1. 在“**Blob 存储/ADLS Gen2 - 新输出**”窗格上，在“**输出别名**”下输入 `vibrationOutput`。

1. 确保已选择“**从订阅中选择 Blob 存储/ADLS Gen2**”。

1. 在 **“订阅”** 下，选择你为本实验室使用的订阅。

1. 在 **“存储帐户”** 下，单击 **“vibrationstore{your-id}”**。

1. 在“**容器**”下，确保选择了“**使用现有容器**”，并从下拉列表中选择了“**振动容器**”。

1. 在“**身份验证模式**”下，确保已选择“**连接字符串**”。

    > **备注**：  “**存储帐户密钥**”将自动填充且为只读。

1. 将“**路径模式**”保留为空。

1. 将“**日期格式**”和“**时间格式**”保留为各自的默认值。

1. 在“**事件序列化格式**”选项下， 确保“**JSON**”已选定。

1. 在 **“格式”** 下，确保选择 **“按行分隔”**。

1. 在“**编码**”下，确保选择“**UTF-8**”。

    > **备注**：  此设置将每条记录整体作为一个 JSON 对象存储在每行上，最终导致文件是一个无效的 JSON 记录。另一个选项“**数组**”可确保将整个文档格式化为 JSON 数组，其中每条记录都是数组中的一项。这样就可以将整个文件解析为有效的 JSON。

1. 将“**最小行数**”保留为空白。

1. 将“**最长时间**”下的“**小时**”和“**分钟**”保留为空白。

1. 要创建输出，请单击 **“保存”**，然后等待输出创建完毕。

    使用新输出更新**输出**列表。

1. 要编辑查询，请在左侧菜单的 **“作业拓扑”** 下，单击 **“查询”**。

1. 在“查询编辑器”窗格中，将现有查询替换为以下查询：

    ```sql
    SELECT
        *
    INTO
        vibrationOutput
    FROM
        vibrationInput
    ```

1. 直接在查询编辑器窗格上方，单击 **“保存查询”**。

1. 在左侧菜单上，单击 **“概述”**。

#### 任务 2：测试日记记录路线

现在这一部分非常有趣。你的设备应用抽取出的遥测数据是否会按照路由进行工作并发送到存储容器？

1. 确保你在 Visual Studio Code 中创建的设备应用仍在运行。 

    如果未运行，请使用 `dotnet run` 在 Visual Studio Code 终端运行它。

1. 在流分析作业的 **“概述”** 窗格中，单击 **“开始”**。

1. 在 **“开始作业”** 窗格中，将 **“作业输出开始时间”** 保留设置为 **“立即”**，然后单击 **“开始”**。

    可能需要一些时间才能开始作业

1. 在“Azure 门户中心”菜单上，单击 **“仪表板”**。

1. 在“资源”磁贴上，单击 **“vibrationstore{your-id}”**。

    如果看不到你的存储帐户，请使用资源组图块顶部的 **“刷新”** 按钮。

1. 在存储帐户的 **“概览”** 窗格中，向下滚动直至看到 **“监控”** 部分。

1. 在 **“监控”** 下的 **“显示上次的数据”** 旁边，将时间范围更改为 **“1 小时”**。

    你应在图表中看到活动。

1. 在左侧菜单上，单击 **“存储资源管理器(预览版)”**。

    可使用存储资源管理器进一步确保你的所有数据都将进入存储帐户。 

    >  **备注：** 存储资源管理器当前处于预览模式，因此其确切的操作模式可能会更改。

1. 在 **“存储资源管理器(预览版)”** 的 **“BLOB 容器”** 下，单击  **vibrationcontainer**。

    要查看数据，你需要向下浏览文件夹的层次结构。第一个文件夹将以 IoT 中心命名，下一个文件夹将是分区，然后是年、月、日，最后是小时。 

1. 在右侧窗格的 **“名称”** 下，双击 IoT 中心的文件夹，然后继续双击以向下导航到层次结构，直到打开最新的小时文件夹。

    在小时文件夹中，你将看到以文件生成时的分钟命名的文件。这会验证你的数据是否按预期到达存储位置。

1. 导航回到你的仪表板。

1. 在“资源”磁贴上，单击 **“vibrationJob”**。

1. 在 **“vibrationJob”** 边栏选项卡中，依次单击 **“停止”** 和 **“是”**。

    你已通过设备应用-中心-路由-存储容器跟踪活动。进展很大！在下一个模块（即快速查看数据可视化）中，你将继续此方案的流分析。

1. 切换到 Visual Studio Code 窗口。

1. 在终端命令提示符下，要退出设备模拟器应用，请按  **CTRL-C**。

> **重要说明**： 在完成本课程的数据可视化模块之前，请勿删除这些资源。
