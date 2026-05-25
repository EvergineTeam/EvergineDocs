<#
.SYNOPSIS
	Evergine API Docs generation script. (c) Evergine
.DESCRIPTION
	This script generates the Evergine API Documentation for the current Evergine target framework.
	It uses DocFX.
.EXAMPLE
	.\<script_name>
.LINK
	https://evergine.com
#>

# Config variables
$buildFolder = "build"
$configFile = "docfx-api.json"
$apiFolder = "build/api"

# Add common configuration and functions
. "$PSScriptRoot/ps_support.ps1"

# Set root as working directory
$currentDir = (Get-Location).Path
Push-Location $currentDir
Set-Location $PSScriptRoot/..

$docfx = GetDocFX

# Clean API yaml files, except .gitignore
Get-ChildItem -Path $apiFolder -Recurse -Exclude ".gitignore" | Remove-Item -Force

# Get json config file
$configFile = Resolve-Path (Join-Path $buildFolder $configFile)

LogInfo "START Building the sources API with DocFX ..."

$cmd = "$(Resolve-Path (Join-Path $toolsFolder docfx.exe))"
Invoke-Expression "$docfx metadata $configFile"

LogInfo "END Building the sources API with DocFX."

Pop-Location
