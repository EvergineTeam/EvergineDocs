# Update from Evergine 2025.10.21 to Evergine 2026.5.26

This guide describes the steps required to update your existing Evergine projects to the latest version.

---

## Migration Script

To automate most of the changes described in this guide, a PowerShell migration script is provided.

> ⚠️ **Important** ⚠️  
> This script modifies files in your project directly. We strongly recommend using a version control system like Git to track and review the changes. Make sure your project is committed or backed up before running the script so you can verify or revert any changes if necessary.

Download: [migration-2026.5.26.zip](https://github.com/EvergineTeam/EvergineDocs/tree/master/src/manual/get_started/migrations/migration-2026.5.26.zip)

Basic usage:
```powershell
.\migration-2026.5.26.ps1 -RootPath "C:\Projects\MySolution"
```

Additional options:
```powershell
# Preview changes without writing any files
.\migration-2026.5.26.ps1 -RootPath "C:\Projects\MySolution" -DryRun

# Create a .bak backup of each modified file before overwriting
.\migration-2026.5.26.ps1 -RootPath "C:\Projects\MySolution" -BackupOriginals

# Also update Evergine package versions in .weproj files
.\migration-2026.5.26.ps1 -RootPath "C:\Projects\MySolution" -OldEvergineVersion "2025.10.21.x" -NewEvergineVersion "2026.5.26.x"
```

The script handles:
- Target framework upgrades (net8.0/net9.0 → net10.0)
- NuGet package version updates
- Render layer `.werl` file fixes (Reverse-Z depth function)
- Web project file replacements (`tsconfig.json`, `ts/` folder, `Program.cs`)

---

## ⚠️ Breaking Change: Upgrade to .NET 10

As of this release, Evergine requires **.NET 10**. All project files must be updated to target `net10.0` instead of `net8.0` or `net9.0`.

Update the `<TargetFramework>` (or `<TargetFrameworks>`) element in each `.csproj` file, preserving any platform suffix:

```xml
<!-- Before -->
<TargetFramework>net8.0-windows</TargetFramework>

<!-- After -->
<TargetFramework>net10.0-windows</TargetFramework>
```

This applies to all platform-specific start projects (Windows, Android, iOS, Web, etc.). The script handles all variants automatically, including semicolon-separated multi-target entries and `Condition` attributes that reference `$(TargetFramework)`.

---

## ⚠️ Breaking Change: Reverse-Z Depth Projection

Evergine now uses **Reverse-Z projection**, which inverts the depth buffer direction (1.0 = near plane, 0.0 = far plane). As a result, fragments closer to the camera have a *greater* depth value, and the depth comparison function must be updated accordingly.

**All render layer files (`.werl`) must have their `DepthFunction` updated:**

```yaml
# Before
DepthFunction: LessEqual

# After
DepthFunction: GreaterEqual
```

The migration script applies this change automatically to every `.werl` file found under the specified root path.

---

## ⚠️ Breaking Change: `TextureDescription.Faces` Removed

The `Faces` property has been removed from `TextureDescription`. Its value must now be folded into the `Layers` property by **multiplying** the two values together.

**Before:**
```csharp
var desc = new TextureDescription
{
    Width  = 512,
    Height = 512,
    Faces  = 6,
    Layers = 1,
    // ...
};
```

**After:**
```csharp
var desc = new TextureDescription
{
    Width  = 512,
    Height = 512,
    Layers = 6,   // Layers = old Layers × old Faces
    // ...
};
```

The most common case is a **cubemap**, which has 6 faces. Any code that previously set `Faces = 6` (and `Layers = 1`) must be updated to `Layers = 6`. For a cubemap array with, for example, 4 elements, the old `Faces = 6, Layers = 4` becomes `Layers = 24`.

> This change is not handled by the migration script and must be applied manually.

---

## NuGet Package Updates

### ASP.NET Core Projects

If your project uses **ASP.NET Core** (e.g. WebAssembly-based or MAUI hybrid projects), update the following packages to version **10.0.8**:

```xml
<PackageReference Include="Microsoft.AspNetCore.Components.WebAssembly" Version="10.0.8" />
<PackageReference Include="Microsoft.AspNetCore.Components.WebAssembly.Server" Version="10.0.8" />
<PackageReference Include="Microsoft.AspNetCore.Components.WebAssembly.DevServer" Version="10.0.8" PrivateAssets="all" />
```

### TypeScript Projects

For projects that include TypeScript build steps, update **TypeScript MSBuild** to version **6.0.3**:

```xml
<PackageReference Include="Microsoft.TypeScript.MSBuild" Version="6.0.3" />
```

### Logging (Debug)

If your project references `Microsoft.Extensions.Logging.Debug`, update it to **10.0.8**:

```xml
<PackageReference Include="Microsoft.Extensions.Logging.Debug" Version="10.0.8" />
```

### Physics Engine (LibBulletC)

If your project uses physics components, ensure **Evergine.LibBulletc.Natives** is at version **2025.8.29.27**:

```xml
<PackageReference Include="Evergine.LibBulletc.Natives.Wasm" Version="2025.8.29.27" />
```

---

## Web Template Adjustments

Projects created from the **HTML5 (Web)** or **WebGPU** templates require several file-level updates. The migration script applies these automatically by replacing `tsconfig.json`, the `ts/` folder, and the server `Program.cs` with updated versions from the release package.

If you prefer to apply changes manually, the sections below describe what was changed.

### 1. Update `tsconfig.json`

TypeScript 6.0 deprecates some previously accepted constructs. To suppress deprecation errors without modifying existing code, add `"ignoreDeprecations": "6.0"` to your `compilerOptions`:

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

The `Module` interface definition has been extended to include the `canvasId` property:

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

### 3. Update Web Server `Program.cs`

The `Program.cs` for `.Web.Server` and `.WebGPU.Server` projects has been updated to align with .NET 10 and the revised static files configuration. Replace its contents with:

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
