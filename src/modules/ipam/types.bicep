import { networkGroupType, securityAdminConfigurationType } from 'br/public:avm/res/network/network-manager:0.5.2'
@export()
type avnmType = {
  @minLength(1)
  @maxLength(64)
  @description('Required. Name of the Network Manager.')
  name: string

  @description('Optional. Subscription scopes for the Network Manager.')
  subscriptionScopes: string[]?

  @description('Optional. Management group scopes for the Network Manager.')
  managementGroupScopes: string[]?

  @description('Optional. Security Admin Configurations requires enabling the "SecurityAdmin" feature on Network Manager. A security admin configuration contains a set of rule collections. Each rule collection contains one or more security admin rules. You then associate the rule collection with the network groups that you want to apply the security admin rules to.')
  securityAdminConfigurations: securityAdminConfigurationType[]?

  @description('Conditional. Network Groups and static members to create for the network manager. Required if using "connectivityConfigurations" or "securityAdminConfigurations" parameters. A network group is global container that includes a set of virtual network resources from any region. Then, configurations are applied to target the network group, which applies the configuration to all members of the group. The two types are group memberships are static and dynamic memberships. Static membership allows you to explicitly add virtual networks to a group by manually selecting individual virtual networks, and is available as a child module, while dynamic membership is defined through Azure policy. See [How Azure Policy works with Network Groups](https://learn.microsoft.com/en-us/azure/virtual-network-manager/concept-azure-policy-integration) for more details.')
  networkGroups: networkGroupType[]?

  @description('Required. IPAM Root Settings.')
  ipamRootSettings: ipamRootType
}

type ipamRootType = {
  rootIpamPoolName: string
  AzureCIDR: string
  RegionCIDRsize: int
  @maxValue(32)
  @minValue(8)
  RegionCIDRsplitSize: int
}

@export()
@maxLength(16)
type ipamRegionType = {
  name: string
  displayName: string
  @maxValue(100)
  @minValue(0)
  PlatformAndApplicationSplitFactor: int
  @maxValue(100)
  @minValue(0)
  ConnectivityAndIdentitySplitFactor: int
  @maxValue(100)
  @minValue(0)
  CorpAndOnlineSplitFactor: int
  cidr: string
}[]
