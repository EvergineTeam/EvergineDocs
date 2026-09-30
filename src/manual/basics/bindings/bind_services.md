# Bind Services

---

The **[BindService]** attribute gives an element a reference to a [service](../services.md) registered in the [Application Container](../application/container.md), such as the `AssetsService`, the `GraphicsPresenter` or a service of your own.

```csharp
// The graphics context registered by the launcher of the profile.
[BindService]
private GraphicsContext graphicsContext;
```

> [!NOTE]
> `[BindService]` works inside components, scene managers and services. It resolves the member type from the container exactly as `Application.Current.Container.Resolve()` would, so anything registered there can be bound, including interfaces and base classes that match a single registration.

## Parameters

| Parameter | Default | Description |
| --- | --- | --- |
| `isRequired` | `true` | When `true`, the element does not attach unless the container returns an instance. When `false`, the member is left `null` if nothing is registered for its type. |

### isRequired

The project template registers these services in the `MyApplication` constructor:

```csharp
this.Container.Register<Settings>();
this.Container.Register<Clock>();
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

So this component attaches, because `AssetsService` is registered:

```csharp
public class MyComponent : Component
{
    [BindService]
    private AssetsService assetsService;

    // ...
}
```

This one does not, until you register a `ScoreService` (see [Services](../services.md#register-a-service)):

```csharp
public class MyComponent : Component
{
    [BindService]
    private ScoreService scoreService;

    // ...
}
```

With `isRequired: false`, the component attaches in both cases and `scoreService` is `null` when the service is missing:

```csharp
[BindService(isRequired: false)]
private ScoreService scoreService;
```

> [!TIP]
> A service registered by type is created the first time it is resolved, so binding it is also what brings it to life. See [Register a Service](../services.md#register-a-service).

## List Bindings

A `List<T>` member receives every registered object whose type is `T` or derives from it, which is how you collect several implementations of one interface:

```csharp
public interface IScoreListener
{
    void OnScoreChanged(int score);
}
```

```csharp
// Every registered object that implements IScoreListener.
[BindService]
private List<IScoreListener> scoreListeners;
```
