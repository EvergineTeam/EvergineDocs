# OpenXR Platform

![OpenXR sits between applications and the runtimes of every conformant device](images/openxr_overall.png)

`OpenXRPlatform` is the [`XRPlatform`](../xrplatform.md) implementation for OpenXR, in the **Evergine.OpenXR** package. It creates the OpenXR instance and session, renders the scene into the runtime's swapchains, and turns the runtime's actions and extensions into Evergine devices, hand joints and passthrough layers.

Every OpenXR template creates one in its launcher project. You change its configuration there: which extensions to request, which controllers to support, and how the tracking space is anchored.

## Creating the platform

`OpenXRPlatform` has two constructors:

| Constructor | Description |
| --- | --- |
| `OpenXRPlatform()` | No optional extensions. Controllers use the Khronos simple controller profile. |
| `OpenXRPlatform(string[] extensionsToEnable, OpenXRInteractionProfile[] interactionProfiles = null)` | Requests the given [extensions](#extensions) and registers the given [interaction profiles](#interaction-profiles). A `null` profile list falls back to `DefaultInteractionProfiles.KhronosSimpleProfile`. |

This is how the **Android Meta Quest (OpenXR)** template creates it, in `MainActivity.cs`:

```csharp
// Create mirror display...
FrameBuffer frameBuffer = null!;
var mirrorDisplay = new Display(surface, frameBuffer);

// Create OpenXR Platform
openXRPlatform = new OpenXRPlatform(
    new string[]
    {
            "XR_EXT_hand_tracking",         // Enable hand tracking in OpenXR application
            "XR_FB_hand_tracking_aim",      // Allow to use hand gestures in Meta Quest devices
            "XR_FB_hand_tracking_mesh",     // Obtain hand mesh in Meta Quest devices

        // "XR_FB_passthrough",         // Enable Passthrough in Meta Quest devices
        // "XR_FB_triangle_mesh",       // Allow to project Passthrough on Meshes

        // "XR_META_simultaneous_hands_and_controllers", // Allow to use hands and controllers simultaneously
    },
    new OpenXRInteractionProfile[]
    {
            DefaultInteractionProfiles.OculusTouchProfile
    })
{
    // UseSimultaneousHandsAndControllers = true, // Enable using simultaneously the hands and controllers
    RenderMirrorTexture = false,
    ReferenceSpace = ReferenceSpaceType.Stage,
    MirrorDisplay = mirrorDisplay,
};

application.Container.RegisterInstance(openXRPlatform);

// Register the displays...
var graphicsPresenter = application.Container.Resolve<GraphicsPresenter>();
graphicsPresenter.AddDisplay("DefaultDisplay", openXRPlatform.Display);
graphicsPresenter.AddDisplay("MirrorDisplay", mirrorDisplay);
```

The [Pico](pico.md) and [Windows](windows.md) templates differ only in the extension list, the interaction profiles, and the graphics context they create before this code. [XR Platform](../xrplatform.md#creating-and-registering-a-platform) explains the four steps every launcher follows.

> [!IMPORTANT]
> Set every property in the object initializer, before `RegisterInstance`. The platform reads the extension list and `ApplicationName` when it creates the OpenXR instance, and `FormFactor`, `ViewConfiguration`, `ReferenceSpace` and `OverSampling` when it creates the session, both during `application.Initialize()`. Changing them afterwards has no effect.

## Properties

| Property | Default | Description |
| --- | --- | --- |
| **ReferenceSpace** | `Stage` | The origin of the tracking space. See [Reference spaces](#reference-spaces). |
| **FormFactor** | `HeadMountedDisplay` | The kind of device to request from the runtime: `HeadMountedDisplay` or `HandheldDisplay`. If no device of that kind is found, the platform logs it and asks again every second. |
| **ViewConfiguration** | `PrimaryStereo` | `PrimaryStereo` renders one view per eye. `PrimaryMono` renders a single view, for handheld displays. |
| **OverSampling** | 1.0 | Multiplier of the resolution the runtime recommends for the swapchain. Values above 1 sharpen the image at a GPU cost, and the result is clamped to the runtime's maximum. |
| **ApplicationName** | `"Evergine.OpenXR"` | The name sent to the runtime when the instance is created. Some runtimes show it in their dashboards. |
| **UseSimultaneousHandsAndControllers** | `false` | Tracks hands and controllers at the same time, so a hand can be tracked while the other holds a controller. Needs `XR_META_simultaneous_hands_and_controllers`. Unlike the other properties, you can change it while the application runs. |
| **ExtensionsToEnable** | The constructor argument | The extensions requested at startup. Read-only. |
| **GraphicBackend** | Created on attach | The OpenXR integration of the graphics backend: DirectX 11, Vulkan or OpenGL. Any other backend throws `InvalidOperationException` when the platform attaches. |

`OpenXRPlatform` also inherits the [`XRPlatform` properties](../xrplatform.md#properties): `MirrorDisplay`, `RenderMirrorTexture`, `MSAASampleCount`, `NearClipDistance`, `FarClipDistance`, and the `InputTracking`, `RenderableModels` and `Passthrough` subsystems.

### Reference spaces

The reference space decides where the origin of the tracking space is, and so where the parent of your camera sits in the real world.

| Value | Origin | Use it for |
| --- | --- | --- |
| **Stage** (default) | On the floor, at the centre of the play area the user set up | Standing and room-scale experiences. The height of the camera above its parent is the user's real eye height. |
| **Local** | At the head position when the application started, facing forward | Seated experiences. Content does not depend on the floor. |
| **View** | At the head, moving with it | Head-locked content only. Rarely what you want for a whole scene. |
| **Unbounded** | World-locked, with no play area limit | Large spaces where the user walks far from the start point. Requires the `XR_MSFT_unbounded_reference_space` extension in the constructor list. |

```csharp
// In the launcher: a seated experience, rendered 20% above the recommended resolution.
openXRPlatform = new OpenXRPlatform(
    new[] { "XR_EXT_hand_tracking" },
    new[] { DefaultInteractionProfiles.OculusTouchProfile })
{
    ReferenceSpace = ReferenceSpaceType.Local,
    OverSampling = 1.2f,
    MirrorDisplay = mirrorDisplay,
};
```

## Extensions

OpenXR features beyond the core are **extensions**. `OpenXRPlatform` enables some by itself and the rest only when you pass their names to the constructor.

Always enabled when the runtime supports them:

* The extension of the graphics backend: `XR_KHR_D3D11_enable`, `XR_KHR_vulkan_enable` or `XR_KHR_opengl_enable`.
* `XR_KHR_composition_layer_depth`, which lets the runtime use the depth buffer to reproject frames.

Extensions that Evergine uses when you request them:

| Extension | What it enables in Evergine |
| --- | --- |
| `XR_EXT_hand_tracking` | Articulated hand devices for [`TrackXRArticulatedHand`](../input_tracking/trackxrarticulatedhand.md). |
| `XR_FB_hand_tracking_aim` | A pinch reports as the hand's `Trigger` and `TriggerButton`, and the hand gets an aim `Pointer`. Meta Quest. |
| `XR_FB_hand_tracking_mesh` | A skinned hand model for [`XRDeviceRenderableModel`](../input_tracking/trackxrarticulatedhand.md#render-the-hands). Meta Quest. |
| `XR_FB_passthrough` | The [passthrough](../passthrough.md) subsystem. Meta Quest. |
| `XR_FB_triangle_mesh` | Passthrough projected on your own meshes (`XRPassthroughSurfaceMeshComponent`). Meta Quest. |
| `XR_META_simultaneous_hands_and_controllers` | The `UseSimultaneousHandsAndControllers` property. Meta Quest. |
| `XR_MSFT_unbounded_reference_space` | The `Unbounded` reference space. |

An extension the runtime does not support is skipped: the platform reports a warning through the graphics context's validation layer, when one is enabled, and starts without it. The feature it drives then stays unavailable, for example `Passthrough` stays `null`.

> [!NOTE]
> Some extensions also need permissions or features in the Android manifest. See [Meta Quest](metaquest.md#optional-features) for passthrough.

## Interaction profiles

An **interaction profile** tells the runtime which physical controller you expect and how its inputs map to Evergine's actions. The runtime picks the profile that matches the controller in the user's hands. If none of the profiles you registered matches, the controller never connects, and `TrackXRController.IsConnected` stays `false`.

`DefaultInteractionProfiles` provides profiles for the common controllers:

| Profile | Interaction path | Used by |
| --- | --- | --- |
| `KhronosSimpleProfile` | `/interaction_profiles/khr/simple_controller` | The default when you pass no profiles. Select and menu buttons only. |
| `OculusTouchProfile` | `/interaction_profiles/oculus/touch_controller` | Meta Quest template, Windows template |
| `PicoNeo3Profile` | `/interaction_profiles/pico/neo3_controller` | Pico template |
| `HTCViveControllerProfile` | `/interaction_profiles/htc/vive_controller` | Windows template |
| `ValveIndexControllerProfile` | `/interaction_profiles/valve/index_controller` | Windows template |
| `MixedRealityMotionControllerProfile` | `/interaction_profiles/microsoft/motion_controller` | Windows template |
| `OculusGoProfile` | `/interaction_profiles/oculus/go_controller` | Windows template |

Each profile maps Evergine action names to OpenXR input paths in its `SupportedComponents` dictionary. These are the actions and the part of the controller state they fill:

| Action | Fills |
| --- | --- |
| `pose` | The device pose that moves the entity. |
| `aimpose` | `Pointer`. |
| `trigger` | `ControllerState.Trigger` (0 to 1). |
| `triggerclick` | `ControllerState.TriggerButton`. |
| `gripclick` | `ControllerState.Grip`. |
| `thumbstickx`, `thumbsticky` | `ControllerState.ThumbStick`. |
| `thumbstickclick` | `ControllerState.ThumbStickButton`. |
| `menu` | `ControllerState.Menu`. |
| `button1`, `button2` | `ControllerState.Button1` and `ControllerState.Button2`. |

To support a controller that has no default profile, or to map its inputs differently, create an `OpenXRInteractionProfile` with its interaction path, the user paths it applies to, and the input path for each action, then pass it to the constructor with the others. A path that starts with `/input` applies to every user path. A full path such as `/user/hand/left/input/x/click` applies to that hand only, and several paths are separated by spaces.

```csharp
using System.Collections.Generic;
using Evergine.OpenXR;

// The simple controller has no trigger: report its select button as the trigger button.
var simpleProfile = new OpenXRInteractionProfile()
{
    InteractionPath = "/interaction_profiles/khr/simple_controller",
    UserPaths = new List<string>() { "/user/hand/left", "/user/hand/right" },
    SupportedComponents = new Dictionary<string, string>()
    {
        { "triggerclick", "/input/select/click" },
        { "menu", "/input/menu/click" },
        { "pose", "/input/grip/pose" },
        { "aimpose", "/input/aim/pose" },
    },
};
```

## In this section

* [Meta Quest](metaquest.md)
* [Pico](pico.md)
* [Windows (PC VR)](windows.md)
