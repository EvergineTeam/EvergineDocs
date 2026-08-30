# RaytracingPipeline

A `RaytracingPipelineState` traces rays against a scene instead of rasterising triangles. It replaces the vertex and pixel stages with a set of shaders the hardware calls as a ray travels: one to generate rays, one for the closest surface hit, one for rays that hit nothing, and optionally shaders for transparency tests and custom intersection shapes.

Ray tracing needs hardware support, and it runs only on the DirectX 12 and Vulkan backends. Everything on this page is unavailable elsewhere.

```csharp
if (!this.graphicsContext.Capabilities.IsRaytracingSupported)
{
    // Fall back to a rasterised path.
}
```

> [!NOTE]
> The API spells this one with a lower case `t`: `CreateRaytracingPipeline`, `RaytracingPipelineState`, `RaytracingShaderStateDescription`, and the namespace `Evergine.Common.Graphics.Raytracing`.

## Acceleration structures

Rays are traced against a two level structure. A **bottom level** structure holds the geometry of one object. A **top level** structure holds instances, each pointing at a bottom level structure with its own transform. Both are built by recording commands, not by the factory:

```csharp
var commandBuffer = this.graphicCommandQueue.CommandBuffer();
commandBuffer.Begin();

// Bottom level: the geometry itself...
AccelerationStructureGeometry geometry = new AccelerationStructureTriangles()
{
    Flags = AccelerationStructureGeometryFlags.Opaque,
    VertexBuffer = vertexBuffer,
    VertexFormat = PixelFormat.R32G32B32_Float,
    VertexStride = (uint)Unsafe.SizeOf<Vector3>(),
    VertexCount = (uint)this.vertexData.Length,
};

BottomLevelASDescription bottomLevel = new BottomLevelASDescription()
{
    Geometries = new AccelerationStructureGeometry[] { geometry },
};

var blas = commandBuffer.BuildRaytracingAccelerationStructure(bottomLevel);

// Top level: one instance of that geometry...
AccelerationStructureInstance instance = new AccelerationStructureInstance()
{
    InstanceID = 0,
    InstanceContributionToHitGroupIndex = 0,
    Flags = AccelerationStructureInstanceFlags.None,
    Transform4x4 = Matrix4x4.Identity,
    BottonLevel = blas,
    InstanceMask = 0xFF,
};

TopLevelASDescription topLevel = new TopLevelASDescription()
{
    Flags = AccelerationStructureFlags.None,
    Instances = new AccelerationStructureInstance[] { instance },
};

var tlas = commandBuffer.BuildRaytracingAccelerationStructure(topLevel);

commandBuffer.End();
commandBuffer.Commit();
this.graphicCommandQueue.Submit();
this.graphicCommandQueue.WaitIdle();
```

The vertex buffer feeding a bottom level structure has to be created with `BufferFlags.AccelerationStructure` alongside its usual flags:

```csharp
var vertexBufferDescription = new BufferDescription(
    (uint)Unsafe.SizeOf<Vector3>() * (uint)this.vertexData.Length,
    BufferFlags.VertexBuffer | BufferFlags.AccelerationStructure,
    ResourceUsage.Default);
```

Use `AccelerationStructureAABBs` in place of `AccelerationStructureTriangles` for procedural geometry, which is intersected by your own shader rather than by fixed-function triangle tests.

> [!WARNING]
> The field naming the bottom level structure on an instance is spelled `BottonLevel`. That is the name in the API.

Only the top level structure moves. When instances change position you rebuild it with `UpdateRaytracingAccelerationStructure` and leave the bottom level structures alone, which is far cheaper than rebuilding geometry every frame.

## Creating the pipeline

```csharp
var pipelineDescription = new RaytracingPipelineDescription(
    new[] { resourcesLayout },
    new RaytracingShaderStateDescription()
    {
        RayGenerationShader = raygenerationShader,
        ClosestHitShader = new[] { closestHitShader },
        MissShader = new[] { missShader },
    },
    new HitGroupDescription[]
    {
        new HitGroupDescription()
        {
            Name = "RaygenGroup",
            Type = HitGroupDescription.HitGroupType.General,
            GeneralEntryPoint = "rayGen",
        },
        new HitGroupDescription()
        {
            Name = "MissGroup",
            Type = HitGroupDescription.HitGroupType.General,
            GeneralEntryPoint = "miss",
        },
        new HitGroupDescription()
        {
            Name = "HitGroup",
            Type = HitGroupDescription.HitGroupType.Triangles,
            ClosestHitEntryPoint = "chs",
        },
    },
    1,                  // Max recursion depth: primary rays only.
    sizeof(float) * 3,  // Max payload size: a float3 colour.
    sizeof(float) * 2); // Max attribute size: float2 barycentrics.

this.pipelineState = this.graphicsContext.Factory.CreateRaytracingPipeline(ref pipelineDescription);
```

