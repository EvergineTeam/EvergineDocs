<#
.SYNOPSIS
	Evergine Docs generation script. (c) Evergine
.DESCRIPTION
	This script generates the Evergine Documentation. If no evergineFolder is provided, API documentation will not be generated.
.EXAMPLE
	.\<script_name> [-evergineFolder "../Engine"]
.LINK
	https://evergine.com
#>

param
(
	[Parameter(HelpMessage="The Evergine folder path")][string]$evergineFolder = $null
)

# Config variables
$configFile = "docfx.json"

# Add common configuration and functions
. "$PSScriptRoot/ps_support.ps1"

# Set root as working directory
$currentDir = (Get-Location).Path
Push-Location $currentDir
Set-Location $PSScriptRoot/..

# Generate API documentation if available
$isAPIAvailable = Test-Path -Path $evergineFolder
if ($isAPIAvailable)
{
    # First, generate the API configuration
    . "./create_docfx_api_config.ps1" -evergineFolder $evergineFolder

    # Then, delete the API yaml files (folder build/api), except .gitignore file
    $apiFolder = "build/api"
    Get-ChildItem -Path $apiFolder -Recurse -Exclude ".gitignore" | Remove-Item -Force

    # Finally, build the API documentation for all target frameworks
    . "./build_api.ps1 -targetFramework net8.0"
    . "./build_api.ps1 -targetFramework net8.0-windows"
    . "./build_api.ps1 -targetFramework net8.0-android"
    . "./build_api.ps1 -targetFramework net8.0-ios"
}
else
{
    LogWarning "Evergine folder not found. No API documentation will be generated."
}

# Generate the Evergine documentation
LogInfo "START Building the documentation with DocFX for Evergine ..."

$docfx = InstallDocFX

Invoke-Expression "$docfx build $configFile"

LogInfo "END Building the documentation with DocFX for Evergine."

Pop-Location
