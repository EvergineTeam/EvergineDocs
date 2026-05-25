# Getting Started

---

Follow these steps to begin working with Evergine.Cesium:

## Project Setup

### 1. Create a New Project

Use [Evergine Launcher](../../evergine_launcher/create_project.md) to start a new project. Along with Windows, select an additional template for your target device.

> [!NOTE]
> This addon doesn't support Web platforms. Please, select a different platform to test and use the addon.

### 2. Add the Evergine.Cesium Add-on

Open Evergine Studio and add the Evergine.Cesium add-on to your project. Refer to [this guide](../../addons/index.md) for instructions on adding add-ons.

![Add-on installation](./images/addon_installation.png)

> [!NOTE]
> Evergine.Cesium add-on is available as NuGet packages. For nightly builds, update `nuget.config` to include the Evergine nightly feed:
> 
> ```xml
> <?xml version="1.0" encoding="utf-8"?>
> <configuration>
>  <packageSources>
>    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" />
>    <add key="Evergine Nightly" value="https://pkgs.dev.azure.com/plainconcepts/Evergine.Nightly/_packaging/Evergine.NightlyBuilds/nuget/v3/index.json" />
>  </packageSources>
> </configuration>
> ```

### 3. Setup the CesiumCoordinator

#### Register CesiumCoordinator during `Application` construction

```csharp
using Evergine.Cesium;
using Evergine.Framework;

public class MyScene : Scene
{
    public override void RegisterManagers()
    {
        base.RegisterManagers();

        var cesium = new CesiumCoordinator
        {
            AccessToken = "<CESIUM_ION_TOKEN>",
            AzureMapsKey = "<OPTIONAL_AZURE_MAPS_KEY>",
            EntityManager = this.Managers.EntityManager,
            OverlayProvider = TerrainOverlayProvider.BingAerial,
        };

        this.Managers.AddManager(cesium);

        // Optional startup move
        // cesium.FlyTo(40.4168, -3.7038, 3.0);
    }
}
```

> Make sure your scene has an entity tagged MainCamera with a Camera3D component attached to it.

### Core runtime API

- Initialize and status:
  - CurrentStatus gives loader state and connectivity/auth results.
  - IsInitialized indicates successful startup.
- Camera/navigation:
  - FlyTo(latitude, longitude, seconds)
  - WorldCamera exposes current geospatial camera state.
- Terrain:
  - QueryTerrainMinHeight(latitude, longitude, callback)
- Geocoding (requires Azure key):
  - GeocodeAsync(query)
  - ReverseGeocodeAsync(latitude, longitude)
  - AutocompleteAsync(query, maxResults)
- Monitoring:
  - Diagnostics exposes tile/queue counters
  - UnmanagedDiagnostics exposes native allocation/free counters

### Placing entities on Earth

Attach CesiumPlacerComponent to any entity and configure:

- Latitude
- Longitude
- Height
- HeightIsRelativeToTerrain
- Rotation

The component converts geodetic coordinates to world coordinates each update and aligns orientation to local up.

## FAQ

**Q: Can I change Overlay in runtime?**

Yes, you can change OverlayProvider at runtime. Terrain tiles are reset and reloaded with the new imagery.

**Q: Do I have to manage tiles and overlays memory?**
No, it is automatically manage by the addon.
