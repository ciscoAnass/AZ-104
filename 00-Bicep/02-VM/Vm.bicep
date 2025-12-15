param location string = resourceGroup().location
param vmName string = 'VM-Anass'
param adminUsername string = 'ciscoanass'
param sshPublicKey string = 'Your_SSH_Key'

var addressPrefix = '10.0.0.0/16'
var subnetPrefix  = '10.0.1.0/24'
var allowedPorts  = [
  22  // SSH
  80  // HTTP
  443 // HTTPS
]

// Public IP
resource pip 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: '${vmName}-pip'
  location: location
  sku: { name: 'Standard' }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// VNet & Subnet
resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: '${vmName}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [ addressPrefix ]
    }
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = {
  name: '${vnet.name}/default'
  properties: {
    addressPrefix: subnetPrefix
  }
}

// NSG with simple per-port allow rules
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: '${vmName}-nsg'
  location: location
  properties: {
    securityRules: [
      for (port, i) in allowedPorts: {
        name: 'allow-${port}'
        properties: {
          priority: 1000 + i
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: string(port)
          sourceAddressPrefix: '*'              // keep it simple; tighten to your IP/CIDR if desired
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// NIC (attaches NSG + Public IP)
resource nic 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: { id: subnet.id }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: { id: pip.id }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

// VM
resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        diskSizeGB: 64
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

output publicIp   string = pip.properties.ipAddress
output sshCommand string = 'ssh ${adminUsername}@${pip.properties.ipAddress}'
