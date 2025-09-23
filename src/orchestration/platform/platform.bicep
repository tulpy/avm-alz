targetScope = 'managementGroup'

metadata name = 'ALZ AVM Management Groups & Platform Resources Orchestration'
metadata description = 'Module used to bootstrap an Azure Landing Zone Platform.'
metadata version = '0.0.2'
metadata author = 'Insight APAC Platform Engineering'

@description('Required. The Int Root Management Group Id.')
param mgId string

@description('Required. The Int Root Management Group Display Name.')
param mgDisplayName string

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
    displayName: mgDisplayName
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
  platformConnectivity: {
    displayName: 'Connectivity'
    id: '${mgId}-platform-connectivity'
  }
  platformManagement: {
    displayName: 'Management'
    id: '${mgId}-platform-management'
  }
  platformIdentity: {
    displayName: 'Identity'
    id: '${mgId}-platform-identity'
  }
  platformSecurity: {
    displayName: 'Security'
    id: '${mgId}-platform-security'
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
var additionalCustomRbacRoleDefs = []
var unionedCustomRbacRoleDefs = union(alzCustomRbacRoleDefsJsonParsed, additionalCustomRbacRoleDefs)

// Role Assignments
var managementGroupRoleAssignments = {
  intRoot: [
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
  decommissioned: []
  sandbox: []
  platform: []
  platformConnectivity: []
  platformManagement: []
  platformIdentity: []
  platformSecurity: []
  landingZones: []
  lzCorp: []
  lzOnline: []
}

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
module intRoot 'br/public:avm/ptn/alz/empty:0.3.1' = {
  name: take('intRoot-${guid(deployment().name)}', 64)
  params: {
    // Required parameters
    managementGroupName: managementGroupNames.intRoot.id
    // Non-required parameters
    createOrUpdateManagementGroup: createOrUpdateManagementGroup
    managementGroupCustomRoleDefinitions: unionedCustomRbacRoleDefs
    managementGroupDisplayName: managementGroupNames.intRoot.displayName
    managementGroupRoleAssignments: managementGroupRoleAssignments.intRoot
    managementGroupCustomPolicyDefinitions: !empty(managementGroupCustomPolicyDefinitions)
      ? managementGroupCustomPolicyDefinitions
      : null
    managementGroupCustomPolicySetDefinitions: !empty(managementGroupCustomPolicySetDefinitions)
      ? managementGroupCustomPolicySetDefinitions
      : null
    subscriptionsToPlaceInManagementGroup: []
  }
}

@description('Module: Decommissioned Management Group - https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/alz/empty')
module decommissioned 'br/public:avm/ptn/alz/empty:0.3.1' = {
  name: take('decommissioned-${guid(deployment().name)}', 64)
  params: {
    // Required parameters
    managementGroupName: managementGroupNames.decommissioned.id
    // Non-required parameters
    createOrUpdateManagementGroup: createOrUpdateManagementGroup
    managementGroupDisplayName: managementGroupNames.decommissioned.displayName
    managementGroupRoleAssignments: managementGroupRoleAssignments.decommissioned
    managementGroupParentId: intRoot.outputs.managementGroupId
    subscriptionsToPlaceInManagementGroup: []
  }
}

@description('Module: Sandbox Management Group - https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/alz/empty')
module sandbox 'br/public:avm/ptn/alz/empty:0.3.1' = {
  name: take('sandbox-${guid(deployment().name)}', 64)
  params: {
    // Required parameters
    managementGroupName: managementGroupNames.sandbox.id
    // Non-required parameters
    createOrUpdateManagementGroup: createOrUpdateManagementGroup
    managementGroupDisplayName: managementGroupNames.sandbox.displayName
    managementGroupRoleAssignments: managementGroupRoleAssignments.sandbox
    managementGroupParentId: intRoot.outputs.managementGroupId
    subscriptionsToPlaceInManagementGroup: []
  }
}

@description('Module: Platform Management Group - https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/alz/empty')
module platform 'br/public:avm/ptn/alz/empty:0.3.1' = {
  name: take('platform-${guid(deployment().name)}', 64)
  params: {
    // Required parameters
    managementGroupName: managementGroupNames.platform.id
    // Non-required parameters
    createOrUpdateManagementGroup: createOrUpdateManagementGroup
    managementGroupDisplayName: managementGroupNames.platform.displayName
    managementGroupRoleAssignments: managementGroupRoleAssignments.platform
    managementGroupParentId: intRoot.outputs.managementGroupId
    subscriptionsToPlaceInManagementGroup: []
  }
}

@description('Module: Platform Management Management Group - https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/alz/empty')
module platformManagement 'br/public:avm/ptn/alz/empty:0.3.1' = {
  name: take('platformManagement-${guid(deployment().name)}', 64)
  params: {
    // Required parameters
    managementGroupName: managementGroupNames.platformManagement.id
    // Non-required parameters
    createOrUpdateManagementGroup: createOrUpdateManagementGroup
    managementGroupDisplayName: managementGroupNames.platformManagement.displayName
    managementGroupRoleAssignments: managementGroupRoleAssignments.platformManagement
    managementGroupParentId: platform.outputs.managementGroupId
    subscriptionsToPlaceInManagementGroup: []
  }
}

@description('Module: Platform Identity Management Group - https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/alz/empty')
module platformIdentity 'br/public:avm/ptn/alz/empty:0.3.1' = {
  name: take('platformIdentity-${guid(deployment().name)}', 64)
  params: {
    // Required parameters
    managementGroupName: managementGroupNames.platformIdentity.id
    // Non-required parameters
    createOrUpdateManagementGroup: createOrUpdateManagementGroup
    managementGroupDisplayName: managementGroupNames.platformIdentity.displayName
    managementGroupRoleAssignments: managementGroupRoleAssignments.platformIdentity
    managementGroupParentId: platform.outputs.managementGroupId
    subscriptionsToPlaceInManagementGroup: []
  }
}

@description('Module: Platform Connectivity Management Group - https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/alz/empty')
module platformConnectivity 'br/public:avm/ptn/alz/empty:0.3.1' = {
  name: take('platformConnectivity-${guid(deployment().name)}', 64)
  params: {
    // Required parameters
    managementGroupName: managementGroupNames.platformConnectivity.id
    // Non-required parameters
    createOrUpdateManagementGroup: createOrUpdateManagementGroup
    managementGroupDisplayName: managementGroupNames.platformConnectivity.displayName
    managementGroupRoleAssignments: managementGroupRoleAssignments.platformConnectivity
    managementGroupParentId: platform.outputs.managementGroupId
    subscriptionsToPlaceInManagementGroup: []
  }
}

@description('Module: Platform Security Management Group - https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/alz/empty')
module platformSecurity 'br/public:avm/ptn/alz/empty:0.3.1' = {
  name: take('platformSecurity-${guid(deployment().name)}', 64)
  params: {
    // Required parameters
    managementGroupName: managementGroupNames.platformSecurity.id
    // Non-required parameters
    createOrUpdateManagementGroup: createOrUpdateManagementGroup
    managementGroupDisplayName: managementGroupNames.platformSecurity.displayName
    managementGroupRoleAssignments: managementGroupRoleAssignments.platformSecurity
    managementGroupParentId: platform.outputs.managementGroupId
    subscriptionsToPlaceInManagementGroup: []
  }
}

@description('Module: Landing Zone Management Group - https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/alz/empty')
module landingZones 'br/public:avm/ptn/alz/empty:0.3.1' = {
  name: take('landingZones-${guid(deployment().name)}', 64)
  params: {
    // Required parameters
    managementGroupName: managementGroupNames.landingZones.id
    // Non-required parameters
    createOrUpdateManagementGroup: createOrUpdateManagementGroup
    managementGroupDisplayName: managementGroupNames.landingZones.displayName
    managementGroupRoleAssignments: managementGroupRoleAssignments.landingZones
    managementGroupParentId: intRoot.outputs.managementGroupId
    subscriptionsToPlaceInManagementGroup: []
  }
}

@description('Module: Landing Zone Corp Management Group - https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/alz/empty')
module lzCorp 'br/public:avm/ptn/alz/empty:0.3.1' = {
  name: take('corp-${guid(deployment().name)}', 64)
  params: {
    // Required parameters
    managementGroupName: managementGroupNames.corp.id
    // Non-required parameters
    createOrUpdateManagementGroup: createOrUpdateManagementGroup
    managementGroupDisplayName: managementGroupNames.corp.displayName
    managementGroupRoleAssignments: managementGroupRoleAssignments.lzCorp
    managementGroupParentId: landingZones.outputs.managementGroupId
    subscriptionsToPlaceInManagementGroup: []
  }
}

@description('Module: Landing Zone Online Management Group - https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/alz/empty')
module lzOnline 'br/public:avm/ptn/alz/empty:0.3.1' = {
  name: take('online-${guid(deployment().name)}', 64)
  params: {
    // Required parameters
    managementGroupName: managementGroupNames.online.id
    // Non-required parameters
    createOrUpdateManagementGroup: createOrUpdateManagementGroup
    managementGroupDisplayName: managementGroupNames.online.displayName
    managementGroupRoleAssignments: managementGroupRoleAssignments.lzOnline
    managementGroupParentId: landingZones.outputs.managementGroupId
    subscriptionsToPlaceInManagementGroup: []
  }
}
