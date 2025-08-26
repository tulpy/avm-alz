param location string
param regionDisplayName string
param regionCIDR string
param rootIPAMpoolName string
param avnmName string

@description('Required. Set to true to deploy IPAM resources, false to only generate outputs.')
param deploy bool

@maxValue(32)
@minValue(8)
@description('CIDR size for the region IPAM pool. This is used to determine how many subnets can be created within the region CIDR.')
param RegionCIDRsplitSize int

@maxValue(100)
@minValue(0)
@description('Factor to divide the region CIDR into platform and application landing zones, in percentage.')
param PlatformAndApplicationSplitFactor int

@maxValue(100)
@minValue(0)
@description('Factor to divide the platform CIDR into connectivity and identity landing zones, in percentage.')
param ConnectivityAndIdentitySplitFactor int

//@maxValue(100)
//@minValue(0)
//@description('Factor to divide the application CIDR into Corp and Online landing zones, in percentage.')
//param CorpAndOnlineSplitFactor int

// Calculate the total number of CIDR blocks available in the region
// Using the RegionCIDRsplitSize parameter to determine subdivision granularity
var powersOfTwo = [1, 2, 4, 8, 16, 32, 64, 128, 256, 512]
var currentRegionCIDRspliSize = int(split(regionCIDR, '/')[1])
var subdivisionSize = RegionCIDRsplitSize // Use the parameter directly for subdivision
var totalSubnetCount = powersOfTwo[subdivisionSize - currentRegionCIDRspliSize]

// Generate all possible CIDR blocks for allocation
var allSubnets = [for i in range(0, totalSubnetCount): cidrSubnet(regionCIDR, subdivisionSize, i)]

// Calculate how many subnets go to platform vs application based on the factor
var platformSubnetCount = max(1, totalSubnetCount * PlatformAndApplicationSplitFactor / 100)
var platformSubnets = take(allSubnets, platformSubnetCount)
var applicationSubnets = skip(allSubnets, platformSubnetCount)

// Create platform and application landing zone CIDRs using the allocated subnets
// For platform: subdivide the platform subnets into smaller pieces for connectivity and identity
var platformCIDRs = platformSubnets
var platformSubCIDRsize = subdivisionSize + 1
var platformSubCIDRcount = 2
// Use the first platform subnet and subdivide it for connectivity and identity
var platformFirstSubnet = platformSubnets[0]
var platformSubCIDRs = [
  for i in range(0, platformSubCIDRcount): cidrSubnet(platformFirstSubnet, platformSubCIDRsize, i)
]

// Calculate how many subnets go to connectivity vs identity based on the factor
var platformConnectivityCount = max(1, platformSubCIDRcount * ConnectivityAndIdentitySplitFactor / 100)
var platformConnectivityCIDRs = take(platformSubCIDRs, platformConnectivityCount)
var platformIdentityCIDRs = skip(platformSubCIDRs, platformConnectivityCount)

// Calculate the CIDRs for application landing zones
var applicationCIDRs = applicationSubnets

var applicationSubCIDRsize = subdivisionSize + 1
var applicationSubCIDRcount = 2
// Use the first platform subnet and subdivide it for connectivity and identity
var applicationFirstSubnet = applicationSubnets[0]
var applicationSubCIDRs = [
  for i in range(0, applicationSubCIDRcount): cidrSubnet(applicationFirstSubnet, applicationSubCIDRsize, i)
]
//var totalRemainingCount = length(applicationCIDRs)
//var applicationCorpCount = max(1, totalRemainingCount * CorpAndOnlineSplitFactor / 100)

//var applicationCorpCIDRs = take(applicationCIDRs, applicationCorpCount)
//var applicationOnlineCIDRs = skip(applicationCIDRs, applicationCorpCount)

// Calculate CIDRs for small, medium, and large IPAM pools from application subnets
// Split applicationCIDRs: 70% small, 15% medium, 15% large
var applicationSmallCount = max(1, applicationSubCIDRcount * 70 / 100)
//var applicationLargeCount = totalApplicationCount - applicationSmallCount - applicationMediumCount

// Allocate subnets to each category
var applicationSmallCIDRs = take(applicationSubCIDRs, applicationSmallCount)
var applicationLargeCIDRs = skip(applicationSubCIDRs, applicationSmallCount)

resource avnm 'Microsoft.Network/networkManagers@2024-05-01' existing = if (deploy) {
  name: avnmName
}

// Root IPAM pool for the Azure region
resource regionIpamPool 'Microsoft.Network/networkManagers/ipamPools@2024-05-01' = if (deploy) {
  name: 'regionIpamPool-${replace(location, ' ', '-')}-${replace(regionCIDR, '/', '-')}'
  parent: avnm
  location: location
  properties: {
    addressPrefixes: [
      regionCIDR
    ]
    parentPoolName: rootIPAMpoolName
    displayName: regionDisplayName
    description: 'IPAM pool for ${regionDisplayName} region (${regionCIDR})'
  }
}

