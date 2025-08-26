using '../orchestration/platformManagement/platformManagement.bicep'

param lzPrefix = 'plat'
param envPrefix = 'mgmt'
param subscriptionId = 'a50d2a27-93d9-43b1-957c-2a663ffaf37f'
param tags = {
  environment: envPrefix
  applicationName: 'Platform Management Landing Zone'
  owner: 'Platform Team'
  criticality: 'Tier0'
  costCenter: '1234'
  contactEmail: 'test@outlook.com'
  dataClassification: 'Internal'
  iac: 'Bicep'
}
param budgetConfiguration = {
  enabled: false
  budgets: [
    {
      name: 'budget-forecasted'
      amount: 500
      thresholdType: 'Forecasted'
      thresholds: [
        90
        100
      ]
      contactEmails: [
        'test@outlook.com'
      ]
    }
    {
      name: 'budget-actual'
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
param logAnalyticsConfiguration = {
  dataRetention: 90
  skuName: 'PerGB2018'
}
