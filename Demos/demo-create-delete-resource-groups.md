# 演示：创建和删除资源组

>**备注**：只有所有者和用户访问管理员角色才能管理资源锁。

## 管理门户中的资源组

1. 访问 Azure 门户。
1. 创建资源组。记住该资源组的名称。 
1. 在资源组的“**设置**”边栏选项卡中选择“**锁**”。
1. 要添加锁，请选择“**添加**”。如果要创建父级锁，请选择父锁。当前选定的资源将从该父锁继承锁。例如，你可以锁定资源组，以将锁应用于其所有资源。
1. 设定锁的“**名称**”和“**锁类型**”。或者，你也可以添加描述该锁的注释。
1. 要删除该锁，请选择省略号，然后单击可用选项中的“**删除**”。

## 使用 PowerShell 管理资源组

1. 访问 Cloud Shell。
2. 创建资源锁，并确认操作。

    ```
        New-AzResourceLock -LockName <lockName> -LockLevel CanNotDelete -ResourceGroupName <resourceGroupName>
    ```

3. 查看资源锁信息。注意 LockId，将在下一步中用它来删除该锁。

    ```
        Get-AzResourceLock
    ```

4. 删除资源锁，并确认操作。 

    ```
        Remove-AzResourceLock -LockName <Name> -ResourceGroupName <Resource Group>
    ```

5. 验证资源锁是否已删除。


    ```
        Get-AzResourceLock
    ```

>**备注：** 配置资源锁、跨资源组移动资源以及删除资源组是认证考试的一部分。
