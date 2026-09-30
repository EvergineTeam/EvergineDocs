# Getting started with Cesium

---

![Add-on installation](images/addon_installation.png)

This page adds Cesium to a project and streams terrain and buildings into a scene. Everything goes through `CesiumCoordinator`, a scene manager that connects to Cesium ion, streams the tilesets you configure, drives the camera, and places your entities on the globe.

## Project setup

### 1. Create a project

Create a project with [Evergine Launcher](../../evergine_launcher/create_project.md) with a **Windows** profile.

> [!NOTE]
> Evergine Cesium does not support Web platforms (WebGL and WebGPU).

### 2. Install the add-on

In Evergine Studio, open the [Add-ons Manager](../index.md#add-ons-manager) and install **Evergine.Cesium**.

> [!NOTE]
> The add-on references NuGet packages. To use nightly builds, add the Evergine nightly feed to your `nuget.config`:
>
> ```xml
> <?xml version="1.0" encoding="utf-8"?>
> <configuration>
>   <packageSources>
>     <add key="nuget.org" value="https://api.nuget.org/v3/index.json" />
>     <add key="Evergine Nightly" value="https://pkgs.dev.azure.com/plainconcepts/Evergine.Nightly/_packaging/Evergine.NightlyBuilds/nuget/v3/index.json" />
>   </packageSources>
> </configuration>
> ```

### 3. Register the CesiumCoordinator

Create the coordinator in your scene's `RegisterManagers`, add the tilesets to stream, and register it. The tilesets must be added before the coordinator starts, because it creates their streams when the scene starts.

```csharp
using Evergine.Cesium;
using Evergine.Cesium.Utils;
using Evergine.Framework;

public class MyScene : Scene
{
    public override void RegisterManagers()
    {
        base.RegisterManagers();

        var cesium = new CesiumCoordinator
        {
            // Read the token from your configuration; do not commit it to source control.
            AccessToken = "<CESIUM_ION_TOKEN>",

            // Optional: enables GeocodeAsync, ReverseGeocodeAsync and AutocompleteAsync.
            GeocodingService = new AzureMapsGeocodingService("<AZURE_MAPS_KEY>"),
        };

        // Cesium World Terrain (asset 1) with Bing aerial imagery.
        cesium.AddOverlayedTileset(1, RasterOverlayProvider.BingAerial, "Terrain");

        // Cesium OSM Buildings (asset 96188), geometry only.
        cesium.AddGeometryTileset(96188, "Buildings");

        this.Managers.AddManager(cesium);
    }
}
```

When the scene starts, the coordinator checks the internet connection and the token, finds the active camera, adds a `WorldCamera` component to it if it has none, and creates a `CesiumRoot` entity that holds the tiles.

> [!IMPORTANT]
> The scene must have an active camera with a `Camera3D` component. The token needs the `assets:read` scope.

## CesiumCoordinator

Find the coordinator from any component or manager with `this.Managers.FindManager<CesiumCoordinator>()`.

### Configuration and status

| Member | Default | Description |
| --- | --- | --- |
| `AccessToken` | `""` | Cesium ion access token. It can only be set when the coordinator is created. |
| `GeocodingService` | `null` | Service used for geocoding: `AzureMapsGeocodingService`, `GoogleMapsGeocodingService`, or your own `IGeocodingService`. |
| `OverlayProvider` | `RasterOverlayProvider.BingAerial` | Imagery of the overlayed tilesets. Changing it reloads their imagery. |
| `CurrentStatus` | `Status.Uninitialized` | Read-only. Connection state: `Ready`, `ReadyWithErrors`, `NoInternetConnection`, `CantReachEndpoint`, `CantAuthenticate`, `MissingTokenPermissions`, and others. |
| `IsInitialized` | `false` | Read-only. `true` when `CurrentStatus` is `Ready` or `ReadyWithErrors`. |
| `IsGeocodingConfigured` | `false` | Read-only. `true` when `GeocodingService` is set. |
| `WorldCamera` | | Read-only. The `WorldCamera` component of the active camera. |
| `Camera` | | Read-only. The `Camera3D` the coordinator drives. |
| `Root` | | Read-only. The `CesiumRoot` entity that contains the tiles. |
| `FetcherNames` | | Read-only. Names of the tilesets that are streaming. |

### Tilesets

| Method | Description |
| --- | --- |
| `AddOverlayedTileset(int assetId, RasterOverlayProvider overlayProvider, string name = "Overlayed")` | Adds a Cesium ion tileset, usually terrain, drawn with an imagery overlay. |
| `AddGeometryTileset(int assetId, string name = "Geometry")` | Adds a tileset that is drawn with its own materials, such as 3D buildings. |
| `RemoveTileset(string name)` | Removes a configured tileset by name. |

These methods configure the tilesets that the coordinator creates when it initializes, so call them before the scene starts.

`RasterOverlayProvider` values: `BingAerial`, `BingAerialWithLabels`, `BingRoads`, `GoogleMapsSatellite`, `GoogleMapsSatelliteWithLabels`, `GoogleMapsRoads`, `GoogleMapsLabelsOnly`, and `GoogleMapsContours`.

### Camera and terrain

| Method | Description |
| --- | --- |
| `FlyTo(double latitude, double longitude, double seconds)` | Animates the camera to a latitude and longitude, in degrees, over the given time. |
| `QueryTerrainMinHeight(double latitude, double longitude, Action<double?> callback)` | Samples the terrain height at a latitude and longitude, in degrees, and calls the callback with the result, or `null` if it is not available yet. |

`FlyTo` needs the `WorldCamera`, which exists once the coordinator is initialized. For example, from a component:

```csharp
using System;
using Evergine.Cesium;
using Evergine.Framework;

public class FlyToMadrid : Behavior
{
    private bool done;

    protected override void Update(TimeSpan gameTime)
    {
        var cesium = this.Managers.FindManager<CesiumCoordinator>();
        if (!this.done && cesium?.IsInitialized == true)
        {
            cesium.FlyTo(40.4168, -3.7038, 3.0);
            this.done = true;
        }
    }
}
```

### Geocoding

These methods use the configured `GeocodingService`. Without one, they return a result with the `GeocodingStatus.NotConfigured` status.

| Method | Returns |
| --- | --- |
| `GeocodeAsync(string query)` | `GeocodingLookupResult` with the places that match an address or name. `FirstResult` gives the best match. |
| `ReverseGeocodeAsync(double latitude, double longitude)` | `ReverseGeocodingLookupResult` with the address at a position. |
| `AutocompleteAsync(string query, int maxResults = 5)` | `GeocodingAutocompleteResult` with suggestions for a partial query. |

```csharp
var result = await cesium.GeocodeAsync("Eiffel Tower, Paris");
if (result.Status == GeocodingStatus.Success && result.FirstResult is { } place)
{
    cesium.FlyTo(place.Latitude, place.Longitude, 3.0);
}
```

### Diagnostics

| Member | Description |
| --- | --- |
| `Diagnostics` | `CesiumDiagnostics` with the loaded, visible, and newly loaded tiles per tileset, and the queued entities and textures. |
| `UnmanagedDiagnostics` | `UnmanagedAllocationDiagnostics` with the native memory allocation counters per tileset. |

## WorldCamera

`WorldCamera` moves the camera around the globe. With the mouse, drag with the left button to pan, drag with the middle button to tilt, and use the wheel to change the height. When the camera is low, it keeps a minimum height above the terrain.

| Member | Default | Description |
| --- | --- | --- |
| `latitude` | `40.41` | Latitude of the camera, in degrees. |
| `longitude` | `-3.71` | Longitude of the camera, in degrees. |
| `height` | `1000` | Height of the camera above the ellipsoid, in meters. |
| `Heading`, `Tilt` | `0` | Read-only. Orientation of the camera, in radians. |
| `UIHasFocus` | `false` | Set it to `true` while your UI uses the mouse, so the camera ignores it. |

## Place entities on the globe

Add a `CesiumPlacerComponent` (namespace `Evergine.Cesium.Components`) to an entity to place it at geodetic coordinates. Every frame, the coordinator converts the coordinates to world space and aligns the entity with the local up direction of the globe.

| Field | Default | Description |
| --- | --- | --- |
| `Latitude` | `0` | Latitude, in **radians**. Evergine Studio shows and edits it in degrees. |
| `Longitude` | `0` | Longitude, in **radians**. Evergine Studio shows and edits it in degrees. |
| `Height` | `0` | Height, in meters. |
| `HeightIsRelativeToTerrain` | `false` | When `true`, `Height` is measured from the terrain surface; otherwise, from the WGS84 ellipsoid. |
| `Rotation` | | `Quaternion` applied after aligning the entity with the surface. Set it to `Quaternion.Identity` when you create the component from code. |

```csharp
using System;
using Evergine.Cesium.Components;
using Evergine.Components.Graphics3D;
using Evergine.Framework;
using Evergine.Framework.Graphics;
using Evergine.Mathematics;

const double DegreesToRadians = Math.PI / 180.0;

// A marker 10 m above the ground at the Eiffel Tower.
var marker = new Entity("EiffelTower")
    .AddComponent(new Transform3D())
    .AddComponent(new CesiumPlacerComponent
    {
        Latitude = 48.8584 * DegreesToRadians,
        Longitude = 2.2945 * DegreesToRadians,
        Height = 10.0,
        HeightIsRelativeToTerrain = true,
        Rotation = Quaternion.Identity,
    })
    .AddComponent(new MaterialComponent())
    .AddComponent(new SphereMesh() { Diameter = 5 })
    .AddComponent(new MeshRenderer());

this.Managers.EntityManager.Add(marker);
```

## FAQ

**Can I change the imagery at runtime?**

Yes. Set `CesiumCoordinator.OverlayProvider` to another `RasterOverlayProvider` value. The overlayed tilesets reload their imagery.

**Do I have to manage tile or texture memory?**

No. The add-on loads, caches, and evicts tiles automatically.

**What happens without a geocoding service?**

The geocoding methods return results with the `NotConfigured` status. Terrain, buildings, imagery, camera navigation, and entity placement work normally.

**The scene loads but there is no terrain. What should I check?**

1. `CesiumCoordinator.CurrentStatus`: it tells you whether the connection or the token failed.
2. That you added at least one tileset with `AddOverlayedTileset` or `AddGeometryTileset` before the scene started.
3. That your Cesium ion token has the `assets:read` scope and access to those assets.
4. That the scene has an active camera with a `Camera3D` component.
