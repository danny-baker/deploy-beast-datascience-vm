// ADVANCED USERS ONLY
// Build a fully private VM behind a premium VPN gateway. Ports are ok to leave open as there is no public facing IP for the VM. You must connect successfully to the VPN to access the VM.
// At deployment this file accepts 4 secure parameters: username, password, SSH public Key, VPN Root certificate 

// virtual machine specs (modify as you need, even if you are scared)
var vmSize = 'Standard_E4s_v3'    // View available vm types with 'az vm list-skus -l centralus --output table' from azure CLI or checkout https://azureprice.net/ or https://docs.microsoft.com/en-us/azure/virtual-machines/sizes
var osDiskSize = 256              // size in GiB (allowable: 256 - 4,095 GiB) https://azure.microsoft.com/en-gb/pricing/details/managed-disks/
var osDiskType = 'Premium_LRS'    // choices are 'Premium_LRS' for premium SSD, 'StandardSSD_LRS' for standard SSD, 'Standard_LRS' for HDD platter 
var dataDiskSize = 1              // size in GiB (allowable: 1 - 32,000 GiB). Note you must manually mount data disks. Guide here https://docs.microsoft.com/en-us/azure/virtual-machines/linux/attach-disk-portal
var dataDiskType = 'Premium_LRS'  
var projectName = 'projectname'

// Advanced users only (don't touch if this scares you)
var vmName_var = '${projectName}-prod-vm'
var VnetName_var = '${projectName}-VNet'
var vnetAddressPrefixes = '10.1.0.0/16' //CIDR notation
var SubnetName = '${projectName}-prod-subnet'
var SubnetAddressPrefixes = '10.1.0.0/24'
//var publicIPAddressNameVM_var = '${projectName}-prod-ip'
var networkInterfaceName_var = '${projectName}-prod-nic'
var networkSecurityGroupName_var = '${projectName}-prod-nsg'
var subnetRef = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', VnetName_var, SubnetName)
var vmPort80 = 'Allow'      //'Allow' or 'Deny' (HTTP)
var vmPort443 = 'Allow'     //'Allow' or 'Deny' (HTTPS)
var vmPort22 = 'Allow'      //'Allow' or 'Deny' (SSH)
var vmPort8000 = 'Allow'    //'Allow' or 'Deny' (JHUB SERVER)
var vmPort8787 = 'Allow'    //'Allow' or 'Deny' (RSTUDIO SERVER)
@secure() 
param adminUsername string
@secure()
param adminPassword string
@secure()
param adminPublicKey string

// VPN gateway
//https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-about-vpn-gateway-settings
//https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-certificates-point-to-site for generating root and client certificates
var gatewaySubnetName = 'GatewaySubnet'
var vpnSKU = 'VpnGw1'
var GatewaySubnetAddressPrefixes = '10.1.255.0/27'
var vpnClientAddressPoolPrefixes = '10.2.0.0/24'
var publicIPAddressNameGW_var = '${projectName}-VNetGWIP'
var subnetRefGW = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', VnetName_var, gatewaySubnetName)
var VPNGatewayName_var = '${projectName}-VNetGW'
@secure()
param VPNrootCert string

// resource declarations 

/*
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
*/

// This is the public IP address of the VPN gateway that you will connect to over the internet to tunnel in from your local machine
resource publicIPAddressNameGW 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressNameGW_var
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
      {
        name: gatewaySubnetName
        properties: {
          addressPrefix: GatewaySubnetAddressPrefixes 
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
          //publicIPAddress: {
          //  id: publicIPAddressNameVM.id
          //}
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
      dataDisks: [
        {
          lun: 0          
          createOption: 'Empty'
          caching: 'None'
          writeAcceleratorEnabled: false
          managedDisk: {
            storageAccountType: dataDiskType            
          }
          diskSizeGB: dataDiskSize
          toBeDetached: false
        }
      ]
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


resource VPNGatewayName 'Microsoft.Network/virtualNetworkGateways@2020-05-01' = {
  name: VPNGatewayName_var
  location: resourceGroup().location
  properties: {
    enablePrivateIpAddress: false
    ipConfigurations: [
      {
        name: 'vnetGatewayConfig0'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressNameGW.id
          }
          subnet: {
            id: subnetRefGW
          }
        }
      }
    ]
    sku: {
      name: vpnSKU
      tier: vpnSKU
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
    activeActive: false
    vpnClientConfiguration: {
      vpnClientAddressPool: {
        addressPrefixes: [
          vpnClientAddressPoolPrefixes 
        ]
      }
      vpnClientProtocols: [
        'IkeV2'
        'OpenVPN'
      ]
      vpnClientRootCertificates: [
        {
          name: 'VPNcert'
          properties: {
            publicCertData: VPNrootCert
          }
        }
      ]
      vpnClientRevokedCertificates: []
      radiusServers: []
      vpnClientIpsecPolicies: []
    }
    
    vpnGatewayGeneration: 'Generation1'
  }
}



