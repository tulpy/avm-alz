using 'main.bicep'

param deploy = true
param avnmConfiguration = {
    name: 'avnm-01'
    subscriptionScopes: []
    managementGroupScopes: [
      '/providers/Microsoft.Management/managementGroups/mg-alz'
    ]
  ipamRootSettings: {
    rootIpamPoolName: 'AU-IPAM-RootPool'
    AzureCIDR: '10.15.0.0/16'
    RegionCIDRsize: 17
    RegionCIDRsplitSize: 22
  }
}

param regions = [
  {
    name: 'australiaeast'
    displayName: 'Australia East'
    PlatformAndApplicationSplitFactor: 5
    ConnectivityAndIdentitySplitFactor: 50
    CorpAndOnlineSplitFactor: 75
    cidr: cidrSubnet(avnmConfiguration.ipamRootSettings.AzureCIDR, avnmConfiguration.ipamRootSettings.RegionCIDRsize, 0)
  }/*
  {
    name: 'australiasoutheast'
    displayName: 'Australia Southeast'
    PlatformAndApplicationSplitFactor: 5
    ConnectivityAndIdentitySplitFactor: 50
    CorpAndOnlineSplitFactor: 75
    cidr: cidrSubnet(avnmConfiguration.ipamRootSettings.AzureCIDR, avnmConfiguration.ipamRootSettings.RegionCIDRsize, 1)
  }
    */
]
