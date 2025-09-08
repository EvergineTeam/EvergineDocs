# Bind Services

Using the **[BindService]** attribute allows the developer to establish dependencies with a [Service](../services.md) registered in the [Application Container](../application/container.md). 

```csharp
// Bind the Graphics Context registered in the Application...
[BindService]
private GraphicsContext transform;
```

> [!NOTE]
> [BindService] can be used inside Services, Components, and SceneManagers. Otherwise, the binding cannot be resolved.

## [BindService] Properties
This attribute offers several ways to customize:

### isRequired (default `true`)

If the value is true, the dependency is required to be resolved; otherwise, the current Component won't be attached.

The isRequired value has the same functionality as [BindComponent] (see [Bind Components](bind_components.md) for further details).

For example, if these are all the Services registered inside the Application Container:

```csharp
// Register services in the application container...
this.Container.Register<TimerFactory>();
this.Container.Register<Random>();
this.Container.Register<ErrorHandler>();
this.Container.Register<ScreenContextManager>();
this.Container.Register<GraphicsPresenter>();
this.Container.Register<AssetsDirectory>();
this.Container.Register<AssetsService>();
this.Container.Register<ForegroundTaskSchedulerService>();            
this.Container.Register<WorkActionScheduler>();
```

The following component will be attached because the `AssetsService` has been registered:

```csharp
public class MyComponent : Component
{
    [BindService]
    private AssetsService assetService;

    // ...
}
```

However, in this case, the dependency will fail because the `Clock` service is not registered:

```csharp
public class MyComponent : Component
{
    [BindService]
    private Clock clock;

    // ...
}
```

