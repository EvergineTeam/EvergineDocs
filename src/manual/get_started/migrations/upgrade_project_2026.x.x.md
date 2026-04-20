# Update from Evergine 2025.10.21 to Evergine 2026.x.x

This guide describes the steps required to update your existing Evergine projects to the latest version.  
There are no major breaking changes in this release, and only a few manual updates are needed.

---

## ⚠️ Breaking Changes: Up to .NET 10
As of this release, Evergine now requires .NET 10. This means that all your project files need to be updated to target .NET 10 instead of previous versions.

```xml
<PropertyGroup>
    <OutputType>Exe</OutputType>
    <!-- 
    Previous Windows project - used by Evergine Studio - was referencing .NET8. Do the same for the rest of your platform-specific start projects.
    <TargetFramework>net8.0-windows</TargetFramework>
    -->
    <TargetFramework>net10.0-windows</TargetFramework>
    <UseWindowsForms>true</UseWindowsForms>
</PropertyGroup>
```