# ResourceSet

A `ResourceSet` is the other half of a binding. Where a [ResourceLayout](resourcelayout.md) declares which slots exist, a resource set puts real objects in them. You create one per combination of resources you want to bind, and swap between them at draw time.

Sets are immutable once created. To point a slot at a different texture, create another set rather than editing this one.

## Creation

A set is built from the layout it fills and the resources that fill it:

```csharp
var resourceSetDescription = new ResourceSetDescription(resourceLayout, constantBuffer, texture, sampler);
var resourceSet = this.graphicsContext.Factory.CreateResourceSet(ref resourceSetDescription);
```

### ResourceSetDescription

| Property | Type | Description |
| --- | --- | --- |
| **Layout** | `ResourceLayout` | The layout this set fills. Required. |
| **Resources** | `GraphicsResource[]` | One resource per element of the layout, in the same order. |

## What goes in each slot

The type declared on the layout element decides which object the set expects:

| Layout declares | Pass an instance of |
| --- | --- |
| `ConstantBuffer` | [Buffer](buffer.md) created with `BufferFlags.ConstantBuffer` |
| `StructuredBuffer` | [Buffer](buffer.md) created with `BufferFlags.ShaderResource` and `BufferFlags.BufferStructured` |
| `StructuredBufferReadWrite` | [Buffer](buffer.md) created with `BufferFlags.UnorderedAccess` |
| `TextureView` | [Texture](texture.md), or a `TextureView` over one |
| `TextureViewReadWrite` | [Texture](texture.md) created with `TextureFlags.UnorderedAccess`, or a `TextureView` over one |
| `Sampler` | [SamplerState](sampler.md) |
| `AccelerationStructure` | `TopLevelAS`. See [RaytracingPipeline](raytracingpipeline.md) |

Passing a `Texture` where the layout says `TextureView` is the common case, and the backend uses that texture's `DefaultView`. Create an explicit view when you need a subrange of mip levels or array slices, or a different but compatible pixel format.

> [!IMPORTANT]
> Resources are matched to layout elements by position. The set does not look at slot numbers to work out where each resource belongs, so the two arrays have to be written in the same order.

A slot may be left empty by passing `null`, which is useful when one layout serves several materials and some of them have no texture in a given slot. The shader still has to cope with reading nothing there.

## Binding

Bind a set to the index of the layout it was built from, counting positions in the pipeline's `ResourceLayouts` array:

```csharp
commandBuffer.SetResourceSet(this.resourceSetPerDraw, 0);
commandBuffer.SetResourceSet(this.resourceSetPerView, 1);
commandBuffer.SetResourceSet(this.resourceSetPerMat, 2);
```

When a set is bound to index `0` and its layout has no other consumer, the index can be left out.

### Dynamic offsets

An element declared with `AllowDynamicOffset` takes a byte offset at bind time, so one large constant buffer can serve many draws:

```csharp
for (int i = 0; i < instanceCount; i++)
{
    commandBuffer.SetResourceSet(this.resourceSet, 0, new uint[] { this.stride * (uint)i });
    commandBuffer.Draw(vertexCount);
}
```

The offsets array carries one entry per element of the layout that allows a dynamic offset, in the order those elements appear. `ResourceLayoutDescription.DynamicConstantBufferCount` tells you how many the layout expects.

> [!NOTE]
> Every backend requires dynamic offsets to be a multiple of its own constant buffer alignment, which is 256 bytes on DirectX 12 and reported by the device on Vulkan. Round your stride up rather than packing structures tightly.

## Sets carry their own barriers

Creating a set records, for every resource in it, the state that resource has to be in for the shader to read it. On DirectX 12 and Vulkan the render pipeline uses that precomputed list to transition resources without walking the set again each frame.

| Layout declares | State the resource is transitioned to |
| --- | --- |
| `ConstantBuffer` | `Buffer.StateFlags.UniformBuffer` |
| `StructuredBuffer`, `AccelerationStructure` | `Buffer.StateFlags.ShaderResource` |
| `StructuredBufferReadWrite` | `Buffer.StateFlags.UnorderedAccess` |
| `TextureView` | `Texture.StateFlags.PixelShaderResource`, `NonPixelShaderResource`, or both, depending on the element's `Stages` |
| `TextureViewReadWrite` | `Texture.StateFlags.UnorderedAccess` |

`CollectBarriers` exposes that list if you are writing your own submission code:

```csharp
var bufferBarriers = new List<Buffer.Barrier>();
var textureBarriers = new List<Texture.Barrier>();
resourceSet.CollectBarriers(bufferBarriers, textureBarriers);

commandBuffer.Barrier(CollectionsMarshal.AsSpan(bufferBarriers), CollectionsMarshal.AsSpan(textureBarriers));
```

See [Barriers](barriers.md) for when those transitions have to be recorded.

## Cleaning up

A set does not own the resources inside it. Disposing it leaves the buffers, textures and samplers alive for other sets to use.

```csharp
resourceSet.Dispose();
```
