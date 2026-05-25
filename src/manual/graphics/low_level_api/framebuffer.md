# Framebuffer

Framebuffers represent a collection of memory attachments that are used by a render pass instance. Examples of these memory attachments include color textures and a depth texture.

## Creation

A framebuffer provides the attachments that a RenderPass needs while rendering.

```csharp
// Create Render Target FrameBuffer
var rTColorTargetDescription = new TextureDescription()
{
    Format = PixelFormat.R8G8B8A8_UNorm,
    Width = rtSize,
    Height = rtSize,
    Depth = 1,
    Layers = 1,
    Flags = TextureFlags.RenderTarget | TextureFlags.ShaderResource,
    CpuAccess = ResourceCpuAccess.None,
    MipLevels = 1,
    Type = TextureType.Texture2D,
    Usage = ResourceUsage.Default,
    SampleCount = TextureSampleCount.None,
};
var rTColorTarget = this.graphicsContext.Factory.CreateTexture(ref rTColorTargetDescription);

var rTDepthTargetDescription = new TextureDescription()
{
    Format = PixelFormat.D24_UNorm_S8_UInt,
    Width = rtSize,
    Height = rtSize,
    Depth = 1,
    Layers = 1,
    Flags = TextureFlags.DepthStencil,
    CpuAccess = ResourceCpuAccess.None,
    MipLevels = 1,
    Type = TextureType.Texture2D,
    Usage = ResourceUsage.Default,
    SampleCount = TextureSampleCount.None,
};

var rTDepthTarget = this.graphicsContext.Factory.CreateTexture(ref rTDepthTargetDescription);
var depthAttachment = new FrameBufferAttachment(rTDepthTarget, 0, 1);
var colorAttachments = new[] { new FrameBufferAttachment(rTColorTarget, 0, 1) };
this.rTFrameBuffer = this.graphicsContext.Factory.CreateFrameBuffer(depthAttachment, colorAttachments);
```

## How to Use

First, you need to create a graphics pipeline that uses the framebuffer output description:

```csharp
var trianglePipelineDescription = new GraphicsPipelineDescription()
{
    PrimitiveTopology = PrimitiveTopology.TriangleList,
    InputLayouts = triangleVertexLayouts,
    ResourceLayouts = new[] { triangleResourceLayout },
    Shaders = new GraphicsShaderStateDescription()
    {
        VertexShader = triangleVertexShader,
        PixelShader = trianglePixelShader,
    },
    RenderStates = new RenderStateDescription()
    {
        RasterizerState = RasterizerStates.None,
        BlendState = BlendStates.Opaque,
        DepthStencilState = DepthStencilStates.None,
    },
    Outputs = this.rTFrameBuffer.OutputDescription,
};

this.trianglePipelineState = this.graphicsContext.Factory.CreateGraphicsPipeline(ref trianglePipelineDescription);
```

Finally, you can use it to start a render pass:

```csharp
// Render to texture
var commandBuffer = this.commandQueue.CommandBuffer();

commandBuffer.Begin();

RenderPassDescription renderPassDescription = new RenderPassDescription(this.rTFrameBuffer, new ClearValue(ClearFlags.Target, Color.CornflowerBlue));
commandBuffer.BeginRenderPass(ref renderPassDescription);

commandBuffer.SetViewports(this.rTViewports);
commandBuffer.SetScissorRectangles(this.scissors);
commandBuffer.SetGraphicsPipelineState(this.trianglePipelineState);
commandBuffer.SetResourceSet(this.triangleResourceSet);
commandBuffer.SetVertexBuffers(this.triangleVertexBuffers);

commandBuffer.Draw((uint)this.triangleVertexData.Length);

commandBuffer.EndRenderPass();
commandBuffer.End();
commandBuffer.Commit();

this.commandQueue.Submit();
this.commandQueue.WaitIdle();
```