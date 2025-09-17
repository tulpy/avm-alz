New-AzDeployment `
    -Name "Deploy-AVM-platformConnectivity" `
    -TemplateFile 'platformConnectivity.bicep' `
    -TemplateParameterFile '../../configuration/platformConnectivity.bicepparam' `
    -Location 'australiaeast' `
    -Verbose