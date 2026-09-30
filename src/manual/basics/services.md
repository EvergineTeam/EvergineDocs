# Services

---

**Services** hold application-wide functionality in Evergine. A service lives in the [Application Container](application/container.md), outside any scene, so it survives scene changes and every scene, component and scene manager can reach the same instance. Write a service when you need global state or a single entry point to something outside the engine: a backend API, a save system, a device, analytics.

Evergine itself is built from services. `AssetsService`, `ScreenContextManager`, `GraphicsPresenter` and `Clock` are all services registered by the project template.

There are two kinds of services:

| Base class | Description |
| --- | --- |
| `Service` | Exposes functionality and global state. It follows the [lifecycle](lifecycle_elements.md) of every Evergine element, but it is not called every frame. |
| `UpdatableService` | A `Service` with an abstract `Update(TimeSpan gameTime)` method that the application calls once per frame, before the scenes are updated. |

## Create a Service

Add a class to your project that derives from `Service`:

```csharp
using Evergine.Framework.Services;

namespace MyProject
{
    public class ScoreService : Service
    {
        public int Score { get; private set; }

        public int BestScore { get; private set; }

        public void Add(int points)
        {
            this.Score += points;

            if (this.Score > this.BestScore)
            {
                this.BestScore = this.Score;
            }
        }

        public void ResetScore()
        {
            this.Score = 0;
        }
    }
}
```

A service can override the same lifecycle methods as a component (`OnLoaded()`, `OnAttached()`, `OnActivated()`, `Start()`, `OnDeactivated()`, `OnDetached()` and `OnDestroy()`) and can use `[BindService]` to depend on other services. See [Lifecycle of Elements](lifecycle_elements.md).

### Create an Updatable Service

Derive from `UpdatableService` when the service must do some work every frame. This one counts down a session time limit, independently of the scene that is playing:

```csharp
using System;
using Evergine.Framework.Services;

namespace MyProject
{
    public class SessionTimerService : UpdatableService
    {
        public TimeSpan Remaining { get; private set; } = TimeSpan.FromMinutes(5);

        public bool IsExpired => this.Remaining <= TimeSpan.Zero;

        public event EventHandler Expired;

        public override void Update(TimeSpan gameTime)
        {
            if (this.IsExpired)
            {
                return;
            }

            this.Remaining -= gameTime;

            if (this.IsExpired)
            {
                this.Expired?.Invoke(this, EventArgs.Empty);
            }
        }
    }
}
```

Updatable services are updated in the order in which they were created, and always before the [ScreenContextManager](application/screen_context_manager.md) updates the scenes, so a behavior that reads `Remaining` sees the value of the current frame. Unlike behaviors, `gameTime` here is not affected by the `Speed` of any scene.

## Register a Service

Before anything can use a service, register it in the [Application Container](application/container.md). Register it by type, or register an instance you create yourself:

```csharp
using Evergine.Framework;

namespace MyProject
{
    public partial class MyApplication : Application
    {
        public MyApplication()
        {
            // ... the services registered by the project template ...

            // By type: the container creates the instance the first time it is needed.
            this.Container.Register<ScoreService>();

            // By instance: the service exists from now on and is updated from the first frame.
            this.Container.RegisterInstance(new SessionTimerService());
        }
    }
}
```

> [!IMPORTANT]
> A service registered **by type** is created the first time something resolves it, through `[BindService]` or `Container.Resolve<T>()`. Until then it does not exist, so an `UpdatableService` that nobody resolves is never updated. Register an instance when the service must run from the first frame even though no one binds to it.

You can also add and configure services from Evergine Studio, without writing registration code. See [Manage services](../evergine_studio/settings/project_services.md). A service registered from code takes precedence over the same service configured in Evergine Studio.

## Use a Service

### With the [BindService] Attribute

The simplest way to get a service is to bind it. Evergine injects the instance before `OnAttached()` runs:

```csharp
using System;
using Evergine.Framework;

namespace MyProject
{
    public class PickupBehavior : Behavior
    {
        [BindService]
        private ScoreService scoreService;

        [BindService]
        private SessionTimerService sessionTimer;

        protected override void Update(TimeSpan gameTime)
        {
            if (!this.sessionTimer.IsExpired)
            {
                this.scoreService.Add(1);
            }
        }
    }
}
```

`[BindService]` works in components, scene managers and other services. See [Bind Services](bindings/bind_services.md) for the details.

### From the Application Container

You can also resolve the service yourself through `Application.Current.Container`. This is useful in classes that are not Evergine elements, or when the dependency is optional and decided at runtime:

```csharp
using System;
using Evergine.Framework;

namespace MyProject
{
    public class ScoreDisplay : Behavior
    {
        private ScoreService scoreService;

        protected override bool OnAttached()
        {
            this.scoreService = Application.Current.Container.Resolve<ScoreService>();

            // Refuse to attach if the service was never registered.
            return this.scoreService != null && base.OnAttached();
        }

        protected override void Update(TimeSpan gameTime)
        {
            // Draw this.scoreService.Score on screen...
        }

        protected override void OnDetached()
        {
            base.OnDetached();

            // Drop the reference so a detached component does not keep the service alive.
            this.scoreService = null;
        }
    }
}
```

> [!NOTE]
> `Resolve<T>()` returns `null` when nothing is registered for `T`. A required `[BindService]` in the same situation keeps the component from attaching (see [Binding Errors](bindings/index.md#binding-errors)).
