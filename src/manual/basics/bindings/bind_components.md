# Bind Components

---

The **[BindComponent]** attribute gives a [component](../component_arch/components/index.md) a reference to another component: one on the same entity, on its children or parents, or anywhere in the scene. It is the usual way for a component to reach the `Transform3D` of its entity or the camera it works with.

```csharp
// The Transform3D of the owner entity.
[BindComponent]
private Transform3D transform;

// Every Camera3D of the scene.
[BindComponent(source: BindComponentSource.Scene)]
private List<Camera3D> sceneCameras;
```

> [!NOTE]
> `[BindComponent]` only works inside components, because every search starts from the owner entity of the component.

## Parameters

| Parameter | Default | Description |
| --- | --- | --- |
| `isExactType` | `true` | When `true`, only components of exactly the member type match. When `false`, components of derived types match too. |
| `isRequired` | `true` | When `true`, the component does not attach unless a match is found. When `false`, the member is left `null` if nothing matches. |
| `source` | `BindComponentSource.Owner` | Where to search. See [source](#source). |
| `tag` | `null` | When set, only entities with this tag are searched. |
| `isRecursive` | `true` | For the `Children` and `Parents` sources, `true` searches all descendants or ancestors, and `false` only the direct children or the direct parent. |

### isRequired

This component needs a `Transform3D` but can live without a `Camera3D`:

```csharp
using Evergine.Framework;
using Evergine.Framework.Graphics;

namespace MyProject
{
    public class MyComponent : Component
    {
        [BindComponent(isRequired: true)]
        private Transform3D transform;

        [BindComponent(isRequired: false)]
        private Camera3D camera;
    }
}
```

On this entity, `MyComponent` attaches: `transform` gets the entity's `Transform3D`, and `camera` stays `null` because it is optional.

```csharp
Entity entity = new Entity()
    .AddComponent(new Transform3D())
    .AddComponent(new MyComponent());
```

On this other entity, `MyComponent` does not attach, because its required `Transform3D` is missing (see [Binding Errors](index.md#binding-errors)):

```csharp
Entity anotherEntity = new Entity()
    .AddComponent(new MyComponent());
```

### isExactType

`Camera3D` derives from `Camera`. With the default `isExactType: true`, this binding does not match a `Camera3D`, because the member type is `Camera`:

```csharp
[BindComponent]
private Camera camera;
```

Set `isExactType: false` to accept any component that is a `Camera`, including a `Camera3D`:

```csharp
[BindComponent(isExactType: false)]
private Camera camera;
```

### source

The `BindComponentSource` value says where the search starts and how far it goes:

| Source | Searches |
| --- | --- |
| `Owner` (default) | The owner entity only. |
| `Scene` | Every entity of the scene. |
| `Children` | The owner entity and its descendants. |
| `ChildrenSkipOwner` | The descendants of the owner entity, **without** the owner. |
| `Parents` | The owner entity and its ancestors. |
| `ParentsSkipOwner` | The ancestors of the owner entity, **without** the owner. |

For a single member, the first match wins. The `Children` sources check the owner first (unless skipped) and then each child with its whole branch, in the order the children were added. The `Parents` sources go from the nearest ancestor up.

```csharp
using System.Collections.Generic;
using Evergine.Framework;
using Evergine.Framework.Graphics;

namespace MyProject
{
    public class MyComponent : Component
    {
        // The first Camera3D found in the scene.
        [BindComponent(source: BindComponentSource.Scene)]
        private Camera3D firstCamera;

        // Every Camera3D in the scene.
        [BindComponent(source: BindComponentSource.Scene)]
        private List<Camera3D> sceneCameras;

        // The Transform3D of the nearest ancestor, which is how Transform3D itself finds its parent.
        [BindComponent(isRequired: false, source: BindComponentSource.ParentsSkipOwner)]
        private Transform3D parentTransform;
    }
}
```

> [!TIP]
> `Scene` searches every entity when the component attaches. It is fine for a handful of components, but prefer `Owner`, `Children` or `Parents` for components that are created in large numbers.

### tag

`tag` narrows the search to entities with that `Tag`:

```csharp
// Every Camera3D on entities tagged "Minimap".
[BindComponent(source: BindComponentSource.Scene, tag: "Minimap")]
private List<Camera3D> minimapCameras;
```

### isRecursive

With `isRecursive: false`, the `Children` sources only look at the direct children, and the `Parents` sources only at the direct parent:

```csharp
// A MeshRenderer on the owner or one of its direct children, but not on grandchildren.
[BindComponent(source: BindComponentSource.Children, isRecursive: false)]
private MeshRenderer renderer;
```

> [!NOTE]
> `isRecursive` applies to single members. A `List<T>` member with a `Children` or `Parents` source always searches the whole branch.
