# Packages

Packages are Evergine extensions that add specific functionalities and assets to your project.

When a package is added, its assets (textures, sounds, meshes, etc.), source code (components, behaviors, services, etc.) and its nuget dependencies are automatically added for you, so you can start using them.

## Packages in Evergine Studio

To check wich packages are installed in your application, you just need to take a look to the Project Explorer tab in Evergine Studio, and inspect the Dependencies section:

![packages on evergine studio](Images/mrtk_package.png)

## Supported packages

Evergine comes gives the possibility to extend your applications using different packages

### Evergine Core

**Evergine.Core** is the most important package in Evergine, and it is registered into your application by default. It gives your application all default [Effects](../graphics/effects/builtin_effects.md), [Materials](../graphics/materials/index.md), [Textures](../graphics/textures/index.md), [PostProcessingGraph](../graphics/postprocessing_graph/index.md) and core functionality to start developing your project.

![Evergine.Core package](Images/evergine_core.png)

#### Evergine.Core Package information
* Id: **Evergine.Core**
* Latest Version: *This package is installed with the same version as used in your Evergine application*
* NuGet Dependencies:
  * **Evergine.Framework**

### Mixed Reality Toolkit

[**Evergine.MRTK**](https://github.com/EvergineTeam/MixedRealityToolkit) is a package that provides a set of components and features used to accelerate cross-platform XR application development in Evergine.
Evergine.MRTK provides a set of basic building blocks for Evergine development on XR platforms such as:
* Microsoft HoloLens 2
* Windows Mixed Reality hreadsets
* OpenVR headsets (Oculus, HTC Vive, etc..)

![Evergine.MRTK](Images/MRTK_Examples.png)

#### Evergine.MRTK Package information
* Id: **Evergine.MRTK.Assets**
* Latest Version: **2021.11.4.5-nightly**
* NuGet Dependencies:
  * **Evergine.Framework**
  * **Evergine.MRTK**

### Upcoming packages

Evergine is on continuous development, and more upcoming packages are coming:

| Package | Description | 
| --- | --- |
| **Azure Remote Rendering** | This package provides integration of Evergine with [Azure Remote Rendering](https://azure.microsoft.com/es-es/services/remote-rendering/), allowing to render on cloud complex industrial scenes and reproduce on portable devices or HoloLens. |
| **Noesis GUI** | Using [NoesisGUI](https://www.noesisengine.com/) with Evergine allows you to create appealing User Interfaces using powerful XAML tools like Microsoft Expression Blend. |
| **CAD Formats** | Take your industrial CAD/3D model and bring it into your Evergine application. |
| **Bing Maps** | Provides [Bing Maps](https://www.bingmapsportal.com/) integration with Evergine, that allows you to utilize Bing Maps 3D mapping data in your application. |

## Add a new package

Unfortunately, there is no way right now from Evergine Studio to automatically search and install an extension in a project. For now, a slightly more manual steps must be done:

1. Check each package documentation for its Id, version and nuget dependencies.
1. Add it manually to the `weproj` file at your project root, under the Packages yaml list.

```yaml
Packages:
  - Id: Evergine.Core
    Version: ...
  - Id: [PACKAGE ID]
    Version: [VERSION ACCORDING TO YOUR EVERGINE VERSION]
```

For example:

```yaml
- Id: Evergine.MRTK.Assets
  Version: 2021.9.29.2-nightly
```

3. Finally, add the nuget dependencies to your root project, the one that contains the `EvergineContent.cs` file.

## Customize assets

By default, all assets included in a package cannot be modified. This is indicated by this lock icon: ![lock icon](Images/locked_icon.png).

However, you can modify an asset included in the package. When you modify a package asset, and try to save it, the following message apperas, indicating if you want to create a new copy of this asset in your project:

![confirm](Images/package_locked_save.png)


Automatically a new copy of the asset will be created on your local folder project, overwriting the one provided by the package. By doing this allows you to modify or adapt Evergine core assets to your application requirements

![Asset customization](Images/asset_edit.png)
