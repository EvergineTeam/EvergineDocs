# Bind Scene Managers

---

The **[BindSceneManager]** attribute gives a component or a scene manager a reference to a [scene manager](../scenes/scenemanagers.md) of its scene, such as the `RenderManager`, the `EnvironmentManager` or one of your own.

```csharp
// The RenderManager of the scene.
[BindSceneManager]
private RenderManager renderManager;
```

> [!NOTE]
> `[BindSceneManager]` works inside components and scene managers, which are the elements that belong to a scene.

## Parameters

| Parameter | Default | Description |
| --- | --- | --- |
| `isExactType` | `false` | When `false`, any registered manager that is of the member type or derives from it matches. When `true`, only a manager registered under exactly that type matches. |
| `isRequired` | `true` | When `true`, the element does not attach unless the manager is found. When `false`, the member is left `null` if the scene does not have that manager. |

> [!TIP]
> Unlike `[BindComponent]`, `isExactType` is `false` by default. That is what lets `[BindSceneManager] private BaseRenderManager renderManager;` find the scene's `RenderManager`.

### isRequired

The binding can only find managers that the scene registered. With the default managers of a scene:

```csharp
this.Managers.AddManager(new EntityManager());
this.Managers.AddManager(new AssetSceneManager());
this.Managers.AddManager(new BehaviorManager());
this.Managers.AddManager(new RenderManager());
this.Managers.AddManager(new EnvironmentManager());
```

this component attaches, because the `EnvironmentManager` is registered:

```csharp
public class MyComponent : Component
{
    [BindSceneManager]
    private EnvironmentManager environmentManager;

    // ...
}
```

However, in this case, the dependency will fail because `PhysicsManager` is not registered in the scene:

```csharp
public class MyComponent : Component
{
    [BindSceneManager]
    private PhysicsManager physicsManager;

    // ...
}
```

Mark the binding with `isRequired: false` when your component can work without the manager, and check the member for `null` before using it.

## List Bindings

A `List<T>` member receives every registered manager that matches the member type:

```csharp
// Every updatable scene manager of the scene, including the BehaviorManager.
[BindSceneManager]
private List<UpdatableSceneManager> updatableManagers;
```
