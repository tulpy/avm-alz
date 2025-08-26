New-AzManagementGroupDeployment `
    -Name "Deploy-AVM-subVending" `
    -ManagementGroupId 'a2ebc691-c318-4ec2-998a-a87c528378e0' `
    -TemplateFile 'subVending.bicep' `
    -TemplateParameterFile '../../configuration/sub-sap-sbx-01.bicepparam' `
    -Location 'australiaeast' `
    -Verbose