### RaytracingPipelineDescription

| Property | Type | Description |
| --- | --- | --- |
| **ResourceLayouts** | `ResourceLayout[]` | The layouts the ray tracing shaders read. |
| **Shaders** | `RaytracingShaderStateDescription` | The shader programs, grouped by role. |
| **HitGroups** | `HitGroupDescription[]` | Names the entry points and ties them together into groups. |
| **MaxTraceRecursionDepth** | `uint` | How deep `TraceRay` may nest. Range 0 to 31. Keep it as low as the effect allows. |
| **MaxPayloadSizeInBytes** | `uint` | Largest ray payload, counted in 4 byte scalars. |
| **MaxAttributeSizeInBytes** | `uint` | Largest hit attribute structure. Barycentrics need 8 bytes. |

### RaytracingShaderStateDescription

| Property | Type | Description |
| --- | --- | --- |
| **RayGenerationShader** | `Shader` | Launches the rays. One per pipeline. |
| **ClosestHitShader** | `Shader[]` | Runs at the nearest hit along a ray. |
| **MissShader** | `Shader[]` | Runs when a ray hits nothing. |
| **AnyHitShader** | `Shader[]` | Runs at every candidate hit, for alpha tested surfaces. |
| **IntersectionShader** | `Shader[]` | Custom intersection test, for procedural geometry. |

Only the ray generation shader is a single value. The rest are arrays, because one pipeline can carry several variants and a hit group picks between them by entry point name.

### HitGroupDescription

| Property | Type | Description |
| --- | --- | --- |
| **Type** | `HitGroupType` | `General`, `Triangles` or `Procedural`. |
| **Name** | `string` | The name of the group, used to build the shader table. |
| **GeneralEntryPoint** | `string` | Entry point for a `General` group, such as the ray generation or miss shader. |
| **ClosestHitEntryPoint** | `string` | Entry point run at the closest hit. |
| **AnyHitEntryPoint** | `string` | Entry point run at each candidate hit. |
| **IntersectionEntryPoint** | `string` | Entry point for the intersection test. `Procedural` groups only. |

> [!IMPORTANT]
> The entry point strings have to match the function names in the shader source exactly. They are resolved by name when the pipeline is created, so a typo appears as a pipeline that fails to build rather than as a compiler error.

## Tracing

A ray tracing pass writes into a texture, so that texture is bound as `ResourceType.TextureViewReadWrite` and needs `TextureFlags.UnorderedAccess`. The acceleration structure goes in a slot declared as `ResourceType.AccelerationStructure`:

```csharp
ResourceLayoutDescription layoutDescription = new ResourceLayoutDescription(
    new LayoutElementDescription(0, ResourceType.TextureViewReadWrite, ShaderStages.RayGeneration),
    new LayoutElementDescription(0, ResourceType.AccelerationStructure, ShaderStages.RayGeneration));

ResourceSetDescription resourceSetDescription = new ResourceSetDescription(resourcesLayout, this.output, tlas);
```

A dispatch covers a grid the same way a compute dispatch does, with one ray generation invocation per cell:

```csharp
commandBuffer.SetRaytracingPipelineState(this.pipelineState);
commandBuffer.SetResourceSet(this.resourceSet);
commandBuffer.DispatchRays(new DispatchRaysDescription()
{
    Width = this.width,
    Height = this.height,
    Depth = 1,
});
```

Like compute, this happens outside a render pass. Copy or sample the result afterwards, with the barriers that transition demands.

### DispatchRaysDescription

| Property | Type | Description |
| --- | --- | --- |
| **Width** | `uint` | Width of the ray generation thread grid. |
| **Height** | `uint` | Height of the grid. |
| **Depth** | `uint` | Depth of the grid. Use `1` for a flat image. |

## Cleaning up

```csharp
pipelineState.Dispose();
tlas.Dispose();
blas.Dispose();
```
