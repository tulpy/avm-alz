import { avnmType, ipamRegionType } from './types.bicep'

param location string

@description('Required. Configuration for the Ipam AVNM.')
param avnmConfiguration avnmType

@description('Required. List of regions for the Ipam Pool.')
param regions ipamRegionType

@description('Required. Set to true to deploy IPAM resources, false to only generate outputs.')
param deploy bool

param avnmName string

resource avnm 'Microsoft.Network/networkManagers@2024-05-01' existing = if (deploy) {
  name: avnmName
}

@description('Resource: Root Ipam Pool for the Azure Supernet.')
resource rootIpamPool 'Microsoft.Network/networkManagers/ipamPools@2024-05-01' = if (deploy) {
  name: 'rootIpamPool-${replace(avnmConfiguration.ipamRootSettings.AzureCIDR, '/', '-')}'
  parent: avnm
  location: location
  properties: {
    addressPrefixes: [
      avnmConfiguration.ipamRootSettings.AzureCIDR
    ]
    displayName: avnmConfiguration.ipamRootSettings.rootIpamPoolName
    description: 'Root Ipam pool for the Azure Supernet - (${avnmConfiguration.ipamRootSettings.AzureCIDR})'
  }
}

@description('Module: Ipam Pool for each region.')
module regionIpamPool './ipamPerRegion.bicep' = [
  for region in regions: {
    name: 'regionIpamPool-${region.name}'
    params: {
      regionDisplayName: region.displayName
      regionCIDR: region.cidr
      location: region.name
      avnmName: avnmName
      RegionCIDRsplitSize: avnmConfiguration.ipamRootSettings.RegionCIDRsplitSize
      PlatformAndApplicationSplitFactor: region.PlatformAndApplicationSplitFactor
      ConnectivityAndIdentitySplitFactor: region.ConnectivityAndIdentitySplitFactor
      //CorpAndOnlineSplitFactor: region.CorpAndOnlineSplitFactor
      deploy: deploy
      rootIPAMpoolName: rootIpamPool.name
    }
  }
]


// outputs
output AzureCIDR string = avnmConfiguration.ipamRootSettings.AzureCIDR

// outputs per region:
output regionIpamPools array = [
  for (region, i) in regions: {
    Region: region.displayName
    value: {
      name: region.name
      regionCIDR: region.cidr
      platformCIDRs: regionIpamPool[i].outputs.platformCIDRs
      platformCIDRsCount: regionIpamPool[i].outputs.platformCIDRsCount
      platformConnectivityCIDRs: regionIpamPool[i].outputs.platformConnectivityCIDRs
      platformConnectivityCIDRsCount: regionIpamPool[i].outputs.platformConnectivityCIDRsCount
      platformIdentityCIDRs: regionIpamPool[i].outputs.platformIdentityCIDRs
      platformIdentityCIDRsCount: regionIpamPool[i].outputs.platformIdentityCIDRsCount
      applicationCIDRs: regionIpamPool[i].outputs.applicationCIDRs
      applicationCIDRsCount: regionIpamPool[i].outputs.applicationCIDRsCount
      //applicationCorpCIDRs: regionIpamPool[i].outputs.applicationCorpCIDRs
      //applicationCorpCIDRsCount: regionIpamPool[i].outputs.applicationCorpCIDRsCount
      //applicationOnlineCIDRs: regionIpamPool[i].outputs.applicationOnlineCIDRs
      //applicationOnlineCIDRsCount: regionIpamPool[i].outputs.applicationOnlineCIDRsCount
    }
  }
]
