# Create a Texture from Code

---

Textures are usually assets that you assign to materials and components in Evergine Studio. From code you can do two things with them: load a texture asset and use it, or create a texture at runtime from your own pixel data.

## Load a texture asset from code

Load the asset through the scene's `AssetSceneManager` (or the `AssetsService`) with the id that `EvergineContent` generates for it, as explained in [Using assets](../../evergine_studio/assets/use.md). This example gives a teapot a material with a base color texture:

```csharp
using Evergine.Common.Graphics;
using Evergine.Components.Graphics3D;
using Evergine.Framework;
using Evergine.Framework.Graphics;
using Evergine.Framework.Graphics.Effects;
using Evergine.Framework.Graphics.Materials;
using Evergine.Framework.Managers;

public class MyScene : Scene
{
    protected override void CreateScene()
    {
        AssetSceneManager assets = this.Managers.AssetSceneManager;

        // Content/Textures/Diffuse.png
        Texture diffuseTexture = assets.Load<Texture>(EvergineContent.Textures.Diffuse_png);

        var material = new StandardMaterial(assets.Load<Effect>(DefaultResourcesIDs.StandardEffectID))
        {
            LayerDescription = assets.Load<RenderLayerDescription>(DefaultResourcesIDs.OpaqueRenderLayerID),
            BaseColorTexture = diffuseTexture,
            BaseColorSampler = assets.Load<SamplerState>(DefaultResourcesIDs.LinearWrapSamplerID),
        };

        Entity teapot = new Entity("texturedTeapot")
            .AddComponent(new Transform3D())
            .AddComponent(new TeapotMesh())
            .AddComponent(new MaterialComponent() { Material = material.Material })
            .AddComponent(new MeshRenderer());

        this.Managers.EntityManager.Add(teapot);
    }
}
```

## Create a texture from pixel data

To create a texture at runtime you need two things: a `TextureDescription` that says what kind of texture it is, and one `DataBox` per subresource with the pixels. The [Texture](../low_level_api/texture.md) page of the low-level API covers every option; this section shows the common case.

### TextureDescription

| Field | Default | Description |
| --- | --- | --- |
| **Type** | `Texture2D` | `Texture1D`, `Texture1DArray`, `Texture2D`, `Texture2DArray`, `TextureCube`, `TextureCubeArray` or `Texture3D`. |
| **Format** | `R8G8B8A8_UNorm` | The `PixelFormat` of each texel. |
| **Width** | 1 | Width in texels. The maximum depends on the device. |
| **Height** | 1 | Height in texels. |
| **Depth** | 1 | Depth in texels, for `Texture3D` only. |
| **ArraySize** | 1 | Number of textures in an array texture. A cube map counts its six faces as one element, so a single cube map has `ArraySize = 1`. |
| **MipLevels** | 1 | Number of mipmap levels. |
| **Flags** | `ShaderResource` | How the GPU uses it: `ShaderResource`, `RenderTarget`, `UnorderedAccess`, `DepthStencil`, `GenerateMipmaps`, combinable. |
| **Usage** | `Default` | `Default` (GPU reads and writes), `Immutable` (GPU reads only, contents fixed at creation), `Dynamic` (GPU reads, CPU writes) or `Staging` (copies between GPU and CPU). |
| **CpuAccess** | `None` | `None`, `Write` or `Read`. Only `Dynamic` and `Staging` textures can be accessed from the CPU. |
| **SampleCount** | `None` | Multisampling: `None`, `Count2`, `Count4`, `Count8`, `Count16` or `Count32`. |

The static helpers `TextureDescription.CreateTexture1DDescription`, `CreateTexture2DDescription`, `CreateTexture3DDescription` and `CreateTextureCubeDescription` return a description with these defaults and the size and format you pass.

### DataBox

A `DataBox` points at the pixels of one subresource: one mip level of one array slice or cube face. It also carries the row pitch (bytes per row) and the slice pitch (bytes per 2D slice). A texture with several mip levels or slices takes an array of them, ordered slice by slice and, within each slice, mip by mip.

### Example

This scene creates a 256 × 256 checkerboard and shows it on a plane:

```csharp
using Evergine.Common.Graphics;
using Evergine.Components.Graphics3D;
using Evergine.Framework;
using Evergine.Framework.Graphics;
using Evergine.Framework.Graphics.Effects;
using Evergine.Framework.Graphics.Materials;
using Evergine.Framework.Services;

public class CheckerScene : Scene
{
    protected override void CreateScene()
    {
        var graphicsContext = Application.Current.Container.Resolve<GraphicsContext>();
        var assetsService = Application.Current.Container.Resolve<AssetsService>();

        const uint size = 256;
        const uint cell = 32;
        byte[] pixels = new byte[size * size * 4];

        for (uint y = 0; y < size; y++)
        {
            for (uint x = 0; x < size; x++)
            {
                byte value = (((x / cell) + (y / cell)) % 2 == 0) ? (byte)255 : (byte)40;
                uint i = ((y * size) + x) * 4;
                pixels[i] = value;
                pixels[i + 1] = value;
                pixels[i + 2] = value;
                pixels[i + 3] = 255;
            }
        }

        var description = TextureDescription.CreateTexture2DDescription(size, size, PixelFormat.R8G8B8A8_UNorm);

        // One subresource: mip 0 of slice 0. The row pitch is the width in bytes.
        var data = new DataBox[] { new DataBox(pixels, size * 4) };
        Texture checker = graphicsContext.Factory.CreateTexture(data, ref description, "Checker");

        var material = new StandardMaterial(assetsService.Load<Effect>(DefaultResourcesIDs.StandardEffectID))
        {
            LayerDescription = assetsService.Load<RenderLayerDescription>(DefaultResourcesIDs.OpaqueRenderLayerID),
            BaseColorTexture = checker,
            BaseColorSampler = assetsService.Load<SamplerState>(DefaultResourcesIDs.LinearWrapSamplerID),
        };

        Entity plane = new Entity("checkerPlane")
            .AddComponent(new Transform3D())
            .AddComponent(new PlaneMesh())
            .AddComponent(new MaterialComponent() { Material = material.Material })
            .AddComponent(new MeshRenderer());

        this.Managers.EntityManager.Add(plane);
    }
}
```

> [!NOTE]
> A texture you create yourself is not tracked by the asset system. Dispose it when you no longer need it.
