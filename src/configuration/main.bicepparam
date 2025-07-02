using '../main.bicep'

param mgId = 'mg-alz'
param alzCustomRbacRoleDefsJson = [
  loadJsonContent('../lib/role_definitions/application_owners.alz_role_definition.json')
  loadJsonContent('../lib/role_definitions/network_management.alz_role_definition.json')
  loadJsonContent('../lib/role_definitions/network_subnet_contributor.alz_role_definition.json')
  loadJsonContent('../lib/role_definitions/security_operations.alz_role_definition.json')
  loadJsonContent('../lib/role_definitions/subscription_owner.alz_role_definition.json')
]

param alzCustomPolicyDefsJson = [
  loadJsonContent('../lib/policy_definitions/Deploy_Budget.alz_policy_definition.json')
]

param alzCustomPolicySetDefsJson = [
  loadJsonContent('../lib/policy_set_definitions/Audit-TrustedLaunch.alz_policy_set_definition.json')
]
