# Point Cloud

---

![TeaserAddon.png](images/TeaserAddon.png)

**Evergine Cesium** integrates Cesium ion platform into the Engine, allowing stream real-world content, including global terrain and buildings, and provides helpers for geospatial navigation and placement.

## Features

- Real-time terrain streaming from Cesium World Terrain
- 3D buildings streaming for cities and urban areas
- Switchable imagery overlays (Bing and Google variants)
- Earth-aware camera controls using latitude, longitude, and altitude
- Smooth FlyTo camera animation to any destination
- Entity placement by geodetic coordinates
- Terrain height sampling for accurate placement
- Optional geocoding with Azure Maps:
  - search by address
  - reverse geocode camera position
  - autocomplete suggestions
- Runtime diagnostics for streaming and native memory behavior 

## Requirements

- Evergine
- .NET 10 SDK
- Cesium ion access token with permissions for terrain and 3D tiles
- Optional Azure Maps key for geocoding features

### In this Section

* [Getting Started](getting_started.md)
