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

@description('Optional. Configuration for Azure Storage Account.')
param storageAccountConfiguration type.storageAccountType?

// Subscription Budget Module Parameters
@description('Optional. Deployment flag for Azure Budgets.')
param deployBudgets bool = true

@description('Optional. Configuration for Azure Budgets.')
param budgetConfiguration type.budgetType?

// Action Group Module Parameters
@description('Optional. Configuration for Action Groups.')
param actionGroupConfiguration type.actionGroupType?

// Configuration Maintenance Module Parameters
@description('Optional. Configuration for Configuration Maintenance.')
param configurationMaintenanceConfiguration type.maintenanceConfigurationType?

// Orchestration Variables
var argPrefix = toLower('${shared.resPrefixes.resourceGroup}${shared.delimiter.dash}${shared.locPrefixes[location]}${shared.delimiter.dash}${lzPrefix}${shared.delimiter.dash}${envPrefix}${shared.delimiter.dash}')
var lawPrefix = toLower('${shared.resPrefixes.logAnalytics}${shared.delimiter.dash}${shared.locPrefixes[location]}${shared.delimiter.dash}${lzPrefix}${shared.delimiter.dash}${envPrefix}${shared.delimiter.dash}')
var aaaPrefix = toLower('${shared.resPrefixes.azureAutomation}${shared.delimiter.dash}${shared.locPrefixes[location]}${shared.delimiter.dash}${lzPrefix}${shared.delimiter.dash}${envPrefix}${shared.delimiter.dash}')
var staPrefix = toLower('${shared.resPrefixes.storage}${shared.locPrefixes[location]}${lzPrefix}${envPrefix}')
var dcrPrefix = toLower('${shared.resPrefixes.dataCollectionRule}${shared.delimiter.dash}${shared.locPrefixes[location]}${shared.delimiter.dash}${lzPrefix}${shared.delimiter.dash}${envPrefix}${shared.delimiter.dash}')
var uaiPrefix = toLower('${shared.resPrefixes.userAssignedIdentity}${shared.delimiter.dash}${shared.locPrefixes[location]}${shared.delimiter.dash}${lzPrefix}${shared.delimiter.dash}${envPrefix}${shared.delimiter.dash}')
var umPrefix = toLower('${shared.resPrefixes.updateManagement}${shared.delimiter.dash}${shared.locPrefixes[location]}${shared.delimiter.dash}${lzPrefix}${shared.delimiter.dash}${envPrefix}${shared.delimiter.dash}')
var akvPrefix = toLower('${shared.resPrefixes.keyVault}${shared.delimiter.dash}${shared.locPrefixes[location]}${shared.delimiter.dash}${lzPrefix}${shared.delimiter.dash}${envPrefix}${shared.delimiter.dash}')

var resourceGroups = {
  network: '${argPrefix}network'
  logging: '${argPrefix}logging'
  updateManagement: '${argPrefix}updatemgmt'
}

