# Behaviors

---

A **behavior** is a component that runs code every frame. `Behavior` derives from [`Component`](index.md) and adds an abstract `Update(TimeSpan gameTime)` method, which is where movement, input handling, game rules and any other per-frame logic go. Every behavior of a scene is driven by the scene's `BehaviorManager`.

## Create a Behavior

Add a class to the base project that derives from `Behavior` and implement `Update()`:

```csharp
using System;
using Evergine.Framework;

namespace MyProject
{
    public class MyBehavior : Behavior
    {
        protected override void Update(TimeSpan gameTime)
        {
            // gameTime is the time elapsed since the previous frame.
        }
    }
}
```

`Update()` is only called once the behavior has started and while it is activated, so a disabled behavior, or a behavior on a disabled entity, costs nothing. See [Lifecycle of Elements](../../lifecycle_elements.md).

## Example: Rotate an Entity

This behavior turns its entity around the Y axis at a configurable speed. Because it uses `gameTime`, the rotation speed does not depend on the frame rate:

```csharp
using System;
using Evergine.Framework;
using Evergine.Framework.Graphics;
using Evergine.Mathematics;

namespace MyProject
{
    public class Rotator : Behavior
    {
        // Resolved before OnAttached(); the behavior does not attach without a Transform3D.
        [BindComponent]
        private Transform3D transform;

        // Radians per second. Public properties are editable in Evergine Studio.
        public float Speed { get; set; } = 1;

        protected override void Update(TimeSpan gameTime)
        {
            var step = Quaternion.CreateFromYawPitchRoll(this.Speed * (float)gameTime.TotalSeconds, 0, 0);
            this.transform.LocalOrientation *= step;
        }
    }
}
```

```csharp
var teapot = new Entity("Teapot")
    .AddComponent(new Transform3D())
    .AddComponent(new TeapotMesh())
    .AddComponent(new MaterialComponent())
    .AddComponent(new MeshRenderer())
    .AddComponent(new Rotator() { Speed = 2 });

this.Managers.EntityManager.Add(teapot);
```

> [!TIP]
> `[BindComponent]` gives the behavior its dependencies without any lookup code. See [Bindings](../../bindings/index.md).

Evergine ships ready-made behaviors that work the same way, such as `Spinner` (in `Evergine.Components.Graphics3D`) for constant rotation and `FreeCamera3D` (in `Evergine.Components.Cameras`) for a fly camera.

## Update Order

All behaviors of a scene run one after another, in the order given by their `UpdateOrder` property:

| Property | Default | Description |
| --- | --- | --- |
| **UpdateOrder** | `0.5` | A value between `0` and `1`. Behaviors with lower values are updated first. Values outside that range throw an exception. |

Use it when one behavior must see the result of another in the same frame. For example, a camera that follows a character should run after the behavior that moves the character, so give the camera behavior a higher value:

```csharp
// Runs after every behavior left at the default 0.5.
entity.AddComponent(new Rotator() { UpdateOrder = 0.9f });
```

> [!NOTE]
> Behaviors are sorted when they are added to the scene. Changing `UpdateOrder` on a behavior that is already running does not move it in the order.

## Behavior Families

Every behavior belongs to a family, set through the base constructor with a `FamilyType` value. The family decides where the behavior runs:

| Family | Description |
| --- | --- |
| `FamilyType.DefaultBehavior` | The default. The behavior runs in your application, but not while the scene is being edited in Evergine Studio. |
| `FamilyType.PriorityBehavior` | The behavior also runs inside Evergine Studio, so its effect is visible while you edit the scene. |
| `FamilyType.PhysicsBehavior` | Reserved for the physics bodies of the engine. |

```csharp
using System;
using Evergine.Framework;

namespace MyProject
{
    public class EditorVisibleBehavior : Behavior
    {
        public EditorVisibleBehavior()
            : base(FamilyType.PriorityBehavior)
        {
        }

        protected override void Update(TimeSpan gameTime)
        {
            // Runs in Evergine Studio too: keep it cheap and free of side effects on the scene asset.
        }
    }
}
```

> [!TIP]
> Code that must behave differently inside Evergine Studio can check `Application.Current.IsEditor`. See [Using Application](../../application/using_application.md#check-whether-the-code-runs-in-evergine-studio).

## BehaviorManager

The **BehaviorManager** is a [scene manager](../../scenes/scenemanagers.md) registered in every scene. Behaviors register with it when they are attached and unregister when they are detached, so you never call it directly. Each frame it updates every started behavior in `UpdateOrder`.

## Add or Remove a Behavior

A behavior is a component, so you add it to and remove it from an entity exactly like any other component, in Evergine Studio or from code. See [Components](index.md#using-components).
