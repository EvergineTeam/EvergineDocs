# Update from Evergine 2026.5.26 to Evergine 2026.10

Evergine 2026.10 makes **DirectX 12 the default graphics backend** and tightens the behavior of a few low-level graphics APIs. Most projects update without code changes. This guide lists what changes for existing projects, what you may want to change by hand, and the new features you can start using.

If your project is older than 2026.5.26, first follow [Update from Evergine 2025.10.21 to Evergine 2026.5.26](upgrade_project_2026.5.26.md). That release moved the engine to .NET 10 and Reverse-Z, and this guide assumes both.

## Summary

| Change | Affects | Action |
| --- | --- | --- |
| DirectX 12 is the default backend | Evergine Studio, new projects | None for existing projects. Optionally move your Windows profile to DirectX 12. |
| Vulkan `QueryHeap.ReadData` writes at absolute slot indices | Code that reads query results on Vulkan | Size the results array to `startIndex + count`. |
| New `IsTimestampQuerySupported` capability | Code that creates timestamp query heaps | Check the capability before creating the heap. |
| Quest and Pico launchers render outside the UI thread | Meta Quest and Pico projects | Optional one-line change in `MainActivity.cs`. |
| WebGPU template limits the frames in flight | Web (Experimental WebGPU) projects | Optional update of `ts/app.ts` and `ts/helper.ts`. |
| Custom graphics backends have new abstract members | Only if you implement your own backend | Implement the new members. |

## Update the project

