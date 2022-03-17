---
lab:
  title: 实验室 19：开发 Azure 数字孪生 (ADT) 解决方案
  module: 'Module 11: Develop with Azure Digital Twins'
ms.openlocfilehash: 654a98a8b7affffb99e1c88a6c1c9c5a32546488
ms.sourcegitcommit: 7874419a1f0f346f972914893b4b3644ba84a267
ms.translationtype: HT
ms.contentlocale: zh-CN
ms.lasthandoff: 03/04/2022
ms.locfileid: "139262460"
---
# <a name="develop-azure-digital-twins-adt-solutions"></a>开发 Azure 数字孪生 (ADT) 解决方案

## <a name="lab-scenario"></a>实验室场景

Contoso 管理层决定在他们的数字化发展进程中迈出新的一步，利用 Azure 数字孪生 (ADT) 为他们的奶酪制作设施开发模型。 利用 Azure 数字孪生，可以创建真实环境的实况模型并与之交互。 首先，将每个单独的元素建模为一个数字孪生。 然后将它们连接到一个知识图，该图可以响应实时事件并用于查询信息。

为了更好地理解如何以最佳方式利用 ADT，公司要求你构建一个概念验证原型，展示如何将现有的奶酪储藏室设备传感器遥测合并到一个简洁的模型层次结构中：

* 奶酪工厂
* 奶酪储藏室
* 奶酪储藏室设备

公司要求你通过这第一个原型来展示以下场景的解决方案：

* 如何将设备遥测从 IoT 中心映射到 ADT 中的适当设备
* 如何使用子级数字孪生属性的更新来更新父级孪生属性（从奶酪储藏室设备到奶酪储藏室）
* 如何通过 ADT 将设备遥测路由到时序见解

将创建以下资源：

![实验室 19 基础结构](media/LAB_AK_19-architecture.png)

## <a name="in-this-lab"></a>本实验室概览

在本实验室中，你将完成以下活动：

* 配置实验室先决条件（所需的 Azure 资源）
* 创建和配置数字孪生体
  * 使用提供的 DTDL 来创建数字孪生
  * 使用数字孪生实例生成 ADT 图
* 实现 ADT 图交互（ADT Explorer)
  * 查询 ADT 图
  * 更新图中 ADT 实体上的属性
* 将 ADT 与上游和下游系统集成
  * 引入 IoT 设备消息并将消息转换为 ADT
  * 配置 ADT 路由和终结点，用于将遥测发布到时序见解 (TSI)

## <a name="lab-instructions"></a>实验室说明

### <a name="exercise-1---configure-lab-prerequisites"></a>练习 1 - 配置实验室先决条件

#### <a name="task-1---create-resources"></a>任务 1 - 创建资源

本实验室假定以下 Azure 资源可用：

| 资源类型  | 资源名称                |
| :------------- | :--------------------------- |
| 资源组 | rg-az220                     |
| IoT 中心        | iot-az220-training-{your-id} |
| TSI            | tsi-az220-training-{your-id} |
| TSI 访问策略 | access1                   |

若要确保这些资源可用，请完成以下步骤。

1. 在虚拟机环境中，打开 Microsoft Edge 浏览器窗口，然后导航到以下 Web 地址：
 
    +++https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FMicrosoftLearning%2FAZ-220-Microsoft-Azure-IoT-Developer%2Fmaster%2FAllfiles%2FARM%2Flab19.json+++

    > 注意：每当看到绿色的“T”符号（例如+++输入此文本+++）时，可以单击关联的文本，信息将键入到虚拟机环境内的当前字段中。

1. 如果系统提示登录到 Azure 门户，请输入将要用于本课程的 Azure 凭据。

    将显示“自定义部署”页。

1. 在“订阅”下拉列表中的“项目详细信息”下方，确保你打算在本课程中使用的 Azure 订阅已选中 。

1. 在“资源组”下拉列表中，单击“rg-az220” 。

    > 注意：如果未列出 rg-az220：
    >
    > 1. 在“资源组”下拉列表中，选择“新建”。
    > 1. 在“名称”下，输入 rg-az220 。
    > 1. 单击 **“确定”** 。

1. 在“实例详细信息”下，“区域”下拉列表中，选择离你最近的区域 。

    > 注意：如果 rg-az220 组已存在，则“区域”字段将设置为资源组使用的区域，并且为只读 。

1. 在“你的 ID”字段中，输入在练习 1 中创建的唯一 ID。

1. 在“课程 ID”字段中，输入 az220 。

1. 若要确定当前用户对象 ID，请打开 Cloud Shell，然后执行以下命令：

    ```sh
    az ad signed-in-user show --query objectId -o tsv
    ```

    复制显示的对象 ID。

1. 在“对象 ID”字段中，输入从上述步骤复制的对象 ID。

1. 若要验证模板，请单击“查看并创建”。

1. 验证通过后，单击“创建”。

    将启动部署。

1. 部署完成后，在左侧导航区域中，若要查看模板的任何输出值，请单击“输出”。

    记下输出供稍后使用：

    * connectionString
    * deviceConnectionString
    * devicePrimaryKey
    * storageAccountName

现已创建资源。

#### <a name="task-2---verify-tools"></a>任务 2 - 验证工具

1. 在虚拟机环境中，打开一个 Windows 命令提示符窗口。

1. 若要显示本地安装的 Azure CLI 版本，请输入以下命令：

    ```powershell
    az --version
    ```

1. 验证列出的 azure-cli 版本是否为 2.11.0 或更高版本。

    Azure CLI 版本 2.11 提供升级到最新版本的功能。 若要升级，请输入以下命令：

        ```powershell
        az update
        ```

    > 注意：如果未安装 Azure CLI，需要先安装它，然后才能继续操作：

    1. 打开浏览器，然后导航到 Azure CLI 工具下载页面：[安装 Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest "Azure CLI 安装")

        你应该安装最新版本的 Azure CLI 工具。 Azure CLI 的当前版本（截至 2022 年 2 月）为 2.33 版，但请注意，新版本每月发布一次，因此最新版本可能已经更改。

    1. 在“安装 Azure CLI”页面上，为 OS 选择安装选项（例如“在 Windows 上安装”），然后按照屏幕上的说明安装 Azure CLI 工具 。

### <a name="exercise-2---create-an-instance-of-the-azure-digital-twins-resource"></a>练习 2 - 创建 Azure 数字孪生资源的实例

在本练习中，将使用 Azure 门户创建 Azure 数字孪生 (ADT) 实例。 Azure 数字孪生的连接数据将存储在一个文本文件中供以后使用。 最后，将为当前用户分配一个角色，以便能够访问 ADT 资源。

#### <a name="task-1---use-the-azure-portal-to-create-a-resource-azure-digital-twins"></a>任务 1 - 使用 Azure 门户创建资源（Azure 数字孪生）

