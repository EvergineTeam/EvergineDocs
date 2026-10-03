# Fog

---

**Fog** fades objects towards a color with distance from the camera, height above the ground, or both. It adds depth to large scenes and hides the far plane.

## Parameters

| Parameter | Default | Description |
| --- | --- | --- |
| **Enabled** | Off | Turns the effect on. |
| **Color** | (0.5, 0.5, 0.5) | Color objects fade to. |
| **Mode** | `Exponential` | How fog grows with distance: `Linear` goes from no fog at **Distance Start** to full fog at **Distance End**; `Exponential` and `ExponentialSquared` grow with **Distance Density**, the squared version more gently at first and faster later. |
| **Distance Enabled** | On | Apply fog by distance from the camera. |
| **Distance Start** | 1 | Distance at which linear fog starts. |
| **Distance End** | 10 | Distance at which linear fog is complete. |
| **Distance Density** | 0.5 | Density of exponential fog. |
| **Height Enabled** | Off | Apply height fog: a layer that fills the space below **Height** and gets denser the deeper you look into it. |
| **Height** | 0 | Height, in world units, at which the fog layer ends. |
| **Height Density** | 1 | How quickly height fog thickens below the fog height. |

> [!NOTE]
> In the current version of Evergine Studio the **Height Density** field edits the distance density instead of the height density. To change the height density, edit the `HeightDensity` input of the Fog node in the [Post-Processing Graph Editor](../postprocessing_graph_editor.md).
