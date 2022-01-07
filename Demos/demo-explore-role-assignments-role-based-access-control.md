# 演示：探索角色分配和基于角色的访问控制

## 找到“访问控制”边栏选项卡

1. 访问 Azure 门户，然后选择一个资源组。记下所使用的资源组。 
2. 选择“**访问控制 (IAM)**”边栏选项卡。 
3. 此边栏选项卡可用于许多不同的资源，以便控制访问。

## 查看角色权限

1. 选择“**角色**”选项卡（顶部）。
2. 查看大量可用的内置角色。
3. 双击某个角色，然后选择“**权限**”（顶部）。
4. 继续点击该角色，直到可以查看该角色的**读取、写入和删除**操作。
5. 返回“**访问控制 (IAM)**” 边栏选项卡。

## 添加角色分配

1. 选择“**添加角色分配**”。 

    + **角色**：*所有者*
    + **选择**：*经理*
    + **保存**更改。 

2. 选择“**检查访问**”。
3. **找到** Chris Green。
4. 请注意，他是“管理者”组的成员，并且是所有者。 
5. 请注意，您可以 **拒绝分配**。 

## 探索 PowerShell 命令

1. 打开 Azure Cloud Shell。
2. 选择 PowerShell 下拉列表。
3. 列出角色定义。

    ```PowerShell
    Get-AzRoleDefinition | FT Name, Description
    ```

4. 列出角色的操作。

    ```PowerShell
    Get-AzRoleDefinition owner | FL Actions, NotActions
    ```

5. 列出角色分配。

    ```PowerShell
    Get-AzRoleAssignment -ResourceGroupName <resource group name>
    ```
