# Create a Render Layer

---

![RenderLayer header](images/renderlayer.jpg)

`RenderLayers` control the drawing order of your meshes and allow configuration of the rasterizer state, blend state, and depth-stencil parameters for each draw call that renders your mesh.

## Creating a RenderLayer Asset in Evergine Studio
To create a new `RenderLayer` asset in **Evergine Studio**, follow these steps:

1. Open the [**Assets Details**](../../evergine_studio/interface.md) panel.
2. Click on the ![Plus Icon](../images/plusIcon.jpg) button to open the create menu.
3. Select the _"Create Layer"_ option from the dropdown menu.

![Create new RenderLayer menu option](images/AssetsDetailsMenu.jpg)

This will create a new `RenderLayer` asset in the selected folder of your project.

### Inspecting the RenderLayer Asset
Once created, you can view and edit `RenderLayer` assets in the [**Assets Details**](../../evergine_studio/interface.md) panel by selecting a folder in the [**Project Explorer**](../../evergine_studio/interface.md).

![RenderLayer asset](images/renderLayerAsset.jpg)

### RenderLayer Files in the Content Directory
`RenderLayer` files are stored with the `.werl` extension in the content directory. You can manage these files directly or through the Evergine Studio interface.

![RenderLayer file](images/renderLayerFile.jpg)

## Create a render layer from code
This scene creates a render layer that draws in wireframe, and a Standard material that uses it:

```csharp
using Evergine.Common.Graphics;
using Evergine.Components.Graphics3D;
using Evergine.Framework;
using Evergine.Framework.Graphics;
using Evergine.Framework.Graphics.Effects;
using Evergine.Framework.Services;

public class MyScene : Scene
{
    protected override void CreateScene()
    {
        var assetsService = Application.Current.Container.Resolve<AssetsService>();

        // Create a custom RenderLayer with specified render states
        RenderLayerDescription customLayer = new RenderLayerDescription()
        {
            RenderState = new RenderStateDescription()
            {
                // Start from a preset so every other rasterizer field keeps a sensible value.
                RasterizerState = RasterizerStates.WireframeCullBack,
                BlendState = BlendStates.Opaque,
                DepthStencilState = DepthStencilStates.ReadWrite,
            },
            Order = 0,
            SortMode = SortMode.FrontToBack,
        };

        // Load the standard effect
        Effect standardEffect = assetsService.Load<Effect>(DefaultResourcesIDs.StandardEffectID);

        // Create a material using the custom RenderLayer
        Material material = new Material(standardEffect)
        {
            LayerDescription = customLayer
        };

        // Apply the material to an entity
        Entity primitive = new Entity()
            .AddComponent(new Transform3D())
            .AddComponent(new MaterialComponent() { Material = material })
            .AddComponent(new TeapotMesh())
            .AddComponent(new MeshRenderer());

        this.Managers.EntityManager.Add(primitive);
    }
}
```