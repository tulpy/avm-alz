import * as shared from '../../configuration/shared/shared.conf.bicep'
import * as type from '../../configuration/shared/shared.type.bicep'

targetScope = 'subscription'

metadata name = 'ALZ Bicep - Azure Platform Management Orchestration Module'
metadata description = 'Module used to create Azure Platform Management resources.'
metadata version = '0.1.0'
metadata author = 'Insight APAC Platform Engineering'

// Subscription Module Parameters
@description('Required. Specifies the Landing Zone prefix for the deployment.')
param lzPrefix string

@description('Required. Specifies the environment prefix for the deployment.')
param envPrefix string

@description('Optional. The Azure Region to deploy the resources into.')
param location string = deployment().location

@description('Required. The Subscription Id for the deployment.')
@maxLength(36)
param subscriptionId string

@description('Optional. Tags that will be applied to all resources in this module.')
param tags type.tagsType?

// Logging Module Parameters
@description('Optional. Configuration for Log Analytics.')
param logAnalyticsConfiguration type.logAnalyticsType?

// Subscription Budget Module Parameters
@description('Optional. Configuration for Azure Budgets.')
param budgetConfiguration type.budgetConfigurationType?

@description('Optional. Date timestamp.')
param startDate string = '${utcNow('yyyy')}-${utcNow('MM')}-01T00:00:00Z'

// Action Group Module Parameters
@description('Optional. Configuration for Action Groups.')
param actionGroupConfiguration type.actionGroupConfigurationType?

// Orchestration Variables
var argPrefix = toLower('${shared.resPrefixes.resourceGroup}-${shared.locPrefixes[location]}-${lzPrefix}-${envPrefix}${shared.delimiter.dash}')
var lawPrefix = toLower('${shared.resPrefixes.logAnalytics}-${shared.locPrefixes[location]}-${lzPrefix}-${envPrefix}${shared.delimiter.dash}')
var aaaPrefix = toLower('${shared.resPrefixes.azureAutomation}-${shared.locPrefixes[location]}-${lzPrefix}-${envPrefix}${shared.delimiter.dash}')
//var staPrefix = toLower('${shared.resPrefixes.storage}${shared.locPrefixes[location]}${lzPrefix}${envPrefix}')
//var vntPrefix = toLower('${shared.resPrefixes.virtualNetwork}-${shared.locPrefixes[location]}-${lzPrefix}-${envPrefix}-')
//var nsgPrefix = toLower('${shared.resPrefixes.networkSecurityGroup}-${shared.locPrefixes[location]}-${lzPrefix}-${envPrefix}-')
//var udrPrefix = toLower('${shared.resPrefixes.routeTable}-${shared.locPrefixes[location]}-${lzPrefix}-${envPrefix}-')
var dcrPrefix = toLower('${shared.resPrefixes.dataCollectionRule}${shared.delimiter.dash}${shared.locPrefixes[location]}${shared.delimiter.dash}${lzPrefix}${shared.delimiter.dash}${envPrefix}${shared.delimiter.dash}')
var uaiPrefix = toLower('${shared.resPrefixes.userAssignedIdentity}${shared.delimiter.dash}${shared.locPrefixes[location]}${shared.delimiter.dash}${lzPrefix}${shared.delimiter.dash}${envPrefix}${shared.delimiter.dash}')
var umPrefix = toLower('${shared.resPrefixes.updateManagement}${shared.delimiter.dash}${shared.locPrefixes[location]}${shared.delimiter.dash}${lzPrefix}${shared.delimiter.dash}${envPrefix}${shared.delimiter.dash}')
var akvPrefix = toLower('${shared.resPrefixes.keyVault}${shared.delimiter.dash}${shared.locPrefixes[location]}${shared.delimiter.dash}${lzPrefix}${shared.delimiter.dash}${envPrefix}${shared.delimiter.dash}')
var deployBudgets = budgetConfiguration.?enabled ?? true

var resourceGroups = {
  network: '${argPrefix}network'
  logging: '${argPrefix}logging'
}

var resourceNames = {
  logAnalyticsWorkspace: logAnalyticsConfiguration.?name ?? '${lawPrefix}${uniqueString(subscriptionId)}'
  azureAutomation: '${aaaPrefix}${uniqueString(subscriptionId)}'
  //storageAccount: storageAccountConfiguration.?name ?? take('${staPrefix}${uniqueString(subscriptionId)}', 24)
  dcrVMInsights: '${dcrPrefix}vminsights'
  dcrCT: '${dcrPrefix}changetracking'
  dcrMDFCSQL: '${dcrPrefix}mdfcsql'
  actionGroup: '${shared.resPrefixes.platform}${shared.resPrefixes.platformMgmt}ActionGroup'
  actionGroupShort: '${shared.resPrefixes.platform}AG'
  userAssignedIdentityAMA: '${uaiPrefix}ama'
  virtualMachine_Jumphosts: '${shared.resPrefixes.platform}${shared.resPrefixes.platformMgmt}vm'
  keyvault: '${akvPrefix}-${uniqueString(subscriptionId)}'
  vmName: '${shared.resPrefixes.platform}${shared.resPrefixes.platformMgmt}vm'
  akvName: '${akvPrefix}-${uniqueString(subscriptionId)}'
  updateManagerConfiguration: '${umPrefix}${uniqueString(subscriptionId)}'
}

