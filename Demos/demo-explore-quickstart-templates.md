# 演示：探索快速启动模板

## 探索库

1. 你可以首先浏览到 [Azure 快速启动模板库](https://azure.microsoft.com/resources/templates?azure-portal=true)。在库中，你将找到许多最近更新的热门模板。这些模板可用于 Azure 资源和常用软件包。
2. 浏览多种不同类型的可用模板。
3. 是否有你感兴趣的模板？

## 探索模板

1. 假设浏览 <a href="https://azure.microsoft.com/resources/templates/101-vm-simple-windows?azure-portal=true" target="_blank"><span style="color: #0066cc;" color="#0066cc">部署简单的 Windows VM</span></a> 模板。

    ![部署简单的 Windows VM 页面的屏幕截图](Images/AZ103_Demo_QS_Templates2.png)

    >**备注：**
    >- 借助“**部署到 Azure**”按钮，你可以根据需要直接通过 Azure 门户部署模板。
    >- 向下滚动到使用模板 **PowerShell** 代码。下一个演示将需要 **TemplateURI**。**复制值**。 

```
https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-vm-simple-windows/azuredeploy.json
```

2. 单击“**在 GitHub 上浏览**”，导航到 GitHub 上的模板源代码。

    ![资源管理器模板的 GitHub README 的屏幕截图](Images/AZ103_Demo_QS_Templates3.png)

3. 请注意，从这个页面你也可以**部署到 Azure**。花一点时间查看自述文件。这有助于确定模板是否适合你。  

4. 单击“**可视化**”导航到“**Azure 资源管理器可视化工具**”。

    ![Azure 资源管理器可视化工具显示 Azure 资源。](Images/AZ103_Demo_QS_Templates4.png)

5. 注意构成部署的资源，包括 VM、存储帐户和网络资源。
6. 使用鼠标来排列资源。还可使用鼠标滚轮缩放。
7. 单击标签为“**SimpleWinVM**”的 VM 资源。

    ![Azure 资源管理器可视化工具显示模板的源代码。](Images/AZ103_Demo_QS_Templates5.png)

8. 查看定义 VM 资源的源代码。

    * 资源的类型为 `Microsoft.Compute/virtualMachines`。
    * 其位置或 Azure 区域来自名为 `location` 的模板参数。
    * VM 的大小为“**Standard_A2**”。
    * 计算机名称读取自模板变量，VM 的用户名和密码读取自模板参数。

9. 返回显示模板中文件的“快速入门”页面。将链接复制到 azuredeploy.json 文件。其将采用以下格式：

>**备注：** 下一个演示将需要模板链接。