var resourceNames = {
  logAnalyticsWorkspace: logAnalyticsConfiguration.?name ?? '${lawPrefix}${uniqueString(subscriptionId)}'
  azureAutomation: '${aaaPrefix}${uniqueString(subscriptionId)}'
  storageAccount: storageAccountConfiguration.?name ?? take('${staPrefix}${uniqueString(subscriptionId)}', 24)
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

@description('Module: Azure Automation Account - https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/automation/automation-account')
module automationAccount 'br/public:avm/res/automation/automation-account:0.16.1' = {
  scope: resourceGroup('${resourceGroups.logging}')
  name: take('automationAccount-${guid(deployment().name)}', 64)
  params: {
    // Required parameters
    name: resourceNames.azureAutomation
    // Non-required parameters
    disableLocalAuth: true
    managedIdentities: {
      systemAssigned: true
    }
    tags: tags
  }
}

@description('Module: Storage Account - https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/storage/storage-account')
module storageAccount 'br/public:avm/res/storage/storage-account:0.26.2' = {
  scope: resourceGroup('${resourceGroups.logging}')
  name: take('storageAccount-${guid(deployment().name)}', 64)
  params: {
    // Required parameters
    name: resourceNames.storageAccount
    // Non-required parameters
    accessTier: storageAccountConfiguration.?accessTier ?? 'Hot'
    allowBlobPublicAccess: storageAccountConfiguration.?allowBlobPublicAccess ?? false
    allowSharedKeyAccess: storageAccountConfiguration.?allowSharedKeyAccess ?? false
    blobServices: {
      containerDeleteRetentionPolicyDays: storageAccountConfiguration.?containerDeleteRetentionPolicyDays ?? 7
      containerDeleteRetentionPolicyEnabled: storageAccountConfiguration.?containerDeleteRetentionPolicyEnabled ?? true
      deleteRetentionPolicyDays: storageAccountConfiguration.?deleteRetentionPolicyDays ?? 7
      deleteRetentionPolicyEnabled: storageAccountConfiguration.?deleteRetentionPolicyEnabled ?? true
    }
    defaultToOAuthAuthentication: !(storageAccountConfiguration.?allowSharedKeyAccess ?? true)
    managedIdentities: {
      systemAssigned: true
    }
    kind: storageAccountConfiguration.?kind ?? 'StorageV2'
    location: location
    minimumTlsVersion: storageAccountConfiguration.?minimumTlsVersion ?? 'TLS1_2'
    networkAcls: storageAccountConfiguration.?networkAcls ?? {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
    publicNetworkAccess: storageAccountConfiguration.?publicNetworkAccess ?? 'Enabled'
    skuName: storageAccountConfiguration.?skuName ?? 'Standard_ZRS'
    supportsHttpsTrafficOnly: storageAccountConfiguration.?supportsHttpsTrafficOnly ?? true
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
      startDate: bg.startDate
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
module actionGroup 'br/public:avm/res/insights/action-group:0.8.0' = if (!empty(actionGroupConfiguration.?emailReceivers)) {
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

@description('Module: Service Health Alerts - https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/subscription/service-health-alerts')
module serviceHealthAlerts 'br/public:avm/ptn/subscription/service-health-alerts:0.1.1' = {
  name: take('serviceHealthAlerts-${guid(deployment().name)}', 64)
  params: {
    location: location
    serviceHealthAlerts: [
      for alert in shared.serviceHealthAlerts: {
        actionGroup: {
          enabled: true
          existingActionGroupResourceId: actionGroup.?outputs.resourceId ?? ''
        }
        serviceHealthAlert: alert
      }
    ]
    serviceHealthAlertsResourceGroupName: 'alertsRG'
    subscriptionId: subscriptionId
  }
}

@description('Module: Resource Group (Update Management)')
module resourceGroupForUpdateManagement 'br/public:avm/res/resources/resource-group:0.4.1' = {
  scope: subscription(subscriptionId)
  name: take('resourceGroupForUpdateManagement-${guid(deployment().name)}', 64)
  params: {
    // Required parameters
    name: resourceGroups.updateManagement
    // Non-required parameters
    location: location
    tags: tags
  }
}

module maintenanceConfiguration 'br/public:avm/res/maintenance/maintenance-configuration:0.3.1' = {
  scope: resourceGroup(subscriptionId, resourceGroups.updateManagement)
  name: take('maintenanceConfiguration-${guid(deployment().name)}', 64)
  params: {
    // Required parameters
    name: resourceNames.updateManagerConfiguration
    // Non-required parameters
    extensionProperties: configurationMaintenanceConfiguration.?extensionProperties ?? {}
    installPatches: {
      linuxParameters: configurationMaintenanceConfiguration.?installPatches.?linuxParameters ?? {}
      windowsParameters: configurationMaintenanceConfiguration.?installPatches.?windowsParameters ?? {}
      rebootSetting: configurationMaintenanceConfiguration.?installPatches.?rebootSetting ?? 'IfRequired'
    }
    location: location
    maintenanceScope: configurationMaintenanceConfiguration.?maintenanceScope ?? 'InGuestPatch'
    maintenanceWindow: configurationMaintenanceConfiguration.?maintenanceWindow ?? {}
    tags: tags
  }
}
