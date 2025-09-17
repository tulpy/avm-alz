import * as shared from '../../configuration/shared/shared.conf.bicep'
import * as type from '../../configuration/shared/shared.type.bicep'

targetScope = 'subscription'

metadata name = 'ALZ Bicep - Azure Platform Connectivity Orchestration Module'
metadata description = 'Module used to create Azure Platform Connectivity resources.'
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

@description('Required. The IP address range for all virtual networks to use.')
param addressPrefixes array = ['10.52.0.0/16']

@description('Optional. Switch which allows Private DNS Zones to be provisioned.')
param privateDnsZonesEnabled bool = true

@description('Optional.Whether to deploy the Azure DNS Private resolver or not.')
param privateResolverEnabled bool = false

@description('Optional. Configuration for Azure Bastion Host.')
param bastionHostConfiguration type.bastionHostType?

@description('Optional. An Array of Routes to be established within the route table for Gateway Subnet.')
param gatewayRoutes array = []

@description('Optional. Array of DNS Server IP addresses for the Hub virtual Network.')
param dnsServerIps array = []

// Subscription Budget Module Parameters
@description('Optional. Deployment flag for Azure Budgets.')
param deployBudgets bool = true

@description('Optional. Configuration for Azure Budgets.')
param budgetConfiguration type.budgetType?

@description('Optional. The Action Group Resource Id to be used for Service Health Alerts.')
param actionGroupResourceId string?

// Orchestration Variables
var argPrefix = toLower('${shared.resPrefixes.resourceGroup}${shared.delimiter.dash}${shared.locPrefixes[location]}${shared.delimiter.dash}${lzPrefix}${shared.delimiter.dash}${envPrefix}${shared.delimiter.dash}')
var vntPrefix = toLower('${shared.resPrefixes.virtualNetwork}${shared.delimiter.dash}${shared.locPrefixes[location]}${shared.delimiter.dash}${lzPrefix}${shared.delimiter.dash}${envPrefix}${shared.delimiter.dash}')
var vngPrefix = toLower('${shared.resPrefixes.virtualNetworkGateway}${shared.delimiter.dash}${shared.locPrefixes[location]}${shared.delimiter.dash}${lzPrefix}${shared.delimiter.dash}${envPrefix}${shared.delimiter.dash}')
var udrPrefix = toLower('${shared.resPrefixes.routeTable}${shared.delimiter.dash}${shared.locPrefixes[location]}${shared.delimiter.dash}${lzPrefix}${shared.delimiter.dash}${envPrefix}${shared.delimiter.dash}')
var basPrefix = toLower('${shared.resPrefixes.azureBastion}${shared.delimiter.dash}${shared.locPrefixes[location]}${shared.delimiter.dash}${lzPrefix}${shared.delimiter.dash}${envPrefix}${shared.delimiter.dash}')
var nsgPrefix = toLower('${shared.resPrefixes.networkSecurityGroup}${shared.delimiter.dash}${shared.locPrefixes[location]}${shared.delimiter.dash}${lzPrefix}${shared.delimiter.dash}${envPrefix}${shared.delimiter.dash}')
var afwPrefix = toLower('${shared.resPrefixes.azureFirewall}${shared.delimiter.dash}${shared.locPrefixes[location]}${shared.delimiter.dash}${lzPrefix}${shared.delimiter.dash}${envPrefix}${shared.delimiter.dash}')
var afpPrefix = toLower('${shared.resPrefixes.azureFirewallPolicy}${shared.delimiter.dash}${shared.locPrefixes[location]}${shared.delimiter.dash}${lzPrefix}${shared.delimiter.dash}${envPrefix}${shared.delimiter.dash}')
var pipPrefix = toLower('${shared.resPrefixes.publicIp}${shared.delimiter.dash}${shared.locPrefixes[location]}${shared.delimiter.dash}${lzPrefix}${shared.delimiter.dash}${envPrefix}${shared.delimiter.dash}')
var ddosPrefix = toLower('${shared.resPrefixes.azureDdos}${shared.delimiter.dash}${shared.locPrefixes[location]}${shared.delimiter.dash}${lzPrefix}${shared.delimiter.dash}${envPrefix}${shared.delimiter.dash}')
var dnsrPrefix = toLower('${shared.resPrefixes.privateDnsResolver}${shared.delimiter.dash}${shared.locPrefixes[location]}${shared.delimiter.dash}${lzPrefix}${shared.delimiter.dash}${envPrefix}${shared.delimiter.dash}')

var vnetAddressSpace = replace(varAddressPrefix, '/', '_')
var varAddressPrefix = first(addressPrefixes)

var resourceGroups = {
  network: '${argPrefix}network'
  privateDns: '${argPrefix}privatedns'
}

var resourceNames = {
  virtualNetwork: '${vntPrefix}${vnetAddressSpace}'
  privateDnsResolver: '${dnsrPrefix}privateresolver'
  privateDnsResolverRuleset: '${dnsrPrefix}forwardingruleset'
  azureBastion: '${basPrefix}${uniqueString(subscriptionId)}'
  azureFirewall: '${afwPrefix}${uniqueString(subscriptionId)}'
  azureFirewallPolicy: '${afpPrefix}${uniqueString(subscriptionId)}'
  routeTable: '${udrPrefix}gatewaySubnet'
  ddosPlan: '${ddosPrefix}${uniqueString(subscriptionId)}'
  bastionPublicIp: '${pipPrefix}bastion'
  bastionNsg: '${nsgPrefix}bastion'
  vpnGwyPublicIp1: '${pipPrefix}vpnGwy1'
  vpnGwyPublicIp2: '${pipPrefix}vpnGwy2'
  erGwyPublicIp: '${pipPrefix}erGwy'
  azFwPublicIp: '${pipPrefix}azFw'
  vpnGateway: '${vngPrefix}vpnGwy'
  erGateway: '${vngPrefix}erGwy'
}

