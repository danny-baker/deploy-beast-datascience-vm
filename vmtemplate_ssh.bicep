// DATA SCIENCE VM: SSH ACCESS ONLY (PUBLIC IP)

// This template builds a data science VM with public IP and exposed ports. It is designed for direct applications where you can work from a terminal (SSH) and do not need JHub.
// It accepts up to 6 parameters at build: 2 mandatory parameters are adminUserName, adminPublicKey; and you can optionally pass in vm specs vmModel, osDiskSize, osDiskType, projectName or leave to defaults

// vm specs
param vmModel string = 'Standard_E4s_v3'    // View available vm types with 'az vm list-skus -l centralus --output table' from azure CLI or checkout https://azureprice.net/ or https://docs.microsoft.com/en-us/azure/virtual-machines/sizes
param osDiskSize int = 1000                 // OS disk size in GB (allowable: 256 - 4,095 GB) https://azure.microsoft.com/en-gb/pricing/details/managed-disks/
param osDiskType string = 'Premium_LRS'     // choices are 'Premium_LRS' for premium SSD, 'StandardSSD_LRS' for standard SSD, 'Standard_LRS' for HDD platter 
param projectName string = 'projectname'    // If this parameter is not passed in at build it will default to this value.

// advanced 
param vmName_var string = '${projectName}-vm'
var vmPort80 = 'Deny'      //'Allow' or 'Deny' (HTTP)
var vmPort443 = 'Deny'     //'Allow' or 'Deny' (HTTPS)
var vmPort22 = 'Allow'     //'Allow' or 'Deny' (SSH)       ====== ALL PORTS SHUT EXCEPT SSH ======
var vmPort8000 = 'Deny'    //'Allow' or 'Deny' (JHUB SERVER)
var vmPort8787 = 'Deny'    //'Allow' or 'Deny' (RSTUDIO SERVER)
var VnetName_var = '${projectName}-VNet'
var vnetAddressPrefixes = '10.1.0.0/16' 
var SubnetName = '${projectName}-subnet'
var SubnetAddressPrefixes = '10.1.0.0/24'
var publicIPAddressNameVM_var = '${projectName}-ip'
var networkInterfaceName_var = '${projectName}-nic'
var networkSecurityGroupName_var = '${projectName}-nsg'
var subnetRef = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', VnetName_var, SubnetName)
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
          access: vmPort443 
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
      vmSize: vmModel
    }
    osProfile: {
      computerName: vmName_var
      adminUsername: adminUsername
      //adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: true  //If you also want to have user/pass for this vm, set this to true, uncomment the adminPassword line above, and uncomment the @secure() paramater declarations near top of document      
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
        publisher: 'microsoft-dsvm' //This is the magical data science image
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



