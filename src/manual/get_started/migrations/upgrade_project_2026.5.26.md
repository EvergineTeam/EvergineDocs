# Update from Evergine 2025.10.21 to Evergine 2026.5.26

Evergine 2026.5.26 moves the engine to .NET 10 and switches the depth buffer to Reverse-Z. Both changes touch every project, so most of the work is mechanical. This guide lists each breaking change, what the migration script does for you, and what you have to change by hand.

## Migration script

A PowerShell script applies most of the changes in this guide.

> [!IMPORTANT]
> The script modifies the files of your project in place. Commit your project to a version control system such as Git, or make a backup, before you run it. That way you can review every change and revert it if needed.

Download [migration-2026.5.26.zip](https://github.com/EvergineTeam/EvergineDocs/raw/main/src/manual/get_started/migrations/migration-2026.5.26.zip), extract it, and run the script from the extracted folder. It needs the `resources` folder that ships next to it.

Basic usage:

```powershell
.\migration-2026.5.26.ps1 -RootPath "C:\Projects\MySolution"
```

Additional options:

```powershell
# Preview the changes without writing any file
.\migration-2026.5.26.ps1 -RootPath "C:\Projects\MySolution" -DryRun

# Keep a .bak copy of every file before overwriting it
.\migration-2026.5.26.ps1 -RootPath "C:\Projects\MySolution" -BackupOriginals

# Also update the Evergine package versions in .weproj files
.\migration-2026.5.26.ps1 -RootPath "C:\Projects\MySolution" -OldEvergineVersion "2025.10.21.x" -NewEvergineVersion "2026.5.26.x"
```

The script handles:

- Target framework upgrades (`net8.0` and `net9.0` to `net10.0`).
- NuGet package version updates.
- The depth function of render layer (`.werl`) files, for Reverse-Z.
- The web project files: `tsconfig.json`, the `ts/` folder and the server `Program.cs`.

It does **not** handle the `TextureDescription.Faces` removal. You have to fix that code by hand, as described below.

## Breaking change: .NET 10

Evergine now requires **.NET 10**. Every project file must target `net10.0` instead of `net8.0` or `net9.0`.

Update the `<TargetFramework>` (or `<TargetFrameworks>`) element of each `.csproj` file and keep any platform suffix:

```xml
<!-- Before -->
<TargetFramework>net8.0-windows</TargetFramework>

<!-- After -->
<TargetFramework>net10.0-windows</TargetFramework>
```

This applies to the shared project, the Editor project and every platform launcher (Windows, Android, iOS, Web and so on). The script handles every variant, including semicolon-separated multi-target values and `Condition` attributes that test `$(TargetFramework)`.

## Breaking change: Reverse-Z depth

Evergine now uses **Reverse-Z projection**. The depth buffer stores 1.0 at the near plane and 0.0 at the far plane, so a fragment closer to the camera has a *greater* depth value. The depth comparison of every render layer has to flip accordingly.

Update the `DepthFunction` of every render layer file (`.werl`):

```yaml
# Before
DepthFunction: LessEqual

# After
DepthFunction: GreaterEqual
```

The script applies this change to every `.werl` file under the root path.

> [!NOTE]
> Reverse-Z is controlled by `GraphicsContext.ReverseZBuffer`, which is `true` by default. Custom render layers and effects that you write from now on should assume that greater depth means closer.

## Breaking change: `TextureDescription.Faces` removed

`TextureDescription` no longer has a `Faces` field. Cube faces are now counted in `ArraySize`, the number of array slices the texture holds. The new value is the old `ArraySize` multiplied by the old `Faces`.

Before:

```csharp
var description = new TextureDescription()
{
    Type = TextureType.TextureCube,
    Format = PixelFormat.R8G8B8A8_UNorm,
    Width = 512,
    Height = 512,
    Depth = 1,
    ArraySize = 1,
    Faces = 6,
    MipLevels = 1,
    Flags = TextureFlags.ShaderResource,
    Usage = ResourceUsage.Default,
    CpuAccess = ResourceCpuAccess.None,
    SampleCount = TextureSampleCount.None,
};
```

After:

```csharp
using Evergine.Common.Graphics;

public static class CubemapFactory
{
    public static Texture CreateCubemap(GraphicsContext graphicsContext)
    {
        var description = new TextureDescription()
        {
            Type = TextureType.TextureCube,
            Format = PixelFormat.R8G8B8A8_UNorm,
            Width = 512,
            Height = 512,
            Depth = 1,

            // One slice per face: old ArraySize (1) x old Faces (6).
            ArraySize = 6,
            MipLevels = 1,
            Flags = TextureFlags.ShaderResource,
            Usage = ResourceUsage.Default,
            CpuAccess = ResourceCpuAccess.None,
            SampleCount = TextureSampleCount.None,
        };

        return graphicsContext.Factory.CreateTexture(ref description, "MyCubemap");
    }
}
```

A single cubemap goes from `Faces = 6` (with `ArraySize = 1`) to `ArraySize = 6`. A cubemap array of 4 cubes goes from `Faces = 6, ArraySize = 4` to `ArraySize = 24`. Any code that reads `Description.Faces` from an existing texture must read `Description.ArraySize` instead.

> [!IMPORTANT]
> `TextureDescription.CreateTextureCubeDescription(width, height, format)` sets the type to `TextureCube` but keeps the default `ArraySize` of 1. If you create cubemap descriptions with that helper, set `ArraySize = 6` on the result before you create the texture.

## NuGet package updates

### ASP.NET Core projects

Web projects (WebGL, WebGPU, WebXR and React) reference the ASP.NET Core WebAssembly packages. The web templates of this release use version **10.0.5**:

```xml
<PackageReference Include="Microsoft.AspNetCore.Components.WebAssembly" Version="10.0.5" />
<PackageReference Include="Microsoft.AspNetCore.Components.WebAssembly.Server" Version="10.0.5" />
<PackageReference Include="Microsoft.AspNetCore.Components.WebAssembly.DevServer" Version="10.0.5" PrivateAssets="all" />
```

> [!NOTE]
> The migration script writes version 10.0.8, a later servicing release of the same packages. Either version works; what matters is that all three packages move to a 10.0 release together.

### TypeScript projects

Projects with a TypeScript build step must update **Microsoft.TypeScript.MSBuild** to version **6.0.3**:

```xml
<PackageReference Include="Microsoft.TypeScript.MSBuild" Version="6.0.3" />
```

### Debug logging (MAUI)

The MAUI template references `Microsoft.Extensions.Logging.Debug` 8.0.0, which still works on .NET 10. The migration script updates it to 10.0.8 to keep it aligned with the rest of the .NET 10 packages. The update is optional:

```xml
<PackageReference Include="Microsoft.Extensions.Logging.Debug" Version="10.0.8" />
```

### Physics natives for the web (LibBulletC)

Web projects that use physics must reference **Evergine.LibBulletc.Natives.Wasm** version **2025.8.29.27**:

```xml
<PackageReference Include="Evergine.LibBulletc.Natives.Wasm" Version="2025.8.29.27" />
```

## Web template adjustments

Projects created from the **Web (WebGL2.0)** or **Web (Experimental WebGPU)** templates need several file updates. The script replaces `tsconfig.json`, the `ts/` folder and the server `Program.cs` with the versions of the new templates.

To apply the changes by hand, follow the steps below.

### 1. Update `tsconfig.json`

TypeScript 6.0 deprecates some constructs that earlier versions accepted. Add `"ignoreDeprecations": "6.0"` to `compilerOptions` to silence those errors without changing your code:

```json
{
  "compilerOptions": {
    "noImplicitAny": false,
    "noEmitOnError": true,
    "removeComments": false,
    "target": "es6",
    "outFile": "wwwroot/evergine.js",
    "rootDir": "./ts",
    "ignoreDeprecations": "6.0"
  },
  "include": [
    "ts/**/*"
  ],
  "exclude": [
    "node_modules",
    "wwwroot"
  ]
}
```

### 2. Update `ts/types/evergine.d.ts`

The `Module` interface gains a `canvasId` property:

```ts
declare global {
  var areAllAssetsLoaded: any;
  var startAssetsDownloadIfNeeded: any;
  var evergineSetProgressCallback: (progress: number) => void;
  var Blazor: any;
  var DotNet: any;
  interface Window {
    (src: any, event: any): void;
    BINDING: {
      call_static_method: (method: string, args?: unknown[]) => unknown;
    };
    EGL: any;
  }
  interface Module {
    canvasId: HTMLCanvasElement;
    locateFile: (base: string) => string;
    setProgress: (progress: number) => void;
  }
}

export {};
```

### 3. Update the web server `Program.cs`

The `Program.cs` of the `.Web.Server` and `.WebGPU.Server` projects now follows the .NET 10 hosting model and registers the Evergine asset extensions as static files. Replace its contents with:

```csharp
using Microsoft.AspNetCore.ResponseCompression;
using Microsoft.AspNetCore.StaticFiles;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddRazorPages();
builder.Services.AddServerSideBlazor();
builder.Services.AddResponseCompression(options =>
{
    options.EnableForHttps = true;
    options.MimeTypes = ResponseCompressionDefaults.MimeTypes.Concat(
        new[] { "application/octet-stream" });
});

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}
else
{
    app.UseDeveloperExceptionPage();
    app.UseWebAssemblyDebugging();
}

app.UseHttpsRedirection();
app.UseResponseCompression();

app.UseBlazorFrameworkFiles();

// Evergine assets use their own extensions; without these mappings the server would not serve them.
var contentTypeProvider = new FileExtensionContentTypeProvider();
var evergineExtensions = new[]
{
    ".weptx", ".wepsn", ".wepsc", ".wepsp", ".weprl", ".weprp",
    ".weppp", ".wepmd", ".wepmt", ".wepfb", ".wepfx", ".wepprf"
};
foreach (var ext in evergineExtensions)
{
    contentTypeProvider.Mappings.Add(ext, "application/octet-stream");
}
app.UseStaticFiles(new StaticFileOptions
{
    ServeUnknownFileTypes = true,
    ContentTypeProvider = contentTypeProvider
});

app.UseRouting();
app.MapRazorPages();
app.MapFallbackToFile("index.html");

app.Run();
```

## Next steps

Continue with [Update from Evergine 2026.5.26 to Evergine 2026.10](upgrade_project_2026.10.md) if you are moving to the next release.
