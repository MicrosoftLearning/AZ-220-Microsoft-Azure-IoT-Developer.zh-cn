# 演示：探索 Active Directory 用户和组

>**备注：** “Active Directory”边栏选项卡的可用区域取决于你的订阅。

## 确定域信息

1. 访问 Azure 门户，并导航到“**Azure Active Directory**”边栏选项卡。
2. 记下你的可用域名。例如 usergmail.onmicrosoft.com。

## 浏览用户帐户

1. 选择“**用户**”边栏选项卡。
2. 选择“**新建用户**”。 
3. 请注意选择创建“**新来宾用户**”。
4. 创建**新用户**。替换你的域。 

    + **名称**： *Chris Green*
    + **地址**： *chris@your domain*
    + **个人资料信息**：输入名称。 
    + **目录角色** - *用户*。

5. 查看“**用户设置**”边栏选项卡。
6. 查看“**审计日志**”边栏选项卡。

## 浏览组帐户

1. 选择“**组**”边栏选项卡。
2. 添加“**新组**”。 

    + **组类型**：*安全性*
    + **组名**：*管理器*
    + **成员身份类型**：*已分配*
    + **成员**：将 *Chris Green* 添加到组中。 

3. 在“**设置**”下，查看“**常规**”边栏选项卡。
4. 在“**活动**”下，查看“**审计日志**”边栏选项卡。

## 浏览 PowerShell 以进行组管理

1. 创建一个名为“**开发人员**”的新组。

    ```
    New-AzADGroup -DisplayName Developers -MailNickname Developers
    ```

2. 检索**开发人员**组 **ObjectId**。

    ```
    Get-AzADGroup
    ```

3. 检索要添加成员的用户 **ObjectId**。

    ```
    Get-AzADUser
    ```

4. 将用户添加到组中。替换 **groupObjectId** 和 **userObjectId**。

    ```
    Add-AzADGroupMember -MemberUserPrincipalName ""myemail@domain.com"" -TargetGroupDisplayName ""MyGroupDisplayName""
    ```

5. 验证组成员。替换 **groupObjectId**。

    ```
    Get-AzADGroupMember -GroupDisplayName "MyGroupDisplayName"
    ```
