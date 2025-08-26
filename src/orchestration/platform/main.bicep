targetScope = 'managementGroup'

metadata name = 'AVM ALZ Management Groups & Custom RBAC Roles'
metadata description = 'Module used to bootstrap an Azure Landing Zone.'
metadata version = '0.0.1'
metadata author = 'Insight APAC Platform Engineering'

@description('Required. A short Management Group identifier for the kind of deployment.')
param mgId string

@description('Optional. JSON files containing the custom RBAC role definitions.')
param alzCustomRbacRoleDefsJson array = []

@description('Optional. JSON files containing the custom policy definitions.')
param alzCustomPolicyDefsJson array = []

@description('Optional. JSON files containing the custom policy definitions.')
param alzCustomPolicySetDefsJson array = []

@description('Optional. The name of the management group to create or update.')
param createOrUpdateManagementGroup bool = true

// Management Group Structure
var managementGroupNames = {
  intRoot: {
    displayName: 'AVM ALZ Management Group'
    id: mgId
  }
  decommissioned: {
    displayName: 'Decommissioned'
    id: '${mgId}-decommissioned'
  }
  sandbox: {
    displayName: 'Sandbox'
    id: '${mgId}-sandbox'
  }
  platform: {
    displayName: 'Platform'
    id: '${mgId}-platform'
  }
  connectivity: {
    displayName: 'Connectivity'
    id: '${mgId}-platform-connectivity'
  }
  management: {
    displayName: 'Management'
    id: '${mgId}-platform-management'
  }
  identity: {
    displayName: 'Identity'
    id: '${mgId}-platform-identity'
  }
  landingZones: {
    displayName: 'Landing Zones'
    id: '${mgId}-landingzones'
  }
  corp: {
    displayName: 'Corp'
    id: '${mgId}-lz-corp'
  }
  online: {
    displayName: 'Online'
    id: '${mgId}-lz-online'
  }
}

// Custom Role Definitions
var alzCustomRbacRoleDefsJsonParsed = [
  for roleDef in alzCustomRbacRoleDefsJson: {
    name: roleDef.name
    roleName: roleDef.properties.roleName
    description: roleDef.properties.description
    actions: roleDef.properties.permissions[0].actions
    notActions: roleDef.properties.permissions[0].notActions
    dataActions: roleDef.properties.permissions[0].dataActions
    notDataActions: roleDef.properties.permissions[0].notDataActions
  }
]
var additionalCustomRbacRoleDefs = [
  {
    name: '[${managementGroup().name}] VM Operator'
    description: 'Start and Stop Virtual Machines and reader access'
    actions: [
      'Microsoft.Compute/virtualMachines/read'
      'Microsoft.Compute/virtualMachines/start/action'
      'Microsoft.Compute/virtualMachines/restart/action'
      'Microsoft.Resources/subscriptions/resourceGroups/read'
      'Microsoft.Compute/virtualMachines/deallocate/action'
      'Microsoft.Compute/virtualMachineScaleSets/deallocate/action'
      'Microsoft.Compute/virtualMachineScaleSets/virtualMachines/deallocate/action'
      'Microsoft.Compute/virtualMachines/powerOff/action'
    ]
  }
]
var unionedCustomRbacRoleDefs = union(alzCustomRbacRoleDefsJsonParsed, additionalCustomRbacRoleDefs)

// Role Assignments
var managementGroupRoleAssignments = [
  {
    principalId: deployer().objectId
    roleDefinitionIdOrName: 'Reader'
  }
  {
    principalId: deployer().objectId
    roleDefinitionIdOrName: 'Contributor'
  }
  {
    principalId: deployer().objectId
    roleDefinitionIdOrName: alzCustomRbacRoleDefsJson[1].name
  }
  {
    principalId: deployer().objectId
    roleDefinitionIdOrName: alzCustomRbacRoleDefsJson[3].name
  }
]

// Policy Definitions, Initiatives and Assignments
var managementGroupCustomPolicyDefinitions = [
  for policy in alzCustomPolicyDefsJson: {
    name: policy.name
    properties: {
      description: policy.properties.description
      displayName: policy.properties.displayName
      metadata: policy.properties.metadata
      mode: policy.properties.mode
      parameters: policy.properties.parameters
      policyType: policy.properties.policyType
      policyRule: policy.properties.policyRule
    }
  }
]

var managementGroupCustomPolicySetDefinitions = [
  for policy in alzCustomPolicySetDefsJson: {
    name: policy.name
    properties: {
      description: policy.properties.description
      displayName: policy.properties.displayName
      metadata: policy.properties.metadata
      parameters: policy.properties.parameters
      policyType: policy.properties.policyType
      version: policy.properties.?version
      policyDefinitions: policy.properties.policyDefinitions
    }
  }
]

@description('Module: Int Root Management Group - https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/alz/empty')
module intRoot 'br/public:avm/ptn/alz/empty:0.2.0' = {
  name: take('intRoot-${guid(deployment().name)}', 64)
  params: {
    // Required parameters
    managementGroupName: managementGroupNames.intRoot.id
    // Non-required parameters
    createOrUpdateManagementGroup: createOrUpdateManagementGroup
    managementGroupCustomRoleDefinitions: unionedCustomRbacRoleDefs
    managementGroupDisplayName: managementGroupNames.intRoot.displayName
    managementGroupRoleAssignments: managementGroupRoleAssignments
    managementGroupCustomPolicyDefinitions: managementGroupCustomPolicyDefinitions
    managementGroupCustomPolicySetDefinitions: managementGroupCustomPolicySetDefinitions
    managementGroupPolicyAssignments: [
      {
        name: 'allowed-locations'
        displayName: 'Allowed locations for resources - AVM'
        identity: 'None'
        enforcementMode: 'Default'
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c'
        definitionVersion: '1.*.*'
        parameters: {
          listOfAllowedLocations: {
            value: [
              'australiaeast'
              'global'
            ]
          }
        }
      }
    ]
  }
}

