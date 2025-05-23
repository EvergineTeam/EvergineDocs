# Application Container

The **Application Container** is a class responsible for storing objects that will be accessed throughout the entire application. The application itself does not have inherent functionality; all logic is implemented using instances registered in the Container.

The application Container can be accessed using the `Container` property in the Application class.

Here you will register all [Services](../services.md) of your application, among other instances to control your project (like the [GraphicContext](../../graphics/low_level_api/graphicscontext.md) to expose the graphic API, AssetsService to control the asset library of your application, and [ScreenContextManager](../scenes/using_scenes.md) to control the scenes that will be played in your application).

> [!TIP]
> In general, in the **Container**, you will register all Services and logic that will be consumed by every Scene or Component in your Application.

> [!NOTE]
> There can be only one instance per Type in the Container. Every object registered here is treated as a Singleton.

![Application Container](images/application_container.png)

## Using the Container

### Register Instances

You can register elements inside the Container in two ways:

#### Register a Type

You can register a type in the Container. If this functionality is needed in the future, the Container will create an instance and will offer it to everyone that requires this instance. This is done by the `Container.RegisterType<T>()` method:

| Method | Description |
| --- | --- |
| `RegisterType<T>()` | Registers the specified type `T` to the container. |

A small example:

 ```csharp
 public partial class MyApplication : Application
    {
        public MyApplication()
        {
            // Previous code :)

            // You can register the service by type...
            this.Container.RegisterType<MyService>();
        }
    ...
 ```

#### Register an Instance

On the other hand, you can register an instance directly. This is useful if you want to properly initialize the service or offer an implementation of an abstract class:

| Methods | Description |
| --- | --- |
| `RegisterInstance(T instance)` | Registers the instance object into the Container. It will be associated with the type of the instance. |
| `RegisterInstance<T>(T instance)` | Registers the instance object into the Container. It will be associated with the type of the generic type `<T>`. The instance parameter type must be a subclass of `<T>`.  |

A small example:
 ```csharp
 public partial class MyApplication : Application
    {
        public MyApplication()
        {
            // Previous code :)

            // Register the service instance directly...
            this.Container.RegisterInstance(new MyService());

            // You can register an instance specifying a parent class to indicate
            // the type that you want to expose.
            // In this case, you are offering the DX11 implementation when someone requests the GraphicsContext...
            this.Container.RegisterInstance<GraphicsContext>(new DX11GraphicsContext());
        }
    ...
 ```

### Get Instances

It is easy to obtain instances from the Application Container.

#### Using [BindService] Tag Attribute

You can use the [BindService] attribute in your Component, SceneManager, or even from other Services to automatically inject the Service instance into your property.

```csharp
using Evergine.Framework;
using System;

namespace MyProject
{
    public class MyBehavior : Behavior
    {
        // Use the BindService attribute on top of the property or field 
        // where you want to inject the Service
        [BindService]
        private MyService myService = null;

        protected override void Update(TimeSpan gameTime)
        {
            this.myService.DoRequest();
        }
    }
}
```

#### Using Resolve() Methods

The Container has the following methods to obtain instances:

| Methods | Description |
| --- | --- |
| `T Resolve<T>()` | Obtains the instance of the specified type `<T>`. |
| `object Resolve(Type type)` | Another way to obtain an object, but without C# generics.  |


 ```csharp
using Evergine.Framework;
using System;

namespace MyProject
{
    public class MyBehavior : Behavior
    {
        private MyService myService = null;

        protected override bool OnAttached()
        {            
            // Use the Resolve<Type> method from the Application Container....
            this.myService = Application.Current.Container.Resolve<MyService>();

            return base.OnAttached();
        }

        protected override void Update(TimeSpan gameTime)
        {
            this.myService.DoRequest();
        }

        protected override bool OnDetached()
        {
            base.OnDetached();

            // Release the reference when a component is being detached...
            this.myService = null;
        }
    }
}
 ```