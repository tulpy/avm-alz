using '../main.bicep'

param managementGroupNames = {
  intRoot: {
    displayName: 'AVM ALZ Management Group'
    id: 'mg-avm-alz'
  }
  decommissioned: {
    displayName: 'Decommissioned'
    id: 'mg-avm-alz-decommissioned'
  }
  sandbox: {
    displayName: 'Sandbox'
    id: 'mg-avm-alz-sandbox'
  }
  platform: {
    displayName: 'Platform'
    id: 'mg-avm-alz-platform'
  }
  connectivity: {
    displayName: 'Connectivity'
    id: 'mg-avm-alz-connectivity'
  }
  management: {
    displayName: 'Management'
    id: 'mg-avm-alz-management'
  }
  identity: {
    displayName: 'Identity'
    id: 'mg-avm-alz-identity'
  }
  landingZones: {
    displayName: 'Landing Zones'
    id: 'mg-avm-alz-landingzones'
  }
  corp: {
    displayName: 'Corp'
    id: 'mg-avm-alz-corp'
  }
  online: {
    displayName: 'Online'
    id: 'mg-avm-alz-online'
  }
}

param alzCustomRbacRoleDefsJson = [
  loadJsonContent('../lib/role_definitions/application_owners.alz_role_definition.json')
  loadJsonContent('../lib/role_definitions/network_management.alz_role_definition.json')
  loadJsonContent('../lib/role_definitions/network_subnet_contributor.alz_role_definition.json')
  loadJsonContent('../lib/role_definitions/security_operations.alz_role_definition.json')
  loadJsonContent('../lib/role_definitions/subscription_owner.alz_role_definition.json')
]
