# Bind SceneManagers

Using the **[BindSceneManager]** attribute allows the developer to establish dependencies with a [SceneManager](../scenes/scenemanagers.md) registered in the Scene.

```csharp
// Bind the RenderManager of the scene...
[BindSceneManager]
private RenderManager renderManager;
```

> [!NOTE]
> [BindSceneManager] can be used inside Components and SceneManagers. Otherwise, the binding cannot be resolved.

## [BindSceneManager] Properties
This attribute offers several ways to customize:

### isRequired (default `true`)

If the value is true, the dependency is required to be resolved; otherwise, the current Component won't be attached.

The isRequired value has the same functionality as [BindComponent] (see [Bind Components](bind_components.md) for further details).

For example, if these are all Services registered inside the Application Container:

```csharp
this.managers.AddManager(new EntityManager());
this.managers.AddManager(new AssetSceneManager());
this.managers.AddManager(new BehaviorManager());
this.managers.AddManager(new RenderManager());
this.managers.AddManager(new EnvironmentManager());
```

The following component will be attached because the `EnvironmentManager` has been registered:

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
