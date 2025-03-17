# Help System

Another predefined window that _XRV_ offers is the _Help_ window. This window is designed to contain text and images that guide application users in learning how to use the application. It operates in the same way as the [Settings System](settings_system.md): you can associate a help section with your custom module or add and remove items programmatically. To open the _Help window_, simply press the help hand menu button found in the hand menu.

![settings hand menu](images/help_system_menu.png)

This window is a _TabbedWindow_ and you have two ways of adding new elements:
- **Adding a help section to your custom module**

```csharp
public class MyModule : Module
{
    public override TabItem Help { get; protected set; }

    public override void Initialize(Scene scene)
    {
        this.Help = new TabItem()
        {
            Name = () => "Module Name",
            Contents = this.CreateContents() // Entity with help item contents.
        };
    }
}
```

- **Using the _HelpSystem_ API**

```csharp
var help = this.xrvService.HelpSystem;
var item = new TabItem
{
    Order = 1,
    Name = "My item",
    Contents = () => this.CreateContents(),
};
help.AddTabItem(item);
```

You can also remove an existing item using the _RemoveTabItem_ method.