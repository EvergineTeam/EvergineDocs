# Using Entities

---

Entities can be created and edited in Evergine Studio, where they are saved with the scene asset, or from code, where they exist only while the application runs. Both kinds live side by side in the same scene.

## From Evergine Studio

### Add an Entity

In the **Entities Hierarchy** panel of the [Scene Editor](../../scenes/scene_editor.md), click the ![Add Button](../../../graphics/images/plusIcon.jpg) button. A menu opens with the kinds of entity you can create:

![Create Entity](images/create_entity.png)

Each option creates an entity with the components that kind needs, such as a mesh, a material and a `MeshRenderer` for a primitive, or a `Camera3D` for a camera. **Empty entity** creates an entity with only a `Transform3D`.

### Edit an Entity

Select the entity to show it in the **Entity Details** panel, where you can change its name, tag and enabled state, and edit its components:

![Entity details](images/entity_details.png)

Drag an entity onto another one in the **Entities Hierarchy** to make it a child of that entity.

## From Code

### Create an Entity

Create the entity, add its components, and add it to the scene's `EntityManager`:

```csharp
// The default material of Evergine; load your own material assets the same way.
var assetsService = Application.Current.Container.Resolve<AssetsService>();
var material = assetsService.Load<Material>(DefaultResourcesIDs.DefaultMaterialID);

var teapot = new Entity("Teapot")
{
    Tag = "Props",
}
.AddComponent(new Transform3D())
.AddComponent(new TeapotMesh())
.AddComponent(new MaterialComponent() { Material = material })
.AddComponent(new MeshRenderer());

this.Managers.EntityManager.Add(teapot);
```

This code usually lives in the `CreateScene()` method of a [scene class](../../scenes/create_scenes.md) or in a component that spawns entities at runtime.

### Create a Hierarchy

Add the children to their parent, and only the parent to the `EntityManager`:

```csharp
var parent = new Entity("Parent")
    .AddComponent(new Transform3D());

var child = new Entity("Child")
    .AddComponent(new Transform3D() { LocalPosition = new Vector3(0, 1, 0) });

parent.AddChild(child);

this.Managers.EntityManager.Add(parent);
```

The child is placed one unit above its parent and follows it from then on. See [Entity Hierarchy](entity_hierarchy.md).

### Bind an Entity to a Component Property

Components can expose properties that reference other entities in the scene. To make an `Entity` property assignable from Evergine Studio, decorate it with the `[RenderPropertyAsEntity]` attribute:

```csharp
public class Follower : Behavior
{
    [RenderPropertyAsEntity]
    public Entity Target { get; set; }

    [BindComponent]
    private Transform3D myTransform;

    private Transform3D targetTransform;

    protected override void Start()
    {
        base.Start();

        this.targetTransform = this.Target?.FindComponent<Transform3D>();
    }
}
```

In Evergine Studio, you can assign the `Target` property by dragging an entity from the **Scene Hierarchy** and dropping it onto the corresponding property in the component panel.

The entity reference is stored as part of the component configuration. When the scene is loaded and the component dependencies are resolved, the property contains the corresponding `Entity` instance. Therefore, the referenced entity can be used directly from the component code.

In the example above, once the `Follower` component starts, `Target` already references the entity selected in Evergine Studio. The component can then retrieve its `Transform3D` component using `FindComponent<Transform3D>()`.

### Remove an Entity

```csharp
// Destroys the entity, its children and their components.
this.Managers.EntityManager.Remove(teapot);
```

See [EntityManager](entity_manager.md) for `Detach()`, which takes an entity out of the scene without destroying it.
