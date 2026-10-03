# Using Materials

![Materials header](images/materials.jpg)

In this document, you will learn how to load and use **Materials** in your applications.

## Load Material from code
The following sample code can be used to instantiate an existing material asset and apply it to an entity in your scene.
```csharp
using Evergine.Components.Graphics3D;
using Evergine.Framework;
using Evergine.Framework.Graphics;
using Evergine.Framework.Services;

public class MyScene : Scene
{
    protected override void CreateScene()
    {
        var assetsService = Application.Current.Container.Resolve<AssetsService>();

        // Load Material
        Material defaultMaterial = assetsService.Load<Material>(DefaultResourcesIDs.DefaultMaterialID);

        // Apply to an entity
        Entity primitive = new Entity()
                .AddComponent(new Transform3D())
                .AddComponent(new MaterialComponent() { Material = defaultMaterial })
                .AddComponent(new SphereMesh())
                .AddComponent(new MeshRenderer());

        this.Managers.EntityManager.Add(primitive);
    }
}
```

## How to apply material to an entity from Evergine Studio
Select an entity from Viewport or Entities Hierarchy, and then the Entity Details panel shows the entity component list. To apply a new material, set the Material property in the Material Component of your entity.

![Material Component](images/ApplyMaterial.jpg)
