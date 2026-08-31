# ResourceFactory

The `ResourceFactory` creates every GPU object. You reach it through the [GraphicsContext](graphicscontext.md), and from then on it is the only allocator you use:

```csharp
var vertexBufferDescription = new BufferDescription(
    (uint)Unsafe.SizeOf<VertexPositionNormalTexture>() * (uint)vertexData.Length,
    BufferFlags.VertexBuffer,
    ResourceUsage.Default);

var vertexBuffer = this.graphicsContext.Factory.CreateBuffer(vertexData, ref vertexBufferDescription);
```

Every object it returns is an abstract type, and the concrete class matches the backend the context was created for. The factory of a `DX11GraphicsContext` always returns DirectX 11 resources (`DX11Texture`, `DX11Buffer`, and so on), and your code never names them. That is what lets one set of resource creation calls run on every backend.

## What it creates

| Method | Returns | Page |
| --- | --- | --- |
| `CreateBuffer` | `Buffer` | [Buffer](buffer.md) |
| `CreateTexture` | `Texture` | [Texture](texture.md) |
| `CreateTextureView` | `TextureView` | [Texture](texture.md) |
| `CreateSamplerState` | `SamplerState` | [Sampler](sampler.md) |
| `CreateShader` | `Shader` | [Shader](shader.md) |
| `CreateResourceLayout` | `ResourceLayout` | [ResourceLayout](resourcelayout.md) |
| `CreateResourceSet` | `ResourceSet` | [ResourceSet](resourceset.md) |
| `CreateFrameBuffer` | `FrameBuffer` | [Framebuffer](framebuffer.md) |
| `CreateGraphicsPipeline` | `GraphicsPipelineState` | [GraphicsPipeline](graphicspipeline.md) |
| `CreateComputePipeline` | `ComputePipelineState` | [ComputePipeline](computepipeline.md) |
| `CreateRaytracingPipeline` | `RaytracingPipelineState` | [RaytracingPipeline](raytracingpipeline.md) |
| `CreateMeshShaderPipeline` | `MeshShaderPipelineState` | |
| `CreateCommandQueue` | `CommandQueue` | [CommandQueue](commandqueue.md) |
| `CreateQueryHeap` | `QueryHeap` | [QueryHeap](queryheap.md) |
| `CreateFence` | `Fence` | [Fence](fence.md) |

## Two objects the factory does not create

| Object | Where it comes from |
| --- | --- |
| `CommandBuffer` | `commandQueue.CommandBuffer()`. See [CommandBuffer](commandbuffer.md). |
| `SwapChain` | `graphicsContext.CreateSwapChain(description)`. See [Swapchain](swapchain.md). |

A command buffer is drawn from its queue's pool rather than allocated, which is what makes it single use. A swapchain is tied to a surface rather than to the device alone, so it is created from the context.

## Descriptions are passed by reference

Most `Create` methods take their description with `ref`:

```csharp
var textureDescription = new TextureDescription() { /* ... */ };
var texture = this.graphicsContext.Factory.CreateTexture(ref textureDescription);
```

The description is a struct, and `ref` avoids copying it. It is not modified, so the same description can create several resources.

> [!NOTE]
> This means you cannot pass a description inline as `CreateTexture(ref new TextureDescription())`. Assign it to a local first.

## Validation

Every `Create` method has a validation step that runs when the device was created with a `ValidationLayer`. It checks descriptions for combinations the backend would reject later, at a point where the error still names what you asked for:

```csharp
graphicsContext.CreateDevice(new ValidationLayer());
```

Turn it on during development. See [GraphicsContext](graphicscontext.md) for the ways it can report.

## Disposing

Every object the factory returns implements `IDisposable`, and none of them is collected for you. Dispose in reverse order of dependency: pipelines before the shaders they were built from, resource sets before the layouts they fill, and everything before the context.

> [!IMPORTANT]
> Wait for the GPU before disposing anything it may still be reading, with `commandQueue.WaitIdle()` or by waiting on the [Fence](fence.md) of the submission that used it. Freeing a resource that is still in flight is a use after free on the GPU, and it usually shows up as a device removed error rather than as anything that names the resource.
