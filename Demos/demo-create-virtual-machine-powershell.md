# 演示：使用 PowerShell 创建虚拟机

在本演示中，将使用 PowerShell 创建一个虚拟机。

## 创建虚拟机

>**备注：** 你可以使用 Cloud Shell 或本地版本的 PowerShell。 

1. 启动 Cloud Shell。
2. 运行此代码：

```
    # create a resource group
    New-AzResourceGroup -Name myResourceGroup -Location EastUS

    # create the virtual machine 
    # when prompted, provide a username and password to be used as the logon credentials for the VM
    New-AzVm `
        -ResourceGroupName "myResourceGroup" `
        -Name "myVM" `
        -Location "East US" `
        -VirtualNetworkName "myVnet" `
        -SubnetName "mySubnet" `
        -SecurityGroupName "myNetworkSecurityGroup" `
        -PublicIpAddressName "myPublicIpAddress" `
        -OpenPorts 80,3389
```

## 验证在门户中创建的计算机

1. 访问门户并查看您的虚拟机。
2. 验证已创建 **myVM**。
3. 评价VM设置。 
4. 请注意，此Windows设备已连入新虚拟网和子网 
5. 请注意，该命令启动了本机。 
6. 此时，您可使用门户或管理员进行更改。 

## 连接到虚拟机

1. 检索计算机的公用 IP 地址。

```
Get-AzPublicIpAddress -ResourceGroupName "myResourceGroup" | Select "IpAddress"
```
2. 从本地计算机创建 RDP 会话。将 IP 地址替换为 VM 的公共 IP 地址。该命令在 cmd 窗口中运行。

```
mstsc /v:publicIpAddress
```

3. 出现提示时，请提供计算机的登录凭据。请务必 **使用不同的帐户**。将用户名键入本地主机\用户名，输入为虚拟机创建的密码，然后选择 **确定**。在登录过程中，你可能会收到证书警告。选择 **是** 或 **继续** ，创建连接
4. 完成后，关闭与 VM 的 RDP 连接。
5. 清理你的资源。这将需要几分钟时间，然后删除资源组和虚拟机。

```
Remove-AzResourceGroup -Name myResourceGroup 
```
