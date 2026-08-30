# GraphicsContext

The `GraphicsContext` is the device. It is the first object you create and the last one you dispose, it owns the [ResourceFactory](resourcefactory.md) that allocates everything else, and it reports what the hardware underneath can do.

Like most classes in this section it is abstract, and the concrete class you instantiate is the one decision in your application that names a backend. Everything after that point is written once and runs on all of them.

```csharp
var graphicsContext = new Evergine.DirectX11.DX11GraphicsContext();
```

| Backend | Class |
| --- | --- |
| **DirectX 11** | `new DX11GraphicsContext()` |
| **DirectX 12** | `new DX12GraphicsContext()` |
| **Vulkan** | `new VKGraphicsContext()` |
| **Metal** | `new MTLGraphicsContext()` |
| **OpenGL and OpenGL ES** | `new GLGraphicsContext()` |
| **WebGPU** | `new WGPUGraphicsContext()` |

## Creating the device

Nothing can be allocated until the device exists:

```csharp
graphicsContext.CreateDevice();
```

### Validation layer

Pass a `ValidationLayer` to have the backend check what you ask of it and report native and internal errors:

```csharp
graphicsContext.CreateDevice(new ValidationLayer());
```

| Notify method | Declaration | Behaviour |
| --- | --- | --- |
| **Exception** | `new ValidationLayer()` | Throws on each error and stops execution. **Default value.** |
| **Trace** | `new ValidationLayer(ValidationLayer.NotifyMethod.Trace)` | Writes errors to the console and keeps going. |
| **Event** | `new ValidationLayer(ValidationLayer.NotifyMethod.Event)` | Raises `ValidationLayer.Error` so you can route the message yourself. |

> [!IMPORTANT]
> On DirectX 12 and Vulkan the validation layer is the only thing that reports a missing or wrong [barrier](barriers.md). Without it, an incorrect resource state renders wrongly and says nothing. Develop with it on, even when the application ships without it.

## Asking what the hardware supports

`Capabilities` answers per device, not per backend, so query it rather than testing `BackendType`:

```csharp
if (this.graphicsContext.Capabilities.IsRaytracingSupported)
{
    // ...
}
```

| Capability | Description |
| --- | --- |
| **IsComputeShaderSupported** | Whether [compute pipelines](computepipeline.md) can run. `false` on OpenGL. |
| **IsRaytracingSupported** | Whether [ray tracing](raytracingpipeline.md) is available. Needs DirectX 12 or Vulkan and a capable device. |
| **IsMeshShaderSupported** | Whether mesh and amplification shaders are available. |
| **IsMRTSupported** | Whether a [framebuffer](framebuffer.md) may have several colour targets. |
| **IsShadowMapSupported** | Whether depth textures can be sampled as shadow maps. |
| **IsTextureFormatSupported(format)** | Whether one `PixelFormat` is usable on this device. |
| **FlipProjectionRequired** | Whether the projection matrix needs flipping vertically for this backend. |
| **MatrixMajorness** | Row or column major, which decides how matrices are uploaded. |
| **ClipDepth** | The depth range of clip space, which differs between DirectX and OpenGL. |

`BackendType` returns the `GraphicsBackend` in use: `DirectX11`, `DirectX12`, `OpenGL`, `OpenGLES`, `Metal`, `Vulkan`, `WebGL1`, `WebGL2` or `WebGPU`. Its main honest use is picking which [shader](shader.md) language to load.

## Creating a swapchain

A window comes first, because the swapchain binds to its surface:

```csharp
// Create a window...
var windowSystem = new Evergine.Forms.FormsWindowsSystem();
var window = windowSystem.CreateWindow(windowTitle, width, height);

// Describe the buffers and point them at that window's surface...
var swapChainDescriptor = new SwapChainDescription()
{
    Width = window.Width,
    Height = window.Height,
    SurfaceInfo = window.SurfaceInfo,
    ColorTargetFormat = PixelFormat.R8G8B8A8_UNorm,
    ColorTargetFlags = TextureFlags.RenderTarget | TextureFlags.ShaderResource,
    DepthStencilTargetFormat = PixelFormat.D24_UNorm_S8_UInt,
    DepthStencilTargetFlags = TextureFlags.DepthStencil,
    SampleCount = TextureSampleCount.None,
    IsWindowed = true,
    RefreshRate = 60,
};

// Finally, create the swapchain...
var swapChain = this.graphicsContext.CreateSwapChain(swapChainDescriptor);
swapChain.VerticalSync = false;
```

See [Swapchain](swapchain.md) for the description properties and for how a frame is presented.

### Windowing systems

| Platform or UI | Class |
| --- | --- |
| **Windows Forms** | `Evergine.Forms.FormsWindowsSystem` |
| **WPF** | `Evergine.WPF.WPFWindowsSystem` |
| **WinUI** | `Evergine.WinUI.WinUIWindowsSystem` |
| **Avalonia** | `Evergine.Avalonia.AvaloniaWindowsSystem` |
| **SDL** | `Evergine.SDL.SDLWindowsSystem` |
| **Android** | `Evergine.Android.AndroidWindowsSystem` |
| **iOS** | `Evergine.iOS.IOSWindowsSystem` |
| **macOS** | `Evergine.MacOS.MacWindowsSystem` |
| **Web** | `Evergine.Web.WebWindowsSystem` |

## Other members

| Member | Description |
| --- | --- |
| **Factory** | The [ResourceFactory](resourcefactory.md). |
| **UpdateBufferData** | Writes CPU data into a [Buffer](buffer.md) outside a command buffer. |
| **UpdateTextureData** | Writes CPU data into a [Texture](texture.md). |
| **MapMemory(resource, mode)** | Maps a resource for CPU access and returns a `MappedResource`. |
| **UnmapMemory(resource, subResource)** | Releases a mapping. |
| **ShaderCompile(source, entryPoint, stage, parameters)** | Compiles shader source to bytecode. See [Shader](shader.md). |
| **GenerateTextureMipmapping(texture)** | Fills a texture's mip chain. |
| **NativeDevicePointer** | The underlying device handle, for interop with native libraries. |
| **ReverseZBuffer** | Whether depth runs from 1 at the near plane to 0 at the far plane. |

## Building on this API directly

The [Low-Level API samples repository](https://github.com/evergineteam/LowLevelAPIDemo) contains complete applications written against this API, with no scene, entities or components involved.
