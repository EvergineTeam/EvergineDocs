# Create a Model from Code

---

![Create Model header](images/CustomModel.jpg)

Most models come from 3D tools such as Blender or 3ds Max, but procedural geometry, data visualization and CAD imports often build their meshes at runtime. To show such meshes in a scene you wrap them in a `Model` and instantiate it, exactly as you would an imported one.

> [!NOTE]
> How to build the meshes themselves, with their vertex and index buffers, is covered in [Meshes](../meshes/index.md#create-a-mesh-from-code). The examples below call the `CreateQuadMesh` and `CreateQuadMeshFromStreams` methods from that page.

## Single-mesh model

For one mesh, the `Model(string name, Mesh mesh)` constructor does all the work. It creates one node and one mesh container named after the model, and assigns the mesh the default material of the Evergine.Core package.

| Parameter | Description |
| --- | --- |
| **name** | Name of the model, its node and its mesh container. |
| **mesh** | The mesh the model contains. |

```csharp
protected override void CreateScene()
{
    var graphicsContext = Application.Current.Container.Resolve<GraphicsContext>();
    var assetsService = Application.Current.Container.Resolve<AssetsService>();

    Mesh mesh = this.CreateQuadMesh(graphicsContext);
    Model model = new Model("CustomModel", mesh);

    Entity entity = model.InstantiateModelHierarchy("MyModel", assetsService);
    this.Managers.EntityManager.Add(entity);
}
```

## Model with several meshes

For anything more complex (several meshes, several nodes, your own materials) you fill in the `Model` yourself. This example puts two meshes in one mesh container on a single root node.

```csharp
using System;
using System.Collections.Generic;
using Evergine.Common.Graphics;
using Evergine.Components.Graphics3D;
using Evergine.Framework;
using Evergine.Framework.Graphics;
using Evergine.Framework.Graphics.Effects;
using Evergine.Framework.Graphics.Materials;
using Evergine.Framework.Services;
using Evergine.Mathematics;

public partial class MyScene : Scene
{
    protected override void CreateScene()
    {
        var graphicsContext = Application.Current.Container.Resolve<GraphicsContext>();
        var assetsService = Application.Current.Container.Resolve<AssetsService>();

        Mesh mesh1 = this.CreateQuadMesh(graphicsContext);
        Mesh mesh2 = this.CreateQuadMeshFromStreams(graphicsContext);

        var meshContainer = new MeshContainer()
        {
            Name = "MultipleMeshes",
            Meshes = new List<Mesh>() { mesh1, mesh2 },
        };

        var rootNode = new NodeContent()
        {
            Name = "MultipleMeshes",
            Mesh = meshContainer,
            Translation = Vector3.Zero,
            Orientation = Quaternion.Identity,
            Scale = Vector3.One,
            Children = new NodeContent[0],
            ChildIndices = new int[0],
        };

        var model = new Model()
        {
            MeshContainers = new[] { meshContainer },

            // Both meshes keep MaterialIndex 0, so they share this entry. An empty id leaves the
            // material unassigned; it is set on the entity below.
            Materials = new List<(string, Guid)>() { ("Default", Guid.Empty) },
            AllNodes = new[] { rootNode },
            RootNodes = new[] { 0 },
        };

        model.RefreshBoundingBox();

        var material = new StandardMaterial(assetsService.Load<Effect>(DefaultResourcesIDs.StandardEffectID))
        {
            LayerDescription = assetsService.Load<RenderLayerDescription>(DefaultResourcesIDs.OpaqueRenderLayerID),

            // The quads have vertex colors but no normals, so lighting has nothing to work with.
            VertexColorEnabled = true,
            LightingEnabled = false,
            IBLEnabled = false,
        };

        Entity entity = model.InstantiateModelHierarchy("MyModel", assetsService);
        entity.FindComponent<MaterialComponent>().Material = material.Material;

        this.Managers.EntityManager.Add(entity);
    }
}
```

The model's material list holds pairs of a slot name and a material asset id. `InstantiateModelHierarchy` loads each id through the `AssetsService` and puts the material in a `MaterialComponent`. A material you create in code is not an asset, so the example leaves the id empty and assigns the material to the component afterwards.

| Model member | Description |
| --- | --- |
| **MeshContainers** | Every mesh container of the model. A node refers to one of them through `NodeContent.Mesh`. |
| **Materials** | The material slots: a name and the id of a material asset. `Mesh.MaterialIndex` points into this list. |
| **AllNodes** | Every node, at any depth. |
| **RootNodes** | Indices into `AllNodes` of the nodes that have no parent. |
| **Skins** | Skinning data, when the model has skinned meshes. |
| **Animations** | Animation clips by name. |
| **LOD** | Level-of-detail groups. See [Level of Detail](level_of_detail.md). |
