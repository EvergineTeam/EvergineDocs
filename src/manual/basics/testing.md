# Testing

---

In all of its forms, testing has became a good practice in the software industry. From speeding debugging scenarios up, to avoiding regressions, for having two examples, it has demostrated how efficient the technique is once we developers embrace it.

Testing applications made with Evergine can be difficult from the instant some of its pieces are involved: components, behaviors, drawables, services and so on. In the end, Evergine is highly coupled to a graphics backend, thus a GPU, and such are not usually available in every machine, nor help to automate the testing scenario.

## Approach

We officially provide Evergine.Mocks, distributed in its own NuGet package, which enables testing applications made with Evergine (inspired on [Xamarin.Forms.Mocks](https://github.com/jonathanpeppers/Xamarin.Forms.Mocks)). Its single goal is to enable testing logic, leaving out of scope drawables or anything related to rendering.

Most of our applications contain a bunch of components (it-self, or behaviors/drawables) which contain logic. Such components, usually, consume other artifacts from outside:
- other components
- services
- managers
- entities from its hierarchy

Beacause of this, isolating a component for testing is quite complicated. However, we can rely on a mock Windows System which, in a headless fashion, replicates the same behavior the app would have.

## Set-up

1. Leave Application.Initialize() empty: refactor its entire logic into a separate public method, called from each WindowsSystem
   - This is needed to avoid tests to set the ScreenContext up and navigate to an actual Scene by default

```csharp
windowsSystem.Run(
    () =>
    {
        // Pull initialization logic from here...
        application.Initialize();
        // to here
        application.NavigateToMainScene();
    },
    () =>
    {
        [...]
    });
```

2. Create a new Class Library project targetting the same .NET version as the Evergine's one (the one referenced by every launcher)
   - We use to name it the same as the Evergine's one, adding the suffix ".Tests"
3. Add a package reference to any testing framework of your choice
   - We work with xUnit in a daily basis, but there are other options equally valid
4. Execute tests sequentially: Evergine currently does not support running tests in parallel
   - For example, you can configure it with xUnit by adding a new file AssemblyInfo.cs (if it is not already present) with the following line in it:
     ```csharp
     [assembly: Xunit.CollectionBehavior(DisableTestParallelization = true)]
     ```

## My first tests

Imagine you have the following component:

```csharp
public class MyComponent : Component
{
    public bool MyBooleanProperty { get; private set; }

    protected override void Start()
    {
        base.Start();

        this.MyBooleanProperty = true;
    }
}
```

If you would like to assure its logic, as simple as it is, does not change during time, you would end up debugging the app once and again and placing a breakpoint to check MyBooleanProperty's value. In a real app, this is much more complicated, obviously.

However, you can just add a few tests and 1) simplify the debugging process and 2) enforce its logic will not change:

```csharp
public class ComponentShould
{
    private readonly MyComponent component;

    private readonly MockWindowsSystem windowsSystem;

    public ComponentShould()
    {
        this.component = new MyComponent();
        var entity = new Entity()
            .AddComponent(this.component);
        var scene = new MockScene();
        scene.Add(entity);
        var application = new MyApplication();
        this.windowsSystem = MockWindowsSystem.Create(application, scene);
    }

    [Fact]
    public void KeepMyBooleanPropertyFalseBeforeStarting()
    {
        // Arrange

        // Act

        // Assert
        Assert.False(this.component.MyBooleanProperty);
    }

    [Fact]
    public void ChangeMyBooleanPropertyToTrueOnStart()
    {
        // Arrange

        // Act
        this.windowsSystem.RunOneLoop(TimeSpan.FromSeconds(1d / 60));

        // Assert
        Assert.True(this.component.MyBooleanProperty);
    }
}
```
