// Shared User Defined Types for Azure Services https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/user-defined-data-types
import * as commonTypes from 'br/public:avm/utl/types/avm-common-types:0.5.1' // Common Types including Locks, Managed Identities, Role Assignments, etc.

///////////////////////////////////////////////

// 1.0 Core Landing Zone Types
// 1.1 Resource Tags
// 1.2 Azure Virtual Network Type (Subnets / Peering / vWAN Peering / Security Rules / Route Table)
// 1.3 Azure Action Group Type
// 1.4 Azure Budget Type
// 1.5 Role Assignment Types
// 1.6 Privileged Identity Management Role Assignment Types
// 1.7 Azure Storage Account Type
// 1.8 Azure Key Vault Type
// 1.9 Azure User Assigned Identity Type

// 2.0 Platform Landing Zone Types
// 2.1 Log Analytics Workspace Type
// 2.2 Azure Maintenance Configuration Type
// 2.3 Azure Virtual Network Gateway Type

// 3.0 Workload Landing Zone Types
// 3.1 Azure Virtual Machine Type
// 3.2 Azure Recovery Services Vault Type


///////////////////////////////////////////////

// 1.0 Core Landing Zone Types
// 1.1 Resource Tags Type
@export()
@description('The type for Azure Resource tags.')
type tagsType = {
  environment: 'sbx' | 'dev' | 'tst' | 'prd' | 'conn' | 'mgmt' | 'idam'
  applicationName: string
  owner: string
  criticality: 'Tier0' | 'Tier1' | 'Tier2' | 'Tier3'
  costCenter: string
  contactEmail: string
  dataClassification: 'Internal' | 'Confidential' | 'Secret' | 'Top Secret'
  iac: 'Bicep'
  *: string
}

// 1.2 Azure Virtual Network Type
@export()
@description('The type for Azure Virtual Network configuration.')
type virtualNetworkType = {
  @minLength(1)
  @maxLength(64)
  @description('Optional. The name of the virtual network resource.')
  name: string?

  @description('Required. The address prefix of the virtual network to create.')
  addressPrefixes: array

  @description('Optional. Number of IP addresses allocated from the pool. To be used only when the addressPrefix param is defined with a resource ID of an IPAM pool.')
  ipamPoolNumberOfIpAddresses: string?

  @description('Optional. The DDoS protection plan ID to associate with the virtual network.')
  ddosProtectionPlanId: string?

  @description('Optional. The DNS servers to associate with the virtual network.')
  dnsServerIps: string[]?

  @description('Optional. A value indicating whether this route overrides overlapping BGP routes regardless of LPM.')
  disableBgpRoutePropagation: bool?

  @description('Required. The subnet type.')
  subnets: subnetType

  @description('Optional. The lock settings of the service.')
  lock: commonTypes.lockType?

  @description('Optional. Array of role assignments to create.')
  roleAssignments: commonTypes.roleAssignmentType[]?
}

