---
lab:
  title: 实验室 09：将 IoT 中心与事件网格集成
  module: 'Module 5: Insights and Business Integration'
ms.openlocfilehash: 85c57fcbf64a6b20636b0ef289d634ef09e9c292
ms.sourcegitcommit: eec2943250f1cd1ad2c5202ecbb9c37af71e8961
ms.translationtype: HT
ms.contentlocale: zh-CN
ms.lasthandoff: 03/24/2022
ms.locfileid: "140872835"
---
# <a name="integrate-iot-hub-with-event-grid"></a>将 IoT 中心与事件网格集成

## <a name="lab-scenario"></a>实验室场景

你使用 Azure IoT 服务创建的原型解决方案给 Contoso 管理层留下了深刻印象，并且他们愿意为你所演示的功能分配额外预算。 他们现在要求你尝试集成某些运营支持功能。 具体来说，他们希望了解 Azure 工具如何支持向负责特定工作区域的经理发送警报通知。 警报条件将由业务区域经理定义。 到达 IoT 中心的遥测数据将被评估以生成通知。

你已经确定一位过去曾与之成功合作过的业务经理 Nancy。 在解决方案的初始阶段，你将与她合作。

Nancy 告知你，她的设备技术员团队将负责安装新的联网恒温器，用于监视不同干酪储藏室的温度。 恒温器设备用作可连接到 IoT 中心的 IoT 设备。 要启动项目，你需要同意创建一个在实现新设备后能够生成通知的警报。

要生成警报，需要在 IoT 中心创建新恒温器设备时将一个设备创建的事件类型推送到事件网格。 你将创建一个逻辑应用实例，用来（在事件网格上）对此事件做出响应，并在创建新设备时发送电子邮件到警报设施，用以指定设备 ID 和连接状态。

将创建以下资源：

![实验室 9 基础结构](media/LAB_AK_09-architecture.png)

## <a name="in-this-lab"></a>本实验室概览

在本实验室中，你将完成以下活动：

* 配置实验室先决条件（所需的 Azure 资源）
* 创建用于发送电子邮件的逻辑应用
* 配置 Azure IoT 中心事件订阅
* 新建设备以触发逻辑应用

### <a name="exercise-1-configure-lab-prerequisites"></a>练习 1：配置实验室先决条件

本实验室假定以下 Azure 资源可用：

| 资源类型  | 资源名称          |
|----------------|------------------------|
| 资源组 | rg-az220              |
| IoT 中心        | iot-az220-training-{your-id} |

若要确保这些资源可用，请完成以下步骤。

1. 在虚拟机环境中，打开 Microsoft Edge 浏览器窗口，然后导航到以下 Web 地址：
 
    +++https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FMicrosoftLearning%2FAZ-220-Microsoft-Azure-IoT-Developer%2Fmaster%2FAllfiles%2FARM%2Flab09.json+++

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

现已创建资源。

>**注意**：你可能需要注册 microsoft.eventgrid 资源提供程序，本实验室才能成功。 运行以下命令进行检查：

```bash
az provider show --namespace microsoft.eventgrid -o tsv
```
> 如果结果显示“Registered”，则无需执行更多操作。 如果显示“NotRegistered”，请运行以下命令，注册 microsoft.eventgrid 提供程序。

```bash
az provider register --namespace microsoft.eventgrid
```
> 这可能需要 15 分钟或更长时间才能完成。 你应看到以下消息：

```bash
Registering is still on-going. You can monitor using 'az provider show -n microsoft.eventgrid'
```

### <a name="exercise-2-create-http-web-hook-logic-app-that-sends-an-email"></a>练习 2：创建发送电子邮件的 HTTP Webhook 逻辑应用

Azure 逻辑应用是一种云服务，当你需要跨企业或组织集成应用、数据、系统和服务时，可帮助你计划、自动执行和编排任务、业务流程和工作流。

在本练习中，你将新建一个通过 HTTP Webhook 触发的 Azure 逻辑应用，然后使用 Outlook.com 电子邮件地址发送电子邮件。

