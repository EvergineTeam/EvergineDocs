# Cesium

---

![Cesium add-on](images/TeaserAddon.png)

The **Evergine Cesium** add-on streams real-world geospatial content from [Cesium ion](https://cesium.com/platform/cesium-ion/) into Evergine: global terrain, 3D buildings, and imagery. It also includes an Earth-aware camera, a component that places entities at latitude and longitude, and optional geocoding to search places by address. Use it to build digital twins, city viewers, or any application that shows content on the real globe.

## Features

| Category | Capabilities |
| --- | --- |
| **Tilesets** | Streams Cesium ion tilesets: terrain with an imagery overlay, such as Cesium World Terrain, and geometry-only tilesets, such as 3D buildings. |
| **Imagery** | Switchable overlays: Bing aerial and roads, and several Google Maps styles. |
| **Camera** | `WorldCamera` navigates by latitude, longitude, and height, and `FlyTo` animates the camera to a place. |
| **Placement** | `CesiumPlacerComponent` places any entity at geodetic coordinates, optionally relative to the terrain height. |
| **Geocoding** | Address search, reverse geocoding, and autocomplete through Azure Maps or Google Maps (requires a key for the service). |
| **Lighting** | `SunLightDirection` orients a directional light like the sun for a day of the year and an hour. |
| **Diagnostics** | Tile and streaming counters, and native memory allocation counters. |

## Requirements

- A **Cesium ion** access token with access to the assets you stream. You can [create one for free](https://ion.cesium.com/tokens).
- Optionally, an **Azure Maps** or **Google Maps** key for geocoding.
- A Windows profile. The add-on sample targets DirectX 11, DirectX 12, and Vulkan.

> [!NOTE]
> Evergine Cesium does not support Web platforms (WebGL and WebGPU).

## In this section

* [Getting started](getting_started.md)
