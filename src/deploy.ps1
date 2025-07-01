New-AzManagementGroupDeploymentStack `
    -Name "Deploy-AVM-ALZ-Stack" `
    -ManagementGroupId 'a2ebc691-c318-4ec2-998a-a87c528378e0' `
    -TemplateFile 'main.bicep' `
    -TemplateParameterFile './configuration/main.bicepparam' `
    -Location 'australiaeast' `
    -DenySettingsMode 'none' `
    -ActionOnUnmanage 'DeleteAll' `
    -Verbose