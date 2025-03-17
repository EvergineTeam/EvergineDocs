# Windows System

One of the main features that XRV offers is the _Windows System_, which includes built-in windows with customizable content. It also provides built-in alert and confirmation dialogs that you can incorporate into your UI logic to notify users or ask for confirmation, allowing different actions based on user choices.

![dialogs snapshot](images/windows_system_main.jpg)

## Windows Interaction

When a window is created, it includes default buttons that allow users to modify the window’s behavior or visibility.

- The window’s position can be changed, with two available positioning modes:
    - ![window follow](images/follow.png) **Follow mode**: the window will follow the user if they move more than 0.6 meters away. In this mode, the window also reorients itself to face the user.
    - ![window pin](images/pin.png) **Pinned mode**: when activated, the window remains fixed in its current position and orientation. In this mode, users can adjust the window’s position and orientation using the pinch gesture on its title bar or content area.
- Press ![window close](images/close.png) to close the window.

## Create and Show a Window Programmatically

To create a window, access the _Windows System_ exposed by _XrvService_. Each window has configurable options, detailed below. You can create as many windows as needed.

```csharp
var xrv = Application.Current.Container.Resolve<XrvService>();
var windowSystem = xrv.WindowSystem;

// Setting Window
var window = xrv.WindowSystem.CreateWindow(config =>
{
    config.Title = "Window #1";
    config.Size = new Vector2(0.3, 0.2);
});

// Show window (empty in this case)
window.Open();
```

Windows have several components:
- **Title bar**: located at the top, it includes action buttons.
- **Back plate**: shares the same material as the title bar and contains an optional logo image..
- **Front plate**: drawn over the back plate, intended to be placed behind the window’s contents.

![dialogs snapshot](images/windows_system_window_parts.jpg)

### Window Instance Options

Each window instance has options that developers can customize. You can open or close any window programmatically or subscribe to events for window opening and closing.

| Properties             | Description                                                                             |
| ------------------- | --------------------------------------------------------------------------------------- |
| `AllowPin`   | Disables the toggle button for window positioning if set to false. |
| `DistanceKey`   | Specifies the distance key to position the window once opened. |
| `EnableManipulation`   | Disables window orientation and positioning adjustments when pinned, if set to false. |

| Methods             | Description                                                                             |
| ------------------- | --------------------------------------------------------------------------------------- |
| `Open`   | Opens the window instance. |
| `Close`   | Closes the window instance. |

| Events             | Description                                                                             |
| ------------------- | --------------------------------------------------------------------------------------- |
| `Opened`   | Triggered when the window is opened. |
| `Closed`   | Triggered when the window is closed. |

### Window Instance Configuration

Use the configuration callback to adjust the window’s display settings.

| Properties             | Description                                                                             |
| ------------------- | --------------------------------------------------------------------------------------- |
| `Content`   | Sets an entity for window contents, such as buttons, 3D text, or images. |
| `DisplayFrontPlate`   | Hides the front plate if set to false. |
| `DisplayBackPlate`   | Hides the back plate if set to false. |
| `DisplayLogo`   | Toggles logo visibility on the back plate. |
| `FrontPlateOffsets`   | XY offset of the front plate relative to the back plate. |
| `FrontPlateSize`   | Sets width and height of the front plate in meters. |
| `LocalizedTitle`   | Sets a [localized title](../localization.md) callback for the window. |
| `LogoMaterial`   | Changes the default logo image by setting a custom material. |
| `Size`   | Defines the window’s width and height in meters. |
| `Title`   | Specifies a fixed title string. |

### How-To: Create Custom Window with Contents

To create a custom window, start by determining the size of its contents. Follow these steps:

1. Create a new scene containing the window contents, which will be saved as a prefab and loaded into the window.
2. Create a mesh with _BorderlessFrontPlate_ material as a size guide.
3. Adjust _PlaneMesh_ width and height to the desired size. 
![windows how-to](images/windows_system_how-to.png)
4. Design your window layout.
5. Create a prefab from your contents entity, excluding the guide reference.
6. Instantiate your window in code, setting its size to match the guide.

