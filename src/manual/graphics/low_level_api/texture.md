# Texture

A **Texture** object in a low-level API is a 2D object (1D and 3D textures also exist) used to provide details to objects or to map information.

Please read the [Graphics Texture](../textures/index.md) section for high-level asset information and usage in Evergine Studio.

## Creation

To create a texture, you first need to create the `TextureDescription` struct:

```csharp
uint expectedSize = 256;
ResourceUsage expectedUsage = ResourceUsage.Default;

var description = new TextureDescription()
{
    Type = TextureType.Texture2D,
    Width = expectedSize,
    Height = expectedSize,
    Depth = 1,
    Layers = 1,
    Usage = expectedUsage,
    CpuAccess = ResourceCpuAccess.None,
    Flags = TextureFlags.None,
    Format = expectedFormat,
    MipLevels = 1,
    SampleCount = TextureSampleCount.None,
};

var texture = this.GraphicsContext.Factory.CreateTexture(ref description);
```

### TextureDescription

| Property | Type | Description |
|--------| ----------- |----------- |
| **Type** | `TextureType` | Type of the texture. |
| **Format** | `PixelFormat` | Format of the texture pixels. |
| **Width** | `uint` | Width of the texture (in texels). |
| **Height** | `uint` | Height of the texture (in texels). |
| **Depth** | `uint` | Depth of the texture (in texels). |
| **Layers** | `uint` | Total number of texture layers. For texture arrays this is the array size; for cubemaps each face counts as one layer (e.g. a single cubemap has `Layers = 6`; a cubemap array of 4 has `Layers = 24`). |
| **MipLevels** | `uint` | The maximum number of mipmap levels in the texture.|
| **Flags** | `TextureFlags` | The texture flags. |
| **Usage** | `ResourceUsage` | Value that identifies how the texture is to be read from and written to. |
| **SampleCount** | `TextureSampleCount` | The number of samples in this texture. |
| **CpuAccess** | `ResourceCpuAccess` | Flags specifying the type of CPU access allowed. |

### TextureType

Specifies the texture type.

| TextureType | Description |
|--------| ----------- |
| **Texture2D** | Represents a two-dimensional texture. |
| **Texture2DArray** | Represents an array of 2D textures. |
| **Texture1D** | Represents a one-dimensional texture. |
| **Texture1DArray** | Represents an array of 1D textures. |
| **TextureCube** | Represents a 6-face texture cube. |
| **TextureCubeArray** | Represents an array of texture cubes. |
| **Texture3D** | Represents a three-dimensional texture. |

### PixelFormat

Specifies the byte format used in each texel. The most common formats are:

| PixelFormat | Description |
|--------| ----------- |
| **R8_UNorm** | A single-component, 8-bit unsigned-normalized-integer format that supports 8 bits for the red channel. |
| **R8G8_UNorm** | A two-component, 16-bit unsigned-normalized-integer format that supports 8 bits for the red channel and 8 bits for the green channel. |
| **R8G8B8A8_UNorm** | A four-component, 32-bit unsigned-normalized-integer format that supports 8 bits per channel including alpha. |
| **R8G8B8A8_UNorm_SRgb** | A four-component, 32-bit unsigned-normalized integer sRGB format that supports 8 bits per channel including alpha. |
| **R16_Float** | A single-component, 16-bit floating-point format that supports 16 bits for the red channel. |
| **R16_SInt** | A single-component, 16-bit signed-integer format that supports 16 bits for the red channel. |
| **R16_UInt** | A single-component, 16-bit unsigned-integer format that supports 16 bits for the red channel. |
| **R16_UNorm** | A single-component, 16-bit unsigned-normalized-integer format that supports 16 bits for the red channel. |
| **R16G16_Float** | A two-component, 32-bit floating-point format that supports 16 bits for the red channel and 16 bits for the green channel. |
| **R16G16_SInt** | A two-component, 32-bit signed-integer format that supports 16 bits for the red channel and 16 bits for the green channel. |
| **R16G16_UInt** | A two-component, 32-bit unsigned-integer format that supports 16 bits for the red channel and 16 bits for the green channel. |
| **R16G16B16A16_Float** | A four-component, 64-bit floating-point format that supports 16 bits per channel including alpha.|
| **R16G16B16A16_SInt** | A four-component, 64-bit signed-integer format that supports 16 bits per channel including alpha. |
| **R16G16B16A16_UInt** | A four-component, 64-bit unsigned-integer format that supports 16 bits per channel including alpha. |
| **R32_Float** | A single-component, 32-bit floating-point format that supports 32 bits for the red channel. |
| **R32_SInt** | A single-component, 32-bit signed-integer format that supports 32 bits for the red channel. |
| **R32_UInt** | A single-component, 32-bit unsigned-integer format that supports 32 bits for the red channel. |
| **R32G32_Float** | A two-component, 64-bit floating-point format that supports 32 bits for the red channel and 32 bits for the green channel. |
| **R32G32_SInt** | A two-component, 64-bit signed-integer format that supports 32 bits for the red channel and 32 bits for the green channel. |
| **R32G32_UInt** | A two-component, 64-bit unsigned-integer format that supports 32 bits for the red channel and 32 bits for the green channel. |
| **R32G32B32_Float** | A three-component, 96-bit floating-point format that supports 32 bits per color channel. |
| **R32G32B32_SInt** | A three-component, 96-bit signed-integer format that supports 32 bits per color channel. |
| **R32G32B32_UInt** | A three-component, 96-bit unsigned-integer format that supports 32 bits per color channel. |
| **R32G32B32A32_Float** | A four-component, 128-bit floating-point format that supports 32 bits per channel including alpha. |
| **R32G32B32A32_SInt** | A four-component, 128-bit signed-integer format that supports 32 bits per channel including alpha. |
| **R32G32B32A32_UInt** | A four-component, 128-bit unsigned-integer format that supports 32 bits per channel including alpha. |

