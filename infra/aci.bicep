@description('Name for the container group')
param name string = 'container-name'

@description('Container image to deploy.')
param image string = 'mcr.microsoft.com/azuredocs/aci-helloworld'

@description('Container Registry Server')
param registryServer string = 'xx.azurecr.io'

@description('Service Principal clientId')
param clientId string = 'xx-xx'

@description('Service Principal clientSecret')
param clientSecret string = 'xx-xx'

@description('Port to open on the container and the public IP address.')
param port int = 80

@description('DNS Name')
param dnsNameLabel string = 'dnsName'

@description('The number of CPU cores to allocate to the container.')
param cpuCores int = 1

@description('The amount of memory to allocate to the container in gigabytes.')
param memoryInGb int = 2

@description('The behavior of Azure runtime if container has stopped.')
@allowed([
  'Always'
  'Never'
  'OnFailure'
])
param restartPolicy string = 'Always'

@description('Location for all resources.')
param location string = resourceGroup().location

resource name_resource 'Microsoft.ContainerInstance/containerGroups@2019-12-01' = {
  name: name
  location: location
  properties: {
    containers: [
      {
        name: name
        properties: {
          image: image
          ports: [
            {
              port: port
              protocol: 'TCP'
            }
          ]
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGB: memoryInGb
            }
          }
        }
      }
    ]
    osType: 'Linux'
    restartPolicy: restartPolicy
    imageRegistryCredentials: [
      {
        server: registryServer
        username: clientId
        password: clientSecret
      }
    ]
    ipAddress: {
      type: 'Public'
      ports: [
        {
          port: port
          protocol: 'TCP'
        }
      ]
      dnsNameLabel: dnsNameLabel
    }
  }
}

output containerIPv4Address string = name_resource.properties.ipAddress.ip
