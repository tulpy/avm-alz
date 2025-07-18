New-AzManagementGroupDeploymentStack `
    -Name "Deploy-AVM-ALZ-Stack" `
    -ManagementGroupId 'a2ebc691-c318-4ec2-998a-a87c528378e0' `
    -TemplateFile '../src/main.bicep' `
    -TemplateParameterFile '../src/configuration/main.bicepparam' `
    -Location 'australiaeast' `
    -DenySettingsMode 'none' `
    -ActionOnUnmanage 'DeleteAll' `
    -Verbose