@description('The type for subnets within a virtual network.')
type subnetType = {
  @description('Required. The Name of the subnet resource.')
  name: string

  @description('Conditional. The address prefix for the subnet. Required if `addressPrefixes` is empty.')
  addressPrefix: string?

  @description('Conditional. List of address prefixes for the subnet. Required if `addressPrefix` is empty.')
  addressPrefixes: string[]?

  @description('Conditional. The address space for the subnet, deployed from IPAM Pool. Required if `addressPrefixes` and `addressPrefix` is empty and the VNet address space configured to use IPAM Pool.')
  ipamPoolPrefixAllocations: [
    {
      @description('Required. The Resource ID of the IPAM pool.')
      pool: {
        @description('Required. The Resource ID of the IPAM pool.')
        id: string
      }
      @description('Required. Number of IP addresses allocated from the pool.')
      numberOfIpAddresses: string
    }
  ]?

  @description('Optional. Application gateway IP configurations of virtual network resource.')
  applicationGatewayIPConfigurations: object[]?

  @description('Optional. The delegation to enable on the subnet.')
  delegation: string?

  @description('Optional. The resource ID of the NAT Gateway to use for the subnet.')
  natGatewayResourceId: string?

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
  securityRules: securityRules?

  @description('Optional. An array of service endpoint policies.')
  serviceEndpointPolicies: object[]?

  @description('Optional. The service endpoints to enable on the subnet.')
  serviceEndpoints: string[]?

  @description('Optional. Set this property to false to disable default outbound connectivity for all VMs in the subnet. This property can only be set at the time of subnet creation and cannot be updated for an existing subnet.')
  defaultOutboundAccess: bool?

  @description('Optional. Set this property to Tenant to allow sharing subnet with other subscriptions in your AAD tenant. This property can only be set if defaultOutboundAccess is set to false, both properties can only be set if subnet is empty.')
  sharingScope: ('DelegatedServices' | 'Tenant')?
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
type securityRules = {
  @description('Required. The name of the security rule.')
  name: string

  @description('Required. The properties of the security rule.')
  properties: {
    @description('Required. Whether network traffic is allowed or denied.')
    access: ('Allow' | 'Deny')

    @description('Optional. The description of the security rule.')
    description: string?

    @description('Optional. The destination address prefix. CIDR or destination IP range. Asterisk "*" can also be used to match all source IPs. Default tags such as "VirtualNetwork", "AzureLoadBalancer" and "Internet" can also be used.')
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

// Azure Virtual Network Peering Type
@export()
@description('The type for peering configuration.')
type peeringType = {
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

// 1.3 Azure Action Group Type
@export()
@description('The type for Azure Action Group configuration.')
type actionGroupType = {
  @minLength(1)
  @maxLength(260)
  @description('Optional. The name of the Action Group.')
  name: string?

  @description('Optional. The shortname of the Action Group.')
  groupShortName: string?

  @description('Optional. The list of email receivers that are part of this action group.')
  emailReceivers: array?

  @description('Optional. The lock settings of the service.')
  lock: commonTypes.lockType?

  @description('Optional. Array of role assignments to create.')
  roleAssignments: commonTypes.roleAssignmentType[]?
}

// 1.4 Azure Budget Type
@export()
@description('The type for Azure Budgets')
type budgetType = {
  budgets: {
    @minLength(1)
    @maxLength(63)
    @description('Required. The name of the budget.')
    name: string

    @description('Optional. The category of the budget, whether the budget tracks cost or usage.')
    category: ('Cost' | 'Usage')?

    @description('Optional. The start date for the budget. Start date should be the first day of the month and cannot be in the past (except for the current month).')
    startDate: string?

    @description('Required. The total amount of cost or usage to track with the budget.')
    amount: int

    @description('Optional. The type of threshold to use for the budget. The threshold type can be either `Actual` or `Forecasted`.')
    thresholdType: ('Actual' | 'Forecasted')?

    @maxLength(5)
    @description('Optional. Percent thresholds of budget for when to get a notification. Can be up to 5 thresholds, where each must be between 1 and 1000.')
    thresholds: array?

    @description('Conditional. The list of email addresses to send the budget notification to when the thresholds are exceeded. Required if neither `contactRoles` nor `actionGroups` was provided.')
    contactEmails: array?
  }[]
}

// 1.5 Role Assignment Types
@export()
@description('The type for Role Assignment configuration.')
type roleAssignmentsType = roleAssignments[]?

@description('The type for Role Assignments.')
type roleAssignments = {
  @description('Optional. The name (as GUID) of the role assignment. If not provided, a GUID will be generated.')
  name: string?

  @description('Required. The role to assign. You can provide either the display name of the role definition, the role definition GUID, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
  roleDefinitionIdOrName: string

  @description('Required. The principal ID of the principal (user/group/identity) to assign the role to.')
  principalId: string

  @description('Optional. The principal type of the assigned principal ID.')
  principalType: ('ServicePrincipal' | 'Group' | 'User' | 'ForeignGroup' | 'Device')?

  @description('Optional. The description of the role assignment.')
  description: string?

  @maxLength(36)
  @description('Subscription ID of the subscription to assign the RBAC role to. If no Resource Group name is provided, the module deploys at subscription level, therefore assigns the provided RBAC role to the subscription.')
  subscriptionId: string?

  @description('Name of the Resource Group to assign the RBAC role to. If Resource Group name is provided, and Subscription ID is provided, the module deploys at resource group level, therefore assigns the provided RBAC role to the resource group.')
  resourceGroupName: string?

  @description('Optional. The conditions on the role assignment. This limits the resources it can be assigned to. e.g.: @Resource[Microsoft.Storage/storageAccounts/blobServices/containers:ContainerName] StringEqualsIgnoreCase "foo_storage_container".')
  condition: string?

  @description('Optional. Version of the condition.')
  conditionVersion: '2.0'?

  @description('Optional. The Resource Id of the delegated managed identity resource.')
  delegatedManagedIdentityResourceId: string?
}?

// 1.6 Privileged Identity Management Role Assignment Types
@export()
@description('The type for Privileged Identity Management role assignment configuration.')
type pimRoleAssignmentType = pimRoleAssignment[]?

@description('The type for Privileged Identity Management role assignment.')
type pimRoleAssignment = {
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

// 1.7 Azure Storage Account Type
import {
  networkAclsType as storageNetworkAclsType
  secretsExportConfigurationType as storageSecretsExportConfigurationType
  localUserType
} from 'br/public:avm/res/storage/storage-account:0.26.2'
@export()
@description('The type for Azure Storage Account configuration.')
type storageAccountType = {
  @maxLength(24)
  @description('Name of the Storage Account. Must be lower-case.')
  name: string?

  @description('Optional. Array of role assignments to create.')
  roleAssignments: commonTypes.roleAssignmentType[]?

  @description('Optional. The lock settings of the service.')
  lock: commonTypes.lockType?

  @description('Optional. Type of Storage Account to create.')
  kind: 'StorageV2' | 'Storage' | 'BlobStorage' | 'FileStorage' | 'BlockBlobStorage'?

  @description('Optional. Storage account SKU. Defaults to \'Standard_ZRS\'.')
  sku:
    | 'Standard_LRS'
    | 'Standard_ZRS'
    | 'Standard_GRS'
    | 'Standard_GZRS'
    | 'Standard_RAGRS'
    | 'Standard_RAGZRS'
    | 'StandardV2_LRS'
    | 'StandardV2_ZRS'
    | 'StandardV2_GRS'
    | 'StandardV2_GZRS'
    | 'Premium_LRS'
    | 'Premium_ZRS'
    | 'PremiumV2_LRS'
    | 'PremiumV2_ZRS'

  @description('Conditional. Required if the Storage Account kind is set to BlobStorage. The access tier is used for billing. The "Premium" access tier is the default value for premium block blobs storage account type and it cannot be changed for the premium block blobs storage account type.')
  accessTier: 'Hot' | 'Cool' | 'Cold' | 'Premium'

  @description('Optional. Allow large file shares if set to \'Enabled\'. It cannot be disabled once it is enabled. Only supported on locally redundant and zone redundant file shares. It cannot be set on FileStorage storage accounts (storage accounts for premium file shares).')
  largeFileSharesState: 'Disabled' | 'Enabled'?

  @description('Optional. Provides the identity based authentication settings for Azure Files.')
  azureFilesIdentityBasedAuthentication: resourceInput<'Microsoft.Storage/storageAccounts@2024-01-01'>.properties.azureFilesIdentityBasedAuthentication?

  @description('Optional. A boolean flag which indicates whether the default authentication is OAuth or not.')
  defaultToOAuthAuthentication: bool?

  @description('Optional. Indicates whether the storage account permits requests to be authorized with the account access key via Shared Key. If false, then all requests, including shared access signatures, must be authorized with Azure Active Directory (Azure AD). The default value is null, which is equivalent to true.')
  allowSharedKeyAccess: bool?

  @description('Optional. The Storage Account ManagementPolicies Rules.')
  managementPolicyRules: array?

  @description('Optional. Networks ACLs, this value contains IPs to whitelist and/or Subnet information. If in use, bypass needs to be supplied. For security reasons, it is recommended to set the DefaultAction Deny.')
  networkAcls: storageNetworkAclsType?

  @description('Optional. A Boolean indicating whether or not the service applies a secondary layer of encryption with platform managed keys for data at rest. For security reasons, it is recommended to set it to true.')
  requireInfrastructureEncryption: bool?

  @description('Optional. Allow or disallow cross AAD tenant object replication.')
  allowCrossTenantReplication: bool?

  @description('Optional. Sets the custom domain name assigned to the storage account. Name is the CNAME source.')
  customDomainName: string?

  @description('Optional. Indicates whether indirect CName validation is enabled. This should only be set on updates.')
  customDomainUseSubDomainName: bool?

  @description('Optional. Allows you to specify the type of endpoint. Set this to AzureDNSZone to create a large number of accounts in a single subscription, which creates accounts in an Azure DNS Zone and the endpoint URL will have an alphanumeric DNS Zone identifier.')
  dnsEndpointType: 'AzureDnsZone' | 'Standard'?

  @description('Optional. Indicates whether public access is enabled for all blobs or containers in the storage account. For security reasons, it is recommended to set it to false.')
  allowBlobPublicAccess: bool?

  @description('Optional. Set the minimum TLS version on request to storage. The TLS versions 1.0 and 1.1 are deprecated and not supported anymore.')
  minimumTlsVersion: 'TLS1_2'

  @description('Conditional. If true, enables Hierarchical Namespace for the storage account. Required if enableSftp or enableNfsV3 is set to true.')
  enableHierarchicalNamespace: bool?

  @description('Optional. If true, enables Secure File Transfer Protocol for the storage account. Requires enableHierarchicalNamespace to be true.')
  enableSftp: bool?

  @description('Optional. Local users to deploy for SFTP authentication.')
  localUsers: localUserType[]?

  @description('Optional. Enables local users feature, if set to true.')
  isLocalUserEnabled: bool?

  @description('Optional. If true, enables NFS 3.0 support for the storage account. Requires enableHierarchicalNamespace to be true.')
  enableNfsV3: bool?

  @description('Optional. Tags of the resource.')
  tags: resourceInput<'Microsoft.Storage/storageAccounts@2024-01-01'>.tags?

  @description('Optional. Restrict copy to and from Storage Accounts within an AAD tenant or with Private Links to the same VNet.')
  allowedCopyScope: 'AAD' | 'PrivateLink'?

  @description('Optional. Whether or not public network access is allowed for this resource. For security reasons it should be disabled. If not specified, it will be disabled by default if private endpoints are set and networkAcls are not set.')
  publicNetworkAccess: 'Enabled' | 'Disabled'?

  @description('Optional. Allows HTTPS traffic only to storage service if sets to true.')
  supportsHttpsTrafficOnly: bool?

  @description('Optional. The SAS expiration period. DD.HH:MM:SS.')
  sasExpirationPeriod: string?

  @description('Optional. The SAS expiration action. Allowed values are Block and Log.')
  sasExpirationAction: 'Log' | 'Block'?

  @description('Optional. The keyType to use with Queue & Table services.')
  keyType: 'Account' | 'Service'?

  @description('Optional. Key vault reference and secret settings for the module\'s secrets export.')
  secretsExportConfiguration: storageSecretsExportConfigurationType?
}

// 1.8 Azure Key Vault Type
import { 
  networkAclsType as keyVaultNetworkAclsType
  accessPolicyType
  secretType 
} from 'br/public:avm/res/key-vault/vault:0.13.0'
@export()
@description('The type for Azure Key Vault configuration.')
type keyVaultType = {
  @minLength(3)
  @maxLength(24)
  @description('Optional. Name of the Azure Key Vault. Must be globally unique.')
  name: string?

  @description('Optional. Specifies the SKU for the vault.')
  sku: ('standard' | 'premium')?

  @description('Optional. Switch to enable/disable Key Vault\'s soft delete feature.')
  enableSoftDelete: bool?

  @description('Optional. The vault\'s create mode to indicate whether the vault need to be recovered or not. - recover or default.')
  createMode: ('default' | 'recover')?

  @minValue(7)
  @maxValue(90)
  @description('Optional. softDelete data retention days. It accepts >=7 and <=90.')
  softDeleteRetentionInDays: int?

  @description('Optional. Provide \'true\' to enable Key Vault\'s purge protection feature.')
  enablePurgeProtection: bool?

  @description('Optional. This value can be set to \'Enabled\' to avoid breaking changes on existing customer resources and templates. If set to \'Disabled\', traffic over public interface is not allowed, and private endpoint connections would be the exclusive access method.')
  publicNetworkAccess: ('Enabled' | 'Disabled' | '')?

  @description('Optional. All access policies to create.')
  accessPolicies: accessPolicyType[]?

  @description('Optional. All secrets to create.')
  secrets: secretType[]?

  @description('Optional. Rules governing the accessibility of the resource from specific network locations.')
  networkAcls: keyVaultNetworkAclsType?

  @description('Optional. Resource tags.')
  tags: resourceInput<'Microsoft.KeyVault/vaults@2024-11-01'>.tags?

  @description('Optional. The lock settings of the service.')
  lock: commonTypes.lockType?

  @description('Optional. Array of role assignments to create.')
  roleAssignments: commonTypes.roleAssignmentType[]?
}

// 1.9 Azure User Assigned Identity Type
@export()
@description('The type for Azure User Assigned Identity configuration.')
type userAssignedIdentityType = {
  @minLength(5)
  @maxLength(128)
  @description('Optional. The name of the User Assigned Identity.')
  name: string?

  @description('Optional. Array of role assignments to create.')
  roleAssignments: commonTypes.roleAssignmentType[]?

  @description('Optional. The lock settings of the service.')
  lock: commonTypes.lockType?

  @description('Required. The name of the resource group containing the user assigned identity.')
  resourceGroupName: string

  @description('Required. The role to assign. You can provide either the display name of the role definition, the role definition GUID, or its fully qualified ID in the following format: /providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11')
  roleDefinitionIdOrName: string
}

// 2.0 Platform Landing Zone Types
// 2.1 Log Analytics Workspace Type
import {
  storageInsightsConfigType
  linkedServiceType
  linkedStorageAccountType
  savedSearchType
  dataExportType
  dataSourceType
  tableType
  gallerySolutionType
  workspaceFeaturesType
  workspaceReplicationType
} from 'br/public:avm/res/operational-insights/workspace:0.12.0'
@export()
@description('The type for Log Analytics configuration.')
type logAnalyticsType = {
  @minLength(4)
  @maxLength(63)
  @description('Optional. The name of the Log Analytics workspace.')
  name: string?

  @description('Optional. The name of the SKU.')
  skuName: (
    | 'CapacityReservation'
    | 'Free'
    | 'LACluster'
    | 'PerGB2018'
    | 'PerNode'
    | 'Premium'
    | 'Standalone'
    | 'Standard')?

  @minValue(100)
  @maxValue(5000)
  @description('Optional. The capacity reservation level in GB for this workspace, when CapacityReservation sku is selected. Must be in increments of 100 between 100 and 5000.')
  skuCapacityReservationLevel: int?

  @description('Optional. List of storage accounts to be read by the workspace.')
  storageInsightsConfigs: storageInsightsConfigType[]?

  @description('Optional. List of services to be linked.')
  linkedServices: linkedServiceType[]?

  @description('Conditional. List of Storage Accounts to be linked. Required if \'forceCmkForQuery\' is set to \'true\' and \'savedSearches\' is not empty.')
  linkedStorageAccounts: linkedStorageAccountType[]?

  @description('Optional. Kusto Query Language searches to save.')
  savedSearches: savedSearchType[]?

  @description('Optional. LAW data export instances to be deployed.')
  dataExports: dataExportType[]?

  @description('Optional. LAW data sources to configure.')
  dataSources: dataSourceType[]?

  @description('Optional. LAW custom tables to be deployed.')
  tables: tableType[]?

  @description('Optional. List of gallerySolutions to be created in the log analytics workspace.')
  gallerySolutions: gallerySolutionType[]?

  @description('Optional. Onboard the Log Analytics Workspace to Sentinel. Requires \'SecurityInsights\' solution to be in gallerySolutions.')
  onboardWorkspaceToSentinel: bool?

  @description('Optional. Number of days data will be retained for.')
  @minValue(0)
  @maxValue(730)
  dataRetention: int?

  @description('Optional. The workspace daily quota for ingestion.')
  @minValue(-1)
  dailyQuotaGb: int?

  @description('Optional. The network access type for accessing Log Analytics ingestion.')
  publicNetworkAccessForIngestion: ('Enabled' | 'Disabled')?

  @description('Optional. The network access type for accessing Log Analytics query.')
  publicNetworkAccessForQuery: ('Enabled' | 'Disabled')?

  @description('Optional. The workspace features.')
  features: workspaceFeaturesType?

  @description('Optional. The workspace replication properties.')
  replication: workspaceReplicationType?

  @description('Optional. Indicates whether customer managed storage is mandatory for query management.')
  forceCmkForQuery: bool?

  @description('Optional. Tags of the resource.')
  tags: resourceInput<'Microsoft.OperationalInsights/workspaces@2025-02-01'>.tags?

  @description('Optional. The lock settings of the service.')
  lock: commonTypes.lockType?

  @description('Optional. Array of role assignments to create.')
  roleAssignments: commonTypes.roleAssignmentType[]?
}

// 2.2 Azure Maintenance Configuration Type
@export()
@description('The type for Azure Maintenance configuration.')
type maintenanceConfigurationType = {

  @description('Optional. The name of the Maintenance configuration.')
  name: string?

  @description('Optional. Gets or sets extensionProperties of the maintenanceConfiguration.')
  extensionProperties: object?

  @description('Optional. Gets or sets maintenanceScope of the configuration.')
  maintenanceScope: 'Host' | 'OSImage' | 'Extension' | 'InGuestPatch' | 'SQLDB' | 'SQLManagedInstance'?

  @description('Optional. Definition of a MaintenanceWindow.')
  maintenanceWindow: object?

  @description('Optional. Gets or sets namespace of the resource.')
  namespace: string?

  @description('Optional. Gets or sets the visibility of the configuration. The default value is \'Custom\'.')
  visibility: 'Custom' | 'Public' | ''?

  @description('Optional. Configuration settings for VM guest patching with Azure Update Manager.')
  installPatches: object?

  @description('Optional. The lock settings of the service.')
  lock: commonTypes.lockType?

  @description('Optional. Array of role assignments to create.')
  roleAssignments: commonTypes.roleAssignmentType[]?

}

// 2.3 Azure Virtual Network Gateway Type
@export()
@description('The type for Virtual Network Gateway configuration.')
type virtualNetworkGatewayType = {
  @description('Optional. Name of the Virtual Network gateway.')
  name: string?

  @description('Required. Type of gateway.')
  gatewayType: ('Vpn' | 'ExpressRoute')

  @description('Required. SKU of the gateway.')
  sku: (
    | 'Basic'
    | 'VpnGw1AZ'
    | 'VpnGw2AZ'
    | 'VpnGw3AZ'
    | 'VpnGw4AZ'
    | 'VpnGw5AZ'
    | 'ErGw1AZ'
    | 'ErGw2AZ'
    | 'ErGw3AZ'
    | 'ErGwScale'
    | 'HighPerformance'
    | 'Standard'
    | 'UltraPerformance')

  @description('Required. Type of VPN.')
  vpnType: ('PolicyBased' | 'RouteBased')

  @description('Required. Generation of the VPN Gateway.')
  vpnGatewayGeneration: ('Generation1' | 'Generation2' | 'None')

  @description('Optional. Enable BGP on the gateway.')
  enableBgp: bool?

  @description('Optional. Enable Active-Active on the gateway.')
  activeActive: bool?

  @description('Optional. Enable BGP Route Translation for NAT on the gateway.')
  enableBgpRouteTranslationForNat: bool?

  @description('Optional. Enable DNS Forwarding on the gateway.')
  enableDnsForwarding: bool?

  @description('Optional. BGP Settings for the gateway.')
  bgpSettings: {
    @minValue(0)
    @maxValue(4294967295)
    @description('Optional. ASN for the gateway.')
    asn: int?

    @description('Optional. Peer Weight for the gateway.')
    peerWeight: int?
  }?

  @description('Optional. VPN Client Configuration for the gateway.')
  vpnClientConfiguration: object?
}

// 3.0 Workload Landing Zone Types
// 3.1 Azure Virtual Machine Type
import {
  nicConfigurationType
  imageReferenceType
  planType
  osDiskType
  dataDiskType
} from 'br/public:avm/res/compute/virtual-machine:0.20.0'
@export()
@description('The type for Azure Virtual Machine configuration.')
type virtualMachineType = {
  @maxLength(15)
  @description('Optional. The name of the virtual machine to be created. You should use a unique prefix to reduce name collisions in Active Directory.')
  name: string?

  @description('Required. If set to 1, 2 or 3, the availability zone is hardcoded to that value. If set to -1, no zone is defined. Note that the availability zone numbers here are the logical availability zone in your Azure subscription. Different subscriptions might have a different mapping of the physical zone and logical zone. To understand more, please refer to [Physical and logical availability zones](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview?tabs=azure-cli#physical-and-logical-availability-zones).')
  availabilityZone: (-1 | 1 | 2 | 3)

  @description('Required. Specifies the size for the VMs.')
  vmSize: string

  @description('Conditional. The username for the administrator account on the virtual machine. Required if a virtual machine is created as part of the module.')
  adminUsername: string?

  @description('Conditional. The password for the administrator account on the virtual machine. Required if a virtual machine is created as part of the module.')
  @secure()
  adminPassword: string?

  @description('Required. Configures NICs and PIPs.')
  nicConfigurations: nicConfigurationType[]

  @description('Optional. This property can be used by user in the request to enable or disable the Host Encryption for the virtual machine. This will enable the encryption for all the disks including Resource/Temp disk at host itself. For security reasons, it is recommended to set encryptionAtHost to \'true\'.')
  encryptionAtHost: bool?

  @description('Optional. Specifies the SecurityType of the virtual machine. It has to be set to any specified value to enable UefiSettings. The default behavior is: UefiSettings will not be enabled unless this property is set.')
  securityType: 'confidentialVM' | 'trustedLaunch' | ''?

  @description('Optional. Specifies whether secure boot should be enabled on the virtual machine. This parameter is part of the UefiSettings. SecurityType should be set to TrustedLaunch to enable UefiSettings.')
  secureBootEnabled: bool?

  @description('Optional. Specifies whether vTPM should be enabled on the virtual machine. This parameter is part of the UefiSettings.  SecurityType should be set to TrustedLaunch to enable UefiSettings.')
  vTpmEnabled: bool?

  @description('Required. OS image reference. In case of marketplace images, it\'s the combination of the publisher, offer, sku, version attributes. In case of custom images it\'s the resource ID of the custom image.')
  imageReference: imageReferenceType

  @description('Optional. Specifies information about the marketplace image used to create the virtual machine. This element is only used for marketplace images. Before you can use a marketplace image from an API, you must enable the image for programmatic use.')
  plan: planType?

  @description('Required. Specifies the OS disk. For security reasons, it is recommended to specify DiskEncryptionSet into the osDisk object.  Restrictions: DiskEncryptionSet cannot be enabled if Azure Disk Encryption (guest-VM encryption using bitlocker/DM-Crypt) is enabled on your VMs.')
  osDisk: osDiskType

  @description('Optional. Specifies the data disks. For security reasons, it is recommended to specify DiskEncryptionSet into the dataDisk object. Restrictions: DiskEncryptionSet cannot be enabled if Azure Disk Encryption (guest-VM encryption using bitlocker/DM-Crypt) is enabled on your VMs.')
  dataDisks: dataDiskType[]?

  @description('Optional. Specifies that the image or disk that is being used was licensed on-premises.')
  licenseType: ('RHEL_BYOS' | 'SLES_BYOS' | 'Windows_Client' | 'Windows_Server')?

  @description('Optional. VM guest patching orchestration mode. Refer to \'https://learn.microsoft.com/en-us/azure/virtual-machines/automatic-vm-guest-patching\'.')
  patchMode: 'AutomaticByPlatform' | 'AutomaticByOS' | 'Manual'?

  @description('Optional. Whether to enable the Microsoft.Azure.ActiveDirectory AADLoginForWindows extension, allowing users to log in to the virtual machine using Microsoft Entra. Defaults to \'false\'.')
  enableAadLoginExtension: bool?

  @description('Optional. Whether to enable the Microsoft.Azure.Monitor AzureMonitorWindowsAgent extension. Defaults to \'false\'.')
  enableAzureMonitorAgent: bool?

  @description('Optional. The resource Id of a maintenance configuration for the virtual machine.')
  maintenanceConfigurationResourceId: string?

  @description('Optional. Tags of the resource.')
  tags: resourceInput<'Microsoft.Compute/virtualMachines@2024-11-01'>.tags?

  @description('Optional. The lock settings of the service.')
  lock: commonTypes.lockType?

  @description('Optional. Array of role assignments to create.')
  roleAssignments: commonTypes.roleAssignmentType[]?
}

// 3.2 Azure Recovery Services Vault Type
import {
  backupPolicyType
  backupConfigType
  protectedItemType
  replicationFabricType
  replicationPolicyType
  replicationAlertSettingsType
  monitoringSettingsType
  softDeleteSettingType
  redundancySettingsType
  restoreSettingsType
} from 'br/public:avm/res/recovery-services/vault:0.10.1'
@export()
@description('The type for Azure Recovery Services Vault configuration.')
type recoveryVaultType = {
  @description('Optional. Name of the Azure Recovery Service Vault.')
  name: string?

  @description('Optional. List of all backup policies.')
  backupPolicies: backupPolicyType[]?

  @description('Optional. The backup configuration.')
  backupConfig: backupConfigType?

  @description('Optional. List of all protection containers.')
  protectedItems: protectedItemType[]?

  @description('Optional. List of all replication fabrics.')
  replicationFabrics: replicationFabricType[]?

  @description('Optional. List of all replication policies.')
  replicationPolicies: replicationPolicyType[]?

  @description('Optional. Replication alert settings.')
  replicationAlertSettings: replicationAlertSettingsType?

  @description('Optional. Array of role assignments to create.')
  roleAssignments: commonTypes.roleAssignmentType[]?

  @description('Optional. The lock settings of the service.')
  lock: commonTypes.lockType?

  @description('Optional. Tags of the Recovery Service Vault resource.')
  tags: resourceInput<'Microsoft.RecoveryServices/vaults@2024-04-01'>.tags?

  @description('Optional. Monitoring Settings of the vault.')
  monitoringSettings: monitoringSettingsType?

  @description('Optional. The soft delete related settings.')
  softDeleteSettings: softDeleteSettingType?

  @description('Optional. The immmutability setting state of the recovery services vault resource.')
  immutabilitySettingState: 'Disabled' | 'Locked' | 'Unlocked'?

  @description('Optional. Whether or not public network access is allowed for this resource. For security reasons it should be disabled.')
  publicNetworkAccess: 'Disabled' | 'Enabled'?

  @description('Optional. The redundancy settings of the vault.')
  redundancySettings: redundancySettingsType?

  @description('Optional. The restore settings of the vault.')
  restoreSettings: restoreSettingsType?
}