> [!Note]
> See the [PixelFormat](xref:Evergine.Common.Graphics.PixelFormat) enum in the `Evergine.Common` namespace for the complete list.

### TextureFlags

Identifies how to bind a texture.

| TextureFlags | Description |
|--------| ----------- |
| **None** | Not specified, **Default value**. |
| **ShaderResource** | A texture usable as a `ShaderResourceView`. |
| **RenderTarget** | A texture usable as a render target. |
| **UnorderedAccess** | A texture usable as an unordered access buffer. |
| **DepthStencil** | A texture usable as a depth stencil buffer. |
| **GenerateMipmaps** | Enables MIP map generation by the GPU. |

### ResourceUsage

Identifies expected resource usage during rendering.

| ResourceUsage | Description |
|--------| ----------- |
| **Default** | A resource that requires read and write access by the GPU, **Default value**. |
| **Immutable** | A resource that can only be read by the GPU. It cannot be written by the GPU and cannot be accessed at all by the CPU. |
| **Dynamic** | A resource that is accessible by both the GPU (read only) and the CPU (write only). |
| **Staging** | A resource that supports data transfer (copy) from the GPU to the CPU. |

### TextureSampleCount

Describes the number of samples to use in a texture.

| TextureSampleCount | Description |
|--------| ----------- |
| **None** | Not multisample, **Default value**. |
| **Count2** | Multisample count of 2 pixels. |
| **Count4** | Multisample count of 4 pixels. |
| **Count8** | Multisample count of 8 pixels. |
| **Count16** | Multisample count of 16 pixels. |
| **Count32** | Multisample count of 32 pixels. |

### ResourceCpuAccess

Specifies the types of CPU access allowed for a resource.

| ResourceCpuAccess | Description |
|--------| ----------- |
| **None** | Not specified, **Default value**. |
| **Write** | The CPU can write to this resource. |
| **Read** | The CPU can read from this resource. |

## Usage examples

### How to create and fill a texture by code

```csharp
uint expectedSize = 256;

var description = new TextureDescription()
{
    Type = TextureType.Texture2D,
    Width = expectedSize,
    Height = expectedSize,
    Depth = 1,
    Layers = 1,
    Usage = ResourceUsage.Default,
    CpuAccess = ResourceCpuAccess.None,
    Flags = TextureFlags.None,
    Format = PixelFormat.R8G8B8A8_UNorm,
    MipLevels = 1,
    SampleCount = TextureSampleCount.None,
};

float[] data = Enumerable.Range(0, (int)(expectedSize * expectedSize)).Select(i => (float)i).ToArray();

var rowPitch = Common.Graphics.Helpers.GetRowPitch(expectedSize, PixelFormat.R8G8B8A8_UNorm);
var slicePitch = Common.Graphics.Helpers.GetSlicePitch(rowPitch, expectedSize, PixelFormat.R8G8B8A8_UNorm);

var pinnedHandle = GCHandle.Alloc(data, GCHandleType.Pinned);
IntPtr dataPointer = Marshal.UnsafeAddrOfPinnedArrayElement(data, 0);
var databox = new DataBox[] { new DataBox(dataPointer, rowPitch, slicePitch) };

var texture = this.GraphicsContext.Factory.CreateTexture(databox, ref description);

pinnedHandle.Free();
```