1. Install the new version from the **Evergine Launcher** and select it for your project, as described in [General upgrade steps](index.md#general-upgrade-steps).
2. Let the Launcher update the Evergine packages of the project.
3. Open the project in Evergine Studio and in Visual Studio, rebuild, and review the sections below.

## DirectX 12 is the default backend

DirectX 12 replaces DirectX 11 as the default on Windows, in three places:

- **Evergine Studio** starts on DirectX 12. When you update, an installation that was using DirectX 11 moves to DirectX 12. An installation where you had explicitly chosen Vulkan keeps Vulkan.
- **New projects** use the **Windows (DirectX12)** template as the required platform. Its `Windows` profile runs on `DX12GraphicsContext` and references the `Evergine.DirectX12` package.
- **DirectX 11** is still available as the optional **Windows (DirectX11)** platform, which adds a `Windows.DirectX11` profile.

You can change the backend Evergine Studio renders with in **Settings > Preferences > Editor backend (Experimental)**. The change applies after you restart Evergine Studio.

> [!IMPORTANT]
> The DirectX 12 backend requires a GPU that supports Direct3D feature level 12_2. On older GPUs `DX12GraphicsContext.CreateDevice()` throws `Couldn't find GPU device that supports feature level 12.2`. If that happens in Evergine Studio, set **Editor backend** to DirectX11 or Vulkan. If it happens in your application, keep the Windows profile on DirectX 11 (see below) or add the Windows (Vulkan) platform.

### What happens to existing projects

Nothing changes on its own. The `Windows` profile of an existing project keeps the backend recorded in its `.weproj` file and the launcher code already on disk, so a project created with DirectX 11 still builds and runs on DirectX 11. Projects that already have a `Windows.DirectX12` profile are not affected either.

### Move the Windows profile to DirectX 12 (optional)

To make an existing project match the new template, change three files.

In the `.weproj` file, set the backend of the `Windows` profile:

```yaml
# Before
    GraphicsBackend: DirectX11
    LauncherType: Default
    Name: Windows

# After
    GraphicsBackend: DirectX12
    LauncherType: Default
    Name: Windows
```

In `MyGame.Windows/MyGame.Windows.csproj`, replace the backend package:

```xml
<!-- Before -->
<PackageReference Include="Evergine.DirectX11" Version="2026.10.x.x" />

<!-- After -->
<PackageReference Include="Evergine.DirectX12" Version="2026.10.x.x" />
```

Use the same version as the other Evergine packages of the project.

In `MyGame.Windows/Program.cs`, create a DirectX 12 context instead of a DirectX 11 one:

```csharp
// Before
GraphicsContext graphicsContext = new global::Evergine.DirectX11.DX11GraphicsContext();

// After
GraphicsContext graphicsContext = new global::Evergine.DirectX12.DX12GraphicsContext();
```

The rest of `ConfigureGraphicsContext` (swap chain description, presenter and container registration) stays the same. The template also changes the window title from `- DX11` to `- DX12`, which is cosmetic.

> [!TIP]
> To test on a machine without a suitable GPU, such as a build agent, create the context with `new DX12GraphicsContext(useWarpAdapter: true)`. It runs DirectX 12 on the WARP software rasterizer, which is slow but needs no GPU.

## Vulkan: `QueryHeap.ReadData` writes at absolute slot indices

`QueryHeap.ReadData(startIndex, count, results)` now writes the result of query `i` at `results[i]` on Vulkan, as it already did on every other backend. Before this release, the Vulkan backend packed the results from the start of the array, so `results[0]` held query `startIndex`.

This is a breaking change for code that reads a range that does not start at 0. The results array must hold at least `startIndex + count` elements. A shorter array now throws `ArgumentException` on every backend.

Before (only correct on Vulkan):

```csharp
// Queries 2 and 3 hold the timestamps around the second pass.
ulong[] results = new ulong[2];
this.queryHeap.ReadData(2, 2, results);
double passMs = (results[1] - results[0]) * 1000.0 / this.graphicsContext.TimestampFrequency;
```

After (correct on every backend):

```csharp
// The array is indexed by query slot, so it needs startIndex + count elements.
ulong[] results = new ulong[4];
this.queryHeap.ReadData(2, 2, results);
double passMs = (results[3] - results[2]) * 1000.0 / this.graphicsContext.TimestampFrequency;
```

If you always read from slot 0 with an array of `QueryCount` elements, as in [QueryHeap](../../graphics/low_level_api/queryheap.md), you do not need to change anything.

## Timestamp query support is now reported

`GraphicsContextCapabilities` has a new `IsTimestampQuerySupported` property. It is `false` by default, and each backend reports `true` only when it implements timestamp queries. Before this release there was no way to ask, and a backend without timestamp queries failed the first time you used them.

- **DirectX 12, DirectX 11 and Vulkan** report `true`.
- **WebGPU** reports `true` when the browser exposes the `timestamp-query` feature.
- **Metal** reports `false`, because its `QueryHeap` and `WriteTimestamp` are not implemented.
- **OpenGL** reports support only when the driver exposes `ARB_timer_query`. OpenGL ES and WebGL do not have it, so they report `false`.

If you create timestamp query heaps, check the capability first:

```csharp
using Evergine.Common.Graphics;

public class GpuTimer
{
    private readonly GraphicsContext graphicsContext;
    private QueryHeap queryHeap;

    public GpuTimer(GraphicsContext graphicsContext)
    {
        this.graphicsContext = graphicsContext;

        // Metal, OpenGL ES and WebGL report false: skip GPU timing there instead of failing.
        if (graphicsContext.Capabilities.IsTimestampQuerySupported)
        {
            var description = new QueryHeapDescription()
            {
                Type = QueryType.Timestamp,
                QueryCount = 2,
            };

            this.queryHeap = graphicsContext.Factory.CreateQueryHeap(ref description);
        }
    }

    public bool IsAvailable => this.queryHeap != null;
}
```

## Meta Quest and Pico: surface created outside the UI thread (optional)

The **Android Meta Quest (OpenXR)** and **Android Pico (OpenXR)** templates now create the Android surface with `runInUIThread` set to `false`, so the graphics loop does not run on the Android UI thread. To apply the same change to an existing project, edit `MainActivity.cs` in the Quest or Pico launcher:

```csharp
// Before
var surface = this.windowsSystem.CreateSurface(0, 0) as global::Evergine.Android.AndroidSurface;

// After
var surface = this.windowsSystem.CreateSurface(false) as global::Evergine.Android.AndroidSurface;
```

`CreateSurface(0, 0)` still works and keeps the previous behavior, because it calls `CreateSurface(true)`.

## WebGPU: frames in flight (optional)

The **Web (Experimental WebGPU)** template now limits how many frames the GPU can have queued. Without a limit, `requestAnimationFrame` keeps submitting frames at display rate even when the GPU cannot keep up, which adds input lag and reports a frame rate higher than what is presented.

The limit lives in `ts/app.ts` (`App.maxFramesInFlight`, 2 by default; set it to 0 to disable it), and `ts/helper.ts` skips a tick while the limit is reached. To get the change in an existing project, create a new project with the WebGPU template and copy its `ts/app.ts` and `ts/helper.ts` over yours. Merge by hand if you had edited those files.

## Custom graphics backends

Skip this section unless you implement your own `GraphicsContext`. The abstract classes of the low-level API gained members that every backend must implement:

| Class | New member |
| --- | --- |
| `CommandQueue` | `Submit(Fence fence = null)` replaces `Submit()`. |
| `CommandQueue` | `GetClockCalibration(out ulong gpuTimestamp, out long cpuTimestamp)` |
| `ResourceFactory` | `CreateFence()` and `CreateBufferViewInternal(...)` |
| `CommandBuffer` | `UpdateTextureData(Texture texture, IntPtr source, uint sourceSizeInBytes, uint subResource = 0)` |
| `GraphicsContextCapabilities` | `IsTimestampQuerySupported` and `IsClockCalibrationSupported` (virtual, `false` by default, so override them to report support) |

Code that only calls `CommandQueue.Submit()` keeps compiling, because the fence parameter is optional.

## New features you can adopt

These features are optional. Existing projects keep working without them.

### Fence

`Fence` tells the CPU when one particular submission has finished on the GPU, instead of waiting for the whole queue with `WaitIdle()`. Create one with `Factory.CreateFence()`, pass it to `CommandQueue.Submit(fence)`, and use `IsSignaled`, `Wait` and `Reset`. It is implemented on DirectX 12, DirectX 11, Vulkan, OpenGL, Metal and WebGPU. See [CommandQueue](../../graphics/low_level_api/commandqueue.md) for how submission works.

`GraphicsContext.FramesInFlight` (0 by default, which disables it) builds on fences: when it is greater than zero, `GraphicsPresenter` creates one fence per frame and lets that many frames be in progress at once.

### GPU and CPU clock calibration

`CommandQueue.GetClockCalibration(out ulong gpuTimestamp, out long cpuTimestamp)` samples the GPU timestamp counter and the CPU `Stopwatch` clock at the same instant, so you can place GPU timestamps on a CPU profiler timeline. Check `Capabilities.IsClockCalibrationSupported` first: DirectX 12, Vulkan and desktop OpenGL support it; DirectX 11, WebGPU and Metal do not.

### Buffer views

`ResourceFactory.CreateBufferView(buffer, offset, size, format, structStride)` creates a `BufferView` over a range of a `Buffer`. Buffer views can be bound as formatted (texel) buffers through the new `ResourceType.TexelBuffer` and `ResourceType.TexelBufferReadWrite` layout entries:

```csharp
// View the first 1024 bytes of an existing buffer as an array of float4 values.
BufferView view = this.graphicsContext.Factory.CreateBufferView(
    this.dataBuffer,
    offset: 0,
    size: 1024,
    format: PixelFormat.R32G32B32A32_Float);
```

### Raw assets

`AssetsService.LoadRaw<T>(Guid id, Func<Stream, T> loader)` loads files that Evergine includes in the application without converting them, such as JSON or plain text. You provide the function that reads the stream:

```csharp
using System;
using System.IO;
using Evergine.Framework;
using Evergine.Framework.Services;

public class LoadTextFile : Component
{
    [BindService]
    private AssetsService assetsService = null;

    // Id of a raw asset, usually taken from the generated EvergineContent class.
    public Guid TextFileId { get; set; }

    public string Text { get; private set; }

    protected override void Start()
    {
        // LoadRaw does not cache: keep the result if you need it again.
        this.Text = this.assetsService.LoadRaw(this.TextFileId, stream =>
        {
            using var reader = new StreamReader(stream, leaveOpen: true);
            return reader.ReadToEnd();
        });
    }
}
```

See [Raw assets loading](../../evergine_studio/assets/use.md#load-raw-assets) for details.

### Application services in Evergine Studio

**Project Settings > Services** lets you add, remove and configure application services from Evergine Studio. The configuration is saved in the project's `.weservices` file and the services are registered automatically when the application starts. A service you register from code takes precedence over the one configured in Studio. See [Manage services](../../evergine_studio/settings/project_services.md).

### Other improvements

- **Evergine Studio:** close opened documents from their context menu, reset profile textures and shader values to the originals, choose the HDR range in the Texture Viewer, and edit multiline string properties.
- **Evergine Launcher:** remove several installed versions at once.
- **MAUI:** better Android, Windows and iOS lifecycle handling in the MAUI template.

The full list of changes and bug fixes is in the release notes shown by the installer.
