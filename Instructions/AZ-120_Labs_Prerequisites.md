
# AZ 120: 实验室先决条件

## vCPU 核心要求

-   要完成本课程的最后一个实验室，你需要一个 Microsoft Azure 订阅，而且在支持本实验室部署的 Azure VM 所在可用性区域的 Azure 区域中至少有 28 个 vCPU 可用。

    -   4 x Standard_DS1_v2（每个 1 个 vCPU）= 4

    -   6 x Standard_D4s_v3（每个 4 个 vCPU）= 24

    > **备注：** 请考虑使用**美国东部**或**美国东部 2** 区域来部署资源。

    > **备注：** 要确定支持可用性区域的 Azure 区域，请参阅 [https://docs.microsoft.com/zh-cn/azure/availability-zones/az-overview]<https://docs.microsoft.com/zh-cn/azure/availability-zones/az-overview>

虽然本课程前三个实验室的 vCPU 要求较低，但我们建议你请求增加配额以满足所有实验室的要求，因为增加配额可能需要一些时间（即使配额增加请求通常是在请求当天的工作日完成）。

## 动手实验室之前

时间框架：120 分钟

### 任务 1：验证 vCPU 核心数量是否足够

1.  在 Azure 门户网站：<http://portal.azure.com>， 

1.  在 Azure 门户中，在 Cloud Shell 中启动 PowerShell 会话。 

    > **注意**： 如果这是你第一次在当前 Azure 订阅中启动 Cloud Shell，则会要求你创建 Azure 文件共享以保留 Cloud Shell 文件。如果是，请接受默认值，将在自动生成的资源组中创建存储帐户。

1.  在 Azure 门户的 **Cloud Shell** 窗格中，在 PowerShell 提示符处运行以下命令：其中 `<Azure_region>` 指定你打算用于本实验室的目标 Azure 区域（例如 `eastus`）：

    ```powershell
    Get-AzVMUsage -Location '<Azure_region>' | Where-Object {$_.Name.Value -eq 'StandardDSv3Family'}

    Get-AzVMUsage -Location '<Azure_region>' | Where-Object {$_.Name.Value -eq 'StandardDSv2Family'}
    ``` 

    > **注意**：要标识 Azure 区域名称，请在 **Cloud Shell** 中的 Bash 提示符处，运行 `(Get-AzLocation).Location`
   
1.  查看上一步执行命令输出中的当前值和限制条目，并确保目标 Azure 区域中有足够数量的 vCPU。

1.  如果 vCPU 数量不足，请在 Azure 门户中导航回"订阅"边栏选项卡，然后单击**使用 + 配额**。 

1.  在"订阅"的**使用 + 配额**边栏选项卡，单击**请求增加**。

1.  在 **基本**边栏选项卡上，指定以下内容并单击**下一步**：

    -   问题类型：**服务和订阅限制（配额）**

    -   订阅：在本次实验室中你将使用的 Azure 订阅名

    -   配额类型：**计算/VM（核心/vCPU）订阅上限增加**

1.  在**详细信息**边栏选项卡，单击**提供详细信息**边栏选项卡。 

1.  在**配额详细信息**边栏选项卡上，指定下列内容并单击**保存并继续**：

    -   部署模型：**资源管理器**

    -   位置：你打算在本实验室中使用的目标 Azure 区域

    -   SKU 系列：DSv3 **系列**和 **DSv2 系列**

1.  在**详细信息**边栏选项卡，指定每个 SKU 系列的新上限并单击**下一个：查看 + 创建**：

    -   严重性：**C - 影响极小**

    -   首选联系方式：选择你的首选选项并提供联系方式

1.  在 **“查看 + 创建”** 边栏选项卡上，单击 **“创建”**

   > **备注：** 配额增加请求通常在请求当天的工作日完成。