```csharp
var contentsSize = new Vector2(0.214f, 0.173f);
var window = windowsSystem.CreateWindow(config => 
{
    config.Size = contentsSize;
    config.FrontPlateSize = contentsSize;
    config.Content = this.assetsService.Load<Prefab>(<Prefab GUID here>).Instantiate();
});
```

## Built-In Dialogs

_XRV_ also includes two dialog types for user prompts:

- **Alert dialog**: Used to inform users without requiring them to make a choice.
- **Confirmation dialog**: Requests user confirmation before proceeding with an action, such as removing a 3D model.

Only one dialog can be open at a time to prevent user confusion and ensure a clear interaction flow. If a new dialog is opened while another is still displayed, the existing dialog will automatically close, allowing the user to focus on the most recent prompt.

```csharp
var dialog = windowsSystem.ShowConfirmationDialog(...); // or ShowAlertDialog
dialog.Closed += Dialog_Closed;

private void Dialog_Closed(object sender, EventArgs e)
{
    if (dialog is ConfirmDialog confirm)
    {
        dialog.Closed -= this.Dialog_Closed;

        if (confirm.Result == confirm.AcceptOption.Key)
        {
            // Do something only if the user taps on the accept option            
        }
    }
}
```

In the example, we subscribe to the _Closed_ event and unsubscribe in the callback. Only one dialog can be open at a time, so opening a new dialog will close any existing one.

**Alert Dialog**

| Result Value             | Description                                                                                         |
| ------------------- | --------------------------------------------------------------------------------------------------- |
| AlertDialog.AcceptKey | When the user presses the dialog _Accept_ button. |
| _null_ | When the user presses the dialog _Close_ button, or another part of the code invokes _ShowAlertDialog_. |

**Confirmation Dialog**

| Result Value             | Description                                                                                                       |
| ------------------- | ----------------------------------------------------------------------------------------------------------------- |
| ConfirmationDialog.AcceptKey | When the user presses the dialog _Accept_ button. |
| ConfirmationDialog.CancelKey | When the user presses the dialog _Cancel_ button. |
| _null_ | When the user presses the dialog _Close_ button, or another part of the code invokes _ShowConfirmationDialog_. |

## Additional Windows System Features

The _Windows System_ provides additional properties for customization:

| Properties             | Description                                                                             |
| ------------------- | --------------------------------------------------------------------------------------- |
| `Distances`   | Registers or modifies predefined window distances. |
| `OverrideIconMaterial`   | Sets a custom material for the default window logo, avoiding per-instance updates. |

### Window Distances Definition

_XRV_ includes predefined window distances, but you can add or modify distances as needed.

| Distance Key | Value (in meters) | Usage                                            |
|--------------|-------------------|--------------------------------------------------|
| `NearKey`      | 0.35              | Default distance for alert and confirmation dialogs. |
| `MediumKey`    | 0.5               | Default for other windows.                       |
| `FarKey`       | 1                 | Available for custom use.                 

Override or add new distances using _SetDistance_:

```csharp
// override an existing key
windowsSystem.Distances.SetDistance(Xrv.Core.UI.Windows.Distances.NearKey, 0.45f);

// adding a new key
windowsSystem.Distances.SetDistance("custom", 0.5f);

// use distance key in a window
window.DistanceKey = "custom";
```

## Examples

### Using the Windows System in a Component

```csharp
public MyComponent : Component 
{
    [BindService]
    private XrvService xrvService = null;

    private windowSystem =>  xrvService.WindowSystem;

    private void ShowAlert()
    {
        var dialog = this.windowSystem.ShowAlertDialog("Alert Title", "Sample Content.", "OK");
        dialog.Closed += this.OnAlertClosed();
    }

    private void ShowConfirmation()
    {
        var dialog = this.windowSystem.ShowConfirmationDialog("Confirmation Title", "Sample Content.", "No", "Yes");
        dialog.Closed += this.OnConfirmationClosed();
    }

    private void OnAlertClosed(object sender, EventArgs e)
    {
        if (sender is AlertDialog dialog) 
        {
            dialog.Closed -= this.OnAlertClosed();
        }
    }

    private void OnConfirmationClosed(object sender, EventArgs e)
    {
        if (sender is ConfirmationDialog dialog) 
        {
            dialog.Closed -= this.OnConfirmationClosed();
        }
    }
}
```