#### <a name="task-1-create-a-logic-app-resource-in-the-azure-portal"></a>任务 1：在 Azure 门户中创建逻辑应用资源

1. 如有必要，使用你在本课程中使用的 Azure 帐户凭据登录到 [Azure 门户](https://portal.azure.com)。

    如果有多个 Azure 帐户，请确保使用与本课程要使用的订阅绑定的帐户登录。

1. 在 Azure 门户菜单上，单击“+ 创建资源”。

1. 在“创建资源”边栏选项卡上，在“搜索服务和市场”框中输入“逻辑应用”  

1. 在搜索结果中，单击“逻辑应用”.

1. 在““逻辑应用””边栏选项卡中，单击““创建””。

1. 在“基本”选项卡中的“项目详细信息”下，选择本课程所使用的“订阅”。

1. 在“资源组”下拉菜单中的“选择现有”下，单击“rg-az220”。

1. 在“实例详细信息”下的“类型”下，选择“消耗”  。

1. 在“名称”字段中，输入 logic-az220-training-{your-id} 

    例如：logic-az220-training-cp191218

    Azure 逻辑应用的名称必须具有全球唯一性，因为它是可公开访问的资源，必须能够从任何 IP 连接的设备访问。

1. 在“区域”下拉列表中，选择用于资源组的同一 Azure 区域。

1. 保留“启用 Log Analytics”设置为“否” 。

1. 单击“查看 + 创建”  。

1. 在“查看 + 创建”选项卡中，单击“创建”。

    > **注意**：逻辑应用部署需要一到两分钟才能完成。

1. 导航回到 Azure 门户仪表板。

#### <a name="task-2-configure-your-logic-app"></a>任务 2：配置你的逻辑应用。

1. 在资源组磁贴上，单击指向刚刚部署的逻辑应用资源的链接。

    如果未显示“logic-az220-training-{your-id}”逻辑应用，请刷新资源组磁贴。

    > **注意**：首次导航到“逻辑应用”时，系统将显示“逻辑应用设计器”窗格 。 如果此页面没有自动显示，请单击“逻辑应用”边栏选项卡上“开发工具”部分下面的“逻辑应用设计器”。

1. 在“从常见触发器开始”部分下，单击“收到 HTTP 请求时”。

    开始使用逻辑应用时，从常用触发器开始会更便捷。

1. 请注意，视觉设计器打开时，“收到 HTTP 请求时”触发器默认已选择。

1. 在“收到 HTTP 请求时”触发器上，在“请求正文 JSON 架构”文本框下方，单击“使用样本有效负载生成架构”链接。

    > **注意**：在下一步中，将向“请求正文 JSON 架构”文本框添加“DeviceCreated”示例事件架构。 如需了解更多信息，可以通过下面的链接获取该事件架构示例以及其他示例和相关文档：[用于 IoT 中心的 Azure 事件网格事件架构](https://docs.microsoft.com/en-us/azure/event-grid/event-schema-iot-hub)。

1. 使用复制并粘贴操作将以下示例 JSON 添加到“输入或粘贴示例 JSON 有效负载。” 文本框，然后单击“完成”。

    ```json
    [{
      "id": "56afc886-767b-d359-d59e-0da7877166b2",
      "topic": "/SUBSCRIPTIONS/<subscription ID>/RESOURCEGROUPS/<resource group name>/PROVIDERS/MICROSOFT.DEVICES/IOTHUBS/<hub name>",
      "subject": "devices/LogicAppTestDevice",
      "eventType": "Microsoft.Devices.DeviceCreated",
      "eventTime": "2018-01-02T19:17:44.4383997Z",
      "data": {
        "twin": {
          "deviceId": "LogicAppTestDevice",
          "etag": "AAAAAAAAAAE=",
          "deviceEtag": "null",
          "status": "enabled",
          "statusUpdateTime": "0001-01-01T00:00:00",
          "connectionState": "Disconnected",
          "lastActivityTime": "0001-01-01T00:00:00",
          "cloudToDeviceMessageCount": 0,
          "authenticationType": "sas",
          "x509Thumbprint": {
            "primaryThumbprint": null,
            "secondaryThumbprint": null
          },
          "version": 2,
          "properties": {
            "desired": {
              "$metadata": {
                "$lastUpdated": "2018-01-02T19:17:44.4383997Z"
              },
              "$version": 1
            },
            "reported": {
              "$metadata": {
                "$lastUpdated": "2018-01-02T19:17:44.4383997Z"
              },
              "$version": 1
            }
          }
        },
        "hubName": "egtesthub1",
        "deviceId": "LogicAppTestDevice"
      },
      "dataVersion": "1",
      "metadataVersion": "1"
    }]
    ```

    此示例 JSON 是在创建逻辑应用后，事件网格将为逻辑应用发布到 Webhook 终结点的 JSON 示例。 该示例包括将发送遥测消息的 IoT 设备的 IoT 中心消息遥测属性。

1. 请注意“请求正文 JSON 架构”文本框中现已填充基于你提供的示例 JSON 自动生成的 JSON 架构。

1. 在“收到 HTTP 请求时”触发器下方，单击“+ 新建步骤”。

1. 在“选择动作”下方的搜索文本框中，输入“Outlook.com”

1. 在“操作”列表中，向下滚动到“发送”选项，然后单击“发送电子邮件 (V2)”。

    > **注意**：这些说明介绍了如何将逻辑应用配置为使用“Outlook.com”电子邮件地址发送电子邮件。 此外，也可以将逻辑应用配置为使用 Office 365 Outlook 或 Gmail 连接器发送电子邮件。

1. 在“Outlook.com”连接器上，单击“登录”，然后按照提示使用现有 Outlook.com 帐户进行身份验证。

1. 如果提示“允许此应用访问你的个人信息”，单击“是”。

1. 在“发送电子邮件(V2)”操作的“收件人”字段中，输入要发送到的电子邮件地址。

    出于本实验的目的，你需要提供一个电子邮件地址，以便接收电子邮件通知。 你可以输入用于此连接器的 Outlook.com 帐户，也可以输入其他易于访问的电子邮件帐户。

    将使用上一步中经过身份验证的 Outlook.com 帐户发送电子邮件。

1. 在“主题”字段中，输入“IoT 中心警报：”

1. 在“正文”字段中，输入以下消息内容：

    ```text
    This is an automated email to inform you that:

    {eventType} occurred at {eventTime}

    IoT Hub: {hubName}
    Device ID: {deviceID}
    Connection state: {connectionState}
    ```

1. 花点时间检查你刚刚输入的消息正文。

    你可能已经意识到，大括号条目旨在表示动态内容。 你需要用实际的动态内容值替换这些占位符条目。

    > **注意**：如果连接器右侧未显示“添加动态内容”工具，请单击“正文”文本框正下方的“添加动态内容”超链接。 如果未列出你需要的字段，请单击“动态内容”窗格中的“查看更多”，以包括你输入的消息正文中包含的字段。

    在下一步中，将每个占位符值替换为相应的动态内容值。

1. 对于每个动态内容占位符，删除该条目，然后将其替换为相应的“动态内容”字段。

    在添加第一个动态内容值时，由于输入数据架构是针对数组的，因此逻辑应用设计器会自动将电子邮件操作更改为嵌套在“对于每个”操作中。 出现这种情况时，**发送电子邮件 (V2)** 操作会折叠。 要重新打开电子邮件，请单击“发送电子邮件 (V2)”，然后继续编辑消息正文。

    完成此步骤后，你会看到类似于以下内容的消息正文：

    ![填写电子邮件信息](./media/LAB_AK_09-email_content.png)

1. 要将所有更改保存到逻辑应用工作流，单击设计器顶部的“保存”。

1. 要展开“收到 HTTP 请求时”触发器，请单击“收到 HTTP 请求时”。

1. 复制“HTTP POST URL”的显示值。

    “HTTP POST URL”类似于以下内容：

    ```text
    https://prod-87.eastus.logic.azure.com:443/workflows/b16b5556cbc54c97b063479ed55b2669/triggers/manual/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=ZGqYl-R5JKTugLG3GR5Ir1FuM0zIpCrMw4Q2WycJRiM
    ```

    该 URL 是用于通过 HTTPS 调用逻辑应用触发器的 Webhook 终结点。 注意“sig”查询字符串参数及其值。 sig 参数包含用于对 Webhook 终结点的请求进行身份验证的共享访问密钥。

1. 保存该 URL，以备将来参考。

### <a name="exercise-3-configure-azure-iot-hub-event-subscription"></a>练习 3：配置 Azure IoT 中心事件订阅

通过将 Azure IoT 中心与 Azure 事件网格进行集成，使你可以向其他服务发送事件通知，并触发下游流程。 你可以将业务应用程序配置为侦听 IoT 中心事件，以便以可靠、可缩放和安全的方式对关键事件做出反应。  例如，生成一个应用程序来更新数据库、创建工作票证，并在每当有新的 IoT 设备注册到 IoT 中心时，发送一封电子邮件通知。

在本练习中，你将在 Azure IoT 中心内创建事件订阅以设置事件网格集成，用来触发逻辑应用发送警报电子邮件。

1. 导航回到 Azure 门户仪表板。

1. 在资源组磁贴上，要导航到 IoT 中心，请单击“iot-az220-training-{your-id}”。

1. 在“IoT 中心”边栏选项卡的左侧导航菜单上，单击“事件”。

1. 在“事件”窗格顶部，单击“+ 事件订阅”。

1. 在“创建事件订阅”边栏选项卡的“名称”字段内，输入“MyDeviceCreateEvent”

1. 确保将“EventSchema”字段设为“事件网格架构”。

1. 在“主题详情”下，输入 myDeviceTopic-{your-id} 

1. 在“事件类型”选项下， 打开“按事件类型筛选”下拉列表，然后取消选择除“已创建设备”之外的所有选择。

1. 在“终结点详细信息”选项下， 打开“终结点类型”下拉列表，然后单击“Web Hook”。

1. 在“终结点详细信息”下，单击“选择终结点”。

1. 在“选择 Webhook”窗格中的“订阅者终结点”下，粘贴你从逻辑应用复制的 URL，然后单击“确认选择”。

    > **重要说明**：不要单击“创建”！

    可在此处保存事件订阅，并接收针对 IoT 中心内创建的每个设备发送的通知。 但是，我们将在本实验室中使用可选字段筛选特定设备。

1. 在窗格顶部，单击“筛选器”。

    你将使用筛选器来筛选特定设备。

1. 在“高级筛选器”下，单击“新增筛选器”，然后使用以下值填充字段：

    * **密钥**：输入 `Subject`

    * **运算符**：选择 `String begins with`

    * **值**：输入 `devices/sensor-th`

    我们将使用该值来筛选与奶酪储藏室温度和湿度传感器相关的设备事件。

1. 要保存事件订阅，请单击“创建”。

### <a name="exercise-4-test-your-logic-app-with-new-devices"></a>练习 4:使用新设备测试逻辑应用

新建设备来触发事件通知电子邮件，从而测试逻辑应用。

1. 在 Azure 门户中，按需导航到“IoT 中心”边栏选项卡。

1. 在左侧导航菜单的“设备管理”下，单击“设备” 。

1. 在“IoT 设备”边栏选项卡顶部，单击“+ 新建”。

1. 在“设备 ID”字段中，输入“sensor-th-0050” 

1. 保留所有其他字段的默认值，然后单击“保存”。

1. 要测试事件订阅筛选器，请使用以下设备 ID 创建其他设备：

    * `sensor-v-3002`
    * `sensor-th-0030`
    * `sensor-v-3003`

    如果总共添加了四个示例，则 IoT 设备列表应如下图所示：

    ![IoT 中心设备列表](./media/LAB_AK_09-iot-hub-device-list.png)

1. 将一些设备添加到 IoT 中心后，请检查电子邮件，确定哪些设备触发了逻辑应用。