@description('Resource: Subscription Scope Resource Tags')
resource tag 'Microsoft.Resources/tags@2025-03-01' = {
  name: 'default'
  properties: {
    tags: tags
  }
}

@description('Module: Resource Group (Network)')
resource resourceGroupForNetwork 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: resourceGroups.network
  location: location
  tags: tags
  properties: {}
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
      startDate: bg
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

@description('Module: Service Health Alerts - https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/subscription/service-health-alerts')
module serviceHealthAlerts 'br/public:avm/ptn/subscription/service-health-alerts:0.1.1' = if (!empty(actionGroupResourceId)) {
  name: take('serviceHealthAlerts-${guid(deployment().name)}', 64)
  params: {
    location: location
    serviceHealthAlerts: [
      for alert in shared.serviceHealthAlerts: {
        actionGroup: {
          enabled: true
          existingActionGroupResourceId: actionGroupResourceId
        }
        serviceHealthAlert: alert
      }
    ]
    serviceHealthAlertsResourceGroupName: 'alertsRG'
    subscriptionId: subscriptionId
  }
}

module hubNetworking 'br/public:avm/ptn/network/hub-networking:0.5.0' = {
  name: take('hubNetworking-${guid(deployment().name)}', 64)
  scope: resourceGroup(subscriptionId, resourceGroupForPrivateDns.name)
  params: {
    hubVirtualNetworks: {
      hub1: {
        addressPrefixes: addressPrefixes
        azureFirewallSettings: {
          azureFirewallName: resourceNames.azureFirewall
          azureSkuTier: 'Standard'
          location: location
          publicIPAddressObject: {
            name: 'hub1-waf-pip'
          }
          threatIntelMode: 'Alert'
          zones: [
            1
            2
            3
          ]
        }
        bastionHost: {
          bastionHostName: resourceNames.azureBastion
          disableCopyPaste: bastionHostConfiguration.?disableCopyPaste ?? false
          enableFileCopy: bastionHostConfiguration.?enableFileCopy ?? true
          enableKerberos: bastionHostConfiguration.?enableKerberos ?? true
          enableIpConnect: bastionHostConfiguration.?enableIpConnect ?? false
          enableShareableLink: bastionHostConfiguration.?enableShareableLink ?? false
          scaleUnits: 2
          skuName: bastionHostConfiguration.?skuName ?? 'Basic'
        }
        dnsServers: dnsServerIps
        enableAzureFirewall: true
        enableBastion: true
        enablePeering: false
        flowTimeoutInMinutes: 30
        location: location
        name: 'hub1'
        peeringSettings: [
          {
            allowForwardedTraffic: true
            allowGatewayTransit: false
            allowVirtualNetworkAccess: true
            remoteVirtualNetworkName: 'hub2'
            useRemoteGateways: false
          }
        ]
        routeTableName: resourceNames.routeTable
        routes: gatewayRoutes
        subnets: [
          {
            addressPrefix: '<addressPrefix>'
            name: 'GatewaySubnet'
          }
          {
            addressPrefix: '<addressPrefix>'
            name: 'AzureFirewallSubnet'
          }
          {
            addressPrefix: '<addressPrefix>'
            name: 'AzureBastionSubnet'
          }
          {
            addressPrefix: '<addressPrefix>'
            delegation: 'Microsoft.Network/dnsResolvers'
            name: 'DNSResolver'
          }
        ]
        tags: tags
        vnetEncryption: false
        vnetEncryptionEnforcement: 'AllowUnencrypted'
      }
    }
    location: location
  }
}

@description('Module: Resource Group (PrivateDNS)')
resource resourceGroupForPrivateDns 'Microsoft.Resources/resourceGroups@2025-04-01' = if (privateDnsZonesEnabled || privateResolverEnabled) {
  name: resourceGroups.privateDns
  location: location
  tags: tags
  properties: {}
}

@description('Module: Private Link Private DNS Zones - https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/network/private-link-private-dns-zones')
module privateLinkPrivateDnsZones 'br/public:avm/ptn/network/private-link-private-dns-zones:0.6.0' = {
  name: take('privateLinkPrivateDnsZones-${guid(deployment().name)}', 64)
  scope: resourceGroup(subscriptionId, resourceGroupForPrivateDns.name)
  params: {
    additionalPrivateLinkPrivateDnsZonesToInclude: [
    ]
    location: location
    privateLinkPrivateDnsZones: [
      'privatelink.{regionCode}.backup.windowsazure.com'
      'privatelink.{regionName}.azmk8s.io'
      'privatelink.api.azureml.ms'
      'privatelink.notebooks.azure.net'
    ]
    privateLinkPrivateDnsZonesToExclude: [
    ]
    tags: tags
    virtualNetworkLinks: [
      {
        name: 'vnet2-link-custom-name'
        registrationEnabled: false
        resolutionPolicy: 'NxDomainRedirect'
        tags: tags
        virtualNetworkResourceId: '<virtualNetworkResourceId>'
      }
    ]
    virtualNetworkResourceIdsToLinkTo: [
      '<vnet1ResourceId>'
    ]
  }
}