1. 在新的浏览器窗口中打开 [Azure 门户](https://portal.azure.com)。

1. 在 Azure 门户菜单上，单击“+ 创建资源”。

    随即打开“新建”边栏选项卡，这是 Azure 市场的前端，该市场是可以在 Azure 中创建的所有资源的集合。 市场包含来自 Microsoft 和社区的资源。

1. 在“搜索市场”文本框中，键入“Azure 数字孪生”。

1. 当“Azure 数字孪生”选项出现时，将其选中，然后单击“创建”。

1. 在“创建资源”窗格的“订阅”下，确保选择了本课程要使用的订阅。

    > **注意**：帐户必须具有订阅的管理员角色

1. 为“资源组”选择“rg-az220”。

1. 为“资源名称”输入“adt-az220-training-{your-id}”。

1. 在“区域”下拉列表中，选择预配 Azure IoT 中心的区域（或最近的可用区域）。

1. 在“授予对资源的访问权限”下，为确保当前用户可以使用 Digital Twins Explorer 应用，请选中“分配 Azure 数字孪生所有者角色”  。

    > **注意**：若要管理实例中的元素，用户需要访问 Azure 数字孪生数据平面 API。 选择上面建议的角色将授予当前用户对数据平面 API 的完全访问权限。 你也可以稍后使用访问控制 (IAM) 选择合适的角色。 可在[此处](https://docs.microsoft.com/azure/digital-twins/concepts-security)了解有关 Azure 数字孪生安全性的详细信息

1. 要查看输入的值，单击“查看 + 创建”。

1. 若要启动部署过程，请单击“创建”。

    显示“正在进行部署”时，请稍候。

1. 选择“转到资源”。

    应会看到 ADT 资源的“概述”窗格，其中包含一个标题为“Azure 数字孪生入门”的正文部分。

#### <a name="task-2---save-the-connection-data-to-a-reference-file"></a>任务 2 - 将连接数据保存到参考文件

1. 使用“记事本”或类似的文本编辑器，创建名为“adt-connection.txt”的文件。

1. 将 Azure 数字孪生实例的名称添加到文件 - adt-az220-training-{your-id} 中

1. 将资源组添加到 rg-az220 文件

1. 在浏览器中，返回“数字孪生”实例的“概述”窗格。

1. 在窗格的“概要信息”部分中，找到“主机名称”字段。

1. 将鼠标指针悬停在“主机名称”字段上，使用该值右侧的图标将主机名复制到剪贴板，然后将其粘贴到文本文件中。

1. 在文本文件中，通过在主机名的开头添加“https://”，将主机名转换为数字孪生实例的连接 url。

    修改后的 url 类似于：

    ```http
    https://adt-az220-training-dm030821.api.eus.digitaltwins.azure.net
    ```

1. 保存 adt-connection.txt 文件。

Azure 数字孪生资源现在已创建，用户帐户已更新，已可通过 API 访问该资源。

### <a name="exercise-3---create-a-graph-of-the-models"></a>练习 3 - 创建模型图

作为建模活动的一部分，分析师会考虑许多因素，例如奶酪储藏室设备消息内容，并在 DTDL“属性”和“遥测”字段定义中创建映射 。 为了使用这些 DTDL 代码片段，会将其合并到一个接口（模型的顶层代码项）中。 然而，奶酪储藏室设备模型的接口只是 Contoso 奶酪工厂 Azure 数字孪生环境的一小部分。 由于对一个代表整个工厂的环境进行建模超出了本课程的范围，我们将考虑构建一个大大简化的环境，该环境主要使用奶酪储藏室设备模型、关联的奶酪储藏室模型和工厂模型。 模型的层次结构如下：

* 奶酪工厂接口
* 奶酪储藏室接口
* 奶酪储藏室设备接口

考虑上述接口定义的层次结构以及它们之间的关系，可以这样考虑：奶酪工厂有奶酪储藏室，奶酪储藏室有奶酪储藏室设备 。

在为 ADT 环境设计数字孪生模型时，最好使用一致的方法来创建用于“接口”、“架构”和“关系”的 ID。 环境中的每个实体都有一个 @id 属性（接口需要该属性），且该属性应唯一标识相关实体。 ID 值的格式采用数字孪生标识符 (DTMI) 的格式。 DTMI 有三个构成部分：架构、路径和版本。 架构和路径之间用冒号“`:`”分隔，路径和版本之间用分号“`;`”分隔。 格式如下所示：`<scheme> : <path> ; <version>`。 DTMI 格式的 ID 中 scheme 的值始终是 dtmi。

Contoso 奶酪工厂 ID 值的一个示例是：`dtmi:com:contoso:digital_factory:cheese_factory;1`。

在本例中，scheme 值与预期一致，为 dtmi，版本设置为 1 。 此 ID 值中的 `<path>` 部分使用以下分类法：

* 模型的来源 - com:contoso
* 模型类别 - digital_factory
* 类别中的类型 - cheese_factory

> 提示：可参阅以下资源，了解 DTMI 格式的详细信息：
> * [数字孪生模型标识符](https://github.com/Azure/opendigitaltwins-dtdl/blob/master/DTDL/v2/dtdlv2.md#digital-twin-model-identifier)

回顾前面确定的模型层次结构和关系，可使用的 ID 的一个示例是：

| 接口                      | ID                                                                     |
| :----------------------------- | :--------------------------------------------------------------------- |
| 奶酪工厂接口       | dtmi:com:contoso:digital_factory:cheese_factory;1                      |
| 奶酪储藏室接口        | dtmi:com:contoso:digital_factory:cheese_factory:cheese_cave;1        |
| 奶酪储藏室设备接口 | dtmi:com:contoso:digital_factory:cheese_factory:cheese_cave_device;1 |

ID 之间的关系可以是：

| 关系 | ID                                                                | 自 ID                                                         | 到 ID                                                                  |
| :----------- | :---------------------------------------------------------------- | :-------------------------------------------------------------- | :--------------------------------------------------------------------- |
| 有储藏室  | dtmi:com:contoso:digital_factory:cheese_factory:rel_has_caves;1 | dtmi:com:contoso:digital_factory:cheese_factory;1               | dtmi:com:contoso:digital_factory:cheese_factory:cheese_cave;1        |
| 有设备  | dtmi:com:contoso:digital_factory:cheese_cave:rel_has_devices;1  | dtmi:com:contoso:digital_factory:cheese_factory:cheese_cave;1 | dtmi:com:contoso:digital_factory:cheese_factory:cheese_cave_device;1 |

> 注意：在“实验室 3 _：设置开发环境”中，你可以通过下载 ZIP 文件并从本地提取内容来克隆包含实验室资源的 GitHub 存储库_。 提取的文件夹结构包括以下文件夹路径：
>
> * Allfiles
>   * 实验室
>       * 19-Azure 数字孪生
>           * 最后
>               * 模型
>
>  可在此文件夹位置获取本练习中引用的模型的完整版。

出于本练习的目的，我们已经为每个数字孪生体定义了用于概念验证的接口，现在该构造实际的数字孪生体图了。 图的构建流程非常简单：

* 导入模型定义
* 根据相应模型创建孪生体实例
* 使用定义的模型关系在创建孪生体实例之间创建关系

有多种方法可以实现此流程：

* 在命令行或脚本中使用 Azure CLI 命令
* 以编程方式使用 SDK 或直接使用 REST API
* 使用 ADT Explorer 样本等工具

由于 ADT Explorer 包括丰富的 ADT 图可视化效果，非常适合增建用于概念验证的简单模型。 然而，也支持更大、更复杂的模型，并且全面的批量导入/导出功能有助于迭代设计。 在本练习中，将完成以下任务：

* 通过 Azure 门户访问 ADT Explorer（预览版）
* 导入 Contoso Cheese 模型
* 使用这些模型来创建数字孪生体
* 向图中添加关系
* 了解如何在 ADT 中删除孪生体、关系和模型
* 将图批量导入 ADT

#### <a name="task-1---access-the-adt-explorer"></a>任务 1 - 访问 ADT Explorer

ADT Explorer 是 Azure 数字孪生服务的一个应用程序。 该应用程序连接到 Azure 数字孪生实例，提供以下功能：

* 上传和浏览模型
* 上传和编辑孪生体的图
* 使用多种布局技术直观显示孪生图
* 编辑孪生体的属性
* 针对孪生图运行查询

ADT 资源管理器作为预览功能并入 Azure 门户，也可作为独立的示例应用程序使用。 在本实验室中，将使用并入 Azure 门户中的版本。

1. 在新的浏览器窗口中打开 [Azure 门户](https://portal.azure.com)。

1. 在浏览器中，导航到数字孪生实例的“概述”窗格。

1. 要在新的浏览器选项卡中打开 ADT Explorer，请单击“打开 Azure Digital Twins Explorer(预览)”。

    此时将打开托管 ADT Explorer 的一个新浏览器选项卡。 你将看到一条警报，指示未找到任何结果 - 这是预料之中的，因为尚未导入任何模型。

    **注意**：如果新窗口提示输入 ADT 实例的 URL，请输入保存到文本编辑器的 URL 值。

    > **重要说明**：如果系统提示你登录，请确保使用创建 Azure 数字孪生实例时使用的同一帐户，否则你将无权访问数据平面 API 并会看到错误。


ADT Explorer 示例应用程序现在已经可以使用了。 下一个任务是加载模型，如果看到一个错误信息提示你没有可用的模型，请不要惊慌。

#### <a name="task-2---import-models"></a>任务 2 - 导入模型

为了在 ADT 中创建数字孪生体，首先需要上传模型。 有多种方法可以上传模型。

* [数据平面 SDK](https://docs.microsoft.com/azure/digital-twins/how-to-use-apis-sdks)
* [数据平面 REST API](https://docs.microsoft.com/rest/api/azure-digitaltwins/)
* [Azure CLI](https://docs.microsoft.com/cli/azure/ext/azure-iot/dt?view=azure-cli-latest)
* [ADT Explorer](https://docs.microsoft.com/samples/azure-samples/digital-twins-explorer/digital-twins-explorer/) 的重要功能

前两个选项更适合编程场景，而 Azure CLI 在“配置即代码”场景或“一次性”要求中可能会更适用。 ADT Explorer 应用提供了一种与 ADT 交互的直观方式。

> 提示：什么是配置即代码？ 由于配置是以源代码的形式编写的（例如，包含 Azure CLI 命令的脚本），你可以使用所有最佳开发做法来进行优化，例如：创建可重复使用的模型上传定义、参数化、使用循环来创建多个模型实例等等。 然后，这些脚本可以存储在源代码管理中，以确保可以保留脚本或对脚本进行版本控制等。

在此任务中，你将使用 Azure CLI 命令和 ADT Explorer 示例应用程序上传 Allfiles\Labs\19-Azure Digital Twins\Final\Models 文件夹中包含的模型。

1. 打开命令提示符窗口。

1. 为确保使用正确的 Azure 帐户凭据，请使用以下命令登录 Azure：

    ```powershell
    az login
    ```

1. 要上传 Cheese Factory Interface，请输入以下命令：

    ```powershell
    az dt model create --models "{file-root}\Allfiles\Labs\19-Azure Digital Twins\Final\Models\CheeseFactoryInterface.json" -n adt-az220-training-{your-id}
    ```

    确保将 {file-root} 替换为本实验室的配套文件所在的文件夹，并将 {your-id} 替换为你的唯一标识符 。

    如果成功，将显示类似以下内容的输出。

    ```json
    [
        {
            "decommissioned": false,
            "description": {},
            "displayName": {
            "en": "Cheese Factory - Interface Model"
            },
            "id": "dtmi:com:contoso:digital_factory:cheese_factory;1",
            "uploadTime": "2021-03-24T19:56:53.8723857+00:00"
        }
    ]
    ```

    **注意**：如果你无法配置 Azure CLI 命令，以下说明将演示如何使用 Azure Digitial Twins Explorer 接口导入模型。
  
1. 返回到“ADT Explorer”。

    > 提示：单击模型资源管理器中的“刷新”按钮可更新模型列表 。

    此时应该会列出上传的 Cheese Factory - Interface 模型：

    ![Factory 模型的 ADT Explorer 模型视图](media/LAB_AK_19-modelview-factory.png)

1. 要使用 ADT Explorer 导入其余两个模型，请在模型资源管理器中，单击“上传模型”图标  

    ![ADT Explorer 模型视图“上传模型”按钮](media/LAB_AK_19-modelview-addmodel.png)

1. 在“打开”对话框中，导航到 Models 文件夹，选择 CheeseCaveInterface.json 和 CheeseCaveDeviceInterface.json 文件，然后单击“打开”    。

    然后这两个文件会上传到 ADT，并添加模型。 完成后，模型资源管理器会更新并列出所有三个模型。

模型现已上传，可以创建数字孪生体。

#### <a name="task-3---creating-twins"></a>任务 3 - 创建孪生体

在 Azure 数字孪生解决方案中，环境中的实体是由数字孪生体表示的。 数字孪生体是你自定义的模型之一的实例。 可以通过关系将其连接到其他数字孪生体以形成孪生图：此孪生图是整个环境的表示形式。

与模型类似，数字孪生体和关系可以通过多种方式创建：

* [数据平面 SDK](https://docs.microsoft.com/azure/digital-twins/how-to-use-apis-sdks)
* [数据平面 REST API](https://docs.microsoft.com/rest/api/azure-digitaltwins/)
* [Azure CLI](https://docs.microsoft.com/cli/azure/ext/azure-iot/dt?view=azure-cli-latest)
* [ADT Explorer](https://docs.microsoft.com/samples/azure-samples/digital-twins-explorer/digital-twins-explorer/) 的重要功能

前两个选项照旧更适合编程场景，而 Azure CLI 在“配置即代码”场景或“一次性”要求中仍更适用。 创建数字孪生体和关系最直观的方式是使用 ADT Explorer，但在初始化属性时会有一些限制。

1. 打开用于上传 CheeseFactoryInterface 模型的命令行窗口。

1. 要使用 Azure CLI 根据 Cheese Factory 模型创建一个数字孪生体，请输入以下命令：

    ```powershell
    az dt twin create --dt-name adt-az220-training-{your-id} --dtmi "dtmi:com:contoso:digital_factory:cheese_factory;1" --twin-id factory_1 --properties "{file-root}\Allfiles\Labs\19-Azure Digital Twins\Final\Properties\FactoryProperties.json"
    ```

    确保将 {file-root} 替换为本实验室的配套文件所在的文件夹，并将 {your-id} 替换为你的唯一标识符 。

    请注意以下内容：

    * --dt-name 值指定 ADT 孪生体实例。
    * --dtmi 值指定先前上传的 Cheese Factory 模型
    * --twin-id 指定赋予数字孪生体的 ID
    * --properties 值提供用于初始化孪生体的 JSON 文档的文件路径。 另外，还可以内联方式指定简单的 JSON。

    如果成功，则命令的输出类似于：

    ```json
    {
        "$dtId": "factory_1",
        "$etag": "W/\"09e781e5-c31f-4bf1-aed4-52a4472b0c5b\"",
        "$metadata": {
            "$model": "dtmi:com:contoso:digital_factory:cheese_factory;1",
            "FactoryName": {
                "lastUpdateTime": "2021-03-24T21:51:04.1371421Z"
            },
            "GeoLocation": {
                "lastUpdateTime": "2021-03-24T21:51:04.1371421Z"
            }
        },
        "FactoryName": "Contoso Cheese 1",
        "GeoLocation": {
            "Latitude": 47.64319985218156,
            "Longitude": -122.12449651580214
        }
    }
    ```

    请注意，$metadata 属性包含一个用于跟踪属性上次更新时间的对象。

1. FactoryProperties.json 文件包含以下 JSON：

    ```json
    {
        "FactoryName": "Contoso Cheese 1",
        "GeoLocation": {
            "Latitude": 47.64319985218156,
            "Longitude": -122.12449651580214
        }
    }
    ```

    这些属性名称与 Cheese Factory Interface 中声明的 DTDL Property 值匹配。

    > 注意：复杂属性 GeoLocation 通过 JSON 对象分配，包含 Latitude 属性和 Longitude 属性  。

1. 在浏览器中，返回到“ADT Explorer”。

1. 要显示到目前为止创建的数字孪生体，请单击“运行查询”。

    > 注意：我们很快会讨论查询和查询语言。

    片刻之后，factory_1 数字孪生体应显示在“孪生图”视图中 。

    ![Factory 1 的 ADT Explorer 图视图](media/LAB_AK_19-graphview-factory_1.png)

1. 要查看数字孪生体的属性，在“孪生图”视图中，单击“factory_1” 。

    factory_1 的属性在属性视图中显示为树状视图中的节点 。

1. 要查看经度和维度属性值，请单击“GeoLocation”。

    注意，这些值与 FactoryProperties.json 文件中的值一致。

1. 要根据 Cheese Factory 模型创建另一个数字孪生体模型，请在模型资源管理器中，找到“奶酪工厂”模型，然后单击“创建孪生体”  

    ![ADT Explorer 模型视图“创建孪生体”按钮](media/LAB_AK_19-modelview-createtwin.png)

1. 当提示输入“新建孪生体名称”时，输入“factory_2”，然后单击“保存”  。

1. 要查看 factory_2 的数字孪生体属性，在“孪生图”视图中，单击“factory_2”  。

    注意，FactoryName 和 GeoLocation 属性没有进行初始化 。

1. 要设置 factoryName，将鼠标光标放在该属性的右侧，此时应该会出现一个文本框控件。 输入“Cheese Factory 2”。

    ![ADT Explorer 属性视图 - 输入工厂名称](media/LAB_AK_19-propertyexplorer-factoryname.png)

1. 在“属性资源管理器”窗格中，要保存对该属性的更新，请选择“修补孪生体”图标 。

    > **注意**：“修补孪生体”图标看起来与“运行查询”按钮右侧的“保存查询”图标相同。 你不需要“保存查询”图标。

    选择“修补孪生体”会导致创建和发送 JSON 补丁，以更新数字孪生体。 补丁信息将显示在一个对话框中。 请注意，由于这是第一次设置值，因此 op（操作）属性为 add 。 该值后面的更改将是 replace 操作 - 要看到此更改，请单击“运行查询”以刷新“孪生图”视图，再进行其他更新  。

   > 提示：若要详细了解 JSON 补丁文档，请参阅以下资源：
   > * [JavaScript 对象表示法 (JSON) 补丁](https://tools.ietf.org/html/rfc6902)
   > * [什么是 JSON 补丁？](http://jsonpatch.com/)

1. 在属性资源管理器中，检查 factory_2 GeoLocation 属性 - 请注意纬度和经度的值显示为“未设置”     。

    > **信息**：ADT Explorer 的早期版本不支持通过 UI 编辑“子属性”- 此功能是一个受欢迎的新增功能。

1. 更新纬度和经度值，如下所示 ：

    | 属性名称 | 值 |
    | :-- | :-- |
    | 纬度 | 47.64530450740752 |
    | 经度 | -122.12594819866645 |

1. 在“属性资源管理器”窗格中，要保存对该属性的更新，请选择“修补孪生体”图标 。

    请注意，补丁信息将再次显示。

1. 通过在模型资源管理器中选择相应的模型然后单击“添加孪生体”，添加以下数字孪生体 ：

    | 模型名称                             | 数字孪生体名称 |
    | :------------------------------------- | :---------------- |
    | 奶酪储藏室 - 接口模型        | cave_1          |
    | 奶酪储藏室 - 接口模型        | cave_2          |
    | 奶酪储藏室设备 - 接口模型 | device_1          |
    | 奶酪储藏室设备 - 接口模型 | device_2          |

    ![显示已创建的孪生体的 ADT Explorer 图形视图](media/LAB_AK_19-graphview-createdtwins.png)

现在已将创建了一些孪生体，接下来可以添加一些关系。

#### <a name="task-4---adding-relationships"></a>任务 4 - 添加关系

孪生体通过其关系连接成为孪生图。 孪生体可以具有的关系定义为其模型的一部分。

例如，“奶酪工厂”模型定义了“包含”关系，该关系的目标是类型为“奶酪储藏室”的孪生体 。 有了此定义，你就可以通过 Azure 数字孪生创建从任何“奶酪工厂”孪生体到任何“奶酪储藏室”孪生体（包括属于“奶酪储藏室”子类型的任何孪生体，例如特定奶酪的专用奶酪储藏室）的“rel_has_caves”关系    。

此过程的结果是一组节点（数字孪生体），它们通过图中的边（它们的关系）连接在一起。

与模型和孪生体类似，可通过多种方法创建关系。

1. 要通过 Azure CLI 创建关系，请返回到命令提示符，并执行以下命令：

    ```powershell
    az dt twin relationship create -n adt-az220-training-{your-id} --relationship-id factory_1_has_cave_1 --relationship rel_has_caves --twin-id factory_1 --target cave_1
    ```

    确保将 {your-id} 替换为唯一标识符。

    如果成功，则命令的输出类似于：

    ```json
    {
        "$etag": "W/\"cdb10516-36e7-4ec3-a154-c050afed3800\"",
        "$relationshipId": "factory_1_has_cave_1",
        "$relationshipName": "rel_has_caves",
        "$sourceId": "factory_1",
        "$targetId": "cave_1"
    }
    ```

1. 要直观显示关系，请在浏览器中返回到 ADT Explorer。

1. 要显示更新后的数字孪生体，请单击“运行查询”。

    示意图将会刷新，并将显示新关系。

    ![包含关系的 ADT Explorer 图形视图](media/LAB_AK_19-graphview-relationship.png)

    如果未看到关系，请刷新浏览器窗口，然后运行查询。

1. 要使用 ADT Explorer 添加关系，请先单击“cave_1”将其选中，然后右键点击“device_1”   。 在显示的上下文菜单中，选择“添加关系”。

1. 在“创建关系”对话框中的“源 ID”下，确认已显示“cave_1”  。

1. 在“目标 ID”下，确认已显示“device_1” 。

1. 在“关系”下，选择“rel_has_devices” 。

    > 注意：与使用 Azure CLI 创建的关系不同，没有等效 UI 来提供 $relationshipId 值。 而是将分配 GUID。

1. 要创建关系，请单击“保存”。

    将创建关系，并且示意图将会更新以显示该关系。 示意图现在显示“factory_1”具有“cave_1”，而后者又具有“device_1”  。

1. 再添加两个关系：

    | Source    | 目标   | 关系    |
    | :-------- | :------- | :-------------- |
    | factory_1 | cave_2 | rel_has_caves |
    | cave_2  | device_2 | rel_has_devices |

    该图现在应类似于：

    ![显示更新后的图形的 ADT Explorer 图形视图](media/LAB_AK_19-graphview-updatedgraph.png)

1. 要查看“孪生图”视图的布局选项，请单击“选择布局”按钮 。

    ![ADT Explorer 图视图选择布局](media/LAB_AK_19-twingraph-chooselayout.png)

    “孪生图”视图可使用不同的算法来设置图形的布局。 默认情况下选择“Klay”布局。 不可以尝试选择其他布局，以查看图形如何变更。

#### <a name="task-5---deleting-models-relationships-and-twins"></a>任务 5 - 删除模型、关系和孪生体

在使用 ADT 进行建模的设计流程中，可能会创建许多概念证明，其中许多将被删除。 与对数字孪生体执行的其他操作类似，可通过编程方法（API、SDK 和 CLI）来删除模型和孪生体，也可以使用 ADT Explorer 进行删除。

> 注意：需要注意的一点是，删除操作属于异步操作，例如，虽然 REST API 调用或在 ADT Explorer 中进行删除可能看起来是立即完成的，但实际上可能需要几分钟时间才可在 ADT 服务中完成该操作。 在后端操作完成前，尝试上传与最近删除的模型同名的修订模型可能会意外失败。

1. 要通过 CLI 删除“factory_2”数字孪生体，请返回到命令提示符窗口，然后输入以下命令：

    ```powershell
    az dt twin delete -n adt-az220-training-{your-id} --twin-id factory_2
    ```

    与其他命令不同，此命令不会显示输出（除非产生错误）。

1. 要删除“factory_1”与“cave_1”之间的关系，请输入以下命令 ：

    ```powershell
    az dt twin relationship delete -n adt-az220-training-{your-id} --twin-id factory_1 --relationship-id factory_1_has_cave_1
    ```

    请注意，此命令需要关系 ID。 你可以查看给定孪生体的关系 ID。 例如，要查看“factory_1”的关系 ID，可以输入以下命令：

    ```powershell
    az dt twin relationship list -n adt-az220-training-{your-id} --twin-id factory_1
    ```

    如果在删除 cave 1 的关系之前运行此命令，则将看到如下所示的输出：

    ```json
    [
        {
            "$etag": "W/\"a6a9f506-3cfa-4b62-bcf8-c51b5ecc6f6d\"",
            "$relationshipId": "47b0754a-25d1-4b71-ac47-c2409bb08535",
            "$relationshipName": "rel_has_caves",
            "$sourceId": "factory_1",
            "$targetId": "cave_2"
        },
        {
            "$etag": "W/\"b5207e88-7c86-498f-a272-7f81dde88dee\"",
            "$relationshipId": "factory_1_has_cave_1",
            "$relationshipName": "rel_has_caves",
            "$sourceId": "factory_1",
            "$targetId": "cave_1"
        }
    ]
    ```

1. 要删除模型，请输入以下命令：

    ```powershell
    az dt model delete -n adt-az220-training-{your-id} --dtmi "dtmi:com:contoso:digital_factory:cheese_factory;1"
    ```

    此命令同样不会显示输出。

    > **重要说明**：此命令删除了工厂模型并成功完成，即使数字孪生体“factory_1”仍然存在。 仍可通过查询图形查找使用已删除的模型创建的数字孪生体，但是无法再更新没有模型的孪生体的属性。 完成模型管理任务（版本控制、删除等）时请格外小心，以避免创建不一致的图形。

1. 要显示最近对数字孪生体进行的更改，请返回到 ADT Explorer。

1. 要更新显示的内容，请刷新浏览器页面，然后单击“运行查询”。

    模型资源管理器中应缺少“奶酪工厂”模型，并且在“孪生图”视图中，“factory_1”和“cave_1”之间应该没有关系    。

1. 要选择“cave_1”和“device_1”之间的关系，请单击这两个孪生体之间的直线 。

    该直线应该加粗，以指示其处于选中状态，并且将启用“删除关系”按钮。

    ![ADT Explorer 图形视图的“删除关系”按钮](media/LAB_AK_19-graphview-deleterel.png)

1. 要删除关系，请右键单击该行并从上下文菜单中选择“删除关系”，然后单击“删除”进行确认 。

    关系将被删除，且图形将更新。

1. 若要删除 device_1 数字孪生体，请右键单击“device_1”，然后从上下文菜单中选择“删除孪生体”  。

    > 注意：通过使用 CTRL 和左键单击，可以选择多个孪生体。 要删除它们，请右键单击最后一个孪生体，然后从上下文菜单中选择“删除孪生体”。

1. 在 ADT Explorer 页面的右上角，单击“删除所有孪生体”，然后再单击“删除”进行确认，以删除图中的所有数字孪生体 。

    ![ADT Explorer 的“删除所有孪生体”按钮](media/LAB_AK_19-deletealltwins.png)

    > **重要说明**：请谨慎使用 - 没有撤消功能！

1. 要从模型资源管理器中删除“奶酪储藏室设备”模型，请单击关联的“删除模型”按钮，然后单击“删除”进行确认   。

1. 要删除所有模型，请单击模型资源管理器顶部的“删除所有模型” 。

    > **重要说明**：请谨慎使用 - 没有撤消功能！

此时，应已清除 ADT 示例的所有模型、孪生体和关系。 不必担心 - 在下一个任务中，将使用“导入图形”功能来创建新的图形。

#### <a name="task-6---bulk-import-with-adt-explorer"></a>任务 6 - 使用 ADT Explorer 批量导入

ADT Explorer 支持导入和导出数字孪生体图。 “导出”功能将最近的查询结果序列化为基于 JSON 的格式（包括模型、孪生体和关系）。 “导入”功能从基于 Excel 的自定义格式或在导出时生成的基于 JSON 的格式进行反序列化。 在执行导入之前，将显示图形预览用于进行验证。

Excel 导入格式基于以下列：

* **ModelId**：应实例化的模型的完整 DTMI。
* **ID**：要创建的孪生体的唯一 ID
* **关系**：具有到新孪生体的传出关系的孪生体 ID
* **关系名**：起源于前一列中的孪生体的传出关系的名称
* **初始化数据**：包含要创建的孪生体的“属性”设置的 JSON 字符串

> 注意：Excel 的导入功能不导入模型定义，而是仅导入孪生体和关系。 JSON 格式还支持模型。

下表显示了将在此任务中创建的孪生体和关系（为了方便阅读，删除了“初始化数据”值：

| ModelID                                                                | ID             | 关系（起源） | 关系名称 | 初始化数据 |
| :--------------------------------------------------------------------- | :------------- | :------------------ | :---------------- | :-------- |
| dtmi:com:contoso:digital_factory:cheese_factory;1                      | factory_1      |                     |                   |           |
| dtmi:com:contoso:digital_factory:cheese_factory:cheese_cave;1        | cave_1       | factory_1           | rel_has_caves   |           |
| dtmi:com:contoso:digital_factory:cheese_factory:cheese_cave;1        | cave_2       | factory_1           | rel_has_caves   |           |
| dtmi:com:contoso:digital_factory:cheese_factory:cheese_cave;1        | cave_3       | factory_1           | rel_has_caves   |           |
| dtmi:com:contoso:digital_factory:cheese_factory:cheese_cave_device;1 | sensor-th-0055 | cave_1            | rel_has_devices   |           |
| dtmi:com:contoso:digital_factory:cheese_factory:cheese_cave_device;1 | sensor-th-0056 | cave_2            | rel_has_devices   |           |
| dtmi:com:contoso:digital_factory:cheese_factory:cheese_cave_device;1 | sensor-th-0057 | cave_3            | rel_has_devices   |           |

电子表格 cheese-factory-scenario.xlsx 位于 {file-root}\Allfiles\Labs\19-Azure Digital Twins\Final\Models 文件夹中 。

1. 在浏览器中，返回到“ADT Explorer”。

1. 要使用 ADT Explorer 导入模型，请在模型资源管理器中单击“上传模型”图标  

1. 在“打开”文件夹中，导航到 Models 文件夹，选择 CheeseFactoryInterface.json、CheeseCaveInterface.json 和 CheeseCaveDeviceInterface.json 文件，然后单击“打开”     。

    这将重新上传所有模型。

1. 要导入 cheese-factory-scenario.xlsx 电子表格，请单击“导入图形” 。

    ![ADT Explorer 图形视图的“导入图形”功能](media/LAB_AK_19-graphview-importgraph.png)

1. 在“打开”文件夹中，导航到 Models 文件夹，选择 cheese-factory-scenario.xlsx 文件，然后单击“打开”   。

    “导入”视图中会显示要导入的图形的预览：

    ![ADT Explorer 图形视图的导入预览](media/LAB_AK_19-graphview-importpreview.png)

1. 要完成导入，请单击“开始导入”。

    将显示“导入成功”对话框，详细说明已导入 7 个孪生体和 6 个关系。 单击“关闭”以继续。

1. 返回到“孪生图”视图，然后单击“运行查询” 。

    现在应显示导入的图形。 可单击每个孪生体以查看属性（每个孪生体已使用值初始化）。

1. 要将当前图形导出为 JSON，请单击“导出图形”（位于之前使用的“导入图形”按钮旁边）。

    “导出”视图的左上角会显示“下载”链接。

1. 要以 JSON 格式下载模型，请单击“下载”链接。

    浏览器将下载模型。

1. 要查看 JSON，请在 Visual Studio Code 中打开已下载的文件。

    如果 JSON 显示为单行，请通过命令面板使用“设置文档格式”命令或通过按 Shift+Alt+F 来重新设置 JSON 的格式 。

    JSON 有三个主要部分：

    * **digitalTwinsFileInfo** - 包含导出的文件格式的版本
    * **digitalTwinsGraph** - 包含导出的图形上显示的每个孪生体和关系（即仅根据查询显示的孪生体和关系）的实例数据
    * **digitalTwinsModels** - 模型定义

    > 注意：与 Excel 格式不同，JSON 文件包含模型定义，这意味着可仅通过一个文件导入所有内容。

1. 要导入 JSON 文件，请按照之前的任务中的说明使用 ADT Explorer 删除模型和孪生，然后导入刚刚创建的 JSON 导出文件。 请注意，重新创建了模型、孪生体及其属性，以及关系。

此孪生体图将用作练习查询的基础。

### <a name="exercise-4---query-the-graph-using-adt-explorer"></a>练习 4 - 使用 ADT Explorer 查询图像

>注意：这个练习需要在前一个练习中导入的图形。

现在，我们来看看数字孪生体图查询语言。

你可以查询刚才构建的数字孪生体图形，以获取有关数字孪生体及其包含的关系的信息。 请采用类似于 SQL 的自定义查询语言编写这些查询，该语言称为 Azure 数字孪生查询语言。 此语言也类似于 Azure IoT 中心的查询语言。

可通过数字孪生体 REST API 和 SDK 进行查询。 在本练习中，你将使用 Azure Digital Twins Explorer 示例应用来处理 API 调用。 本实验室中稍后将探讨其他工具。

> 注意：ADT Explorer 专用于直观显示图形，并且只能显示整个孪生体，而无法只显示从孪生体中选择的单个值（例如名称）。

#### <a name="task-1---query-using-the-adt-explorer"></a>任务 1 - 使用 ADT Explorer 进行查询

在此任务中，ADT Explorer 将用于执行图形查询并以图形的形式呈现结果。 可以按属性、模型类型和关系查询孪生体。 可以使用合并运算符将查询合并到复合查询中，该复合查询可一次查询多种类型的孪生体描述符。

1. 在浏览器中，返回到“ADT Explorer”。

1. 确保“查询资源管理器”查询设置为以下内容：

    ```sql
    SELECT * FROM digitaltwins
    ```

    如果你已经非常熟悉 SQL，你可以确信这将返回数字孪生体的所有信息。

1. 要运行此查询，请单击“运行查询”。

    正如预期的一样，将显示整张图。

1. 要将此查询保存为命名查询，请单击“保存”图标（就在“运行查询”按钮的右侧） 。

1. 在“保存查询”对话框中，输入名称“所有孪生体”，然后单击“保存”  。

    然后，此查询将保存在本地，并在查询文本框左侧的“保存的查询”下拉列表中显示。 要删除保存的查询，请在“保存的查询”下拉列表处于打开状态时单击查询名称旁边的 X 图标 。

    > 提示：随时都可运行“所有孪生体”查询以返回到完整视图。

1. 要筛选图形以便仅显示“奶酪储藏室”孪生体，请输入并运行以下查询：

    ```sql
    SELECT * FROM digitaltwins
    WHERE IS_OF_MODEL('dtmi:com:contoso:digital_factory:cheese_factory:cheese_cave;1')
    ```

    图形中现在将仅显示 3 个“奶酪储藏室”孪生体。

    将此查询保存为“仅储藏室”。

1. 要仅显示状态为“inUse”的“奶酪储藏室”孪生体，请输入并运行以下查询 ：

    ```sql
    SELECT * FROM digitaltwins
    WHERE IS_OF_MODEL('dtmi:com:contoso:digital_factory:cheese_factory:cheese_cave;1')
    AND inUse = true
    ```

    图形中现在应仅显示“cave_3”和“cave_1” 。

1. 要仅显示状态为“inUse”并且具有“temperatureAlert”的“奶酪储藏室”孪生体，请输入并运行以下查询  ：

    ```sql
    SELECT * FROM digitaltwins
    WHERE IS_OF_MODEL('dtmi:com:contoso:digital_factory:cheese_factory:cheese_cave;1')
    AND inUse = true
    AND temperatureAlert = true
    ```

    图形中现在应仅显示“cave_3”和。

1. 要使用关系通过联接来查找设备 sensor-th-0055 的父级，请输入以下查询：

    ```sql
    SELECT Parent FROM digitaltwins Parent
    JOIN Child RELATED Parent.rel_has_devices
    WHERE Child.$dtId = 'sensor-th-0055'
    ```

    应显示“cave_1”孪生体。

    熟悉 SQL JOIN 的用户会发现，此处使用的语法与之前可能经常使用的语法有所不同。 请注意，指定了关系的名称“rel_has_devices”，而不是将此 JOIN 与 WHERE 子句中的键值关联，或根据 JOIN 定义指定键值。 此关联是自动计算的，因为关系属性本身标识目标实体。 以下是关系定义：

    ```json
    {
        "@type": "Relationship",
        "@id": "dtmi:com:contoso:digital_factory:cheese_cave:rel_has_devices;1",
        "name": "rel_has_devices",
        "displayName": "Has devices",
        "target": "dtmi:com:contoso:digital_factory:cheese_factory:cheese_cave_device;1"
    }
    ```

#### <a name="task-2---query-for-properties-using-the-adt-explorer"></a>任务 2 - 使用 ADT Explorer 查询属性

ADT Explorer 的一个重要限制是它专用于呈现图形，主显示屏上不能显示仅返回属性的查询的结果。 在此任务中，你将了解如何在不借助编码解决方案的情况下查看此类查询的结果。

1. 要运行仅返回属性的有效查询，请输入以下代码并单击“运行查询”：

    ```sql
    SELECT Parent.desiredTemperature FROM digitaltwins Parent
    JOIN Child RELATED Parent.rel_has_devices
    WHERE Child.$dtId = 'sensor-th-0055'
    ```

    尽管查询将完成运行且不出错，但不会显示图形。 但这是一种在 ADT Explorer 中查看结果的方法，而在下一个任务中，你将打开“输出”窗格来查看程序结果。

1. 要打开“输出”窗格，请单击页面右上方的“设置”图标 。

1. 在出现的对话框上，在“视图”下启用“输出”，然后关闭对话框 。

    页面底部应显示“输出”窗格。

1. 重新运行上面的查询，并查看“输出”窗格的内容。

    “输出”窗格应显示“请求的查询”，然后显示返回的 JSON。 JSON 应如下所示：

    ```json
    {
        "queryCharge": 20.259999999999998,
        "connection": "close",
        "content-encoding": "gzip",
        "content-type": "application/json; charset=utf-8",
        "date": "Thu, 25 Mar 2021 21:34:40 GMT",
        "strict-transport-security": "max-age=2592000",
        "traceresponse": "00-182f5e54efb95c4b8b3e2a6aac15499f-9c5ffe6b8299584e-01",
        "transfer-encoding": "chunked",
        "vary": "Accept-Encoding",
        "x-powered-by": "Express",
        "value": [
            {
            "desiredTemperature": 50
            }
        ],
        "continuationToken": null
    }
    ```

    除了额外的结果元数据外，请注意“value”属性包含选定的“desiredTemperature”属性和值 。

### <a name="exercise-5---configure-and-launch-device-simulator"></a>练习 5 - 配置和启动设备模拟器

前面的练习中创建了用于概念证明的数字孪生体模型和图形。 为了演示如何将设备消息流量从 IoT 中心传递到 ADT，可以使用设备模拟器。 在本练习中，你将配置一个模拟设备应用，以将遥测发送到 IoT 中心。

#### <a name="task-1-open-the-device-simulator-project"></a>任务 1：打开设备模拟器项目

在此任务中，将在 Visual Studio Code 中打开奶酪储藏室设备模拟器应用，以便进行配置。

1. 打开 **Visual Studio Code**。

1. 在“文件”菜单上，单击“打开文件夹”

1. 在“打开文件夹”对话框中，导航到实验室 19 的初学者文件夹。

    在“实验室 3 _：设置开发环境”中，你可以通过下载 ZIP 文件并从本地提取内容来克隆包含实验室资源的 GitHub 存储库_。 提取的文件夹结构包括以下文件夹路径：

    * Allfiles
        * 实验室
            * 19-Azure 数字孪生
                * 初学者
                    * CheeseCaveDevice

1. 单击“CheeseCaveDevice”，然后单击“选择文件夹” 。

    你应该会在 Visual Studio Code 的资源管理器窗格中看到以下文件：

    * CheeseCaveDevice.csproj
    * Program.cs

1. 若要打开代码文件，请单击“Program.cs”。

    粗略地看上一眼即可发现，此应用程序与你在之前的实验中使用过的模拟设备应用程序非常相似。 此版本使用对称密钥身份验证，将遥测和日志记录消息发送到 IoT 中心，并且具有更复杂的传感器实现。

1. 在“终端”菜单上，单击“新终端”。

    注意命令提示符中指示的目录路径。 你无需在上一个实验室项目的文件夹结构中开始构建此项目。

1. 在终端命令提示符下，请输入以下命令以验证应用程序版本：

    ```bash
    dotnet build
    ```

    输出结果会类似于：

    ```text
    > dotnet build
    Microsoft (R) Build Engine version 16.5.0+d4cbfca49 for .NET Core
    Copyright (C) Microsoft Corporation. All rights reserved.

    Restore completed in 39.27 ms for D:\Az220\AllFiles\Labs\19-Azure Digital Twins\Starter\CheeseCaveDevice\CheeseCaveDevice.csproj.
    CheeseCaveDevice -> D:\Az220\AllFiles\Labs\19-Azure Digital Twins\Starter\CheeseCaveDevice\bin\Debug\netcoreapp3.1\CheeseCaveDevice.dll

    Build succeeded.
        0 Warning(s)
        0 Error(s)

    Time Elapsed 00:00:01.16
    ```

在下一个任务中，你将配置连接字符串并查看应用程序。

#### <a name="task-2-configure-connection-and-review-code"></a>任务 2：配置连接并查看代码

你在此任务中构建的模拟设备应用将模拟监视温度和湿度的 IoT 设备。 该应用与在实验室 15 中构建的应用相同，将模拟传感器读数，并每两秒传达一次传感器数据。

1. 在 Visual Studio Code 中，确保已打开 Program.cs 文件。

1. 在代码编辑器中，找到以下代码行：

    ```csharp
    private readonly static string deviceConnectionString = "<your device connection string>";
    ```

1. 将“\<your device connection string\>”替换为你在实验室设置练习结束时保存的设备连接字符串。

    这是在将遥测发送到 IoT 中心之前唯一需要实现的更改。

    > 注意：你已保存设备连接字符串和服务连接字符串。 请务必提供设备连接字符串。

1. 在“文件”菜单上，单击“保存”。

#### <a name="task-3-test-your-code-to-send-telemetry"></a>任务 3：测试你的代码以发送遥测

在此任务中，将启动已配置的模拟器应用，并验证已成功传输遥测。

1. 在 Visual Studio Code 中，确保“终端”仍处于打开状态。

1. 在终端命令提示符下，输入以下命令以运行模拟设备应用：

    ```bash
    dotnet run
    ```

   此命令将在当前文件夹中运行 Program.cs 文件。

1. 注意输出已发送到终端。

    你应该很快就能看到控制台输出，类似于：

    ![控制台输出](media/LAB_AK_19-cheesecave-telemetry.png)

    > **注意**：绿色文本表示一切正常。 红色文本表示存在异常。 如果你看到的屏幕与上图并不相似，请首先检查设备连接字符串。

1. 保持此应用持续运行。

    在本实验的后部分，你需要将遥测发送到 IoT 中心。

### <a name="exercise-6----set-up-azure-function-to-ingest-data"></a>练习 6 - 设置 Azure 函数以引入数据

概念证明的一个关键部分是演示如何将设备中的数据提交到 Azure 数字孪生。 可通过外部计算资源（例如虚拟机、Azure Functions 和逻辑应用）将数据引入 Azure 数字孪生。 在此练习中，将通过 IoT 中心的内置事件网格调用函数应用。 函数应用接收数据并使用 Azure 数字孪生 API 设置相应数字孪生体实例的属性。

#### <a name="task-1---create-and-configure-a-function-app"></a>任务 1 - 创建并配置函数应用

为了将 IoT 中心事件网格终结点配置为将遥测传递到 Azure 函数，需要先创建 Azure 函数。 在此任务中，创建了一个 Azure 函数应用，用于提供各 Azure 函数运行的执行上下文。

为了访问 Azure 数字孪生及其 API，需要利用具有相应权限的服务主体。 在此任务中，为函数应用创建了服务主体，然后为该服务主体分配了相应权限。 函数应用具有相应权限后，在函数应用上下文内执行的任何 Azure 函数都将使用该服务主体，因此具有访问 ADT 的权限。

函数应用上下文还提供用于管理一个或多个函数的应用设置的环境。 此功能将用于定义包含 ADT 连接字符串的设置，Azure Functions 随后可读取该字符串。 与在函数代码中硬编码值相比，通常认为在应用设置中封装连接字符串和其他配置是更好的做法。

1. 打开包含 Azure 门户的浏览器窗口，然后打开 Azure Cloud Shell。

1. 在 Cloud Shell 命令提示符处，请输入以下命令以创建 Azure 函数应用：

    ```bash
    az functionapp create --resource-group rg-az220 --consumption-plan-location {your-location} --name func-az220-hub2adt-training-{your-id} --storage-account staaz220training{your-id} --functions-version 3
    ```

    > **注意**：请记住替换上面的 {your-location} 和 {your-id} 令牌 。

    Azure 函数需要传递持有者令牌才能向 Azure 数字孪生进行身份验证。 为了确保传递此令牌，你需要为函数应用创建托管标识。

1. 要为函数应用创建（分配）系统关联的标识并显示关联的主体 ID，请输入以下命令：

    ```bash
    az functionapp identity assign -g rg-az220 -n func-az220-hub2adt-training-{your-id} --query principalId -o tsv
    ```

    > **注意**：请记住替换上面的 {your-id} 令牌。

    输出将如下所示：

    ```bash
    1179da2d-cc37-48bb-84b3-544cbb02d194
    ```

    这是分配给函数应用的主体 ID - 你需要在下一步中使用该主体 ID。

1. 要向函数应用主体分配“Azure 数字孪生数据所有者”角色，请输入以下命令：

    ```bash
    az dt role-assignment create --dt-name adt-az220-training-{your-id} --assignee {principal-id} --role "Azure Digital Twins Data Owner"
    ```

    > **注意**：请记住替换上面的 {your-id} 和 {principal-id} 令牌 。 {principal-id} 值显示为上一步的输出。

    现在已将主体分配给 Azure 函数应用，必须向该主体分配“Azure 数字孪生数据所有者”角色，以便其能够访问 Azure 数字孪生实例。

1. 要向 Azure 函数应用提供 Azure 数字孪生实例 URL，请输入以下命令：

    ```bash
    az functionapp config appsettings set -g rg-az220 -n func-az220-hub2adt-training-{your-id} --settings "ADT_SERVICE_URL={adt-url}"
    ```

    > **注意**：请记住替换上面的 {your-id} 和 {adt-url} 令牌 。 {adt-url} 值已在之前的任务中保存到 adt-connection.txt 文件，类似于 `https://adt-az220-training-dm030821.api.eus.digitaltwins.azure.net` 。

    完成后，命令会列出所有可用设置。 Azure 函数将不能通过读取 ADT_SERVICE_URL 值获取 ADT 服务 URL。

#### <a name="task-2---review-contosoadtfunctions-project"></a>任务 2 - 查看 Contoso.AdtFunctions 项目

在此任务中，你将查看一个 Azure 函数，每当相关事件网格上发生事件时就会执行该函数。 将处理事件，并将消息和遥测路由到 ADT。

1. 在 Visual Studio Code 中，打开 Contoso.AdtFunctions 文件夹 。

1. 打开 Contoso.AdtFunctions.csproj 文件。

> 注意：在“实验室 3 _：设置开发环境”中，你可以通过下载 ZIP 文件并从本地提取内容来克隆包含实验室资源的 GitHub 存储库_。 提取的文件夹结构包括以下文件夹路径：
>
> * Allfiles
>   * 实验室
>       * 19-Azure 数字孪生
>           * 最后
>               * Contoso.AdtFunctions

    Notice the project references the following NuGet Packages:

    * Azure.DigitalTwins.Core 包包含 Azure Digital Twins 服务的 SDK。 此库提供到 Azure Digital Twins 服务的访问权限，以便管理孪生体、模型、关系等。
    * Microsoft.Azure.WebJobs.Extensions.EventGrid 包提供了在 Azure Functions 中接收事件网格 Webhook 调用的功能，让你可以轻松编写函数来响应发布到事件网格的任何事件。
    * Microsoft.Azure.WebJobs.Extensions.EventHubs 包提供了在 Azure Functions 中接收事件中心 Webhook 调用的功能，让你可以轻松编写函数来响应发布到事件中心的任何事件。
    * Microsoft.NET.Sdk.Functions 包包括用于生成 .NET 函数项目的生成任务。
    * Azure.identity 包包含 Azure Identity 的 Azure SDK 客户端库。 Azure Identity 库提供跨 Azure SDK 的 Azure Active Directory 令牌身份验证支持。 它提供一组 TokenCredential 实现，可用于构建 Azure SDK 客户端以支持 AAD 令牌身份验证
    * System.Net.Http 包为现代 HTTP 应用程序提供编程接口，包括允许应用程序通过 HTTP 使用 web 服务的 HTTP 客户端组件，以及可供客户端和数据库用于解析 HTTP 表头的 HTTP 组件。

1. 在 Visual Studio Code 中，打开 HubToAdtFunction.cs 文件。

1. 若要查看函数的成员变量，请找到 `// INSERT member variables below here` 注释并查看其下方的代码：

    ```csharp
    //Your Digital Twins URL is stored in an application setting in Azure Functions.
    private static readonly string adtInstanceUrl = Environment.GetEnvironmentVariable("ADT_SERVICE_URL");
    private static readonly HttpClient httpClient = new HttpClient();
    ```

    请注意，adtInstanceUrl 变量分配到了此前在本练习中定义的 ADT_SERVICE_URL 环境变量的值。  代码还遵循最佳做法：使用 HttpClient 的单个静态实例。

1. 找到 Run 方法声明，查看以下注释：

    ```csharp
    [FunctionName("HubToAdtFunction")]
    public async static Task Run([EventGridTrigger] EventGridEvent eventGridEvent, ILogger log)
    ```

    请注意，使用 FunctionName 属性将 Run 方法标记为 HubToAdtFunction 的入口点 Run。  此方法还被 `async` 声明为异步更新 Azure 数字孪生运行的代码。

    eventGridEvent 参数被分配给触发了函数调用的事件网格事件； log 参数提供对可用于调试的日志记录程序的访问权限。

    > 提示：若要详细了解适用于 Azure Functions 的 Azure 事件网格触发器，请查看以下资源：
    > * [Azure Functions 的 Azure 事件网格触发器](https://docs.microsoft.com/azure/azure-functions/functions-bindings-event-grid-trigger?tabs=csharp%2Cbash)

1. 要查看如何记录信息数据，请找到以下代码：

    ```csharp
    log.LogInformation(eventGridEvent.Data.ToString());
    ```

    ILogger  接口在 Microsoft.Extensions.Logging 命名空间中定义，它将大多数日志记录模式聚合到单个方法调用中。 在本例中，在 Information 级别创建了日志条目 - 存在适用于各种级别（包括关键、错误等）的方法。 等等由于 Azure 函数在云中运行，日志记录在开发和生产期间非常重要。

    > 提示：若要详细了解 Microsoft.Extensions.Logging，请参阅以下资源：
    > * [.NET 中的日志记录](https://docs.microsoft.com/dotnet/core/extensions/logging?tabs=command-line)
    > * [Microsoft.Extensions.Logging 命名空间](https://docs.microsoft.com/dotnet/api/microsoft.extensions.logging?view=dotnet-plat-ext-5.0&viewFallbackFrom=netcore-3.1)
    > * [ILogger 接口](https://docs.microsoft.com/en-us/dotnet/api/microsoft.extensions.logging.ilogger?view=dotnet-plat-ext-5.0&viewFallbackFrom=netcore-3.1)

1. 找到以下代码以了解如何检查 adtInstanceUrl 变量值：

    ```csharp
    if (adtInstanceUrl == null)
    {
        log.LogError("Application setting \"ADT_SERVICE_URL\" not set");
        return;
    }
    ```

    此代码会检查是否设置了 adtInstanceUrl 变量 - 如果没有，则记录错误，且函数已存在。 这演示了日志记录的价值：捕捉到函数配置错误的事实。

1. 为了确保记录任何异常，使用了 `try..catch` 循环：

    ```csharp
    try
    {
        // ... main body of code
    }
    catch (Exception e)
    {
        log.LogError(e.Message);
    }
    ```

    注意，已记录了异常消息。

1. 若要查看如何使用函数应用主体向 ADT 进行身份验证并创建客户端实例，请找到 `// REVIEW authentication code below here` 注释并查看以下代码：

    ```csharp
    ManagedIdentityCredential cred = new ManagedIdentityCredential("https://digitaltwins.azure.net");
    DigitalTwinsClient client = new DigitalTwinsClient(new Uri(adtInstanceUrl), cred, new DigitalTwinsClientOptions { Transport = new HttpClientTransport(httpClient) });
    log.LogInformation($"Azure digital twins service client connection created.");
    ```

    注意 ManagedIdentityCredential 类的使用。 此类会使用之前分配给部署环境的托管标志进行身份验证。 返回凭据后，会使用它构造 DigitalTwinsClient 的实例。 该客户端包含用于检索和更新数字孪生信息（例如模型、组件、属性和关系）的方法。

1. 若要查看开始处理事件网格事件的代码，请找到 `// REVIEW event processing code below here` 注释并查看其下方的代码：

    ```csharp
    if (eventGridEvent != null && eventGridEvent.Data != null)
    {
        // Read deviceId and temperature for IoT Hub JSON.
        JObject deviceMessage = (JObject)JsonConvert.DeserializeObject(eventGridEvent.Data.ToString());
        string deviceId = (string)deviceMessage["systemProperties"]["iothub-connection-device-id"];
        var fanAlert = (bool)deviceMessage["properties"]["fanAlert"]; // cast directly to a bool
        var temperatureAlert = deviceMessage["properties"].SelectToken("temperatureAlert") ?? false; // JToken object
        var humidityAlert = deviceMessage["properties"].SelectToken("humidityAlert") ?? false; // JToken object
        log.LogInformation($"Device:{deviceId} fanAlert is:{fanAlert}");
        log.LogInformation($"Device:{deviceId} temperatureAlert is:{temperatureAlert}");
        log.LogInformation($"Device:{deviceId} humidityAlert is:{humidityAlert}");

        var bodyJson = Encoding.ASCII.GetString((byte[])deviceMessage["body"]);
        JObject body = (JObject)JsonConvert.DeserializeObject(bodyJson);
        log.LogInformation($"Device:{deviceId} Temperature is:{body["temperature"]}");
        log.LogInformation($"Device:{deviceId} Humidity is:{body["humidity"]}");
    }
    ```

    注意使用 JSON 反序列化来访问事件数据。 事件数据 JSON 会类似于：

    ```JSON
    {
        "properties": {
            "sensorID": "S1",
            "fanAlert": "false",
            "temperatureAlert": "true",
            "humidityAlert": "true"
        },
        "systemProperties": {
            "iothub-connection-device-id": "sensor-th-0055",
            "iothub-connection-auth-method": "{\"scope\":\"device\",\"type\":\"sas\",\"issuer\":\"iothub\",\"acceptingIpFilterRule\":null}",
            "iothub-connection-auth-generation-id": "637508617957275763",
            "iothub-enqueuedtime": "2021-03-11T03:27:21.866Z",
            "iothub-message-source": "Telemetry"
        },
        "body": "eyJ0ZW1wZXJhdHVyZSI6OTMuOTEsImh1bWlkaXR5Ijo5OC4wMn0="
    }
    ```

    可使用索引器方法轻松访问消息 properties 和 systemProperties，但在属性可选的位置（例如 temperatureAlert 和 humidityAlert），需要使用 `SelectToken` 和 null 联结操作来防止引发异常   。

    > 提示：若要详细了解 null 联结操作符 `??`，请参阅以下内容：
    > * [?? 和 ??= 运算符（C# 参考）](https://docs.microsoft.com/dotnet/csharp/language-reference/operators/null-coalescing-operator)

    消息正文包含遥测有效负载，是 ASCII 编码的 JSON。 因此，必须先对齐进行解码，然后反序列化，才能访问遥测属性。

    > 提示：若要详细了解事件架构，请参阅以下资源：
    > * [事件架构](https://docs.microsoft.com/azure/azure-functions/functions-bindings-event-grid-trigger?tabs=csharp%2Cbash#event-schema)

1. 若要检查更新 ADT 孪生体的代码，请找到 `// REVIEW ADT update code below here` 注释并查看其下方的代码：

    ```csharp
    //Update twin
    var patch = new Azure.JsonPatchDocument();
    patch.AppendReplace<bool>("/fanAlert", fanAlert); // already a bool
    patch.AppendReplace<bool>("/temperatureAlert", temperatureAlert.Value<bool>()); // convert the JToken value to bool
    patch.AppendReplace<bool>("/humidityAlert", humidityAlert.Value<bool>()); // convert the JToken value to bool

    await client.UpdateDigitalTwinAsync(deviceId, patch);

    // publish telemetry
    await client.PublishTelemetryAsync(deviceId, null, bodyJson);
    ```

    现在有两种方法可将数据应用到数字孪生体 - 第一种是通过使用 JSON 补丁进行属性更新，第二种是通过发布遥测数据。

    ADT 客户端利用 JSON 补丁文档来添加或更新数字孪生体属性。 JSON 补丁定义了 JSON 文档结构，用于表达要应用到 JSON 文档的一系列操作。 各种值作为追加或替换操作添加到补丁，然后异步更新 ADT。

   > 提示：若要详细了解 JSON 补丁文档，请参阅以下资源：
   > * [JavaScript 对象表示法 (JSON) 补丁](https://tools.ietf.org/html/rfc6902)
   > * [什么是 JSON 补丁？](http://jsonpatch.com/)
   > * [JsonPatchDocument 类](https://docs.microsoft.com/dotnet/api/azure.jsonpatchdocument?view=azure-dotnet)

   > **重要说明**：在使用 `AppendReplace` 操作之前，数字孪生实例必须具有现有值。

   注意遥测数据的处理方式与属性不同 - 不是用于设置数字孪生体属性，而是被发布为遥测事件。 此机制可确保遥测可被任何下游订阅者用于数字孪生事件路由。

   > 注意：必须先定义数字孪生事件路由，再发布遥测消息，否则就不会路由消息供使用。

现可以发布函数。

> 注意：TelemetryFunction.cs 函数将在稍后的任务中进行审查。

#### <a name="task-3---publish-functions"></a>任务 3 - 发布函数

1. 在适用于 Visual Studio Code 的 Azure Functions 扩展中，选择“部署到函数应用”：

    ![Visual Studio Code 部署到函数应用](media/LAB_AK_19-deploy-to-function-app.png)

1. 系统提示时，作出以下选择：

    * **登录到 Azure**：出现提示时，请登录到 Azure
    * **选择订阅**：出现提示时，选择要用于此课程的订阅。
    * 选择 Azure 中的函数应用：选择“func-az220-hub2adt-training-{your-id}”。

    当系统提示确认部署时，请单击“部署”。

    随后将编译函数，如果编译成功则部署它。 这可能需要一小段时间。

1. 部署完成后，将显示以下提示：

    ![Visual Studio Code 部署完成 - 选择流式传输日志](media/LAB_AK_19-function-stream-logs.png)

    在确认对话中单击“流式传输日志”以启用应用程序记录，然后单击“是”。 

    “输出”窗格现在会显示已部署函数的日志流 - 这将在 2 小时后超时。 将显示一些状态信息，但在启动函数前，不会显示来自该函数本身的任何诊断信息。 这将在下一个练习中介绍。

    可随时在 Visual Studio Code 中右键单击 Azure 函数，并选择“开始流式传输日志”或“停止流式传输日志”，以开始或停止流式传输 ：

    ![Visual Studio Code Azure 函数开始流式传输日志](media/LAB_AK_19-start-function-streaming.png)

### <a name="exercise-7---connect-iot-hub-to-the-azure-function"></a>练习 7 - 将IoT 中心连接到 Azure 函数

在此练习中，设置脚本创建的 IoT 中心将被配置为发布事件，就像对于上一练习中创建的 Azure 函数一样。 然后，将之前创建的设备模拟器的遥测路由到 ADT 实例。

1. 打开浏览器并导航到 [Azure 门户](https://portal.azure.com/)。

1. 导航到 iot-az220-training-{your-id} IoT 中心。

1. 在左侧导航区域中，选择“事件”。

1. 若要添加事件订阅，请单击“+ 事件订阅”。

1. 在“事件订阅详细信息”部分的“名称”字段中，输入“device-telemetry”。  

1. 在“事件网格架构”下拉列表中，确保选择了“事件网格架构”。

1. 在“主题详细信息”部分，验证“主题类型”已设置为“IoT 中心”，“源资源”已设置为“iot-az220-training-{your-id}”。    

1. 在“系统主题名称”字段，输入“Twin-Topic” 

1. 在“事件类型”部分的“筛选事件类型”下拉列表中，仅选择“设备遥测” 。

1. 在“终结点详细信息”部分的“终结点类型”下拉列表中，选择“Azure 函数”。  

    注意 UI 更新以提供终结点的选择。

1. 在“终结点”字段中，单击“选择终结点”。 

1. 在“选择 Azure 函数”窗格中的“订阅”之下，确保选择了正确的订阅。 

1. 在“资源组”下方，确保选择“rg-az220”。 

1. 在“函数应用”下，选择“func-az220-hub2adt-training-{your-id}” 。

1. 在“槽位”下，确认已选择“生产” 。

1. 在“函数”下，确认选择了“HubToAdtFunction”。 

1. 要选择此终结点，请单击“确认选择”。

1. 验证“HubToAdtFunction”现在是指定的终结点。

    在“创建事件订阅”窗格上的“终结点详细信息”部分，“终结点”字段现在应会显示“HubToAdtFunction”。   

1. 要创建此事件订阅，请单击“创建”。

    创建订阅后，应该能在上一个练习中配置的 Azure Functions 日志流中看到消息。 Azure Functions 日志流显示了从事件网格接收到的遥测数据。 它还显示了在连接到 Azure 数字孪生或更新孪生体时出现的任何错误。

    成功函数调用的日志输出应类似于：

    ```log
    2021-03-12T19:14:17.180 [Information] Executing 'HubToAdtFunction' (Reason='EventGrid trigger fired at 2021-03-12T19:14:17.1797847+00:00', Id=88d9f9e8-5cfa-4a20-a4cb-36e07a78acd6)
    2021-03-12T19:14:17.180 [Information] {
    "properties": {
        "sensorID": "S1",
        "fanAlert": "false",
        "temperatureAlert": "true",
        "humidityAlert": "true"
    },
    "systemProperties": {
        "iothub-connection-device-id": "sensor-th-0055",
        "iothub-connection-auth-method": "{\"scope\":\"device\",\"type\":\"sas\",\"issuer\":\"iothub\",\"acceptingIpFilterRule\":null}",
        "iothub-connection-auth-generation-id": "637508617957275763",
        "iothub-enqueuedtime": "2021-03-12T19:14:16.824Z",
        "iothub-message-source": "Telemetry"
    },
    "body": "eyJ0ZW1wZXJhdHVyZSI6NjkuNDcsImh1bWlkaXR5Ijo5Ny44OX0="
    }
    2021-03-12T19:14:17.181 [Information] Azure digital twins service client connection created.
    2021-03-12T19:14:17.181 [Information] Device:sensor-th-0055 fanAlert is:False
    2021-03-12T19:14:17.181 [Information] Device:sensor-th-0055 temperatureAlert is:true
    2021-03-12T19:14:17.181 [Information] Device:sensor-th-0055 humidityAlert is:true
    2021-03-12T19:14:17.181 [Information] Device:sensor-th-0055 Temperature is:69.47
    2021-03-12T19:14:17.181 [Information] Device:sensor-th-0055 Humidity is:97.89
    2021-03-12T19:14:17.182 [Information] Executed 'HubToAdtFunction' (Succeeded, Id=88d9f9e8-5cfa-4a20-a4cb-36e07a78acd6, Duration=2ms)
    ```

    未找到数字孪生实例时的示例日志如下：

    ```log
    2021-03-11T16:35:43.646 [Information] Executing 'HubToAdtFunction' (Reason='EventGrid trigger fired at 2021-03-11T16:35:43.6457834+00:00', Id=9f7a3611-0795-4da7-ac8c-0b380310f4db)
    2021-03-11T16:35:43.646 [Information] {
    "properties": {
        "sensorID": "S1",
        "fanAlert": "false",
        "temperatureAlert": "true",
        "humidityAlert": "true"
    },
    "systemProperties": {
        "iothub-connection-device-id": "sensor-th-0055",
        "iothub-connection-auth-method": "{\"scope\":\"device\",\"type\":\"sas\",\"issuer\":\"iothub\",\"acceptingIpFilterRule\":null}",
        "iothub-connection-auth-generation-id": "637508617957275763",
        "iothub-enqueuedtime": "2021-03-11T16:35:43.279Z",
        "iothub-message-source": "Telemetry"
    },
    "body": "eyJ0ZW1wZXJhdHVyZSI6NjkuNzMsImh1bWlkaXR5Ijo5OC4wOH0="
    }
    2021-03-11T16:35:43.646 [Information] Azure digital twins service client connection created.
    2021-03-11T16:35:43.647 [Information] Device:sensor-th-0055 fanAlert is:False
    2021-03-11T16:35:43.647 [Information] Device:sensor-th-0055 temperatureAlert is:true
    2021-03-11T16:35:43.647 [Information] Device:sensor-th-0055 humidityAlert is:true
    2021-03-11T16:35:43.647 [Information] Device:sensor-th-0055 Temperature is:69.73
    2021-03-11T16:35:43.647 [Information] Device:sensor-th-0055 Humidity is:98.08
    2021-03-11T16:35:43.648 [Information] Executed 'HubToAdtFunction' (Succeeded, Id=9f7a3611-0795-4da7-ac8c-0b380310f4db, Duration=2ms)
    2021-03-11T16:35:43.728 [Error] Service request failed.
    Status: 404 (Not Found)

    Content:
    {"error":{"code":"DigitalTwinNotFound","message":"There is no digital twin instance that exists with the ID sensor-th-0055. Please verify that the twin id is valid and ensure that the twin is not deleted. See section on querying the twins http://aka.ms/adtv2query."}}

    Headers:
    Strict-Transport-Security: REDACTED
    traceresponse: REDACTED
    Date: Thu, 11 Mar 2021 16:35:43 GMT
    Content-Length: 267
    Content-Type: application/json; charset=utf-8
    ```

1. 在浏览器中返回到“ADT 资源管理器”实例，并查询图表。

    应可看到 fanAlert、temperatureAlert 和 humidityAlert 属性已更新。

此时，演示了从设备（在本例中为设备模拟器）到 ADT 的数据引入。 下一个练习将演示如何将遥测数据流式传输到时序见解 (TSI)。

### <a name="exercise-8---connect-adt-to-tsi"></a>练习 8 - 将 ADT 连接到 TSI

在此练习中，你将完成概念验证的最后一个部分 - 使用模拟器流式传输从 Cheese Cave 设备传感器发送的设备遥测（通过 Azure 数字孪生到时序见解）。

> 注意：此实验室的设置脚本创建了将在此练习中使用的 Azure 存储帐户、时序见解环境和访问策略。

从 ADT 到 TSI 的事件数据路由由以下基本流程实现：

* ADT 将通知事件发送到事件中心 (adt2func)
* Azure 函数由来自 adt2func 事件中心的事件触发，为 TSI 创建新事件，添加分区键并发布到其他事件中心 (func2tsi)
* TSI 订阅发布到 func2tsi 事件中心的事件。

为了实现此流，必须创建以下资源（除 ADT 和 TSI 外）：

* Azure Function
* 事件中心命名空间
* 两个事件中心 - 一个用于从 ADT 到 Azure 函数的事件，另一个用于针对 TSI 的 Azure 函数的事件。

Azure 函数可用于许多用途：

* 将特定于设备的遥测消息格式（属性名称、数据类型等）映射到 TSI 的单个格式。 这可以提供跨不同设备的合并视图，以及将 TSI 解决方案与对解决方案的其他部分的更改隔离开。
* 从其他源扩充消息
* 将一个字段添加到每个事件，用作 TSI 中的时序 ID 属性。

#### <a name="task-1---create-event-hub-namespace"></a>任务 1 - 创建事件中心命名空间

事件中心命名空间提供 DNS 集成网络终结点与一系列的访问控制和网络集成管理功能（例如 IP 筛选、虚拟网络服务终结点和专用链接），并且是用于多个事件中心实例（或 Kafka 用语中的“主题”）之一的管理容器。 此解决方案所需的两个事件中心将在此命名空间中创建。

1. 使用你的 Azure 帐户凭据登录到 [portal.azure.com](https://portal.azure.com)。

1. 在 Azure 门户菜单上，单击“+ 创建资源”。

1. 在“搜索”文本框中，键入“事件中心”，然后单击“事件中心”搜索结果。 

1. 要创建“事件中心”，请单击“创建”。 

    随即将打开“创建命名空间”页面。

1. 在“创建命名空间”边栏选项卡的“订阅”下拉列表上，确保已选择用于此课程的 Azure 订阅。

1. 在“资源组”的右侧，打开下拉列表，然后单击“rg-az220”

1. 在“Namespace 名称”字段，输入 evhns-az220-training-{your-id} 。

    此资源公开可访问，且必须具有唯一名称。

1. 在“位置”的右侧，打开下拉列表并选择为资源组所选的相同位置。

1. 在“定价层”右侧，打开下拉列表并选择“标准”。 

    > 提示：在此练习中，“基本”层也会发挥作用，但在大多数生产场景中，“标准”将会是更好的选择： 
    >
    > * **基本**
    >   * 1 个使用者组
    >   * 100 个中转连接
    >   * 入口事件 - 0.028 美元/百万（编写本文时）
    >   * 消息保留 - 1 天
    > * **标准**
    >   * 20 使用者组
    >   * 1000 个中转连接
    >   * 入口事件 - 0.028 美元/百万（编写本文时）
    >   * 消息保留 - 1 天
    >   * 额外存储 - 多达 7 天
    >   * 发布者策略

1. 在“吞吐量单位”右侧，将选择保留为“1” 。

    > 提示：事件中心的吞吐量容量由吞吐量单位控制。 吞吐量单位是预先购买的容量单位。 单个吞吐量是指：
    >
    > * 入口：最高每秒 1 MB 或每秒 1000 个事件（以先达到的限制为准）。
    > * 出口：最高每秒 2 MB，或每秒 4096 个事件。

1. 取消勾选“启用自动膨胀”复选框。

    当流量超出为标准层事件中心命名空间分配的吞吐量单位容量时，“自动膨胀”会自动缩放分配给该命名空间的吞吐量单位数量。 你可以指定命名空间自动缩放的限制。

1. 要开始输入的数据验证，请单击“查看 + 创建”。

1. 验证成功后，单击“创建”。

    资源将在几分钟后部署。 单击“转到资源”。

此命名空间将包含用于将数字孪生遥测与 Azure 函数集成的事件中心，以及将采用 Azure 函数的输出并将其与时序见解集成的事件中心。

#### <a name="task-2---add-an-event-hub-for-adt"></a>任务 2 - 为 ADT 添加事件中心

此任务会创建将订阅孪生遥测事件并将其传递到 Azure 函数的事件中心。

1. 在“evhns-az220-training-{your-id}”命名空间的“概述”页面上，单击“+ 事件中心”  。

1. 在“创建事件中心”页面上的“名称”下，输入“evh-az220-adt2func”。

    > **注意**：由于事件中心限定在全局唯一的命名空间范围内，因此事件中心名称本身不必是全局唯一的。

1. 在“分区计数”下，将值保留为“1” 。

    > 提示：分区是一种与使用应用程序所需的下游并行性有关的数据组织机制。 事件中心的分区数与预期会有的并发读取者数直接相关。

1. 在“消息保留”下，将值保留为“1” 。

    > 提示：这是事件的保留期。 你可以将保留期设置为 1 到 7 天。

1. 在“捕获”下，将值设置保留为“关” 。

    > 提示：通过 Azure 事件中心捕获功能，可自动将事件中心的流式数据发送到所选的 Azure Blob 存储或 Azure Data Lake Store 帐户，同时还可以灵活地指定时间间隔或大小差异。 设置捕获极其简单，无需管理费用即可运行它，并且可以使用事件中心吞吐量单位自动进行缩放。 事件中心捕获是在 Azure 中加载流式处理数据的最简单方法，并可让用户专注于数据处理，而不是数据捕获。

1. 要创建事件中心，请单击“创建”。

    一段时间后，会创建事件中心且显示事件中心命名空间“概述”。 如有必要，滚动到页面底部，evh-az220-adt2func 事件中心会列出。

#### <a name="task-3---add-an-authorization-rule-to-the-event-hub"></a>任务 3 - 将授权规则添加到事件中心

每个事件中心命名空间和事件中心实体（事件中心实例或 Kafka 主题）都有一个由规则构成的共享访问授权策略。 命名空间级别的策略应用到该命名空间中的所有实体，不管这些实体各自的策略配置如何。 对于每个授权策略规则，需要确定三个信息片段：名称、范围和权限。 名称是该范围内的唯一名称。 范围是相关资源的 URI。 对于事件中心命名空间，范围是完全限定的域名 (FQDN)，例如 `https://evhns-az220-training-{your-id}.servicebus.windows.net/`。

策略规则提供的权限可以是以下各项的组合：

* “发送”- 授予向实体发送消息的权限
* “侦听”- 授予向实体侦听或接收的权限
* “管理”- 授予管理命名空间的拓扑的权限，包括创建和删除实体

在此任务中，将创建“侦听”和“发送”权限的授权规则。 

1. 在“evhns-az220-training-{your-id}”命名空间的“概述”页面上，单击“evh-az220-adt2func 事件中心”  。

1. 在左侧导航区域的“设置”下，单击“共享访问策略”。

    随即显示特定于此事件中心的策略的空列表。

1. 要创建新的授权规则，单击“+ 添加”。

1. 在“添加 SAS 策略”窗格的策略名称下，输入“ADTHubPolicy”。 

1. 在权限的列表中，仅勾选“发送”和“侦听”。 

1. 单击“创建”保存授权规则。

    片刻之后，窗格关闭，策略列表刷新。

1. 要检索授权规则的主要连接字符串，单击列表中的 ADTHubPolicy。

    “SAS 策略 **:ADTHubPolicy”窗格随即打开**。

1. 复制“连接字符串主键”值并将其添加到名为 telemetry-function.txt 的新的文本文件 。

1. 关闭“SAS 策略 **:ADTHubPolicy”窗格**。

#### <a name="task-4---add-an-event-hub-endpoint-to-the-adt-instance"></a>任务 4 - 将事件中心终结点添加到 ADT 实例

现在已创建事件中心，它必须添加为 ADT 实例可用作输出以发送事件的终结点。

1. 导航到 adt-az229-training-{your-id} 实例。

1. 在左侧导航区域的“连接输出”下，单击“终结点”。

    此时将显示终结点列表。

1. 要添加新的终结点，单击“+ 创建终结点”。

1. 在“创建终结点”窗格中的“名称”下，输入“eventhub-endpoint”。  

1. 在“终结点类型”下，选择“事件中心”。 

    UI 会更新以包括用于指定事件中心详细信息的字段。

1. 在“订阅”下拉列表中，请确保已选择为本课程使用的 Azure 订阅。

1. 在“事件中心命名空间”下拉列表中，选择“evhns-az220-training-{your-id}” 。

1. 在“事件中心”下拉列表中，选择“evh-az220-adt2func”。 

1. 在“授权规则”下拉列表中，选择“ADTHubPolicy” 。

   这是之前创建的授权规则。

1. 要创建终结点，请单击“保存”。

    窗格关闭，片刻后，终结点列表会刷新以包括新终结点。

#### <a name="task-5---add-a-route-to-send-telemetry-to-the-event-hub"></a>任务 5 - 添加将遥测发送到事件中心的路由

将事件中心终结点添加到 ADT 实例后，现在有必要创建将孪生遥测事件发送到此终结点的路由。

1. 在左侧导航区域的“连接输出”下，单击“事件路由”。

    此时将显示现有路由的列表。

1. 要添加新的事件路由，单击“+ 创建事件路由”。

1. 在“创建事件路由”窗格中的“名称”下，输入“eventhub-telemetryeventroute”。  

1. 在“终结点”下拉列表中，选择“eventhub-endpoint” 。

1. 在“添加事件路由筛选器”下，将“高级编辑器”保持在禁用状态 。

    高级编辑器支持输入特定的筛选表达式 - 对于此任务，UI 已足够。

1. 在“事件类型”下拉列表中，仅选择“遥测”。 

    请注意，“筛选器”字段显示生成的筛选表达式。

1. 要创建事件路由，请单击“保存”。

    窗格关闭，片刻后，事件路由列表会刷新以包括新路由。

#### <a name="task-6---create-tsi-event-hub-and-policy"></a>任务 6 - 创建 TSI 事件中心和策略

此时将使用 Azure CLI 创建事件中心和授权规则。

1. 返回命令提示符并通过输入以下内容验证会话是否仍处于登录状态：

    ```powershell
    az account list
    ```

    如果系统提示运行 `az login`，请执行此操作并登录。

1. 要在 Azure 函数和 TSI 之间创建事件中心，请输入以下命令：

    ```powershell
    az eventhubs eventhub create --name evh-az220-func2tsi --resource-group rg-az220 --namespace-name evhns-az220-training-{your-id}
    ```

    记得替换 {your-id}。

1. 要在新的事件中心上创建具有侦听和发送权限的授权规则，请输入以下命令：

    ```powershell
    az eventhubs eventhub authorization-rule create --rights Listen Send --resource-group rg-az220  --eventhub-name evh-az220-func2tsi --name TSIHubPolicy --namespace-name evhns-az220-training-{your-id}
    ```

    记得替换 {your-id}。

1. 要检索授权规则的主要连接字符串，输入以下命令：

    ```powershell
    az eventhubs eventhub authorization-rule keys list --resource-group rg-az220 --eventhub-name evh-az220-func2tsi --name TSIHubPolicy --namespace-name evhns-az220-training-{your-id} --query primaryConnectionString -o tsv
    ```

    记得替换 {your-id}。

    输出结果会类似于：

    ```text
    Endpoint=sb://evhns-az220-training-dm030821.servicebus.windows.net/;SharedAccessKeyName=TSIHubPolicy;SharedAccessKey=x4xItgUG6clhGR9pZe/U6JqrNV+drIfu1rlvYHEdk9I=;EntityPath=evh-az220-func2tsi
    ```

1. 复制“连接字符串主键”值并将其添加到名为 telemetry-function.txt 的文本文件 。

    下一个文本任务中将需要两个连接字符串。

#### <a name="task-7---add-the-endpoint-addresses-as-app-settings-for-azure-function"></a>任务 7 - 将终结点地址添加为 Azure 函数的应用设置

为了让 Azure 函数连接到事件中心，它必须可以通过适当的权限访问策略的连接字符串。 在此场景中，涉及两个事件中心：发布来自 ADT 的事件的中心以及将由 Azure 函数转换的数据发送到 TSI 的中心。

1. 要将事件中心授权规则连接字符串作为环境变量提供，请在 Azure 门户中，导航到 func-az220-hub2adt-training-{your-id} 实例。

1. 在左侧导航区域的“设置”下，单击“配置”。

1. 在“配置”页面上的“应用程序设置”选项卡上，查看列出的当前的“应用程序设置”。  

    应列出之前通过 CLI 添加的 ADT_SERVICE_URL。

1. 要添加 adt2func 规则连接字符串的环境变量，请单击“+ 新建应用程序设置”。

1. 在“添加/编辑应用程序设置”窗格上的“名称”字段中，输入“ADT_HUB_CONNECTIONSTRING”  

1. 在“值”字段中，输入保存到之前任务中的“telemetry-function.txt”文件中的授权规则连接字符串值（结尾为 `EntityPath=evh-az220-adt2func`） 。

    值应类似于 `Endpoint=sb://evhns-az220-training-dm030821.servicebus.windows.net/;SharedAccessKeyName=ADTHubPolicy;SharedAccessKey=fHnhXtgjRGpC+rR0LFfntlsMg3Z/vjI2z9yBb9MRDGc=;EntityPath=evh-az220-adt2func`。

1. 要关闭该窗格，请单击“确定”。

    > 注意：设置尚未保存。

1. 要添加 func2tsi 规则连接字符串的环境变量，请单击“+ 新建应用程序设置”。

1. 在“添加/编辑应用程序设置”窗格上的“名称”字段中，输入“TSI_HUB_CONNECTIONSTRING”  

1. 在“值”字段中，输入保存到之前任务中的“telemetry-function.txt”文件中的授权规则连接字符串值（结尾为 `EntityPath=evh-az220-func2tsi`） 。

    值应类似于 `Endpoint=sb://evhns-az220-training-dm030821.servicebus.windows.net/;SharedAccessKeyName=TSIHubPolicy;SharedAccessKey=x4xItgUG6clhGR9pZe/U6JqrNV+drIfu1rlvYHEdk9I=;EntityPath=evh-az220-func2tsi`

1. 要关闭该窗格，请单击“确定”。

    > 注意：设置尚未保存。

1. 要保存两个新设置，单击“保存”和“继续”。 

    > 注意：任何对应用设置的更改将重启函数。

#### <a name="task-8---review-a-telemetry-azure-function"></a>任务 8 - 查看遥测 Azure 函数

在此任务中，将评审第二个 Azure 函数。 此函数负责将设备遥测消息映射到 TSI 的其他格式。 此方法的优点是可以处理对设备遥测格式的更改，而无需更改 TSI 解决方案。

1. 在 Visual Studio Code 中，打开 Contoso.AdtFunctions 项目。

1. 打开 TelemetryFunction.cs 文件。

1. 找到 Run 方法定义并查看代码。

    ```csharp
    public static class TelemetryFunction
    {
        [FunctionName("TelemetryFunction")]
        public static async Task Run(
            [EventHubTrigger("evh-az220-adt2func", Connection = "ADT_HUB_CONNECTIONSTRING")] EventData[] events,
            [EventHub("evh-az220-func2tsi", Connection = "TSI_HUB_CONNECTIONSTRING")] IAsyncCollector<string> outputEvents,
            ILogger log)
        {
            var exceptions = new List<Exception>();

            foreach (EventData eventData in events)
            {
                try
                {
                    // main processing code here
                }
                catch (Exception e)
                {
                    // We need to keep processing the rest of the batch - capture this exception and continue.
                    // Also, consider capturing details of the message that failed processing so it can be processed again later.
                    exceptions.Add(e);
                }
            }

            // Once processing of the batch is complete, if any messages in the batch failed processing throw an exception so that there is a record of the failure.

            if (exceptions.Count > 1)
                throw new AggregateException(exceptions);

            if (exceptions.Count == 1)
                throw exceptions.Single();
        }
    }
    ```

    花一点时间查看 Run 方法定义。 events 参数使用 EventHubTrigger 属性 - 属性的构造函数采用事件中心的名称、使用者组的可选名称（如果省略则使用 $Default）和包含连接字符串的应用设置的名称   。 这会配置函数触发器以响应发送到事件中心事件流的事件。 事件定义为一系列 EventData，可使用事件批次填充。

    > 提示：要详细了解 EventHubTrigger，请查看以下资源： [适用于 Azure Functions 的 Azure 事件中心触发器](https://docs.microsoft.com/azure/azure-functions/functions-bindings-event-hubs-trigger?tabs=csharp)

    下一个参数 outputEvents 具有 EventHub 属性 - 该属性的构造函数使用事件中心的名称和包含连接字符串的应用设置的名称。  将数据添加到 outputEvents 变量会将其发布到相关的事件中心。

    由于此函数会处理事件批次，处理错误的方式是创建用于保留异常的集合。 随后函数将迭代批次中的每个事件，从而捕获异常并将其添加到集合。 跳到方法的末尾，你会发现，如果有多个异常，则会创建带有集合的 AggregaeException，如果生成了单个异常，则会引发单个异常。

1. 若要查看检查事件是否包含奶酪储藏室设备遥测的代码，请找到 `// REVIEW check telemetry below here` 注释并查看其下方的代码：

    ```csharp
    if ((string)eventData.Properties["cloudEvents:type"] == "microsoft.iot.telemetry" &&
        (string)eventData.Properties["cloudEvents:dataschema"] == "dtmi:com:contoso:digital_factory:cheese_factory:cheese_cave_device;1")
    {
        // REVIEW TSI Event creation below here
    }
    else
    {
        log.LogInformation($"Not Cheese Cave Device telemetry");
        await Task.Yield();
    }
    ```

    此代码检查当前事件是否是来自 Cheese Cave 设备 ADT 孪生的遥测 - 如果不是，记录下来，然后强制该方法异步完成 - 这样能更好地利用资源。

    > 提示：要了解有关使用 `await Task.Yield();` 的详细信息，请查看以下资源：
    > * [Task.Yield 方法](https://docs.microsoft.com/dotnet/api/system.threading.tasks.task.yield?view=net-5.0)

1. 若要查看处理事件并为 TSI 创建消息的代码，请找到 `// REVIEW TSI Event creation below here` 注释并查看其下方的代码：

    ```csharp
    // The event is Cheese Cave Device Telemetry
    string messageBody = Encoding.UTF8.GetString(eventData.Body.Array, eventData.Body.Offset, eventData.Body.Count);
    JObject message = (JObject)JsonConvert.DeserializeObject(messageBody);

    var tsiUpdate = new Dictionary<string, object>();
    tsiUpdate.Add("$dtId", eventData.Properties["cloudEvents:source"]);
    tsiUpdate.Add("temperature", message["temperature"]);
    tsiUpdate.Add("humidity", message["humidity"]);

    var tsiUpdateMessage = JsonConvert.SerializeObject(tsiUpdate);
    log.LogInformation($"TSI event: {tsiUpdateMessage}");

    await outputEvents.AddAsync(tsiUpdateMessage);
    ```

    由于 eventData.Body 定义为 ArraySegment（而不是仅仅是数组），必须提取包含 messageBody 的基础数组的部分，然后进行反序列化。  

    > 提示：要详细了解 ArraySegment，请查看以下内容：
    > * [ArraySegment&lt;T&gt; 结构](https://docs.microsoft.com/dotnet/api/system.arraysegment-1?view=net-5.0)

    字典随后被实例化以保留组成在 TSI 事件中发送的属性的键/值对。 请注意 cloudEvents:source 属性（包含完全限定的孪生 ID，与 `adt-az220-training-dm030821.api.eus.digitaltwins.azure.net/digitaltwins/sensor-th-0055` 类似）被分配给 \$dtId 键 。 此键具有与设置过程中创建的时序见解环境相同的含义，将 \$dtId 用作时序 ID 属性 。

    温度和湿度值从消息中提取并添加到 TSI 更新 。

    随后更新序列化为 JSON，并添加到 outputEvents，outputEvents 将更新发布到事件中心。

    现在可以发布函数。

#### <a name="task-9---publish-the-function-app-to-azure"></a>任务 9 - 将函数应用发布到 Azure

1. 在适用于 Visual Studio Code 的 Azure Functions 扩展中，选择“部署到函数应用”：

    ![Visual Studio Code 部署到函数应用](media/LAB_AK_19-deploy-to-function-app.png)

1. 系统提示时，作出以下选择：

    * **选择订阅**：出现提示时，选择要用于此课程的订阅。
    * 选择 Azure 中的函数应用：选择“func-az220-hub2adt-training-{your-id}”。

    当系统提示确认部署时，请单击“部署”。

    随后将编译函数，如果编译成功则部署它。 这可能需要一小段时间。

1. 部署完成后，将显示以下提示：

    ![Visual Studio Code 部署完成 - 选择流式传输日志](media/LAB_AK_19-function-stream-logs.png)

    在确认对话中单击“流式传输日志”以启用应用程序记录，然后单击“是”。 

    “输出”窗格现在会显示已部署函数的日志流 - 这将在 2 小时后超时。 将显示一些状态信息，但在启动函数前，不会显示来自该函数本身的任何诊断信息。 这将在下一个练习中介绍。

    可随时在 Visual Studio Code 中右键单击 Azure 函数，并选择“开始流式传输日志”或“停止流式传输日志”，以开始或停止流式传输 ：

    ![Visual Studio Code Azure 函数开始流式传输日志](media/LAB_AK_19-start-function-streaming.png)

#### <a name="task-10---configure-tsi"></a>任务 10 - 配置 TSI

1. 在浏览器中，连接到 Azure 门户并找到 tsi-az220-training-{your-id} 资源。

    > 注意：此资源由设置脚本创建。 如果尚未运行，请运行 - 脚本不会影响现有资源。

1. 在“概述”窗格的“概要”部分中，找到“时序 ID 属性”字段和值“$dtid”。    此值在创建 TSI 环境时指定，应与流式传输到 TSI 的事件数据中的一个字段匹配。

    > **重要说明**：“时序 ID 属性”值在创建 TSI 环境时指定，此后不能更改。

1. 在左侧导航区域的“设置”下，单击“事件源”。

    随即显示“事件源”列表 - 此时，它应该是空的。

1. 若要添加新事件源，请单击“+ 添加”。

1. 在“新建事件源”窗格中的“事件源名称”下，输入“adt-telemetry”  

1. 在“源”下，选择“事件中心”。 

1. 在“导入选项”下，选择“使用来自可用订阅的事件中心” 。

1. 在“订阅 ID”下，选择要用于此课程的订阅。

1. 在“事件中心命名空间”下，选择“echns-az220-training-{your-id}” 

1. 在“事件中心名称”下，选择“evh-az220-func2tsi”。 

1. 在“事件中心策略值”下，选择“TSIHubPolicy” 。

    请注意，只读字段“事件中心策略键”会自动填充。

1. 在“事件中心使用者组”下，选择“$Default” 。

    > 提示：由于 evh-az220-func2tsi 事件中心只有一个事件读取者，因此可以使用 $Default 使用者组 。 如果添加了更多读取者，则建议针对每个读取者使用一个使用者组。 使用者组在事件中心上创建。

1. 在“开始时间”下，选择“我的所有数据” 。

    请注意，还有其他可用选项，例如“现在开始(默认)”，它们可能更适合生产环境。

1. 在“事件序列化格式”下，请注意只读值是 JSON 。

1. 在“时间戳属性名称”下，将值留空。

    > 提示：这指定应用作事件时间戳的事件属性的名称。 如果不指定，则事件源中的“事件排队时间”将用作事件时间戳。

1. 要创建事件源，请单击“保存”。

#### <a name="task-11---visualize-the-telemetry-data-in-time-series-insights"></a>任务 11 - 可视化时序见解中的遥测数据

数据现在应流向时序见解实例并且可供分析。 按照以下步骤浏览传入的数据。

1. 在浏览器中，返回 tsi-az220-training-{your-id} 资源的“概述”窗格 。

1. 要导航到“TSI 资源管理器”，单击“转到 TSI 资源管理器” 。

    “TSI 资源管理器”将在浏览器中的新选项卡中打开。

1. 在资源管理器中，你将看到左侧显示 Azure 数字孪生。

    ![TSI 资源管理器数据](media/LAB_AK_19-tsi-explorer.png)

1. 要将遥测添加到图，单击孪生并选择“EventCount”、“湿度”和“温度”。  

    选择合适的时间范围，显示的数据将类似于：

    ![显示时序数据的 TSI 资源管理器](media/LAB_AK_19-tsi-explorer-data.png)

    > **注意**：可能需要一些时间才能显示充足的数据。

默认情况下，数字孪生存储在时序见解的平层次结构中，但是它们可以通过模型信息和组织的多级别层次结构扩充。 你可以编写自定义逻辑，以使用已存储在 Azure 数字孪生中的模型和图数据自动提供此信息。

恭喜 - 你现在正在将设备遥测数据传递给时序见解。
