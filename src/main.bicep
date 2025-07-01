targetScope = 'managementGroup'

metadata name = 'AVM ALZ MAnagement Groups & Custom RBAC Roles'
metadata description = 'Module used to bootstrap an Azure Landing Zone.'
metadata version = '0.0.1'
metadata author = 'Insight APAC Platform Engineering'

@description('Required. The name of the management group to create or update.')
param managementGroupNames object

@description('Required. JSON files containing the custom RBAC role definitions.')
param alzCustomRbacRoleDefsJson array

@description('Optional. The name of the management group to create or update.')
param createOrUpdateManagementGroup bool = true

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
