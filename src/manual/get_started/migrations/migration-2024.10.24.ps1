
$confirmation = Read-Host "This script performs the following actions:
- Update TargetFramework: Changes netstandard2.0 to net8.0 in .csproj files.
- Update using statements and updated code: Adjusts namespaces in .cs files and update breaking changes in code.
- Update WinUI project files: Changes TargetPlatformVersion and Microsoft.WindowsAppSDK and Microsoft.Windows.SDK.BuildTools versions.
- Modify linker.xml: Replaces Evergine.Platform with Evergine.Common references.
- Update csproj PackageReference: Remove Evergine.Platform PackageReference and rename Android and iOS packages.
- Delete UWP files: Removes UWP solutions and related folders.
- Update sensitivity properties: Changes MouseSensibility and TouchSensibility to MouseSensitivity and TouchSensitivity.
- Remove Platform: UWP nodes: Deletes UWP platform nodes in project and asset files.
They cannot be undone. Do you want to continue?  [y/n]"
if ($confirmation -ne "y") { exit }

# Change TargetFramework in .csproj files
Get-ChildItem -Recurse -Filter *.csproj | ForEach-Object {
    $newContent = (Get-Content -Raw $_.FullName) -replace '<TargetFramework>netstandard2.0</TargetFramework>', '<TargetFramework>net8.0</TargetFramework>'
    [io.file]::WriteAllText($_.FullName, $newContent)
}

# Remove Evergine.Platform "PackageReference" and rename Android and iOS packages
Get-ChildItem -Recurse -Filter *.csproj | ForEach-Object {
    $content = Get-Content -Raw $_.FullName
    $newContent = $content -replace '(?ms)<PackageReference Include="Evergine.Platform" Version="[\w\d\.-]+" \/>\s*', ''
    $newContent = $content -replace 'Include="Evergine.AndroidView"', 'Include="Evergine.Android"'
    $newContent = $content -replace 'Include="Evergine.iOSView"', 'Include="Evergine.iOS"'
    [io.file]::WriteAllText($_.FullName, $newContent)
}

# Change using statements and code in .cs files
Get-ChildItem -Recurse -Filter *.cs | ForEach-Object {
    $newContent = (Get-Content -Raw $_.FullName) -replace 'using Evergine.AndroidView;', 'using Evergine.Android;' |
    ForEach-Object { $_ -replace 'using Evergine.IOSView;', 'using Evergine.iOS;' } | 
    ForEach-Object { $_ -replace 'using Evergine.Platform;', 'using Evergine.Common.IO;' } | 
    ForEach-Object { $_ -replace 'Win32API.GetConsoleWindow();', 'Evergine.Forms.Win32Native.GetConsoleWindow();' } | 
    ForEach-Object { $_ -replace 'Win32API.ShowWindow(handle, 0); ', 'Evergine.Forms.Win32Native.ShowWindow(handle, false);' }
    [io.file]::WriteAllText($_.FullName, $newContent)
}

# Update WinUI project files
Get-ChildItem -Recurse -Filter *.wapproj | ForEach-Object {
    $newContent = (Get-Content -Raw $_.FullName) -replace '<TargetPlatformVersion>10.0.19041.0</TargetPlatformVersion>', '<TargetPlatformVersion>10.0.22621.0</TargetPlatformVersion>' |
    ForEach-Object { $_ -replace '<PackageReference Include="Microsoft.WindowsAppSDK" Version="\[1.4.230822000\]">', '<PackageReference Include="Microsoft.WindowsAppSDK" Version="1.5.240627000">' } | 
    ForEach-Object { $_ -replace '<PackageReference Include="Microsoft.Windows.SDK.BuildTools" Version="\[10.0.22621.756\]">', '<PackageReference Include="Microsoft.Windows.SDK.BuildTools" Version="10.0.26100.1">' }
    [io.file]::WriteAllText($_.FullName, $newContent)
}
Get-ChildItem -Recurse -Filter *.WinUI.csproj | ForEach-Object {
    $newContent = (Get-Content -Raw $_.FullName) -replace '<PackageReference Include="Microsoft.WindowsAppSDK" Version="1.4.230822000" />', '<PackageReference Include="Microsoft.WindowsAppSDK" Version="1.5.240627000" />' |
    ForEach-Object { $_ -replace '<PackageReference Include="Microsoft.Windows.SDK.BuildTools" Version="10.0.22621.756" />', '<PackageReference Include="Microsoft.Windows.SDK.BuildTools" Version="10.0.26100.1" />' }
    [io.file]::WriteAllText($_.FullName, $newContent)
}

