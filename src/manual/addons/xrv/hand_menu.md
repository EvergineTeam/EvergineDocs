# Hand Menu

The hand menu is one of XRV’s primary features, enabling interactive buttons on the user's wrist. It appears when the user turns their palm and is accessible for both left and right hands.

![Hand menu](images/hand_menu.jpg)

Each configured module in an XRV application can add a button to the hand menu by defining a _HandMenuButton_ property in the module’s definition class.

```csharp
public class MyModule : Module 
{
    public override MenuButtonDescription HandMenuButton { get; protected set; }

    public override void Initialize(Scene scene)
    {
        this.HandMenuButton = new MenuButtonDescription 
        {
            // Button configuration here
        };
    }
}
```
If _HandMenuButton_ is set to _null_, no button will be added to the menu for that module.

### Configuring Hand Menu Buttons
The following table details configurable elements for each button using _MenuButtonDescription_:

| Property | Description |
| ------ | ------------------- |
| **IconOn** | Material identifier when the button is _on_ for toggle buttons or the standard icon for non-toggle buttons. |
| **IconOff** | Material identifier when the button is _off_ (toggle buttons only). |
| **IsToggle** | Defines whether the button functions as a toggle. |
| **TextOn** | Text shown when the button is _on_ for toggle buttons, or standard text for non-toggle buttons. Supports localization via _Func\<string>_. |
| **TextOff** | Text when the button is _off_ (toggle buttons only), also supporting localization. |
| **VoiceCommandOn** | Voice command to activate the button in its _on_ state (toggle buttons only). Note: it was only supported on UWP - it's not applied in last version |
| **VoiceCommandOff** | Voice command to activate the button in its _off_ state (toggle buttons only). Note: it was only supported on UWP - it's not applied in last version |

### Attaching/Detaching the Hand Menu
The menu can be detached from the wrist by selecting the _Detach_ button at the top, transforming it into a floating window. Users can pin the detached menu in place or have it follow them. To reattach the menu to the wrist, press the detached menu's _Close_ button.

![Detached hand menu](images/hand_menu_detached.jpg)

### Adding Buttons Programmatically

In addition to module-defined buttons, buttons can be added or removed dynamically using _XrvService’s HandMenu_ property.

```csharp
var xrv = Application.Current.Container.Resolve<XrvService>();
var handMenu = xrv.HandMenu;
var buttonDefinition = new MenuButtonDescription 
{
    // Button configuration here
}

// adding a new button
handMenu.ButtonDescriptors.Add(buttonDefinition);

// removing a defined button
handMenu.ButtonDescriptors.Remove(buttonDefinition);
```

### Hand Menu Layout Customization

The hand menu layout cannot be modified directly. However, the number of buttons per column can be adjusted, with a minimum of 4 buttons per column to maintain functionality in detached mode.

```csharp
handMenu.ButtonsPerColumn = 5;
```

### Hand Menu Tutorial

A startup tutorial animation demonstrates how to display the menu by turning the hand, helping new users interact effectively.

![Hand menu tutorial](images/hand_menu_tutorial.jpg)

To disable this animation at startup, deactivate the flag after initializing XRV:

```csharp
var xrv = Application.Current.Container.Resolve<XrvService>();
xrv.Initialize(this);
xrv.HandMenu.DisplayTutorial = false;
```