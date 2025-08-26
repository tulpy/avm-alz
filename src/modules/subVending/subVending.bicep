import * as shared from '../../configuration/shared/shared.conf.bicep'
import * as type from '../../configuration/shared/shared.type.bicep'

targetScope = 'managementGroup'

metadata name = 'Azure Subscription Vending Module'
metadata description = 'Module used to bootstrap an Azure Landing Zone.'
metadata version = '0.0.1'
metadata author = 'Insight APAC Platform Engineering'

@description('Optional. The Management Group Id to place the subscription in.')
param subscriptionMgPlacement string = ''

@maxLength(36)
@description('Required. An existing subscription ID. Use this when you do not want the module to create a new subscription. But do want to manage the management group membership. A subscription ID should be provided in the example format `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`.')
param existingSubscriptionId string

@description('Optional. The Azure Region to deploy the resources into.')
param location string = deployment().location

@description('Optional. Tags of the resource.')
param tags type.tagsType?

@maxLength(10)
@description('Required. Specifies the Landing Zone prefix for the deployment and Azure resources. This is the function of the Landing Zone AIS, SAP, AVD etc.')
param lzPrefix string

@allowed([
  'dev'
  'tst'
  'prd'
  'sbx'
])
@description('Required. Specifies the environment prefix for the deployment.')
param envPrefix string

@description('Optional. Supply an array of objects containing the details of the role assignments to create.')
param roleAssignments type.roleAssignmentConfigurationType?

@description('Optional. Configuration for Azure Budgets.')
param budgetConfiguration type.budgetConfigurationType?

@description('Optional. Configuration for Action Groups.')
param actionGroupConfiguration type.actionGroupConfigurationType?

@description('Optional. The JSON payload for the name prefixes, if wanting to override that in the ../configuration/shared/ folder.')
param namePrefixesPayload object = {}

@description('Optional. The JSON payload for the location prefixes, if wanting to override that in the ../configuration/shared/ folder.')
param locationPrefixesPayload object = {}

// Variables
var namePrefixes = !empty(namePrefixesPayload) ? namePrefixesPayload : shared.resPrefixes
var locationPrefixes = !empty(locationPrefixesPayload) ? locationPrefixesPayload : shared.locPrefixes

var rgId = toLower('${namePrefixes.resourceGroup}${shared.delimiter.dash}${locationPrefixes[location]}${shared.delimiter.dash}${lzPrefix}${shared.delimiter.dash}${envPrefix}')
var nsgId = toLower('${namePrefixes.networkSecurityGroup}${shared.delimiter.dash}${locationPrefixes[location]}${shared.delimiter.dash}${lzPrefix}${shared.delimiter.dash}${envPrefix}')
var udrId = toLower('${namePrefixes.routeTable}${shared.delimiter.dash}${locationPrefixes[location]}${shared.delimiter.dash}${lzPrefix}${shared.delimiter.dash}${envPrefix}')
var vntId = toLower('${namePrefixes.virtualNetwork}${shared.delimiter.dash}${locationPrefixes[location]}${shared.delimiter.dash}${lzPrefix}${shared.delimiter.dash}${envPrefix}')

var deployBudgets = budgetConfiguration.?enabled ?? true
var resourceNames = {
  actionGroup: actionGroupConfiguration.?name ?? '${lzPrefix}${envPrefix}ActionGroup'
  actionGroupShort: actionGroupConfiguration.?name ?? '${lzPrefix}${envPrefix}AG'
  virtualNetwork: '${vntId}-10.15.0.0_24'
}

@description('Module: Azure Budgets - https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/consumption/budget')
module budget 'br/public:avm/res/consumption/budget:0.3.7' = [
  for (bg, index) in (budgetConfiguration.?budgets ?? []): if (!empty(budgetConfiguration) && deployBudgets) {
    name: take('budget-${guid(deployment().name)}-${index}', 64)
    scope: subscription(existingSubscriptionId)
    params: {
      name: bg.name
      startDate: bg.startDate
      location: location
      amount: bg.amount
      thresholdType: bg.thresholdType
      thresholds: bg.thresholds
      contactEmails: bg.contactEmails
    }
  }
]

@description('Resource Groups (Common) - https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/resources/resource-group')
module commonResourceGroups 'br/public:avm/res/resources/resource-group:0.4.1' = [
  for commonResourceGroup in shared.commonResourceGroupNames: {
    name: take('sharedResourceGroups-${commonResourceGroup}', 64)
    scope: subscription(existingSubscriptionId)
    params: {
      name: commonResourceGroup
      location: location
      tags: tags
    }
  }
]

@description('Module: Action Group - https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/insights/action-group')
module actionGroup 'br/public:avm/res/insights/action-group:0.7.0' = if (!empty(actionGroupConfiguration.?emailReceivers)) {
  name: take('actionGroup-${guid(deployment().name)}', 64)
  scope: resourceGroup(existingSubscriptionId, 'alertsRG')
  dependsOn: [
    commonResourceGroups
  ]
  params: {
    // Required parameters
    groupShortName: resourceNames.actionGroupShort
    name: resourceNames.actionGroup
    // Non-required parameters
    emailReceivers: [
      for email in actionGroupConfiguration.?emailReceivers ?? []: {
        emailAddress: email
        name: split(email, '@')[0]
        useCommonAlertSchema: true
      }
    ]
    location: 'Global'
  }
}

module subVending 'br/public:avm/ptn/lz/sub-vending:0.3.5' = {
  name: 'subVendingDeployment'
  params: {
    deploymentScriptLocation: location
    deploymentScriptName: 'resourcesDeploymentScript'
    deploymentScriptNetworkSecurityGroupName: '${nsgId}-ds'
    deploymentScriptResourceGroupName: '${rgId}-ds'
    deploymentScriptStorageAccountName: '<deploymentScriptStorageAccountName>'
    deploymentScriptVirtualNetworkName: '${vntId}-ds'
    resourceProviders: {
      'Microsoft.Network': []
    }
    existingSubscriptionId: existingSubscriptionId
    roleAssignmentEnabled: true
    roleAssignments: roleAssignments
    routeTables: [
      {
        name: '${udrId}-app'
        location: location
      }
    ]
    routeTablesResourceGroupName: '${rgId}-network'
    subscriptionManagementGroupAssociationEnabled: true
    subscriptionManagementGroupId: subscriptionMgPlacement
    subscriptionTags: tags
    virtualNetworkResourceGroupTags: tags
    virtualNetworkAddressSpace: [
      '10.15.0.0/24'
    ]
    virtualNetworkEnabled: true
    virtualNetworkLocation: location
    virtualNetworkName: resourceNames.virtualNetwork
    virtualNetworkPeeringEnabled: false
    virtualNetworkResourceGroupName: '${rgId}-network'
    virtualNetworkSubnets: [
      {
        addressPrefix: '10.15.0.0/27'
        name: 'app'
        networkSecurityGroup: {
          location: location
          name: '${nsgId}-app'
          securityRules: []
        }
        privateEndpointNetworkPolicies: 'Enabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
        routeTableName: '${udrId}-app'
      }
      {
        addressPrefix: '10.15.0.32/27'
        name: 'db'
        networkSecurityGroup: {
          location: location
          name: '${nsgId}-app'
          securityRules: []
        }
        privateEndpointNetworkPolicies: 'Enabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
        routeTableName: '${udrId}-app'
      }
    ]
    virtualNetworkUseRemoteGateways: false
  }
}
