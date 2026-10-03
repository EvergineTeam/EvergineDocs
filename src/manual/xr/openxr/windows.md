# Windows (PC VR)

![A scene rendered in an XR headset](../images/xrsample.jpg)

The **Windows OpenXR (DirectX11)** template runs your scene on a PC and renders it into any headset connected to that PC through its OpenXR runtime: SteamVR headsets, Meta Quest over Link, Windows Mixed Reality headsets and others. The application also opens a desktop window that mirrors what the user sees, which is useful for spectators and for debugging.

The template uses DirectX 11 because `OpenXRPlatform` does not support DirectX 12, the backend of the default Windows template.

## Create the profile

Select **Windows OpenXR (DirectX11)** when you create a project, or add it later from **Project Settings** > **Profiles**. The profile is named **Windows.OpenXR**.

Before you run it, install the runtime of your headset (for example SteamVR or the Meta Quest PC app) and make it the **active OpenXR runtime** in its settings. `OpenXRPlatform` connects to whichever runtime Windows reports as active.

## What the template contains

The launcher project is a Windows Forms application (`net10.0-windows`) that references `Evergine.OpenXR`, `Evergine.DirectX11`, `Evergine.XAudio2` and `Evergine.Forms`. Its `Program.cs`:

1. Opens a window and creates a DirectX 11 graphics context with a swapchain for it.
2. Uses that window as the mirror display.
3. Creates `OpenXRPlatform` with no optional extensions and with the profiles of the most common PC controllers, so that whichever headset is plugged in gets working controllers.
4. Registers the platform, adds its display as `DefaultDisplay` and the window as `MirrorDisplay`, and calls `openXRPlatform.Update()` at the start of every frame.

```csharp
// Create OpenXR Platform
openXRPlatform = new OpenXRPlatform(
    new string[]
    {
        // OpenXR extensions to enable...
        //"XR_EXT_hand_tracking",         // Enable hand tracking in OpenXR application
        //"XR_FB_hand_tracking_aim",      // Allow to use hand gestures in Meta Quest devices
        //"XR_FB_hand_tracking_mesh",     // Obtain hand mesh in Meta Quest devices
    }
    ,
    new OpenXRInteractionProfile[]
    {
            // Interaction profile to use...
            DefaultInteractionProfiles.OculusTouchProfile,
            DefaultInteractionProfiles.HTCViveControllerProfile,
            DefaultInteractionProfiles.MixedRealityMotionControllerProfile,
            DefaultInteractionProfiles.ValveIndexControllerProfile,
            DefaultInteractionProfiles.OculusGoProfile,
    })
{
    RenderMirrorTexture = true,
    ReferenceSpace = ReferenceSpaceType.Stage,
    MirrorDisplay = mirrorDisplay
};
```

[XR Platform](../xrplatform.md#creating-and-registering-a-platform) shows the complete `ConfigureGraphicsContext` method and the frame loop of this template.

> [!TIP]
> Uncomment `XR_EXT_hand_tracking` to get articulated hands when the runtime supports them. An extension the runtime lacks is skipped with a warning, so enabling one is safe.

## Command-line options

The template's `Program.cs` parses these arguments:

| Argument | Effect |
| --- | --- |
| `-Width <pixels>` | Width of the mirror window. Default 1280. |
| `-Height <pixels>` | Height of the mirror window. Default 720. |
| `-Vsync` / `-NoVsync` | Turns vertical sync of the mirror window on (default) or off. |
| `-Windowed` / `-FullScreen` | Runs the mirror window windowed (default) or full screen. |

Without arguments, the template hides the console window.

## See also

* [OpenXR Platform](openxr_platform.md): every `OpenXRPlatform` property, reference spaces and interaction profiles.
* [OpenVR](../openvr.md): the SteamVR alternative, without a template.
