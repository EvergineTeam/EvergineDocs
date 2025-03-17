# Update from Evergine 2024.6.28 to Evergine 2024.10.24

Since Evergine 2024.6.28, there are some changes that should be applied to already existing projects that want to be upgraded to this version. 

## Steps to migrate to the new version:
- Apply the changes outlined in this article (a script is provided to simplify the process).
- Update your Evergine version using Evergine Studio.

## List of changes

- Update to net8.0:
  - Projects should update their target framework from netstandard2.0 to net8.0 to align with the newer framework version for improved functionality and compatibility.
- Removal of Evergine.Platform project
  - The PackageReference for Evergine.Platform must be deleted, namespaces updated, and the linker.xml file for Android needs to be adjusted accordingly.
- Renaming of Evergine.AndroidView and Evergine.iOSView
  - Update csproj files and code to replace Evergine.AndroidView and Evergine.iOSView with Evergine.Android and Evergine.iOS.
- WinUI Target Platform Version and dependency updates
  - The WinUI project files should be updated to the latest TargetPlatformVersion and dependencies like Microsoft.WindowsAppSDK and Microsoft.Windows.SDK.BuildTools.
- Renaming of MouseSensibility and TouchSensibility
  - Update scene and prefab files to reflect the new naming conventions: MouseSensitivity and TouchSensitivity.
- End of UWP platform support
  - UWP platform is no longer supported, the project files can be removed and the profile from weproj and assets files removed.

To automate these updates, we've provided a script that will carry out the necessary changes for you. You can download and run the script using the link below:

> ⚠️ **Important** ⚠️ 
This script modifies the files in your project directly. We highly recommend using a version control system like Git to track and review the changes made. Ensure you have your project committed or backed up before running the script, so you can easily verify or revert any modifications if necessary.

https://github.com/EvergineTeam/EvergineDocs/tree/master/src/manual/get_started/migrations/migration-2024.10.24.ps1

Simply run the script in your project directory, and it will apply all the changes mentioned above, including framework updates, namespace adjustments, and removal of unsupported platforms.
