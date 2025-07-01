// Shared User Defined Types for Azure Services, exported for reuse in other modules.

// Resource Tags Type
@export()
@description('The type for Azure Resource tags.')
type tagsType = {
  environment: 'sbx' | 'dev' | 'tst' | 'prd'
  applicationName: string
  owner: string
  criticality: 'Tier0' | 'Tier1' | 'Tier2' | 'Tier3'
  costCenter: string
  contactEmail: string
  dataClassification: 'Internal' | 'Confidential' | 'Secret' | 'Top Secret'
  iac: 'Bicep'
  *: string
}

// Networking Types
@export()
@description('The type for Azure Virtual Network configuration.')
type virtualNetworkConfigurationType = {
  @description('Optional. Whether to create an associated virtual network. Defaults to \'true\'.')
  enabled: bool?

  @minLength(1)
  @maxLength(64)
  @description('Optional. The name of the virtual network to create.')
  name: string?

  @description('Optional. The address prefix of the virtual network to create.')
  addressPrefix: string

  @description('Optional. The DDoS protection plan ID to associate with the virtual network.')
  ddosProtectionPlanId: string?

  @description('Optional. The DNS servers to associate with the virtual network.')
  dnsServerIps: string[]?

  @description('Optional. A value indicating whether this route overrides overlapping BGP routes regardless of LPM.')
  disableBgpRoutePropagation: bool?

  @description('Optional. The subnet type.')
  subnets: subnetType?
}?

@export()
@description('The type for subnets within a virtual network.')
type subnetType = {
  @description('Required. The Name of the subnet resource.')
  name: string

  @description('Conditional. The address prefix for the subnet. Required if `addressPrefixes` is empty.')
  addressPrefix: string?

  @description('Conditional. List of address prefixes for the subnet. Required if `addressPrefix` is empty.')
  addressPrefixes: string[]?

  @description('Optional. The delegation to enable on the subnet.')
  delegation: string?

  @description('Optional. The resource ID of the network security group to assign to the subnet.')
  networkSecurityGroupResourceId: string?

  @description('Optional. enable or disable apply network policies on private endpoint in the subnet.')
  privateEndpointNetworkPolicies: ('Disabled' | 'Enabled' | 'NetworkSecurityGroupEnabled' | 'RouteTableEnabled')?

  @description('Optional. enable or disable apply network policies on private link service in the subnet.')
  privateLinkServiceNetworkPolicies: ('Disabled' | 'Enabled')?

  @description('Optional. The resource ID of the route table to assign to the subnet.')
  routeTableResourceId: string?

  @description('Optional. An array of custom routes.')
  routes: routeTableType?

  @description('Optional. The security group rules to apply to the subnet.')
  securityRules: securityRulesType?

  @description('Optional. An array of service endpoint policies.')
  serviceEndpointPolicies: object[]?

  @description('Optional. The service endpoints to enable on the subnet.')
  serviceEndpoints: string[]?
}[]?

@description('The type for Route Table routes.')
type routeTableType = {
  @description('Required. Name of the route table route.')
  name: string

  @description('Required. Properties of the route table route.')
  properties: {
    @description('Required. The type of Azure hop the packet should be sent to.')
    nextHopType: ('VirtualAppliance' | 'VnetLocal' | 'Internet' | 'VirtualNetworkGateway' | 'None')

    @description('Optional. The destination CIDR to which the route applies.')
    addressPrefix: string?

    @description('Optional. A value indicating whether this route overrides overlapping BGP routes regardless of LPM.')
    hasBgpOverride: bool?

    @description('Optional. The IP address packets should be forwarded to. Next hop values are only allowed in routes where the next hop type is VirtualAppliance.')
    nextHopIpAddress: string?
  }
}[]?