resource platformIpamPool 'Microsoft.Network/networkManagers/ipamPools@2024-05-01' = if (deploy) {
  name: 'platformIpamPool-${replace(location, ' ', '-')}'
  parent: avnm
  location: location
  properties: {
    addressPrefixes: platformCIDRs
    parentPoolName: regionIpamPool.name
    displayName: 'Platform IPAM pool - ${regionDisplayName}'
    description: 'IPAM pool for Platform Landing Zones in ${regionDisplayName} region'
  }
}

resource platformConnectivityIpamPool 'Microsoft.Network/networkManagers/ipamPools@2024-05-01' = if (deploy) {
  name: 'platformConnectivityIpamPool-${replace(location, ' ', '-')}'
  parent: avnm
  location: location
  properties: {
    addressPrefixes: platformConnectivityCIDRs
    parentPoolName: platformIpamPool.name
    displayName: 'Platform Connectivity IPAM pool - ${regionDisplayName}'
    description: 'IPAM pool for Platform Connectivity Landing Zone in ${regionDisplayName} region'
  }
}

resource platformIdamMgmtIpamPool 'Microsoft.Network/networkManagers/ipamPools@2024-05-01' = if (deploy) {
  name: 'platformIdamMgmtIpamPool-${replace(location, ' ', '-')}'
  parent: avnm
  location: location
  properties: {
    addressPrefixes: platformIdentityCIDRs
    parentPoolName: platformIpamPool.name
    displayName: 'Platform Identity & Management IPAM pool - ${regionDisplayName}'
    description: 'IPAM pool for Platform Identity & Management Landing Zone in ${regionDisplayName} region'
  }
}

resource applicationIpamPool 'Microsoft.Network/networkManagers/ipamPools@2024-05-01' = if (deploy) {
  name: 'applicationIpamPool-${replace(location, ' ', '-')}'
  parent: avnm
  location: location
  properties: {
    addressPrefixes: applicationCIDRs
    parentPoolName: regionIpamPool.name
    displayName: 'Application IPAM pool - ${regionDisplayName}'
    description: 'IPAM pool for Application Landing Zones in ${regionDisplayName} region'
  }
}

resource applicationSmallIpamPool 'Microsoft.Network/networkManagers/ipamPools@2024-05-01' = if (deploy && length(applicationSmallCIDRs) > 0) {
  name: 'applicationSmallLz-${replace(location, ' ', '-')}'
  parent: avnm
  location: location
  properties: {
    addressPrefixes: applicationSmallCIDRs
    parentPoolName: applicationIpamPool.name
    displayName: 'Application Small LZ IPAM pool (/24) - ${regionDisplayName}'
    description: 'IPAM pool for Small Application Landing Zones (/24) in ${regionDisplayName} region - 70% allocation'
  }
}

resource applicationLargeIpamPool 'Microsoft.Network/networkManagers/ipamPools@2024-05-01' = if (deploy && length(applicationLargeCIDRs) > 0) {
  name: 'applicationLargeLz-${replace(location, ' ', '-')}'
  parent: avnm
  location: location
  properties: {
    addressPrefixes: applicationLargeCIDRs
    parentPoolName: applicationIpamPool.name
    displayName: 'Application Large LZ IPAM pool (/22) - ${regionDisplayName}'
    description: 'IPAM pool for Large Application Landing Zones (/22) in ${regionDisplayName} region - 15% allocation'
  }
}

/*
resource applicationCorpIpamPool 'Microsoft.Network/networkManagers/ipamPools@2024-05-01' = if (deploy) {
  name: 'applicationCorp-${replace(location, ' ', '-')}'
  parent: avnm
  location: location
  properties: {
    addressPrefixes: applicationCorpCIDRs
    parentPoolName: applicationIpamPool.name
    displayName: 'Application Corp IPAM pool - ${regionDisplayName}'
    description: 'IPAM pool for Application Corp Landing Zones in ${regionDisplayName} region'
  }
}

resource applicationOnlineIpamPool 'Microsoft.Network/networkManagers/ipamPools@2024-05-01' = if (deploy) {
  name: 'applicationOnline-${replace(location, ' ', '-')}'
  parent: avnm
  location: location
  properties: {
    addressPrefixes: applicationOnlineCIDRs
    parentPoolName: applicationIpamPool.name
    displayName: 'Application Online IPAM pool - ${regionDisplayName}'
    description: 'IPAM pool for Application Online Landing Zones in ${regionDisplayName} region'
  }
}
*/
// outputs
output regionCIDR string = regionCIDR
// Platform Landing Zone CIDRs
output platformCIDRs array = platformCIDRs
output platformCIDRsCount int = length(platformCIDRs)
output platformConnectivityCIDRs array = platformConnectivityCIDRs
output platformConnectivityCIDRsCount int = length(platformConnectivityCIDRs)
output platformIdentityCIDRs array = platformIdentityCIDRs
output platformIdentityCIDRsCount int = length(platformIdentityCIDRs)

output applicationCIDRs array = applicationCIDRs
output applicationCIDRsCount int = length(applicationCIDRs)
//output applicationCorpCIDRs array = applicationCorpCIDRs
//output applicationCorpCIDRsCount int = length(applicationCorpCIDRs)
//output applicationOnlineCIDRs array = applicationOnlineCIDRs
//output applicationOnlineCIDRsCount int = length(applicationOnlineCIDRs)
