# Evergine Cesium

---

![TeaserAddon.png](images/TeaserAddon.png)

**Evergine Cesium** integrates the [Cesium ion](https://cesium.com/platform/cesium-ion/) platform into Evergine, enabling real-world geospatial content streaming, including global terrain, 3D buildings, and imagery overlays, with helpers for geodetic navigation and entity placement.

## Features

| Category | Capabilities |
|---|---|
| **Terrain & Tiles** | Real-time terrain streaming from Cesium World Terrain; 3D buildings for cities and urban areas |
| **Imagery** | Switchable overlays: Bing Aerial, Bing Maps, Google Maps variants |
| **Camera** | Earth-aware controls using latitude, longitude and altitude; smooth `FlyTo` animation |
| **Placement** | Place any entity at geodetic coordinates; terrain height sampling for accurate ground placement |
| **Geocoding** | Address search, reverse geocoding, and autocomplete suggestions (requires Azure Maps key) |
| **Diagnostics** | Runtime streaming counters and native memory diagnostics |

## Requirements

- Evergine
- .NET 10 SDK
- A **Cesium ion** access token with permissions for terrain and 3D tiles: [get one free](https://ion.cesium.com/tokens)
- *(Optional)* An **Azure Maps** key for geocoding features

> [!NOTE]
> Evergine Cesium does **not** support Web platforms (WebGL / WebGPU).

## In this Section

* [Getting Started](getting_started.md)
