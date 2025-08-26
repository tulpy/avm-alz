New-AzResourceGroupDeployment `
    -Name "Deploy-AVNM" `
    -ResourceGroupName 'arg-aue-plat-conn-network' `
    -TemplateFile 'main.bicep' `
    -TemplateParameterFile 'main.bicepparam' `
    -Verbose