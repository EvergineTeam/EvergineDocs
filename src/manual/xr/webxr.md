# WebXR

![An augmented reality experience](images/ar.jpg)

`WebXRPlatform` is the [`XRPlatform`](xrplatform.md) implementation for the browser, in the **Evergine.WebXR** package. It runs an Evergine web application inside a WebXR session, so a phone browser can place the scene over its camera image with no app to install.

The integration is **experimental** and focused on augmented reality. It provides the viewer pose and projection, and nothing else: there is no input tracking, no hand tracking and no passthrough subsystem.

## Create a WebXR project

Select the **WebXR (Experimental AR)** template when you create a project, or add it later from **Project Settings** > **Profiles**. The profile is named **WebXR**. It is a Blazor WebAssembly application that renders with WebGL 2.0, like the regular [Web](../platforms/web/index.md) profile, plus an ASP.NET Core server project to host it.

WebXR only starts on pages served over HTTPS (or from `localhost`), and only in browsers that implement the WebXR Device API with the `immersive-ar` session mode.

## How the template works

In the web project's `Program.cs`, the template uses a `WebXRWindowsSystem` instead of the regular web windows system, creates the platform for the canvas, and registers it as `XRPlatform`:

```csharp
// Create Services
windowsSystem = new WebXRWindowsSystem();
application.Container.RegisterInstance(windowsSystem);

var canvas = wasm.GetElementById(canvasId);
var surface = (WebSurface)windowsSystem.CreateSurface(canvas);
appCanvas[canvasId] = surface;
ConfigureGraphicsContext(application, surface, canvasId);

// WebXRPlatform
webxrPlatform = new WebXRPlatform((windowsSystem as WebXRWindowsSystem), canvasId);
application.Container.RegisterInstance<XRPlatform>(webxrPlatform);
```

Unlike the OpenXR templates, it does not register an XR display: `WebXRPlatform.Display` is `null`, and the scene keeps rendering into the canvas display that `ConfigureGraphicsContext` registers as `DefaultDisplay`. The frame loop calls `webxrPlatform.Update()` before `UpdateFrame`, as every XR launcher does.

## Entering and leaving the immersive session

A page cannot start an immersive session on its own: the browser only allows it in response to a user action. The template exposes the platform's two methods to JavaScript:

```csharp
[JSInvokable("$safeprojectname$.$safeprofilename$.Program:EnterImmersive")]
public static Task EnterImmersive(string mode, string overlayId)
{
    return webxrPlatform.EnterImmersive(mode, overlayId);
}

[JSInvokable("$safeprojectname$.$safeprofilename$.Program:ExitImmersive")]
public static void ExitImmersive()
{
    webxrPlatform.ExitImmersive();
}
```

`index.html` has an **Enter AR** button that is enabled only when `navigator.xr.isSessionSupported("immersive-ar")` resolves to `true`. Clicking it calls `app.enterARImmersive("overlay")`, which ends in `EnterImmersive("immersive-ar", "overlay")`.

| Parameter | Description |
| --- | --- |
| **mode** | The WebXR session mode. The platform is built for `"immersive-ar"`. |
| **overlayId** | The `id` of the HTML element to keep on top of the camera view during the session (the WebXR DOM overlay). The template passes `overlay`, the element that holds its header and button. |

> [!NOTE]
> In this release the native side of `Evergine.WebXR` always uses the element whose `id` is `overlay`, whatever `overlayId` says. Keep that `id` on your overlay element. The session uses the WebXR `local` reference space, so the origin is where the phone was when the session started.

## What changes in the scene

While an `immersive-ar` session runs, `WebXRPlatform`:

* Moves the active `Camera3D` with the phone and gives it the projection of the phone camera. `EyeCount` is 1, so the camera renders a single view, and its world position and orientation are set directly.
* Sets the camera `BackgroundColor` to `Color.Transparent`, so the real world shows behind the scene.
* Disables every entity whose `Tag` is `Skybox`, for the same reason.

The platform only changes the background when a session starts. `ExitImmersive()` leaves it transparent; entering a later session in a mode other than `immersive-ar` restores the original color and the sky.

> [!TIP]
> Give your sky or background entity the tag `Skybox`, so that it does not hide the camera image in AR.

## See also

* [XR Platform](xrplatform.md): the properties every platform shares.
* [Web platform](../platforms/web/index.md): building and serving Evergine web applications.
