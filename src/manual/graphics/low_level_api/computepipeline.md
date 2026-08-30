# ComputePipeline

A `ComputePipelineState` runs a compute shader. It is the same idea as a [GraphicsPipeline](graphicspipeline.md) with most of it removed: no vertex format, no raster or blend state, no output attachments. What remains is a single shader, the resource layouts it reads, and the size of a thread group.

Compute work does not go through a render pass. You record it directly on the command buffer, between `Begin()` and `End()`.

## Creation

```csharp
var computePipelineDescription = new ComputePipelineDescription()
{
    ResourceLayouts = new[] { computeResourceLayout },
    shaderDescription = new ComputeShaderStateDescription() { ComputeShader = computeShader },
    ThreadGroupSizeX = GroupSizeX,
    ThreadGroupSizeY = GroupSizeY,
    ThreadGroupSizeZ = 1,
};

var computePipelineState = this.graphicsContext.Factory.CreateComputePipeline(ref computePipelineDescription);
```

### ComputePipelineDescription

| Property | Type | Description |
| --- | --- | --- |
| **ResourceLayouts** | `ResourceLayout[]` | The layouts the compute shader reads, in the order their sets will be bound. |
| **shaderDescription** | `ComputeShaderStateDescription` | Holds the single `ComputeShader`. |
| **ThreadGroupSizeX** | `uint` | Threads per group in X. `1` by default. |
| **ThreadGroupSizeY** | `uint` | Threads per group in Y. `1` by default. |
| **ThreadGroupSizeZ** | `uint` | Threads per group in Z. `1` by default. |

> [!IMPORTANT]
> The three `ThreadGroupSize` values have to match the `[numthreads(x, y, z)]` attribute in the shader source. Nothing checks the two against each other, and a mismatch produces wrong results rather than an error.

## Dispatching

A dispatch launches a grid of thread groups. `Dispatch` takes the number of groups, which is the raw form:

```csharp
commandBuffer.SetComputePipelineState(this.computePipelineState);
commandBuffer.SetResourceSet(this.computeResourceSet);
commandBuffer.Dispatch(groupCountX, groupCountY, groupCountZ);
```

More often you know the size of the problem rather than the number of groups. The helper overloads divide for you, rounding up so the last partial group still runs:

| Method | Purpose | Default group size |
| --- | --- | --- |
| `Dispatch1D(threadCountX, groupSizeX)` | One dimensional problems | 64 |
| `Dispatch2D(threadCountX, threadCountY, groupSizeX, groupSizeY)` | Images and grids | 8 by 8 |
| `Dispatch3D(threadCountX, threadCountY, threadCountZ, groupSizeX, groupSizeY, groupSizeZ)` | Volumes | None, pass all three |

```csharp
// Cover a width by height image, 8x8 threads per group.
commandBuffer.Dispatch2D(this.width, this.height, GroupSizeX, GroupSizeY);
```

Because the grid is rounded up, threads can run past the edge of your data. Guard against that in the shader by comparing the dispatch thread ID against the real size.

## Compute writes, graphics reads

The pattern that breaks is writing a texture from compute and then sampling it in a pixel shader without declaring the change. Each side needs a barrier: one to put the texture into `UnorderedAccess` before the dispatch, one to put it back into `PixelShaderResource` before the draw.

```csharp
// The compute pass writes the texture...
var computeCommandBuffer = this.computeCommandQueue.CommandBuffer();
computeCommandBuffer.Begin();

computeCommandBuffer.Barrier(new Texture.Barrier(this.texture, Texture.StateFlags.UnorderedAccess));

computeCommandBuffer.UpdateBufferData(this.constantBuffer, ref this.computeData);
computeCommandBuffer.SetComputePipelineState(this.computePipelineState);
computeCommandBuffer.SetResourceSet(this.computeResourceSet);
computeCommandBuffer.Dispatch2D(this.width, this.height, GroupSizeX, GroupSizeY);

computeCommandBuffer.End();
computeCommandBuffer.Commit();
this.computeCommandQueue.Submit();
this.computeCommandQueue.WaitIdle();

// ...and the graphics pass samples it.
var graphicsCommandBuffer = this.graphicsCommandQueue.CommandBuffer();
graphicsCommandBuffer.Begin();

graphicsCommandBuffer.Barrier(new Texture.Barrier(this.texture, Texture.StateFlags.PixelShaderResource));

RenderPassDescription renderPassDescription = new RenderPassDescription(this.frameBuffer, ClearValue.Default);
graphicsCommandBuffer.BeginRenderPass(ref renderPassDescription);

graphicsCommandBuffer.SetGraphicsPipelineState(this.graphicsPipelineState);
graphicsCommandBuffer.SetResourceSet(this.resourceSet);
graphicsCommandBuffer.SetViewports(this.viewports);
graphicsCommandBuffer.SetScissorRectangles(this.scissors);
graphicsCommandBuffer.Draw(3);

graphicsCommandBuffer.EndRenderPass();
graphicsCommandBuffer.End();
graphicsCommandBuffer.Commit();

this.graphicsCommandQueue.Submit();
this.graphicsCommandQueue.WaitIdle();
```

The texture in that example was created with both `TextureFlags.UnorderedAccess` and `TextureFlags.ShaderResource`, and it appears in two resource layouts: as `TextureViewReadWrite` for the compute side, and as `TextureView` for the graphics side.

See [Barriers](barriers.md) for the full set of states, and for the separate case of two dispatches writing the same resource one after the other.

## A dedicated compute queue

Compute work can go on its own queue, which lets the driver overlap it with graphics work:

```csharp
this.computeCommandQueue = this.graphicsContext.Factory.CreateCommandQueue(CommandQueueType.Compute);
```

A command buffer belongs to the queue that produced it, so take it from the same queue you will submit it on. See [CommandQueue](commandqueue.md).

## Support

Compute is not available on every backend. Ask the device before creating a compute pipeline:

```csharp
if (this.graphicsContext.Capabilities.IsComputeShaderSupported)
{
    // ...
}
```

## Cleaning up

```csharp
computePipelineState.Dispose();
```
