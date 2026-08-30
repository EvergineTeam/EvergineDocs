# Buffer

A `Buffer` is a block of GPU memory. What it holds is up to you: vertex positions and normals, indices, constant data a shader reads each frame, or a structured buffer a compute shader writes into.

What it can be used for, though, is fixed when you create it. `BufferFlags` decides which pipeline stages may bind it, which [barrier](barriers.md) states it can be moved between, and which [ResourceType](resourcelayout.md#resourcetype) slot it can fill in a [ResourceSet](resourceset.md).

## Creation

To create a buffer, first, you need to create the BufferDescription struct:

```csharp
// Populate some data for the buffer...
Vector4[] vertexData = new Vector4[]
{
    new Vector4(0.0f, 0.2f, 0.0f, 1.0f),   new Vector4(1.0f, 0.0f, 0.0f, 1.0f),
    new Vector4(0.2f, -0.2f, 0.0f, 1.0f),  new Vector4(0.0f, 1.0f, 0.0f, 1.0f),
    new Vector4(-0.2f, -0.2f, 0.0f, 1.0f), new Vector4(0.0f, 0.0f, 1.0f, 1.0f),
};

uint expectedSize = (4 * 4) * (uint)vertexData.Length;
BufferFlags expectedFlags = BufferFlags.VertexBuffer;
ResourceUsage expectedUsage = ResourceUsage.Default;

// Create the BufferDescription....
BufferDescription bufferDescription = new BufferDescription(expectedSize, expectedFlags, expectedUsage);

// Create the Buffer
Buffer buffer = this.graphicsContext.Factory.CreateBuffer(vertexData, ref bufferDescription);
```

### BufferDescription

| Property | Type | Description |
|--------| ----------- |----------- |
| **SizeInBytes** | `uint` | Retrieves or sets the size of the new buffer. |
| **Flags** | `BufferFlags` | Buffer flags describing the buffer type. |
| **CpuAccess** | `ResourceCpuAccess` | Specifies the types of CPU access allowed for this buffer. |
| **Usage** | `ResourceUsage` | Usage of this buffer. |
| **StructureByteStride** | `int` | The structure byte stride. |

### ResourceUsage

Identifies expected resource usage during rendering.

| ResourceUsage | Description |
|--------| ----------- |
| **Default**    | A resource that requires read and write access by the GPU. **Default value.** |
| **Immutable**  | A resource that can only be read by the GPU. It cannot be written by the GPU and cannot be accessed at all by the CPU. |
| **Dynamic**    | A resource that is accessible by both the GPU (read-only) and the CPU (write-only). |
| **Staging**    | A resource that supports data transfer (copy) from the GPU to the CPU. |

### BufferFlags

Identifies how to bind a buffer. This flag gives a hint to the graphics API about how this buffer will be used.

| BufferFlags | Description |
|--------| ----------- |
| **None**               | No option. |
| **VertexBuffer**       | Bind a buffer as a vertex buffer to the input-assembler stage. |
| **IndexBuffer**        | Bind a buffer as an index buffer to the input-assembler stage. |
| **ConstantBuffer**     | Bind a buffer as a constant buffer to a shader stage. This flag may NOT be combined with any other bind flag. |
| **ShaderResource**     | Bind a buffer or texture to a shader stage. |
| **AccelerationStructure** | Bind a buffer to be used in a raytracing stage. |
| **RenderTarget**       | Bind a texture as a render target for the output-merger stage. |
| **UnorderedAccess**    | Bind a buffer as an unordered access resource. |
| **BufferStructured**   | Bind a buffer as a structured buffer resource. |
| **IndirectBuffer**     | Bind a buffer as an indirect buffer to the input-assembler stage. |

### ResourceCpuAccess

Specifies the types of CPU access allowed for a resource.

| ResourceCpuAccess | Description |
|--------| ----------- |
| **None**   | Not specified. **Default value.** |
| **Write**  | The CPU can write to this resource. |
| **Read**   | The CPU can read from this resource. |

## Usage examples

### How to update a default buffer

In this case, you just need to execute the `GraphicsContext.UpdateBufferData(...)` method:

```csharp
var vertexData = new Vector4[]
{
    new Vector4(0.0f, 0.2f, 0.0f, 1.0f),   new Vector4(1.0f, 0.0f, 0.0f, 1.0f),
    new Vector4(0.2f, -0.2f, 0.0f, 1.0f),  new Vector4(0.0f, 1.0f, 0.0f, 1.0f),
    new Vector4(-0.2f, -0.2f, 0.0f, 1.0f), new Vector4(0.0f, 0.0f, 1.0f, 1.0f),
};

// Creates a Buffer without data...
uint sizeInBytes = (4 * 4) * (uint)vertexData.Length;
var bufferDescription = new BufferDescription(sizeInBytes, BufferFlags.VertexBuffer, ResourceUsage.Default);
var buffer = this.graphicsContext.Factory.CreateBuffer(ref bufferDescription);

// Update buffer...
this.graphicsContext.UpdateBufferData(buffer, vertexData);
```

### How to copy one default buffer into another

In this case, you need to execute the `CommandBuffer.CopyBufferDataTo(...)` method. To do this, you need to obtain a `CommandBuffer` instance and enqueue the copy command:

```csharp
var vertexData = new Vector4[]
{
    new Vector4(0.0f, 0.2f, 0.0f, 1.0f),   new Vector4(1.0f, 0.0f, 0.0f, 1.0f),
    new Vector4(0.2f, -0.2f, 0.0f, 1.0f),  new Vector4(0.0f, 1.0f, 0.0f, 1.0f),
    new Vector4(-0.2f, -0.2f, 0.0f, 1.0f), new Vector4(0.0f, 0.0f, 1.0f, 1.0f),
};

// Creates the source buffer with some vertex data...
var description = new BufferDescription(
    4 * 4 * (uint)vertexData.Length,
    BufferFlags.VertexBuffer,
    ResourceUsage.Default);

var buffer = this.graphicsContext.Factory.CreateBuffer(vertexData, ref description);

// Creates an empty buffer with the same size and properties as before...
var bufferCopyDescription = new BufferDescription(
    (4 * 4) * (uint)vertexData.Length,
    BufferFlags.VertexBuffer,
    ResourceUsage.Default);

var bufferCopy = this.graphicsContext.Factory.CreateBuffer(ref bufferCopyDescription);

// Creates a CommandBuffer to execute the copy command...
var queue = this.graphicsContext.Factory.CreateCommandQueue();
var command = queue.CommandBuffer();
command.Begin();

// Execute the CopyBufferDataTo() commandBuffer method to copy data from one buffer to another...
command.CopyBufferDataTo(buffer, bufferCopy, buffer.Description.SizeInBytes);

// Commit and submit the commandBuffer...
command.End();
command.Commit();
queue.Submit();
queue.WaitIdle();

buffer.Dispose();
bufferCopy.Dispose();
queue.Dispose();
```

### How to read a default buffer through a staging buffer

In order to read a Default Buffer, you need to copy the content into a Staging Buffer first. Once you do this, you can map the Staging Buffer to CPU memory and access the data without problems:

```csharp
var vertexData = new Vector4[]
{
    new Vector4(0.0f, 0.2f, 0.0f, 1.0f),   new Vector4(1.0f, 0.0f, 0.0f, 1.0f),
    new Vector4(0.2f, -0.2f, 0.0f, 1.0f),  new Vector4(0.0f, 1.0f, 0.0f, 1.0f),
    new Vector4(-0.2f, -0.2f, 0.0f, 1.0f), new Vector4(0.0f, 0.0f, 1.0f, 1.0f),
};

// Create the source buffer with some data...
var description = new BufferDescription(
    4 * 4 * (uint)vertexData.Length,
    BufferFlags.VertexBuffer,
    ResourceUsage.Default);

var buffer = this.graphicsContext.Factory.CreateBuffer(vertexData, ref description);

// Creates the staging buffer...
var stagingDescription = new BufferDescription(
    4 * 4 * (uint)vertexData.Length,
    BufferFlags.None,
    ResourceUsage.Staging, // Use Staging as ResourceUsage...
    ResourceCpuAccess.Read);

var stagingBuffer = this.graphicsContext.Factory.CreateBuffer(ref stagingDescription);

// Copy the buffer data like the previous example...
var queue = this.graphicsContext.Factory.CreateCommandQueue();
var command = queue.CommandBuffer();

command.Begin();
command.CopyBufferDataTo(buffer, stagingBuffer, buffer.Description.SizeInBytes);
command.End();
command.Commit();
queue.Submit();
queue.WaitIdle();

// To read the buffer data, map the buffer into the CPU memory...
var readableResource = this.graphicsContext.MapMemory(stagingBuffer, MapMode.Read);

// Reading through a pointer needs an unsafe context...
var readBack = new Vector4[vertexData.Length];

unsafe
{
    for (int i = 0; i < readBack.Length; i++)
    {
        Vector4* pointer = (Vector4*)(readableResource.Data + (i * sizeof(Vector4)));
        readBack[i] = *pointer;
    }
}

// Unmap the memory to free the CPU memory resources...
this.graphicsContext.UnmapMemory(stagingBuffer);

buffer.Dispose();
stagingBuffer.Dispose();
queue.Dispose();
```

### How to map a dynamic buffer

A Dynamic Buffer can be updated directly from the CPU. To do this, you only need to map a Buffer and write the data directly to the mapped pointer:

```csharp
var vectorSize = (uint)Unsafe.SizeOf<Vector4>();
var vertexData = new Vector4[]
{
    new Vector4(0.0f, 0.2f, 0.0f, 1.0f),   new Vector4(1.0f, 0.0f, 0.0f, 1.0f),
    new Vector4(0.2f, -0.2f, 0.0f, 1.0f),  new Vector4(0.0f, 1.0f, 0.0f, 1.0f),
    new Vector4(-0.2f, -0.2f, 0.0f, 1.0f), new Vector4(0.0f, 0.0f, 1.0f, 1.0f),
};

var dynamicDescription = new BufferDescription(
    vectorSize * (uint)vertexData.Length,
    BufferFlags.VertexBuffer,
    ResourceUsage.Dynamic,
    ResourceCpuAccess.Write);

var dynamicBuffer = this.graphicsContext.Factory.CreateBuffer(ref dynamicDescription);

// Map the write staging and leave mapped...
var writableResource = this.graphicsContext.MapMemory(dynamicBuffer, MapMode.Write);

Vector4* pointer = (Vector4*)writableResource.Data;
for (int i = 0; i < vertexData.Length; i++)
{
    *pointer = vertexData[i];
    pointer++;
}

// Once the buffer is unmapped, the new buffer content is accessible by the GPU...
this.graphicsContext.UnmapMemory(dynamicBuffer);

dynamicBuffer.Dispose();
```