@description('Module: Decommissioned Management Group - https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/alz/empty')
module decommissioned 'br/public:avm/ptn/alz/empty:0.2.0' = {
  name: take('decommissioned-${guid(deployment().name)}', 64)
  params: {
    // Required parameters
    managementGroupName: managementGroupNames.decommissioned.id
    // Non-required parameters
    createOrUpdateManagementGroup: createOrUpdateManagementGroup
    managementGroupDisplayName: managementGroupNames.decommissioned.displayName
    managementGroupParentId: intRoot.outputs.managementGroupId
  }
}

@description('Module: Sandbox Management Group - https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/alz/empty')
module sandbox 'br/public:avm/ptn/alz/empty:0.2.0' = {
  name: take('sandbox-${guid(deployment().name)}', 64)
  params: {
    // Required parameters
    managementGroupName: managementGroupNames.sandbox.id
    // Non-required parameters
    createOrUpdateManagementGroup: createOrUpdateManagementGroup
    managementGroupDisplayName: managementGroupNames.sandbox.displayName
    managementGroupParentId: intRoot.outputs.managementGroupId
  }
}

@description('Module: Platform Management Group - https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/alz/empty')
module platform 'br/public:avm/ptn/alz/empty:0.2.0' = {
  name: take('platform-${guid(deployment().name)}', 64)
  params: {
    // Required parameters
    managementGroupName: managementGroupNames.platform.id
    // Non-required parameters
    createOrUpdateManagementGroup: createOrUpdateManagementGroup
    managementGroupDisplayName: managementGroupNames.platform.displayName
    managementGroupParentId: intRoot.outputs.managementGroupId
  }
}

@description('Module: Platform Management Management Group - https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/alz/empty')
module platformManagement 'br/public:avm/ptn/alz/empty:0.2.0' = {
  name: take('platformManagement-${guid(deployment().name)}', 64)
  params: {
    // Required parameters
    managementGroupName: managementGroupNames.management.id
    // Non-required parameters
    createOrUpdateManagementGroup: createOrUpdateManagementGroup
    managementGroupDisplayName: managementGroupNames.management.displayName
    managementGroupParentId: platform.outputs.managementGroupId
  }
}

@description('Module: Platform Identity Management Group - https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/alz/empty')
module platformIdentity 'br/public:avm/ptn/alz/empty:0.2.0' = {
  name: take('platformIdentity-${guid(deployment().name)}', 64)
  params: {
    // Required parameters
    managementGroupName: managementGroupNames.identity.id
    // Non-required parameters
    createOrUpdateManagementGroup: createOrUpdateManagementGroup
    managementGroupDisplayName: managementGroupNames.identity.displayName
    managementGroupParentId: platform.outputs.managementGroupId
  }
}

@description('Module: Platform Connectivity Management Group - https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/alz/empty')
module platformConnectivity 'br/public:avm/ptn/alz/empty:0.2.0' = {
  name: take('platformConnectivity-${guid(deployment().name)}', 64)
  params: {
    // Required parameters
    managementGroupName: managementGroupNames.connectivity.id
    // Non-required parameters
    createOrUpdateManagementGroup: createOrUpdateManagementGroup
    managementGroupDisplayName: managementGroupNames.connectivity.displayName
    managementGroupParentId: platform.outputs.managementGroupId
  }
}

@description('Module: Landing Zone Management Group - https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/alz/empty')
module landingZones 'br/public:avm/ptn/alz/empty:0.2.0' = {
  name: take('landingZones-${guid(deployment().name)}', 64)
  params: {
    // Required parameters
    managementGroupName: managementGroupNames.landingZones.id
    // Non-required parameters
    createOrUpdateManagementGroup: createOrUpdateManagementGroup
    managementGroupDisplayName: managementGroupNames.landingZones.displayName
    managementGroupParentId: intRoot.outputs.managementGroupId
    subscriptionsToPlaceInManagementGroup: [
      '0b5d0018-2879-4810-b8d7-4f8dda5ce0b9'
    ]
  }
}

@description('Module: Landing Zone Corp Management Group - https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/alz/empty')
module lzCorp 'br/public:avm/ptn/alz/empty:0.2.0' = {
  name: take('corp-${guid(deployment().name)}', 64)
  params: {
    // Required parameters
    managementGroupName: managementGroupNames.corp.id
    // Non-required parameters
    createOrUpdateManagementGroup: createOrUpdateManagementGroup
    managementGroupDisplayName: managementGroupNames.corp.displayName
    managementGroupParentId: landingZones.outputs.managementGroupId
  }
}

@description('Module: Landing Zone Online Management Group - https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/alz/empty')
module lzOnline 'br/public:avm/ptn/alz/empty:0.2.0' = {
  name: take('online-${guid(deployment().name)}', 64)
  params: {
    // Required parameters
    managementGroupName: managementGroupNames.online.id
    // Non-required parameters
    createOrUpdateManagementGroup: createOrUpdateManagementGroup
    managementGroupDisplayName: managementGroupNames.online.displayName
    managementGroupParentId: landingZones.outputs.managementGroupId
  }
}