# Change in linker.xml
$linkerFile = Get-ChildItem -Recurse -Filter linker.xml
if ($linkerFile) {
    $newContent = (Get-Content -Raw $linkerFile.FullName) -replace '(?ms)<assembly fullname="Evergine.Platform">\s*<type fullname="Evergine.Platform.AssetsDirectory" \/>\s*<\/assembly>', '<assembly fullname="Evergine.Common">
    <type fullname="Evergine.Common.IO.AssetsDirectory" />
  </assembly>'
    [io.file]::WriteAllText($linkerFile.FullName, $newContent)
}

# Change MouseSensibility and TouchSensibility in .wescene and .weprefab files
Get-ChildItem -Recurse -Include *.wescene, *.weprefab | ForEach-Object {
    $newContent = (Get-Content -Raw $_.FullName) -replace 'MouseSensibility', 'MouseSensitivity' |
    ForEach-Object { $_ -replace 'TouchSensibility', 'TouchSensitivity' }
    [io.file]::WriteAllText($_.FullName, $newContent)
}

# Delete UWP folders and files
Get-ChildItem -Recurse -Filter *.sln | ForEach-Object {
    if ($_ -match "(.*\.UWP)\.sln") {
        $uwpFolder = $Matches[1]
        if (Test-Path $uwpFolder) {
            Remove-Item -Recurse -Force $uwpFolder
        }
        Remove-Item -Force $_.FullName
    }
}

# Process .weproj files and assets, and remove "Platform" nodes with value "UWP"
Get-ChildItem -Recurse -Include *.weproj, *.wesn, *.wetx, *.wemd, *.wefx, *.wemt, *.wesp, *.werl, *.wesc, *.wefile, *.wedir, *.wepp, *.weps, *.weprf, *.weft | ForEach-Object {
    # Read all lines from the file
    $lines = Get-Content $_.FullName

    # Variable to store the filtered lines
    $filteredLines = $lines

    # Loop to search for multiple occurrences of "Platform: UWP"
    $changesMade = $true
    while ($changesMade) {
        $changesMade = $false
        $uwpIndex = -1
        $spaceCount = 0

        # Search for the line that contains "Platform: UWP"
        for ($i = 0; $i -lt $filteredLines.Length; $i++) {
            if ($filteredLines[$i] -match "Platform: UWP") {
                # Save the index of the found line
                $uwpIndex = $i
                # Count the number of leading spaces in that line
                $spaceCount = ($filteredLines[$i] -replace "\S.*", "").Length
                break
            }
        }

        # If the line with "Platform: UWP" is found
        if ($uwpIndex -ne -1) {
            # Create a new list to store the lines we want to keep
            $newList = @()
            $parentNodeIndex = -1
            $nextNodeIndex = -1

            # Search for the parent node of "Platform: UWP"
            for ($i = 0; $i -lt $filteredLines.Length; $i++) {
                $previousSpaces = ($filteredLines[$i] -replace "\S.*", "").Length
                # If the line starts with spaces followed by a dash, it's a node
                if ($filteredLines[$i] -match "^\s+-") {
                    # If the number of spaces equals that of the "Platform: UWP" line minus 2 (- ), it's the parent node
                    if ($previousSpaces -eq ($spaceCount - 2)) {
                        if ($parentNodeIndex -ne -1 -and $i -gt $uwpIndex) {
                            $nextNodeIndex = $i
                            break
                        }
                        $parentNodeIndex = $i
                    }
                }
            }

            # Add lines excluding from the parent node to the next node
            for ($i = 0; $i -lt $filteredLines.Length; $i++) {
                if ($i -lt $parentNodeIndex -or $i -ge $nextNodeIndex) {
                    $newList += $filteredLines[$i]
                }
            }

            # Update the filtered lines list
            $filteredLines = $newList
        }
    }

    if ($uwpIndex -ne -1) {
        # Save the filtered lines back to the original file
        $filteredLines | Set-Content $_.FullName
    }
}
