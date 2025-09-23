targetScope = 'managementGroup'

metadata name = 'Test and Validation Deployment'
metadata description = 'Test and Validation of the Platform Orchestration Module.'

module testDeployment '../platform.bicep' = {
  name: take('testDeployment-${guid(deployment().name)}', 64)
  params: {
    mgId: 'mg-alz'
    mgDisplayName: 'AVM ALZ Management Group'
  }
}