@description('The type for NSG security Rules.')
type securityRulesType = {
  @description('Required. The name of the security rule.')
  name: string

  @description('Required. The properties of the security rule.')
  properties: {
    @description('Required. Whether network traffic is allowed or denied.')
    access: ('Allow' | 'Deny')

    @description('Optional. The description of the security rule.')
    description: string?

    @description('Optional. Optional. The destination address prefix. CIDR or destination IP range. Asterisk "*" can also be used to match all source IPs. Default tags such as "VirtualNetwork", "AzureLoadBalancer" and "Internet" can also be used.')
    destinationAddressPrefix: string?

    @description('Optional. The destination address prefixes. CIDR or destination IP ranges.')
    destinationAddressPrefixes: string[]?

    @description('Optional. The resource IDs of the application security groups specified as destination.')
    destinationApplicationSecurityGroupResourceIds: string[]?

    @description('Optional. The destination port or range. Integer or range between 0 and 65535. Asterisk "*" can also be used to match all ports.')
    destinationPortRange: string?

    @description('Optional. The destination port ranges.')
    destinationPortRanges: string[]?

    @description('Required. The direction of the rule. The direction specifies if rule will be evaluated on incoming or outgoing traffic.')
    direction: ('Inbound' | 'Outbound')

    @minValue(100)
    @maxValue(4096)
    @description('Required. Required. The priority of the rule. The value can be between 100 and 4096. The priority number must be unique for each rule in the collection. The lower the priority number, the higher the priority of the rule.')
    priority: int

    @description('Required. Network protocol this rule applies to.')
    protocol: ('Ah' | 'Esp' | 'Icmp' | 'Tcp' | 'Udp' | '*')

    @description('Optional. The CIDR or source IP range. Asterisk "*" can also be used to match all source IPs. Default tags such as "VirtualNetwork", "AzureLoadBalancer" and "Internet" can also be used. If this is an ingress rule, specifies where network traffic originates from.')
    sourceAddressPrefix: string?

    @description('Optional. The CIDR or source IP ranges.')
    sourceAddressPrefixes: string[]?

    @description('Optional. The resource IDs of the application security groups specified as source.')
    sourceApplicationSecurityGroupResourceIds: string[]?

    @description('Optional. The source port or range. Integer or range between 0 and 65535. Asterisk "*" can also be used to match all ports.')
    sourcePortRange: string?

    @description('Optional. The source port ranges.')
    sourcePortRanges: string[]?
  }
}[]?

@export()
@description('The type for virtual network peering configuration (Hub and Spoke).')
type vnetPeeringConfigurationType = {
  @description('Optional. Whether to create an associated peering. Defaults to \'true\'.')
  enabled: bool?

  @description('Optional. The Name of VNET Peering resource. If not provided, default value will be peer-localVnetName-remoteVnetName.')
  name: string?

  @description('Optional. Whether the forwarded traffic from the VMs in the local virtual network will be allowed/disallowed in remote virtual network. Default is true.')
  allowForwardedTraffic: bool?

  @description('Optional. If gateway links can be used in remote virtual networking to link to this virtual network. Default is false.')
  allowGatewayTransit: bool?

  @description('Optional. Whether the VMs in the local virtual network space would be able to access the VMs in remote virtual network space. Default is true.')
  allowVirtualNetworkAccess: bool?

  @description('Optional. Do not verify the provisioning state of the remote gateway. Default is true.')
  doNotVerifyRemoteGateways: bool?

  @description('Optional. If remote gateways can be used on this virtual network. If the flag is set to true, and allowGatewayTransit on remote peering is also true, virtual network will use gateways of remote virtual network for transit. Only one peering can have this flag set to true. This flag cannot be set if virtual network already has a gateway. Default is false.')
  useRemoteGateways: bool?

  @description('Optional. Deploy the outbound and the inbound peering.')
  remotePeeringEnabled: bool?

  @description('Optional. The name of the VNET Peering resource in the remove Virtual Network. If not provided, default value will be peer-remoteVnetName-localVnetName.')
  remotePeeringName: string?

  @description('Optional. Whether the forwarded traffic from the VMs in the local virtual network will be allowed/disallowed in remote virtual network. Default is true.')
  remotePeeringAllowForwardedTraffic: bool?

  @description('Optional. If gateway links can be used in remote virtual networking to link to this virtual network. Default is false.')
  remotePeeringAllowGatewayTransit: bool?

  @description('Optional. Whether the VMs in the local virtual network space would be able to access the VMs in remote virtual network space. Default is true.')
  remotePeeringAllowVirtualNetworkAccess: bool?

  @description('Optional. Do not verify the provisioning state of the remote gateway. Default is true.')
  remotePeeringDoNotVerifyRemoteGateways: bool?

  @description('Optional. If remote gateways can be used on this virtual network. If the flag is set to true, and allowGatewayTransit on remote peering is also true, virtual network will use gateways of remote virtual network for transit. Only one peering can have this flag set to true. This flag cannot be set if virtual network already has a gateway. Default is false.')
  remotePeeringUseRemoteGateways: bool?
}?

