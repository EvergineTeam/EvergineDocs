# Upgrade My Project to the Latest Evergine Release

## Update from Evergine 2023.9.28 to Evergine 2024.6.28

When upgrading to Evergine 2024.6, a few manual adjustments are required to ensure your previous projects work correctly. The main changes include:

- Modifications to how prefabs are serialized.
- Removal of the 2D API.
- Many engine packages are now compatible only with .NET 8.

If you update your project using the Evergine launcher, you might encounter errors such as:

```
<PATH_TO_OUR_PROJECT>\MyScene.wescene(195,18): error WESC000: Unknown node type, check the visibility of the member. [<PATH_TO_OUR_PROJECT>\MigrateSample.csproj]
```

To resolve this, run the following script:

```powershell
<#
.SYNOPSIS
	Removes deprecated InstancedEntities files.
.DESCRIPTION
	Removes deprecated InstancedEntities files.
#>

param (
	[Parameter(mandatory=$false)]
    [string]$path
)

$confirmation = Read-Host "This script performs the following actions:
- Remove InstancedEntities files.
- Migrate modified properties.
They cannot be undone. Do you want to continue?  [y/n]"
if ($confirmation -ne "y") { exit }

# Remove InstancedEntities files 
Get-Childitem -Path $path -Recurse -Include "InstancedEntities","InstancedEntities.wefile" | Remove-Item -Force

# Replace modified properties
Get-ChildItem -Path $path -Recurse -Include "*.wescene","*.weprefab" | 
ForEach-Object {
    $p = $_.FullName
    $a = Get-Content $p
    $a = $a -replace "keyframes","Keyframes"
    $a = $a -replace "additionalComponentList","AdditionalComponents"
    $a = $a -replace "additionalChildrenList","AdditionalChildren"
    $a = $a -replace "removedComponentList","RemovedComponents"
    $a = $a -replace "modificationList","Modifications"
    $a = $a -replace "entityLinks","EntityLinks"
    Set-Content $a -Path $p
}
```

Additionally, review your csproj files and update the _.NET6_ entries to _.NET8_ for the _TargetFramework_ properties.

```xml
<PropertyGroup>
    <OutputType>Exe</OutputType>
    <!-- 
    Previous Windows project - used by Evergine Studio - was referencing .NET6. Do the same for the rest of your platform-specific start projects.
    <TargetFramework>net6.0-windows</TargetFramework>
    -->
    <TargetFramework>net8.0-windows</TargetFramework>
    <UseWindowsForms>true</UseWindowsForms>
</PropertyGroup>
```

Lastly, depending on the specific version of Evergine 2023.9 you are using, you might need to run the following script to address any _VirtualScreenManager_ errors, as this has been removed.

```powershell
<#
.SYNOPSIS
	Removes VirtualScreenManager entries from scenes. This manager has been removed.
.DESCRIPTION
	Removes VirtualScreenManager entries from scenes. This manager has been removed.
#>

param (
	[Parameter(mandatory=$false)]
    [string]$path
)

if ($path -eq "") {
    $path = "."
}

$numberOfFiles = Get-ChildItem -Path $path -Recurse -Filter '*.wescene' | Measure-Object | %{$_.Count}

Get-ChildItem -Path $path -Recurse -Filter '*.wescene' | 
    ForEach-Object {
        $current++
        Write-Host "($current/$numberOfFiles) Processing file $_.FullName"
        $contents = Get-Content -Raw -Path $_.FullName
        $preLength = $contents.Length
        $contents = $contents -replace "\s+-.*VirtualScreenManager.*\n.*\n.*\n.*\n.*\n.*\n.*", ""
        $postLength = $contents.Length

        if ($preLength -ne $postLength) {
            Set-Content -Path $_.FullName -Value $contents
        }
    }
```

### Additional Changes for UWP Projects

If your solution includes UWP projects, update the Default.rd.xml files to create _Release_ builds and avoid _.NET Native_ compiler errors.

```xml
<Assembly Name="*Application*" Dynamic="Required All" />

<!-- Add line below to make it possible for Release builds -->
<Assembly Name="Vortice.XAudio2" Dynamic="Auto" />
```