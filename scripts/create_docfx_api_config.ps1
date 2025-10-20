<#
.SYNOPSIS
	Docfx config creation for Evergine APIs. (c) Evergine
.DESCRIPTION
	This script generates specific configuration for Docfx to compile Evergine APIs information.
.EXAMPLE
	.\<script_name> -evergineFolder "../Engine"
.LINK
	https://evergine.com
#>

param
(
	[Parameter(Mandatory=$true, HelpMessage="The Evergine folder path")][string]$evergineFolder = $null
)

# Config variables
$csproj_sources = "src/Engine|src/Extensions|src/Runtimes|src/Tools/Evergine.HLSLEverywhere"
$csproj_excludes = "macos"  # format a|b|c..
$metadataConfigFile = "docfx_api_template.json"
$buildFolder = "build"
$configFile = "docfx-api.json"

# Add common configuration and functions
. "$PSScriptRoot/ps_support.ps1"

# Set root as working directory
$currentDir = (Get-Location).Path
Push-Location $currentDir
Set-Location $PSScriptRoot/..

$isEngineAvailable = Test-Path -Path $evergineFolder
if (-Not $isEngineAvailable)
{
	LogError "Evergine folder not found. No API config has been generated."
	Pop-Location
	exit 1
}

# Get all csproj file paths that are inside src folder
$absoluteEngineFolder = Resolve-Path $evergineFolder
$csprojFiles = Get-ChildItem -Path $absoluteEngineFolder -Filter "*.csproj" -Recurse

$csprojPaths = @()
foreach ($csproj in $csprojFiles)
{
	$csprojPath = (Resolve-Path -Relative -Path $csproj -RelativeBasePath $absoluteEngineFolder).Replace("\", "/").Replace("./", "")
	# if csproj name contains the filter, discard
	if (($csprojPath -match $csproj_sources) -and (-not ($csproj.Name -match $csproj_excludes)))
	{
		$csprojPaths += @($csprojPath)
	}
}

# Build docfx API config file

# load template metadata & update with the new csproj files
$metadata = Get-Content $metadataConfigFile -Raw | ConvertFrom-Json
$metadata.metadata[0].src[0].files = $csprojPaths

# update metadata with the new src folder
$metadata.metadata[0].src[0].src = (Resolve-Path -Relative -Path $absoluteEngineFolder -RelativeBasePath $buildFolder).Replace("\", "/")

# write the new metadata to a new file
$metadataFile = Join-Path $buildFolder $configFile
$metadata | ConvertTo-Json -Depth 5 | Set-Content $metadataFile

Pop-Location
