@description('The unique name for the VM.')
param virtualMachineName string

@description('IoT Edge Device Connection String')
param deviceConnectionString string = ''

@description('VM size')
param virtualMachineSize string = 'Standard_DS1_v2'

@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
param ubuntuOSVersion string = '18.04-LTS'

@description('User name for the Virtual Machine.')
param adminUsername string

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended for production.')
param authenticationType string = 'password'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('Allow SSH traffic through the firewall')
param allowSSH bool = true

var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var nicName_var = 'nic-${virtualMachineName}'
var vmName_var = virtualMachineName
var virtualNetworkName_var = 'vnet-${virtualMachineName}'
var publicIPAddressName_var = 'ip-${virtualMachineName}'
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'subnet-${virtualMachineName}'
var subnet1Prefix = '10.0.0.0/24'
var publicIPAddressType = 'Dynamic'
var vnetID = virtualNetworkName.id
var subnet1Ref = '${vnetID}/subnets/${subnet1Name}'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}
var dcs = deviceConnectionString
var networkSecurityGroupName_var = 'nsg-${virtualMachineName}'
var sshRule = [
  {
    name: 'default-allow-22'
    properties: {
      priority: 1000
      access: 'Allow'
      direction: 'Inbound'
      destinationPortRange: '22'
      protocol: 'Tcp'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
    }
  }
]
var noRule = []

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName_var
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: virtualMachineName
    }
  }
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName_var
  location: resourceGroup().location
  properties: {
    securityRules: (allowSSH ? sshRule : noRule)
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: virtualNetworkName_var
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: nicName_var
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName.id
          }
          subnet: {
            id: subnet1Ref
          }
        }
      }
    ]
  }
}

resource vmName 'Microsoft.Compute/virtualMachines@2016-04-30-preview' = {
  name: vmName_var
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    osProfile: {
      computerName: vmName_var
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      customData: base64('#cloud-config\n\napt:\n  preserve_sources_list: true\n  sources:\n    msft.list:\n      source: "deb https://packages.microsoft.com/ubuntu/18.04/multiarch/prod bionic main"\n      key: |\n        -----BEGIN PGP PUBLIC KEY BLOCK-----\n        Version: GnuPG v1.4.7 (GNU/Linux)\n\n        mQENBFYxWIwBCADAKoZhZlJxGNGWzqV+1OG1xiQeoowKhssGAKvd+buXCGISZJwT\n        LXZqIcIiLP7pqdcZWtE9bSc7yBY2MalDp9Liu0KekywQ6VVX1T72NPf5Ev6x6DLV\n        7aVWsCzUAF+eb7DC9fPuFLEdxmOEYoPjzrQ7cCnSV4JQxAqhU4T6OjbvRazGl3ag\n        OeizPXmRljMtUUttHQZnRhtlzkmwIrUivbfFPD+fEoHJ1+uIdfOzZX8/oKHKLe2j\n        H632kvsNzJFlROVvGLYAk2WRcLu+RjjggixhwiB+Mu/A8Tf4V6b+YppS44q8EvVr\n        M+QvY7LNSOffSO6Slsy9oisGTdfE39nC7pVRABEBAAG0N01pY3Jvc29mdCAoUmVs\n        ZWFzZSBzaWduaW5nKSA8Z3Bnc2VjdXJpdHlAbWljcm9zb2Z0LmNvbT6JATUEEwEC\n        AB8FAlYxWIwCGwMGCwkIBwMCBBUCCAMDFgIBAh4BAheAAAoJEOs+lK2+EinPGpsH\n        /32vKy29Hg51H9dfFJMx0/a/F+5vKeCeVqimvyTM04C+XENNuSbYZ3eRPHGHFLqe\n        MNGxsfb7C7ZxEeW7J/vSzRgHxm7ZvESisUYRFq2sgkJ+HFERNrqfci45bdhmrUsy\n        7SWw9ybxdFOkuQoyKD3tBmiGfONQMlBaOMWdAsic965rvJsd5zYaZZFI1UwTkFXV\n        KJt3bp3Ngn1vEYXwijGTa+FXz6GLHueJwF0I7ug34DgUkAFvAs8Hacr2DRYxL5RJ\n        XdNgj4Jd2/g6T9InmWT0hASljur+dJnzNiNCkbn9KbX7J/qK1IbR8y560yRmFsU+\n        NdCFTW7wY0Fb1fWJ+/KTsC4=\n        =J6gs\n        -----END PGP PUBLIC KEY BLOCK----- \npackages:\n  - moby-cli\n  - moby-engine\nruncmd:\n  - dcs="${dcs}"\n  - |\n      set -x\n      (\n        echo "Device connection string: $dcs"\n\n        # Wait for docker daemon to start\n        while [ $(ps -ef | grep -v grep | grep docker | wc -l) -le 0 ]; do \n          sleep 3\n        done\n\n        apt install aziot-identity-service=1.2.0-1\n        apt install aziot-edge=1.2.0-1\n\n        if [ ! -z $dcs ]; then\n          mkdir /etc/aziot\n          wget https://raw.githubusercontent.com/Azure/iotedge-vm-deploy/1.2.0/config.toml -O /etc/aziot/config.toml\n          sed -i "s#\\(connection_string = \\).*#\\1\\"$dcs\\"#g" /etc/aziot/config.toml\n          iotedge config apply -c /etc/aziot/config.toml\n        fi\n\n        apt install -y deviceupdate-agent \n        apt install -y deliveryoptimization-plugin-apt\n        systemctl restart adu-agent\n      ) &\n\n')
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: ubuntuOSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName.id
        }
      ]
    }
  }
}

output PublicFQDN string = 'FQDN: ${publicIPAddressName.properties.dnsSettings.fqdn}'
output PublicSSH string = 'SSH : ssh ${vmName.properties.osProfile.adminUsername}@${publicIPAddressName.properties.dnsSettings.fqdn}'
