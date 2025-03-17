# Settings System

_XRV_ provides a default window where you can include specific settings for your application or modules. It also includes a section for general settings provided by the core library, such as enabling or disabling voice commands. To open the _Configuration_ window, simply press the ![settings hand menu](images/settings.png) button found in the hand menu.

![settings hand menu](images/settings_system_panel.png)

This window is a _TabbedWindow_, and you have two ways to add new elements:

- **Adding a configuration section to your custom module**

```csharp
public class MyModule : Module
{
    public override TabItem Settings { get; protected set; }

    public override void Initialize(Scene scene)
    {
        this.Settings = new TabItem()
        {
            Name = () => "Module Name",
            Contents = this.CreateContents() // Entity with configuration item contents.
        };
    }
}
```

- **Using the _SettingsSystem_ API**

```csharp
var settings = this.xrvService.SettingsSystem;
var item = new TabItem
{
    Order = 1,
    Name = "My item",
    Contents = () => this.CreateContents(),
};
settings.AddTabItem(item);
```

You can also remove an existing item using the _RemoveTabItem_ method.