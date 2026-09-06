# Shader

A `Shader` is one compiled shader program: a single stage, with a single entry point, in a form the current backend can execute. You create one per stage and hand them to a pipeline, which is what binds them together into something the GPU can run.

Compiling and creating are separate steps. `GraphicsContext.ShaderCompile` turns source text into bytecode, and `ResourceFactory.CreateShader` turns that bytecode into a `Shader`.

## Compiling from source

```csharp
string source = File.ReadAllText("Shaders/HLSL/VertexShader.fx");

CompilationResult result = this.graphicsContext.ShaderCompile(source, "VS", ShaderStages.Vertex);
if (result.HasErrors)
{
    throw new InvalidOperationException($"Line {result.ErrorLine}: {result.Message}");
}

var shaderDescription = new ShaderDescription(ShaderStages.Vertex, "VS", result.ByteCode);
var vertexShader = this.graphicsContext.Factory.CreateShader(ref shaderDescription);
```

### CompilationResult

| Property | Type | Description |
| --- | --- | --- |
| **ByteCode** | `byte[]` | The compiled bytecode. Pass it to `ShaderDescription`. |
| **HasErrors** | `bool` | `true` when compilation failed. Check it before using `ByteCode`. |
| **ErrorLine** | `uint` | The line the compiler stopped on, when `HasErrors` is `true`. |
| **Message** | `string` | The compiler's message, when `HasErrors` is `true`. |

> [!WARNING]
> `ShaderCompile` reports failure through `HasErrors` rather than by throwing. A shader that failed to compile has a null or empty `ByteCode`, and `CreateShader` will then fail somewhere less obvious. Check the result at the point of compilation.

### CompilerParameters

The three-argument overload of `ShaderCompile` uses `CompilerParameters.Default`. Pass your own to change the target profile or ask for debug information:

```csharp
var parameters = new CompilerParameters()
{
    Profile = GraphicsProfile.Level_11_0,
    CompilationMode = CompilationMode.Debug,
};

var result = this.graphicsContext.ShaderCompile(source, "VS", ShaderStages.Vertex, parameters);
```

| Property | Type | Description |
| --- | --- | --- |
| **Profile** | `GraphicsProfile` | The feature level to compile against. `Level_10_0` by default. |
| **CompilationMode** | `CompilationMode` | `None` by default. `Debug` keeps debugging information, `Release` optimises. |

### GraphicsProfile

The profile you compile against has to be one the target device actually supports. Ray tracing needs `Level_12_0` or above, and mesh shaders need `Level_12_5`.

| GraphicsProfile | Target |
| --- | --- |
| **Level_9_1**, **Level_9_2**, **Level_9_3** | DirectX 9, HLSL 3.0, OpenGL ES 2.0 |
| **Level_10_0** | DirectX 10, HLSL 4.0, OpenGL ES 3.0. **Default value.** |
| **Level_10_1** | DirectX 10.1, HLSL 4.1, OpenGL ES 3.0 |
| **Level_11_0** | DirectX 11, HLSL 5.0, OpenGL ES 3.1, OpenGL 4.0 |
| **Level_11_1** | DirectX 11, HLSL 5.0, OpenGL ES 3.1, OpenGL 4.1 |
| **Level_12_0** | Shader Model 6.0. Wave intrinsics, basic ray tracing. |
| **Level_12_1** | Shader Model 6.1. Ray tracing functions and structures. |
| **Level_12_2** | Shader Model 6.2. 16-bit scalar types. |
| **Level_12_3** | Shader Model 6.3. Ray tracing enhancements. |
| **Level_12_4** | Shader Model 6.4. Wave matrix intrinsics. |
| **Level_12_5** | Shader Model 6.5. Mesh and amplification shaders. |
| **Level_12_6** | Shader Model 6.6. 64-bit atomics, packed intrinsics. |
| **Level_12_7** | Shader Model 6.7. QuadAny and QuadAll, writable MSAA. |

## Creating the shader

### ShaderDescription

| Property | Type | Description |
| --- | --- | --- |
| **Stage** | `ShaderStages` | The single stage this program is for. See the [ShaderStages table](resourcelayout.md#shaderstages). |
| **EntryPoint** | `string` | The name of the function to run, such as `VS` or `PS`. It has to match the source. |
| **ShaderBytes** | `byte[]` | The bytecode, normally `CompilationResult.ByteCode`. |

All three fields are read only, so a description is fixed once constructed.

> [!NOTE]
> `Stage` takes a single value here, not a combination. One `Shader` covers one stage, and a pipeline lists them separately through `GraphicsShaderStateDescription`.

## One shader, six languages

There is no single shader language across backends. Each one wants its own source, and two of them want bytecode that was produced ahead of time rather than compiled at runtime:

| Backend | Language | Extension | How it is loaded |
| --- | --- | --- | --- |
| **DirectX 11**, **DirectX 12** | HLSL | `.fx` | Compiled at runtime by `ShaderCompile` |
| **OpenGL** | GLSL | `.glsl` | Compiled at runtime by `ShaderCompile` |
| **OpenGL ES**, **WebGL** | GLSL ES | `.essl` | Compiled at runtime by `ShaderCompile` |
| **Metal** | MSL | `.msl` | Compiled at runtime by `ShaderCompile` |
| **Vulkan** | SPIR-V | `.spirv` | Read as bytes, already compiled |
| **WebGPU** | WGSL | `.wgsl` | Read as bytes, no compilation step |

The usual arrangement is to write HLSL, cross-compile it to the other five as a build step, and pick the right file at load time from `graphicsContext.BackendType`:

```csharp
GraphicsBackend backend = this.graphicsContext.BackendType;

switch (backend)
{
    case GraphicsBackend.DirectX11:
    case GraphicsBackend.DirectX12:
        source = await this.assetsDirectory.ReadAsStringAsync($"Shaders/HLSL/{fileName}.fx");
        bytecode = this.graphicsContext.ShaderCompile(source, entryPoint, stage, parameters).ByteCode;
        break;

    case GraphicsBackend.Vulkan:
        using (var stream = this.assetsDirectory.Open($"Shaders/VK/{fileName}.spirv"))
        using (var memstream = new MemoryStream())
        {
            stream.CopyTo(memstream);
            bytecode = memstream.ToArray();
        }

        break;
}
```

> [!TIP]
> The [Low-Level API samples](https://github.com/evergineteam/LowLevelAPIDemo) keep one folder per language under `Shaders/`, and ship a translation script that regenerates the other five from the HLSL. `TestHelpers.ReadAndCompileShader` in those samples is the complete version of the switch above.

## Where the shader meets its resources

Nothing in a `Shader` says which registers it reads. That is declared separately, in a [ResourceLayout](resourcelayout.md), and the pipeline checks that the two agree. Two rules follow from that split:

* The slot numbers in the layout have to match the register numbers in the source. Nothing warns you when they drift apart.
* The index passed to `SetResourceSet` becomes the register space, so a shader that uses `space2` needs its set bound at index 2.

## Cleaning up

A pipeline keeps its `GraphicsPipelineDescription`, and that description holds references to the shaders it was built from. Keep a shader alive for as long as any pipeline that uses it, and dispose it after those pipelines:

```csharp
pipelineState.Dispose();

vertexShader.Dispose();
pixelShader.Dispose();
```
