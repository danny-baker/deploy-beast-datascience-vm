// This compiles into an ARM template to build a dedicated vm for datascience (access via ssh key)

// vm specs
var vmSize = 'Standard_E4s_v3'    // View available vm types with 'az vm list-skus -l centralus --output table' from azure CLI or checkout https://azureprice.net/ or https://docs.microsoft.com/en-us/azure/virtual-machines/sizes
var osDiskSize = 256              // size in GiB (allowable: 256 - 4,095 GiB) https://azure.microsoft.com/en-gb/pricing/details/managed-disks/
var osDiskType = 'Premium_LRS'    // choices are 'Premium_LRS' for premium SSD, 'StandardSSD_LRS' for standard SSD, 'Standard_LRS' for HDD platter 

// general
param projectName string = 'projectname'

// advanced (Leave alone unless you know what you're doing)
param vmName_var string = '${projectName}-vm'
var vmPort80 = 'Allow'      //'Allow' or 'Deny' (HTTP)
var vmpPort443 = 'Allow'    //'Allow' or 'Deny' (HTTPS)
var vmPort22 = 'Allow'      //'Allow' or 'Deny' (SSH)
var vmPort8000 = 'Allow'    //'Allow' or 'Deny' (JHUB SERVER)
var vmPort8787 = 'Allow'    //'Allow' or 'Deny' (RSTUDIO SERVER)
var VnetName_var = '${projectName}-VNet'
var vnetAddressPrefixes = '10.1.0.0/16' //CIDR notation
var SubnetName = '${projectName}-subnet'
var SubnetAddressPrefixes = '10.1.0.0/24'
var publicIPAddressNameVM_var = '${projectName}-ip'
var networkInterfaceName_var = '${projectName}-nic'
var networkSecurityGroupName_var = '${projectName}-nsg'
var subnetRef = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', VnetName_var, SubnetName)

// access (don't touch)
@secure() 
param adminUsername string
//@secure()
//param adminPassword string
@secure()
param adminPublicKey string

// resource declarations 

resource publicIPAddressNameVM 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressNameVM_var
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
  sku: {
    name: 'Basic'
  }
}

resource VnetName 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: VnetName_var
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefixes
      ]
    }
    dhcpOptions: {
      dnsServers: []
    }
    subnets: [
      {
        name: SubnetName
        properties: {
          addressPrefix: SubnetAddressPrefixes 
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }      
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: networkSecurityGroupName_var
  location: resourceGroup().location
  properties: {
    securityRules: [
      {
        name: 'HTTPS'
        properties: {
          priority: 320
          access: vmpPort443 
          direction: 'Inbound'
          destinationPortRange: '443'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'HTTP'
        properties: {
          priority: 340
          access: vmPort80
          direction: 'Inbound'
          destinationPortRange: '80'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'SSH'
        properties: {
          priority: 360
          access: vmPort22
          direction: 'Inbound'
          destinationPortRange: '22'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'JupyterHub'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8000'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: vmPort8000
          priority: 1020
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'RStudio_Server'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8787'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: vmPort8787
          priority: 1030
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}

resource networkInterfaceName 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: networkInterfaceName_var
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressNameVM.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroupName.id
    }
  }
  dependsOn: [
    VnetName
  ]
}

resource vmName 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vmName_var
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName_var
      adminUsername: adminUsername
      //adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: true        
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: adminPublicKey
            }
          ]
        }
      }
      secrets: []      
    }
    storageProfile: {
      imageReference: {
        publisher: 'microsoft-dsvm'
        offer: 'ubuntu-1804'
        sku: '1804'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        diskSizeGB: osDiskSize
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }      
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName.id
        }
      ]
    }
  }
}



