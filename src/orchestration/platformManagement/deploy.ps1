New-AzDeployment `
    -Name "Deploy-AVM-platformManagement" `
    -TemplateFile 'platformManagement.bicep' `
    -TemplateParameterFile '../../configuration/platformManagement.bicepparam' `
    -Location 'australiaeast' `
    -Verbose