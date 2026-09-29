# Upgrade My Project to the Latest Evergine Release

Each Evergine release brings new features, performance work and bug fixes. Most releases update with a few clicks in the Evergine Launcher. Some also change project files or APIs, and those have a migration guide in this section with the exact steps.

## Before you upgrade

- **Back up your project.** Commit it to a version control system such as Git, or copy the folder. Upgrading changes package versions, project files and sometimes assets.
- **Read the guides for every version you skip.** If you jump across several releases, apply the migration steps of each intermediate release in order, oldest first. Skipping one can leave the project with errors that the later guides do not cover.

## General upgrade steps

1. Install the new Evergine version from the **Evergine Launcher**. See [Manage Evergine Versions](../../evergine_launcher/manage_versions.md).
2. In the Launcher project list, find your project and select the new version in its version selector.
3. Click **Update**. The Launcher analyzes the project and lists the packages it will update.
4. Review the package list and accept the changes.
5. Open the project in Evergine Studio and in Visual Studio, rebuild it, and fix any compilation errors with the help of the migration guide for that version.

## Migration guides

| Guide | Main changes |
| --- | --- |
| [2026.5.26 to 2026.10](upgrade_project_2026.10.md) | DirectX 12 as the default backend, Vulkan query results, timestamp query capability. |
| [2025.10.21 to 2026.5.26](upgrade_project_2026.5.26.md) | .NET 10, Reverse-Z depth, `TextureDescription.Faces` removed. Migration script provided. |
| [2025.3.18 to 2025.10.21](upgrade_project_2025.10.21.md) | sRGB textures and framebuffers, web template updates. Migration script provided. |
| [2024.10.24 to 2025.3.18](upgrade_project_2025.3.18.md) | `RenderManager` binding, HLSL 2021. |
| [2024.6.28 to 2024.10.24](upgrade_project_2024.10.24.md) | .NET 8, package renames, end of UWP. Migration script provided. |
| [2023.9.28 to 2024.6.28](upgrade_project_2024.6.28.md) | Prefab serialization, removal of the 2D API. |

## In this section

* [Update from Evergine 2026.5.26 to Evergine 2026.10](upgrade_project_2026.10.md)
* [Update from Evergine 2025.10.21 to Evergine 2026.5.26](upgrade_project_2026.5.26.md)
* [Update from Evergine 2025.3.18 to Evergine 2025.10.21](upgrade_project_2025.10.21.md)
* [Update from Evergine 2024.10.24 to Evergine 2025.3.18](upgrade_project_2025.3.18.md)
* [Update from Evergine 2024.6.28 to Evergine 2024.10.24](upgrade_project_2024.10.24.md)
* [Update from Evergine 2023.9.28 to Evergine 2024.6.28](upgrade_project_2024.6.28.md)
