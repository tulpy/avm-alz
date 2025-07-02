<#
.SYNOPSIS
Outputs necessary details for authoring policy definitions and set definitions in a Bicep format.

.DESCRIPTION
This script generates .txt files that detail the names and paths of policy definitions and set definitions. It supports creating parameter files for each policy set definition. The script is useful for auditing changes in policies as it also outputs the number of policy and policy set definition files, aiding the review process in pull requests.

.PARAMETER rootPath
Specifies the root path where module source files are located. Default is "./src/modules/policy".

.PARAMETER definitionsRoot
Specifies the subdirectory under rootPath where definitions are stored. Default is "definitions".

.PARAMETER lineEnding
Specifies the type of line ending to use in output files. Default is "unix".

.PARAMETER policyDefinitionsPath
Specifies the path where policy definitions are stored, relative to definitionsRoot. Default is "lib/policy_definitions".

.PARAMETER definitionsSetPath
Specifies the path where policy set definitions are stored, relative to definitionsRoot. Default is "lib/policy_set_definitions".

.PARAMETER assignmentsRoot
Specifies the subdirectory under rootPath where assignments are stored. Default is "assignments".

.PARAMETER assignmentsPath
Specifies the path where policy assignments are stored, relative to assignmentsRoot. Default is "lib/policy_assignments".

.PARAMETER policyDefintionsTxtFileName
Specifies the filename for policy definitions output. Default is "_policyDefinitionsBicepInput.txt".

.PARAMETER defintionsSetTxtFileName
Specifies the filename for policy set definitions output. Default is "_policySetDefinitionsBicepInput.txt".

.PARAMETER assignmentsTxtFileName
Specifies the filename for policy assignments output. Default is "_policyAssignmentsBicepInput.txt".

#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification = "False Positive")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseBOMForUnicodeEncodedFile", "", Justification = "False Positive")]

[CmdletBinding(SupportsShouldProcess)]
param (
  [Parameter()]
  [string]
  $rootPath = "../src",
  [string]
  $lineEnding = "unix",

  [string]
  $policyDefinitionsPath = "/lib/policy_definitions",
  [string]
  $policySetDefinitionsPath = "/lib/policy_set_definitions",
  [string]
  $roleDefinitionsPath = "/lib/role_definitions",

  [string]
  $policyDefinitionsLongPath = "$policyDefinitionsPath",
  [string]
  $policySetDefinitionsLongPath = "$policySetDefinitionsPath",
  [string]
  $roleDefinitionsLongPath = "$roleDefinitionsPath",


  [string]
  $policyDefinitionsTxtFileName = "_policyDefinitionsBicepInput.txt",
  [string]
  $policySetDefinitionsTxtFileName = "_policySetDefinitionsBicepInput.txt",
  [string]
  $roleDefinitionsTxtFileName = "_roleDefinitionsBicepInput.txt"
)

# This script relies on a custom set of classes and functions
# defined within the [ALZ-PowerShell-Module](https://github.com/Azure/Alz-powershell-module).
if (-not (Get-Module -ListAvailable -Name ALZ)) {
  # Module doesn't exist, so install it
  Write-Information "====> ALZ module isn't already installed. Installing..." -InformationAction Continue
  Install-Module -Name ALZ -Force -Scope CurrentUser -ErrorAction Stop
  Write-Information "====> ALZ module now installed." -InformationAction Continue
}
else {
  Write-Information "====> ALZ module is already installed." -InformationAction Continue
}

# Line Endings function to be used in three functions below
function Update-FileLineEndingType {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [string]
    $filePath
  )

  if (Get-Command -Name Edit-LineEnding -ErrorAction SilentlyContinue) {
    (Get-Content $filePath | Edit-LineEnding -LineEnding $LineEnding) | Out-File $filePath
  }
  else {
    Write-Information "Edit-LineEnding command not found. Skipping line ending update." -InformationAction Continue
    Get-Content $filePath | Out-File $filePath
  }
}