@export()
@description('The type for Azure Virtual WAN peering configuration (vWAN).')
type vwanPeeringConfigurationType = {
  @description('Optional. Whether to create virtual hub connection.')
  enabled: bool?

  @description('Optional. Enable internet security.')
  enableInternetSecurity: bool?

  @description('Optional. Indicates whether routing intent is enabled on the Virtual HUB within the virtual WAN.')
  routingIntentEnabled: bool?

  @description('Optional. The resource ID of the virtual hub route table to associate to the virtual hub connection (this virtual network). If left blank/empty default route table will be associated.')
  associatedRouteTableResourceId: string?

  @description('Optional. An array of virtual hub route table resource IDs to propagate routes to. If left blank/empty default route table will be propagated to only.')
  propagatedRouteTablesResourceIds: array[]

  @description('Optional. An array of virtual hub route table labels to propagate routes to. If left blank/empty default label will be propagated to only.')
  propagatedLabels: array[]
}?

// Common Types
@export()
@description('The type for Azure Action Group configuration.')
type actionGroupConfigurationType = {
  @minLength(1)
  @maxLength(260)
  @description('Optional. The name of the Action Group.')
  name: string?

  @description('Optional. The shortname of the Action Group.')
  groupShortName: string?

  @description('Optional. The list of email receivers that are part of this action group.')
  emailReceivers: array?
}

@export()
@description('The type for Azure Budget configuration.')
type budgetConfigurationType = {
  @description('Optional. Deployment flag for Azure Budgets.')
  enabled: bool?

  @description('Optional. Budget  Type.')
  budgets: budgetType[]?
}

@export()
@description('The type for Azure Budgets')
type budgetType = {
  @minLength(1)
  @maxLength(63)
  @description('Required. The name of the budget.')
  name: string

  @description('Optional. The category of the budget, whether the budget tracks cost or usage.')
  category: 'Cost' | 'Usage'?

  @description('Required. The total amount of cost or usage to track with the budget.')
  amount: int

  @description('Optional. The start date for the budget. Start date should be the first day of the month and cannot be in the past (except for the current month).')
  startDate: string?

  @description('Optional. The type of threshold to use for the budget. The threshold type can be either `Actual` or `Forecasted`.')
  thresholdType: 'Actual' | 'Forecasted'?

  @maxLength(5)
  @description('Optional. Percent thresholds of budget for when to get a notification. Can be up to 5 thresholds, where each must be between 1 and 1000.')
  thresholds: array?

  @description('Conditional. The list of email addresses to send the budget notification to when the thresholds are exceeded. Required if neither `contactRoles` nor `actionGroups` was provided.')
  contactEmails: array?
}

// Role Permissions Types
@export()
@description('The type for Role Assignment configuration.')
type roleAssignmentConfigurationType = roleAssignmentType[]?

@export()
type roleAssignmentType = {
  @description('Required. The principal ID of the user, group, or service principal.')
  principalId: string

  @description('Required. The role definition ID or name.')
  definition: string

  @description('Required. The relative scope of the role assignment.')
  relativeScope: string

  @description('Optional. The principal type of the user, group, or service principal.')
  principalType: 'User' | 'Group' | 'ServicePrincipal'?

  @description('Optional. The role assignment description.')
  description: string?
}

@export()
@description('The type for Privileged Identity Management role assignment configuration.')
type pimRoleAssignmentConfigurationType = pimRoleAssignmentType[]?

@export()
@description('The type for Privileged Identity Management role assignment.')
type pimRoleAssignmentType = {
  @description('Principal (user or service principal) object ID.')
  principalId: string

  @description('ID of the role definition.')
  roleDefinitionId: string

  @description('The ISO 8601 time duration for eligibility.')
  duration: string

  @description('Defines how eligibility ends.')
  expirationType: ('AfterDateTime' | 'AfterDuration' | 'NoExpiration')?

  @description('Reason or note justifying the request.')
  justification: string

  @description('Type of eligibility request (e.g., AdminAssign, AdminExtend, etc.).')
  requestType: (
    | 'AdminAssign'
    | 'AdminExtend'
    | 'AdminRemove'
    | 'AdminRenew'
    | 'AdminUpdate'
    | 'SelfActivate'
    | 'SelfDeactivate'
    | 'SelfExtend'
    | 'SelfRenew')

  @description('Optional. Random for the deployment name (true or false).')
  deploymentSeedRandom: bool?
}
