using '../modules/subVending/subVending.bicep'

param existingSubscriptionId = '9df3a442-42f1-40dd-8547-958c3e01597a'
param subscriptionMgPlacement = 'mg-alz-landingzones-corp'
param lzPrefix = 'sap'
param envPrefix = 'sbx'
param roleAssignments = [
  {
    definition: '/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7'
    description: 'Reader role'
    principalId: '2b33ff60-edf0-4216-b2a6-66ec07050fd4'
    principalType: 'Group'
    relativeScope: ''
  }
]
param tags = {
  environment: envPrefix
  applicationName: 'SAP Landing Zone'
  owner: 'Platform Team'
  criticality: 'Tier2'
  costCenter: '1234'
  contactEmail: 'stephen.tulp@outlook.com'
  dataClassification: 'Internal'
  iac: 'Bicep'
}
param budgetConfiguration = {
  enabled: true
  budgets: [
    {
      name: 'budget-forecasted'
      startDate: '2025-10-01'
      amount: 500
      thresholdType: 'Forecasted'
      thresholds: [
        90
      ]
      contactEmails: [
        'test@outlook.com'
      ]
    }
    {
      name: 'budget-actual'
      startDate: '2025-10-01'
      amount: 500
      thresholdType: 'Actual'
      thresholds: [
        95
        100
      ]
      contactEmails: [
        'test@outlook.com'
      ]
    }
  ]
}
param actionGroupConfiguration = {
  emailReceivers: [
    'test@outlook.com'
  ]
}