#region Policy Definitions
function New-PolicyDefinitionsBicepInputTxtFile {
  [CmdletBinding(SupportsShouldProcess)]
  param()

  Write-Information "====> Creating/Emptying '$policyDefinitionsTxtFileName'" -InformationAction Continue
  Set-Content -Path "$rootPath/$policyDefinitionsLongPath/$policyDefinitionsTxtFileName" -Value $null -Encoding "utf8"

  Write-Information "====> Looping Through Policy Definitions:" -InformationAction Continue
  Get-ChildItem -Recurse -Path "$rootPath/$policyDefinitionsLongPath" -Filter "*.json" | ForEach-Object {
    $policyDef = Get-Content $_.FullName | ConvertFrom-Json -Depth 100

    $policyDefinitionName = $policyDef.name
    $fileName = $_.Name

    Write-Information "==> Adding '$policyDefinitionName' to '$PWD/$policyDefinitionsTxtFileName'" -InformationAction Continue
    Add-Content -Path "$rootPath/$policyDefinitionsLongPath/$policyDefinitionsTxtFileName" -Encoding "utf8" -Value "`tloadJsonContent('..$policyDefinitionsPath/$fileName')"
  }

  Write-Information "====> Running '$policyDefinitionsTxtFileName' through Line Endings" -InformationAction Continue
  Update-FileLineEndingType -filePath "$rootPath/$policyDefinitionsLongPath/$policyDefinitionsTxtFileName"

  $policyDefCount = Get-ChildItem -Recurse -Path "$rootPath/$policyDefinitionsLongPath" -Filter "*.json" | Measure-Object
  $policyDefCountString = $policyDefCount.Count
  Write-Information "====> Policy Definitions Total: $policyDefCountString" -InformationAction Continue
}
#endregion

#region Policy Set Definitions
function New-PolicySetDefinitionsBicepInputTxtFile {
  [CmdletBinding(SupportsShouldProcess)]
  param()

  Write-Information "====> Creating/Emptying '$policySetDefinitionsTxtFileName'" -InformationAction Continue
  Set-Content -Path "$rootPath/$policySetDefinitionsLongPath/$policySetDefinitionsTxtFileName" -Value $null -Encoding "utf8"

  Write-Information "====> Looping Through Policy Set/Initiative Definition:" -InformationAction Continue
  Get-ChildItem -Recurse -Path "$rootPath/$policySetDefinitionsLongPath" -Filter "*.json" | ForEach-Object {
    $policySetDef = Get-Content $_.FullName | ConvertFrom-Json -Depth 100

    $policySetDefinitionName = $policySetDef.name
    $fileName = $_.Name

    Write-Information "==> Adding '$policySetDefinitionName' to '$PWD/$policySetDefinitionsTxtFileName'" -InformationAction Continue
    Add-Content -Path "$rootPath/$policySetDefinitionsLongPath/$policySetDefinitionsTxtFileName" -Encoding "utf8" -Value "`tloadJsonContent('..$policySetDefinitionsPath/$fileName')"
  }

  Write-Information "====> Running '$policySetDefinitionsTxtFileName' through Line Endings" -InformationAction Continue
  Update-FileLineEndingType -filePath "$rootPath/$policySetDefinitionsLongPath/$policySetDefinitionsTxtFileName"

  $policySetDefCount = Get-ChildItem -Recurse -Path "$rootPath/$policySetDefinitionsLongPath" -Filter "*.json" | Measure-Object
  $policySetDefCountString = $policySetDefCount.Count
  Write-Information "====> Policy SetDefinitions Total: $policySetDefCountString" -InformationAction Continue
}
#endregion

#region Role Definitions
function New-RoleDefinitionsBicepInputTxtFile {
  [CmdletBinding(SupportsShouldProcess)]
  param()

  Write-Information "====> Creating/Emptying '$roleDefinitionsTxtFileName'" -InformationAction Continue
  Set-Content -Path "$rootPath/$roleDefinitionsLongPath/$roleDefinitionsTxtFileName" -Value $null -Encoding "utf8"

  Write-Information "====> Looping Through Role Definitions:" -InformationAction Continue
  Get-ChildItem -Recurse -Path "$rootPath/$roleDefinitionsLongPath" -Filter "*.json" | ForEach-Object {
    $roleDef = Get-Content $_.FullName | ConvertFrom-Json -Depth 100

    $roleDefinitionName = $roleDef.name
    $fileName = $_.Name

    Write-Information "==> Adding '$roleDefinitionName' to '$PWD/$roleDefinitionsTxtFileName'" -InformationAction Continue
    Add-Content -Path "$rootPath/$roleDefinitionsLongPath/$roleDefinitionsTxtFileName" -Encoding "utf8" -Value "`tloadJsonContent('..$roleDefinitionsPath/$fileName')"
  }

  Write-Information "====> Running '$roleDefinitionsTxtFileName' through Line Endings" -InformationAction Continue
  Update-FileLineEndingType -filePath "$rootPath/$roleDefinitionsLongPath/$roleDefinitionsTxtFileName"

  $roleDefCount = Get-ChildItem -Recurse -Path "$rootPath/$roleDefinitionsLongPath" -Filter "*.json" | Measure-Object
  $roleDefCountString = $roleDefCount.Count
  Write-Information "====> Policy Definitions Total: $roleDefCountString" -InformationAction Continue
}
#endregion

New-PolicyDefinitionsBicepInputTxtFile
New-PolicySetDefinitionsBicepInputTxtFile
New-RoleDefinitionsBicepInputTxtFile
