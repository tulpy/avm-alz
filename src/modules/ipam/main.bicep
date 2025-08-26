import { avnmType, ipamRegionType } from './types.bicep'

@description('Optional. Location for the resources.')
param location string = resourceGroup().location

@description('Required. Set to true to deploy Ipam resources, false to only generate outputs.')
param deploy bool

@description('Required. Configuration for the Azure Virtual Network Manager.')
param avnmConfiguration avnmType

@description('Required. List of regions for the Ipam Pool.')
param regions ipamRegionType

@description('Resource. Azure Virtual Network Manager.')
module networkManagers 'br/public:avm/res/network/network-manager:0.5.2' = if (deploy) {
  name: take('networkManagers-${guid(deployment().name)}', 64)
  params: {
    name: avnmConfiguration.name
    location: location
    networkManagerScopes: {
      managementGroups: avnmConfiguration.?managementGroupScopes
      subscriptions: avnmConfiguration.?subscriptionScopes
    }
    networkGroups:[
      {
        name: 'test'
        description: 'test'
        memberType: 'VirtualNetwork'
        staticMembers: []
      }
    ]
    networkManagerScopeAccesses: [
      'Connectivity'
      'Routing'
      'SecurityAdmin'
    ]
  }
}

@description('Module: Ipam.')
module ipam './ipam.bicep' = if (deploy) {
  name: 'ipam'
  params: {
    location: location
    avnmName: networkManagers.?outputs.name ?? ''
    avnmConfiguration: avnmConfiguration
    deploy: deploy
    regions: regions
  }
}