@description('Resource: Subscription Scope Resource Tags')
resource tag 'Microsoft.Resources/tags@2025-03-01' = {
  name: 'default'
  properties: {
    tags: tags
  }
}

@description('Module: Resource Group (Logging)')
module resourceGroupForLogging 'br/public:avm/res/resources/resource-group:0.4.1' = {
  scope: subscription(subscriptionId)
  name: 'resourceGroupForLogging-${guid(deployment().name)}'
  params: {
    // Required parameters
    name: resourceGroups.logging
    // Non-required parameters
    location: location
    tags: tags
  }
}

@description('Module: Log Analytics Workspace - https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/operational-insights/workspace')
module workspace 'br/public:avm/res/operational-insights/workspace:0.12.0' = {
  scope: resourceGroup('${resourceGroups.logging}')
  name: take('workspace-${guid(deployment().name)}', 64)
  dependsOn: [
    resourceGroupForLogging
  ]
  params: {
    // Required parameters
    name: resourceNames.logAnalyticsWorkspace
    // Non-required parameters
    dailyQuotaGb: logAnalyticsConfiguration.?dailyQuotaGb ?? -1
    features: {
      enableLogAccessUsingOnlyResourcePermissions: logAnalyticsConfiguration.?features.?enableLogAccessUsingOnlyResourcePermissions ?? true
      disableLocalAuth: logAnalyticsConfiguration.?features.?disableLocalAuth ?? true
      enableDataExport: logAnalyticsConfiguration.?features.?enableDataExport
      immediatePurgeDataOn30Days: logAnalyticsConfiguration.?features.?immediatePurgeDataOn30Days
    }
    dataRetention: logAnalyticsConfiguration.?dataRetention ?? 30
    location: location
    managedIdentities: {
      systemAssigned: true
    }
    publicNetworkAccessForIngestion: logAnalyticsConfiguration.?publicNetworkAccessForIngestion ?? 'Enabled'
    publicNetworkAccessForQuery: logAnalyticsConfiguration.?publicNetworkAccessForQuery ?? 'Enabled'
    replication: logAnalyticsConfiguration.?replication.enabled == true
      ? {
          enabled: logAnalyticsConfiguration.?replication.enabled
          location: logAnalyticsConfiguration.?replication.location
        }
      : null
    skuName: logAnalyticsConfiguration.?skuName ?? 'PerGB2018'
    skuCapacityReservationLevel: logAnalyticsConfiguration.?skuName == 'CapacityReservation'
      ? logAnalyticsConfiguration.?skuCapacityReservationLevel
      : null
    tags: tags
  }
}

@description('Module: Azure Monitor Agent - https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/alz/ama')
module ama 'br/public:avm/ptn/alz/ama:0.1.0' = {
  name: take('ama-${guid(deployment().name)}', 64)
  scope: resourceGroup(subscriptionId, resourceGroups.logging)
  params: {
    // Required parameters
    dataCollectionRuleChangeTrackingName: resourceNames.dcrCT
    dataCollectionRuleMDFCSQLName: resourceNames.dcrMDFCSQL
    dataCollectionRuleVMInsightsName: resourceNames.dcrVMInsights
    logAnalyticsWorkspaceResourceId: workspace.outputs.resourceId
    userAssignedIdentityName: resourceNames.userAssignedIdentityAMA
    // Non-required parameters
    location: location
    tags: tags
  }
}

@description('Module: Azure Budgets - https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/consumption/budget')
module budget 'br/public:avm/res/consumption/budget:0.3.8' = [
  for (bg, index) in (budgetConfiguration.?budgets ?? []): if (!empty(budgetConfiguration) && deployBudgets) {
    name: take('budget-${guid(deployment().name)}-${index}', 64)
    scope: subscription(subscriptionId)
    params: {
      // Required parameters
      amount: bg.amount
      name: bg.name
      // Non-required parameters
      contactEmails: bg.contactEmails
      location: location
      startDate: startDate
      thresholdType: bg.thresholdType
      thresholds: bg.thresholds
    }
  }
]

@description('Resource Groups (Common) - https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/resources/resource-group')
module commonResourceGroups 'br/public:avm/res/resources/resource-group:0.4.1' = [
  for commonResourceGroup in shared.commonResourceGroupNames: {
    name: take('commonResourceGroups-${commonResourceGroup}', 64)
    scope: subscription(subscriptionId)
    params: {
      // Required parameters
      name: commonResourceGroup
      // Non-required parameters
      location: location
      tags: tags
    }
  }
]

@description('Module: Network Watcher - https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/network/network-watcher')
module networkWatcher 'br/public:avm/res/network/network-watcher:0.4.1' = {
  name: take('networkWatcher-${guid(deployment().name)}', 64)
  scope: resourceGroup(subscriptionId, 'networkWatcherRG')
  dependsOn: [
    commonResourceGroups
  ]
  params: {
    // Non-required parameters
    location: location
    tags: tags
  }
}

@description('Module: Action Group - https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/insights/action-group')
module actionGroup 'br/public:avm/res/insights/action-group:0.7.0' = if (!empty(actionGroupConfiguration.?emailReceivers)) {
  name: take('actionGroup-${guid(deployment().name)}', 64)
  scope: resourceGroup(subscriptionId, 'alertsRG')
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
