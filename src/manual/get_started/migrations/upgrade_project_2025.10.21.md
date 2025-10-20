# Update from Evergine 2025.3.18 to Evergine 2025.10.21

This guide describes the steps required to update your existing Evergine projects to the latest version.  
There are no major breaking changes in this release, and only a few manual updates are needed.

---

## ⚠️ Breaking Changes: Gamma Correction

There are major breaking changes related to **gamma correction**.  
After updating, you may notice that **textures look brighter** than before and some textures may **fail to load**.

**Previous behavior:**  
All imported textures had linear format. Gamma decoding was performed in the shader (when needed), which is expensive for the pixel shader and inaccurate when combined with mipmapping and pixel interpolation.

**New behavior:**  
Evergine now leverages **hardware decoding**. Textures that are sRGB **must be marked as sRGB**.  

### How to fix your textures

We provide a **Python 3** script to help you port existing projects.  
It detects texture usage and sets **sRGB** only where needed.

**Steps:**
1) Update your project from the launcher as usual.  
2) Open the project and verify that textures look brighter than usual.  
3) Download the script **[migration-2025.10.21.py](./migration-2025.10.21.py)** to a folder.  
4) Run:  
   ```bash
   python3 migration-2025.10.21.py path/to/my_evergine.weproj
   ```  
5) Reopen your project — textures should now look correct.

### Gamma framebuffers (recommended optimization)

Previously, gamma **encoding** was performed in the pixel shader before writing to the framebuffer, and templates used **linear framebuffers**.

Now, both linear and **sRGB framebuffers** are supported. For **better performance**, we recommend using **sRGB framebuffers**.

In your `Program.cs`, change:

```csharp
ColorTargetFormat = PixelFormat.R8G8B8A8_UNorm,
```

to:

```csharp
ColorTargetFormat = PixelFormat.R8G8B8A8_UNorm_SRgb,
```

---

## ASP.NET Core Projects

If your project uses **ASP.NET Core** (for example, WebAssembly-based or MAUI hybrid projects), update the following package references in your `.csproj` file to version **8.0.20**:

```xml
<PackageReference Include="Microsoft.AspNetCore.Components.WebAssembly" Version="8.0.20" />
<PackageReference Include="Microsoft.AspNetCore.Components.WebAssembly.Server" Version="8.0.20" />
<PackageReference Include="Microsoft.AspNetCore.Components.WebAssembly.DevServer" Version="8.0.20" PrivateAssets="all" />
```

---

## TypeScript Projects

For projects that include TypeScript build steps, update the **TypeScript MSBuild** package to version **5.9.2** where applicable:

```xml
<PackageReference Include="Microsoft.TypeScript.MSBuild" Version="5.9.2" />
```

---

## Physics Engine (LibBulletC)

If your project uses physics components, update the **Evergine.LibBulletc.Natives.Wasm** package to the following version:

```xml
<PackageReference Include="Evergine.LibBulletc.Natives.Wasm" Version="2025.8.29.27" />
```

---

## HTML5 Template Adjustments

For projects created from the **HTML5 template**, a few minor code updates are required in TypeScript files.

### 1. Update `ts/types/evergine.d.ts`

Add the new `startAssetsDownloadIfNeeded` declaration inside the `declare global` block:

```ts
declare global {
    var areAllAssetsLoaded: any;
    var startAssetsDownloadIfNeeded: any; // <-- Add this line
    var evergineSetProgressCallback: (progress: number) => void;
    var Blazor: any;
    var DotNet: any;
}
```

---

### 2. Modify `ts/app.ts`

Inside the `waitAndRun()` function, add a call to `startAssetsDownloadIfNeeded()` before checking the asset load state.

**Before:**

```ts
waitAndRun() {
    if (areAllAssetsLoaded()) {
        console.log("Running...");
        this.program.Run(this.canvasId);
    }
}
```

**After:**

```ts
waitAndRun() {
    startAssetsDownloadIfNeeded(); // <-- Add this line
    if (areAllAssetsLoaded()) {
        console.log("Running...");
        this.program.Run(this.canvasId);
    }
}
```

---

## React Template Adjustments

The new version introduces a simplified communication layer between Evergine and React, improves initialization flow, and updates several dependencies to ensure long-term compatibility with .NET 8 and the latest Evergine React package.

---

### 1. Backend Code Changes (C#)

#### Removed classes
The following classes have been **removed**:
- `Base/WebEventsController.cs`
- `WebFacade.cs`

They have been replaced with a new, unified lifecycle and integration system.

#### New classes added
The following new files have been added:
- `CanvasLifecycle.cs`  
  Handles the full Evergine canvas lifecycle from JavaScript, including initialization, start/stop, and size refresh.

- `WebIntegration.cs`  
  Provides a two-way integration layer between Evergine and React via `JSInterop`. It manages Evergine readiness state and notifies the JavaScript side when the engine is ready.

- `WebReactApplication.cs`  
  Replaces `MyApplication` and registers `WebIntegration` as a service within the Evergine container.

#### Updated Program.cs
- The main application now uses `WebReactApplication` instead of `MyApplication`.  
- All event handling logic (`OnActivatingScene`, `OnDesactivatingScene`) has been removed.  
- The new lifecycle relies entirely on the `CanvasLifecycle` and `WebIntegration` mechanisms for synchronization between .NET and JavaScript.

---

### 2. Frontend Code Changes (React SPA)

#### Updated dependencies

In `package.json` and `package-lock.json`, update:

- `"evergine-react"` → `^1.0.5`  
- Added `"@types/blazor__javascript-interop"` → `^3.1.7` as a dev dependency  

#### Removed constants in `config.ts`

Remove the following constants:

```ts
export const EVERGINE_LOADING_BAR_ID = "evergine-loading-bar";
export const EVERGINE_CLASS_NAME = `${EVERGINE_ASSEMBLY_NAME}.WebFacade";
```

Keep only:

```ts
export const EVERGINE_CANVAS_ID = "evergine-canvas";
export const EVERGINE_ASSEMBLY_NAME = "YourProject.WebReact";
```

---

#### Refactored `evergine-initialize.ts`

The Evergine initialization has been simplified.  
Replace the old call to `initializeEvergineBase` with the new one that defines the `Evergine` global object.

**Before:**
```ts
initializeEvergineBase(
  EVERGINE_LOADING_BAR_ID,
  EVERGINE_ASSEMBLY_NAME,
  EVERGINE_CLASS_NAME
);
```

**After:**
```ts
window.Evergine = {
    initialize: (_dotNetReference: DotNet.DotNetObject) => {
        const evergineApp: WebIntegration = {
            onEvergineReadyChanged: (isReady: boolean) => {
                console.log(`Evergine ready ${isReady}`);
            },
        };

        window.App = evergineApp;
        return window.DotNet.createJSObjectReference(evergineApp);
    },
    initializeCanvasLifecycle: () => window.DotNet?.invokeMethod(
        EVERGINE_ASSEMBLY_NAME,
        `${EVERGINE_ASSEMBLY_NAME}.CanvasLifecycle:Initialize`
    ),
    onEvergineAssetLoaded: (asset: EvergineAsset) => {
        console.log(`Evergine asset ${asset.name} loaded`);
    },
    onEvergineAllAssetsLoaded: () => {
        console.log("Evergine assets loaded");
    },
};

initializeEvergineBase(window.Evergine);
```