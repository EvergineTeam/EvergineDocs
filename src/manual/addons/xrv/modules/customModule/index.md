# Create your own XRV modules

---

A module packages a feature so you can reuse it in several XRV applications. To create one, derive from the abstract `Module` class (namespace `Evergine.Xrv.Core.Modules`). Depending on the properties you set, XRV adds a hand menu button, a tab in the settings window, a tab in the help window, and voice commands for your module.

XRV calls `Initialize` once, when you call `XrvService.Initialize`. Create the module's entities and windows there, and set the properties that XRV reads right after. When the user presses the module's hand menu button, XRV calls `Run`, where you show or hide what you created.

## Module implementation

The following module shows and hides a 3D marker from the hand menu. `HandMenuButton`, `Help`, and `Settings` are abstract properties with a protected setter, so implement them as auto-properties and assign them in `Initialize`.

```csharp
using System.Collections.Generic;
using Evergine.Components.Graphics3D;
using Evergine.Framework;
using Evergine.Framework.Graphics;
using Evergine.Xrv.Core.Modules;
using Evergine.Xrv.Core.UI.Buttons;
using Evergine.Xrv.Core.UI.Tabs;

public class MarkerModule : Module
{
    private Entity marker;

    public override string Name => "Marker";

    public override ButtonDescription HandMenuButton { get; protected set; }

    public override TabItem Help { get; protected set; }

    public override TabItem Settings { get; protected set; }

    public override IEnumerable<string> VoiceCommands => null;

    public override void Initialize(Scene scene)
    {
        this.HandMenuButton = new ButtonDescription
        {
            IsToggle = true,
            IconOn = EvergineContent.Materials.MarkerIcon,
            IconOff = EvergineContent.Materials.MarkerIcon,
            TextOn = () => "Hide marker",
            TextOff = () => "Show marker",
        };

        this.Help = new TabItem
        {
            Name = () => "Marker",
            Contents = () => new Entity(), // Replace with your help contents.
        };

        // Created disabled: the hand menu button turns it on.
        this.marker = new Entity("Marker") { IsEnabled = false }
            .AddComponent(new Transform3D())
            .AddComponent(new MaterialComponent())
            .AddComponent(new SphereMesh() { Diameter = 0.05f })
            .AddComponent(new MeshRenderer());
        scene.Managers.EntityManager.Add(this.marker);
    }

    public override void Run(bool turnOn)
    {
        this.marker.IsEnabled = turnOn;
    }
}
```

`EvergineContent.Materials.MarkerIcon` stands for the ID of an icon material in your project.

| Method | Description |
| --- | --- |
| `Initialize(Scene scene)` | Called once when XRV initializes. Add the module's entities, create its windows, and set the properties below. |
| `Run(bool turnOn)` | Called when the user presses the module's hand menu button. `turnOn` is the toggle state, or always `true` for a non-toggle button. |

| Property | Required | Description |
| --- | --- | --- |
| `Name` | Yes | Name of the module. |
| `HandMenuButton` | No | When set, XRV adds this button to the hand menu. |
| `Help` | No | When set, XRV adds this tab to the help window. |
| `Settings` | No | When set, XRV adds this tab to the settings window. |
| `VoiceCommands` | No | When set, XRV registers these keywords with the [voice system](../../voice_commands.md). |

## Installation

Register the module when you create the `XrvService`:

```csharp
var xrv = new XrvService()
    .AddModule(new MarkerModule());
```

`AddModule` throws an exception if you add two modules of the same type. From other code, `xrv.FindModule<MarkerModule>()` returns the registered instance.