### How to update a default texture

```csharp
uint expectedSize = 256;
ResourceUsage expectedUsage = ResourceUsage.Default;
PixelFormat expectedFormat = PixelFormat.R8G8B8A8_UNorm;

var description = new TextureDescription()
{
    Type = TextureType.Texture2D,
    Width = expectedSize,
    Height = expectedSize,
    Depth = 1,
    Layers = 1,
    Usage = expectedUsage,
    CpuAccess = ResourceCpuAccess.None,
    Flags = TextureFlags.None,
    Format = expectedFormat,
    MipLevels = 1,
    SampleCount = TextureSampleCount.None,
};

var texture = this.GraphicsContext.Factory.CreateTexture(ref description);

float[] data = Enumerable.Range(0, (int)(expectedSize * expectedSize)).Select(i => (float)i).ToArray();

this.GraphicsContext.UpdateTextureData(texture, data);
texture.Dispose();
```

### How to copy from another device texture

```csharp
uint expectedSize = 256;

var description = new TextureDescription()
{
    Type = TextureType.Texture2D,
    Width = expectedSize,
    Height = expectedSize,
    Depth = 1,
    Layers = 1,
    Usage = ResourceUsage.Default,
    CpuAccess = ResourceCpuAccess.None,
    Flags = TextureFlags.None,
    Format = PixelFormat.R8G8B8A8_UNorm,
    MipLevels = 1,
    SampleCount = TextureSampleCount.None,
};

var texture = this.GraphicsContext.Factory.CreateTexture(ref description);

float[] data = Enumerable.Range(0, 256 * 256).Select(i => (float)i).ToArray();
this.GraphicsContext.UpdateTextureData(texture, data);

var textureCopy = this.GraphicsContext.Factory.CreateTexture(ref description);

var queue = this.GraphicsContext.Factory.CreateCommandQueue();
var command = queue.CommandBuffer();

command.Begin();
command.CopyTextureDataTo(texture, textureCopy);
command.End();
command.Commit();
queue.Submit();
queue.WaitIdle();

texture.Dispose();
textureCopy.Dispose();
queue.Dispose();
```

### How to set data in a staging texture

```csharp
uint expectedSize = 256;

var description = new TextureDescription()
{
    Type = TextureType.Texture2D,
    Width = expectedSize,
    Height = expectedSize,
    Depth = 1,
    Layers = 1,
    Usage = ResourceUsage.Staging,
    CpuAccess = ResourceCpuAccess.Write | ResourceCpuAccess.Read,
    Flags = TextureFlags.None,
    Format = PixelFormat.R8G8B8A8_UNorm,
    MipLevels = 1,
    SampleCount = TextureSampleCount.None,
};

var texture = this.GraphicsContext.Factory.CreateTexture(ref description);

float[] data = Enumerable.Range(0, (int)(expectedSize * expectedSize)).Select(i => (float)i).ToArray();

this.GraphicsContext.UpdateTextureData(texture, data);

texture.Dispose();
```

### How to map and read a staging texture

```csharp
uint expectedSize = 256;

var description = new TextureDescription()
{
    Type = TextureType.Texture2D,
    Width = expectedSize,
    Height = expectedSize,
    Depth = 1,
    Layers = 1,
    Usage = ResourceUsage.Staging,
    CpuAccess = ResourceCpuAccess.Write | ResourceCpuAccess.Read,
    Flags = TextureFlags.None,
    Format = PixelFormat.R8G8B8A8_UNorm,
    MipLevels = 1,
    SampleCount = TextureSampleCount.None,
};

var texture = this.GraphicsContext.Factory.CreateTexture(ref description);

float[] data = Enumerable.Range(0, (int)(expectedSize * expectedSize)).Select(i => (float)i).ToArray();

this.GraphicsContext.UpdateTextureData(texture, data);

var mappedResource = this.GraphicsContext.MapMemory(texture, MapMode.Read);
for (int y = 0; y < expectedSize; y++)
{
    for (int x = 0; x < expectedSize; x++)
    {
        int offset = ((y * ((int)mappedResource.RowPitch / sizeof(float))) + x) * sizeof(float);
        float* pointer = (float*)(mappedResource.Data + offset);
        int index = (y * (int)expectedSize) + x;
        Assert.Equal(data[index], *pointer);
    }
}

this.GraphicsContext.UnmapMemory(texture);

texture.Dispose();
```