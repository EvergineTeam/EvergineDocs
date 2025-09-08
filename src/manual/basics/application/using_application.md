# Using Application

In this document, you will learn the common usages and tips for dealing with the Evergine Application class.

## Default Application

After creating a new Evergine project (check the [Project Structure](../project_structure.md) document for further details), you will find a `MyApplication` class that inherits from `Application`:

```csharp
public partial class MyApplication : Application
{
    public MyApplication()
    {
        // Register services into application container...
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
    }

    public override void Initialize()
    {
        base.Initialize();

        // Get ScreenContextManager...
        var screenContextManager = this.Container.Resolve<ScreenContextManager>();
        var assetsService = this.Container.Resolve<AssetsService>();

        // Load the scene asset and instantiate it into a MyScene class instance...
        var scene = assetsService.Load<MyScene>(EvergineContent.Scenes.MyScene_wescene);
                
        // Use ScreenContextManager service to navigate to the main scene (MyScene)...
        ScreenContext screenContext = new ScreenContext(scene);
        screenContextManager.To(screenContext);
    }
}
```

Interesting points:
* The `MyApplication` constructor is used to register all available services. While you can register services elsewhere in your code, it is a good practice to register them here.
* The `Initialize()` method is invoked to initialize your application. In this method, the `ScreenContextManager` is notified of the scene that is going to be played.

> [!NOTE]
> You can register services in any part of your code. For example, if you want to register the `GraphicsContext`, we suggest registering it in the Profile Project. (I recommend again checking the [**Project Structure**](../project_structure.md) document). For example, you will register the `DX11GraphicsContext` in the Windows profile project, or `VulkanGraphicsContext` in the Android profile.

## Application Lifecycle Methods

The application class will invoke several methods to maintain its lifecycle and helps developers to keep things running smoothly.

| Method | Description |
| --- | --- |
| **Initialize()** | Initializes all aspects needed to start your application. Here, you will usually navigate to the Scene to be played, and set up initial functionality or services to be consumed during execution. |
| **UpdateFrame()** | This method executes the Update cycle of your application. It will notify all `UpdatableServices` to be updated, including the `ScreenContextManager`, which will propagate this invocation to the Scene and finally your Components. You can override this method to customize the Update loop. |
| **DrawFrame()** | This method is triggered to draw your application. All Scenes will be rendered, and the `GraphicsPresenter` service will present the rendering results in all displays (windows, XR headsets, off-screen rendering, etc.). You can override this method to customize the Draw loop. |
| **Destroy()** | Use this method to dispose of all resources of your application. |

## Check if the Application Is Running Inside Evergine Studio

When you are developing components or functionality, you may need to check if your code is running inside Evergine Studio or outside.

| Property | Description |
| --- | --- |
| **IsEditor** | Application property that indicates if the application is running in **Evergine Studio**.  |

 ```csharp
public class MyBehavior : Behavior
{
    [BindComponent]
    private Transform3D transform;

    protected override void Start()
    {    
        // Reset the position to Zero only if it is not Evergine Studio...        
        if (!Application.Current.IsEditor)
        {
            this.transform.Position = Vector3.Zero;
        }
    }
}
```