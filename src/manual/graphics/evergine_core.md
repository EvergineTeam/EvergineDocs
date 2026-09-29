# Evergine.Core Package

---

**Evergine.Core** is the asset package every Evergine project references. It contains the effects, materials, render layers, samplers, textures, fonts and compute effects the engine and its components need, so a new project can render, light and post-process a scene without creating any of them. Its assets appear in Evergine Studio under the package in the **Project Explorer**, and from code you load them by the ids in `DefaultResourcesIDs`.

```csharp
var assetsService = Application.Current.Container.Resolve<AssetsService>();

Material defaultMaterial = assetsService.Load<Material>(DefaultResourcesIDs.DefaultMaterialID);
RenderLayerDescription alpha = assetsService.Load<RenderLayerDescription>(DefaultResourcesIDs.AlphaRenderLayerID);
SamplerState wrap = assetsService.Load<SamplerState>(DefaultResourcesIDs.LinearWrapSamplerID);
```

## Contents

| Folder | Assets | See |
| --- | --- | --- |
| **Effects** | `StandardEffect`, `SSSEffect`, `DistortionEffect`, `SkyboxEffect`, `AtmosphericEffect`, `AtmosphericQuadEffect`, `BillboardEffect`, `ParticlesEffect`, `SDFText`, `LineEffect`, `LineBatchEffect`, `RenderQuad`, `BackgroundImageEffect` | [Built-in Effects](effects/builtin_effects.md) |
| **Effects/Libraries** | `Common`, `Structures`, `Lighting`, `LightingModels`, `Shadow`, `Material`, `SSS`, `SSSMaterial` | [Library Effects](effects/library_effect.md) |
| **Materials** | `DefaultMaterial` (Standard effect, lit, with IBL) and `DistortionMat` | [Materials](materials/index.md) |
| **RenderLayers** | `Skybox`, `Opaque`, `Alpha`, `AlphaDoubleSided`, `Additive` | [Render Layers](renderlayers/index.md) |
| **Samplers** | `LinearWrapSampler`, `LinearClampSampler` | [Samplers](samplers.md) |
| **Textures** | `Checker`, `particle` (default particle texture), `dfgLut` (IBL lookup table), `translucency` (SSS lookup table), and the lens dirt and starburst textures of the post-processing graph | [Textures](textures/index.md) |
| **Fonts** | `Arial`, the default font of `Text3D` | [Fonts and Texts](fonts/index.md) |
| **PostProcessingGraphs** | `DefaultPostProcessingGraph` | [Default Post-Processing Graph](postprocessing_graph/default_postprocessing_graph/index.md) |
| **Computes/PostProcessing** | The nodes of the post-processing graph: SSAO, SSR, SSS blur, fog, TAA, motion blur, depth of field, bloom, lens flare, FSR, sharpen, tone mapping, FXAA and their helpers | [Post-Processing Graph](postprocessing_graph/index.md) |
| **Computes/Environment** | `AtmosphereCompute`, `RadianceCompute`, `IrradianceCompute`, which generate the sky and the IBL | [Environment](environment/index.md) |
| **Computes/Particles** | GPU particle simulation and the particle forces | [Particle System](particles/index.md) |
| **Computes/Skinning**, **Computes/Morphing** | GPU skinning and morph targets for animated models | [Models](models/index.md) |
