# Services

---

In Evergine, **Services** are elements that allow you to manage global features. Service functionality can be accessed from every Scene, Component, or Behavior in your application. Services can also be bound to any [component](component_arch/components/index.md) or even other services using the [application container](application/index.md).

Developing custom Evergine services is useful for integrating your application with external services or APIs.

There are two kinds of services:
 
 * **Basic Services**: This type of service is very useful to expose functionality or to execute global tasks.
 * **Updatable Services**: This is a Service subclass with an `Update()` method that allows running an action during every application update cycle.

## Creating a Service

To create a basic Service, add a class in Visual Studio and extend the `Service` class:
 
```csharp
using Evergine.Framework.Services;

namespace MyProject
{
    public struct MyServiceData
    {
        public string name;
        public int requests;
    }

    public class MyService : Service
    {
        private MyServiceData data;

        public MyServiceData Data 
        {
            get => this.data;
            private set => this.data = value;
        }

        public MyService()
        {
            this.data.name = "myService";
        }

        public void DoRequest()
        {
            this.data.requests++;
        }        
    }
}
``` 

### Creating an UpdatableService

To create an updatable service, add a class in Visual Studio and extend the `UpdatableService` class.

```csharp
using Evergine.Framework.Services;

public class MyUpdatableService : UpdatableService
{
    public override void Update(TimeSpan gameTime)
    {
        // Called on every application update cycle...
    }        
}
``` 

## Registering a New Service in Your Application

Before using a service, it is necessary to register it in the [application container](application/index.md) where you can register the type or an instance.

```csharp
public partial class MyApplication : Application
{
    public MyApplication()
    {
        // Previous code :)

        // You can register the service by type...
        this.Container.Register<MyService>();

        // Or register the service using an instance...
        this.Container.RegisterInstance(new MyService());            
    }
}
```

## Using Services

Accessing registered services can be done in two ways:

### Using the [BindService] Attribute

You can use the [BindService] attribute in your Component, SceneManager, or even from another service to automatically inject the Service instance into your property.

```csharp
using Evergine.Framework;
using System;

namespace MyProject
{
    public class MyBehavior : Behavior
    {
        // Use the BindService attribute on top of the property in which you want to inject the Service
        [BindService]
        private MyService myService = null;

        protected override void Update(TimeSpan gameTime)
        {
            this.myService.DoRequest();
        }
    }
}
```

### Using the Application Container

On the other hand, you can obtain the Service instance directly from the Application Container.

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
            // Use the Resolve<Type> method from the Application Container...
            this.myService = Application.Current.Container.Resolve<MyService>();

            return base.OnAttached();
        }

        protected override void Update(TimeSpan gameTime)
        {
            this.myService.DoRequest();
        }

        protected override bool OnDetached()
        {
            // Release the reference when a component is being detached...
            this.myService = null;
        }
    }
}
```