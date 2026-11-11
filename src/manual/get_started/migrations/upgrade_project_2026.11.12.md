# Update from Evergine 2026.5.26 to Evergine 2026.11.12

Evergine 2026.11.12 replaces the **Bullet physics engine with Jolt**, reworks **shadows**, moves ImGui to **Dear ImGui 1.92.9b** and makes **DirectX 12 the default backend** on Windows. The physics change touches every project that referenced `Evergine.Bullet`, which every project template did, so most projects need at least a small change. This guide lists every breaking change, what the migration script does for you, and what you have to change by hand.

If your project is older than 2026.5.26, first follow [Update from Evergine 2025.10.21 to Evergine 2026.5.26](upgrade_project_2026.5.26.md). That release moved the engine to .NET 10 and Reverse-Z, and this guide assumes both.

## Summary

| Change | Affects | Action | Script |
| --- | --- | --- | --- |
| [Physics: Bullet replaced by Jolt](#breaking-change-physics-now-runs-on-jolt) | Every project created from a template | Remove `Evergine.Bullet`; migrate physics code and assets. | Yes |
| [Shadow bias](#breaking-change-shadow-bias) | Lights with a tuned `ShadowBias`, custom shadow shaders | Tune `ShadowDepthBias` and `ShadowNormalBias`. | Removes the old key |
| [ImGui 1.92.9b](#breaking-change-imgui-1929b) | Code that calls ImGui directly | Fix argument order and enum literals. | Mostly |
| [Other API changes](#other-api-changes) | Code that uses the changed members | Rename or replace. | Mostly |
| [Third-party packages](#third-party-package-updates) | Web, Avalonia, WinUI and SkiaSharp projects | Raise the versions. | Yes |
| [DirectX 12 is the default backend](#directx-12-is-the-default-backend) | New projects | Optionally move the Windows profile to DirectX 12. | Optional switch |
| [Vulkan `QueryHeap.ReadData`](#vulkan-queryheapreaddata-writes-at-absolute-slot-indices) | Code that reads query results on Vulkan | Size the results array to `startIndex + count`. | No |
| [Timestamp query capability](#timestamp-query-support-is-now-reported) | Code that creates timestamp query heaps | Check `IsTimestampQuerySupported`. | No |
| [Quest and Pico launchers](#meta-quest-and-pico-surface-created-outside-the-ui-thread-optional) | Meta Quest and Pico projects | Create Vulkan through OpenXR; optionally move the surface off the UI thread. | No |
| [WebGPU frames in flight](#webgpu-frames-in-flight-optional) | Web (WebGPU) projects | Optional template update. | No |
| [Custom graphics backends](#custom-graphics-backends) | Only if you implement your own backend | Implement the new members. | No |

## Migration script

A PowerShell script applies most of the changes in this guide, including the whole Bullet to Jolt physics migration.

> [!IMPORTANT]
> The script modifies the files of your project in place. Commit your project to a version control system such as Git, or make a backup, before you run it. That way you can review every change and revert it if needed.

Download [migration-2026.11.12.zip](https://github.com/EvergineTeam/EvergineDocs/raw/main/src/manual/get_started/migrations/migration-2026.11.12.zip). It contains two scripts that must stay in the same folder:

- `Update-EvergineProject.ps1` updates the whole project. This is the one you run.
- `Migrate-BulletToJolt.ps1` migrates the physics. `Update-EvergineProject.ps1` runs it for you when the project uses physics. It is the same script described in [Migrating from Bullet](../../physics/migrating_from_bullet.md#migration-tool).

The scripts need **PowerShell 7** (`pwsh`). Windows marks downloaded files as coming from the internet and the default execution policy refuses to run them, so unblock the zip before you extract it:

```powershell
Unblock-File .\migration-2026.11.12.zip
```

If you already extracted it, unblock both scripts with `Get-ChildItem *.ps1 | Unblock-File`. When only the first script is unblocked, the physics migration does not run and the report shows a `jolt-no-report` warning.

### Run it

The script is a **dry run unless you add `-Apply`**: the first run lists what it would change and writes nothing.

```powershell
# 1. Preview the changes
pwsh -File .\Update-EvergineProject.ps1 -ProjectPath C:\Projects\MyGame -TargetVersion 2026.11.12.8

# 2. Apply them and keep the report
pwsh -File .\Update-EvergineProject.ps1 -ProjectPath C:\Projects\MyGame -TargetVersion 2026.11.12.8 -Apply -ReportPath port-report.json
```

`-ProjectPath` accepts the project folder, the `.weproj` file, a `.sln` or a `.csproj`. The script prints a table of findings with the file and line of everything it changed or could not change. It exits with code 0 when there is nothing to review, 2 when there are warnings, and 1 on error. Running it again on an updated project changes nothing.

| Parameter | Use |
| --- | --- |
| `-TargetVersion` | The Evergine version to move to, `2026.11.12.8`. |
| `-Apply` | Writes the changes. |
| `-NoBackup` | Skips the copies of the original files. By default they are kept in `.evergine-update-backup\<timestamp>\` and, for the physics files, `.bullet-to-jolt-backup\<timestamp>\`. |
| `-ReportPath <file>` | Writes the JSON report with every change and finding. |
| `-SwitchWindowsProfileToDirectX12` | Moves the `Windows` profile to DirectX 12, as described in [Move the Windows profile to DirectX 12](#move-the-windows-profile-to-directx-12-optional). An existing `Windows.DirectX12` profile becomes `Windows.DirectX11`, so the project keeps one launcher per backend. |
| `-AddOnVersions @{ 'Evergine.Cesium' = '<version>' }` | Versions of add-ons that are not part of the engine. Add-ons not listed keep their version and are reported. |
| `-StabilizeConstraintChains`, `-TuneVehicleChassis` | Passed to the physics migration. See [Migrating from Bullet](../../physics/migrating_from_bullet.md#recommended-process). |
| `-SkipPhysicsMigration` | Does not run the physics migration. |
| `-CleanObsoleteYaml:$false` | Keeps obsolete keys such as `ShadowBias` in scenes and prefabs. |

### What the script does

- Updates every Evergine engine package reference in `.csproj`, `.props` and `.targets` files, the `Evergine.Core` entry of the `.weproj` file and the engine line of `.wespec` files.
- Removes the `Evergine.Bullet`, `Evergine.LibBulletc.Natives`, `Evergine.LibBulletc.Natives.Wasm` and `Evergine.BulletSharpPInvoke` references, and any `Evergine.Bullet` project left in a solution.
- If the project only had the `BulletPhysicManager3D` line of the template, removes it. If it really uses physics, runs `Migrate-BulletToJolt.ps1` on the code, scenes and prefabs, and adds a `PhysicsManager` to the scenes that need one.
- Rewrites the API changes that can be rewritten safely, listed in [Other API changes](#other-api-changes) and [ImGui](#breaking-change-imgui-1929b), and reports the rest with their file and line.
- Removes the obsolete `ShadowBias` key from lights and `MaskBits` from `SpatialMapping` in `.wescene` and `.weprefab` files.
- Raises the third-party packages listed in [Third-party package updates](#third-party-package-updates) when they are below the version the new Evergine packages need, and removes `Avalonia.Diagnostics` from projects that move to Avalonia 12.
- Reports every custom effect (`.fx`, `.fxh`, `.hlsl`) that calls the shadow library functions that changed.
- Drops package sources of `nuget.config` and `Evergine.config` that point at folders that do not exist on your machine.

It does **not** rebuild your content, retune physics behavior, rewrite custom shaders or move shadow bias values. The sections below explain those changes.

## Update the project

1. Install Evergine 2026.11.12 from the **Evergine Launcher**.
2. Run the migration script as shown above, or apply the changes of this guide by hand. If you prefer the Launcher's **Update** button, run the script afterwards anyway: the Launcher updates the engine packages but leaves `Evergine.Bullet` behind, and the project does not build until it is removed.
3. Open the project in Evergine Studio so it rebuilds the content, then build the solution in Visual Studio.
4. Work through the warnings in the report and the manual steps of the sections below.
5. If the project uses physics, run it with [physics debug rendering](../../physics/debug_rendering.md) on and check colliders, sensors, constraints and vehicles.

## Breaking change: physics now runs on Jolt

Evergine's physics has been rebuilt on **[Jolt Physics](https://github.com/jrouwe/JoltPhysics)**. The new engine is built into `Evergine.Framework`, uses several cores, runs on the web too, and adds soft bodies, tracked vehicles, height field terrain, buoyancy and new constraints. The previous `Evergine.Bullet` package and the `Evergine.Framework.Physics3D` namespace are removed.

This section summarizes the migration. [Migrating from Bullet](../../physics/migrating_from_bullet.md) has the complete table of equivalences for every component, property, method and query.

### Every project: remove `Evergine.Bullet`

Every project template referenced `Evergine.Bullet` and registered its manager, even in projects that never use physics. There is no 2026.11.12 version of that package, so the reference has to go.

In the shared project `.csproj`:

```xml
<!-- Remove -->
<PackageReference Include="Evergine.Bullet" Version="2026.5.26.x" />
```

Remove `Evergine.LibBulletc.Natives` from the Android launcher and `Evergine.LibBulletc.Natives.Wasm` from the web launchers too, if they reference them. Then update the scene's `RegisterManagers` (`MyScene.cs` in the templates):

```csharp
// Before
this.Managers.AddManager(new global::Evergine.Bullet.BulletPhysicManager3D());

// After: delete the line if the scene has no physics, or register the new manager
this.Managers.AddManager(new global::Evergine.Framework.Physics.PhysicsManager());
```

The new physics ships with `Evergine.Framework`, so there is nothing to install in its place.

### Projects that use physics

The API keeps the same concepts with new names, plus a few real differences in behavior.

| Before (Bullet) | Now (Jolt) |
| --- | --- |
| `Evergine.Framework.Physics3D` namespace | `Evergine.Framework.Physics` |
| `BulletPhysicManager3D`, `SceneManagers.PhysicManager3D` | `PhysicsManager`, bound with `[BindSceneManager]` |
| `RigidBody3D` with `PhysicBodyType` | `RigidBody` with `IsKinematic` |
| `StaticBody3D` | `StaticBody` |
| `BoxCollider3D`, `SphereCollider3D`, `MeshCollider3D`... | `BoxCollider`, `SphereCollider`, `MeshCollider`... |
| `HingeJoint3D`, `SliderJoint3D`, `ConeTwistJoint3D`... | `HingeConstraint`, `SliderConstraint`, `SwingTwistConstraint`... |
| `CharacterController3D` | `CharacterController` |
| `PhysicVehicle3D`, `PhysicWheel3D` | `WheeledVehicleController`, `VehicleWheel` |
| `BeginCollision`, `UpdateCollision`, `EndCollision` | `CollisionStarted`, `CollisionUpdated`, `CollisionEnded` |
| `RayCast(ref from, ref to, mask)` | `RayCast(origin, direction, maxDistance, in filter, out hit)` |
| `MaskBits` per body | One [collision matrix](../../physics/collision_filtering.md) on the `PhysicsManager` |
| `ContactTestBehavior`, `SetCollisionEvents`, `RayStep` | Removed. Use the collision events and the [queries](../../physics/queries.md) of `PhysicsManager`. |

The differences that change how a migrated scene behaves:

- **Collider sizes.** Bullet colliders were factors of the model's bounds; Jolt colliders are in local units. [`UseModelBounds`](../../physics/colliders/index.md#local-units-or-model-bounds) restores the old convention, and the migration script switches it on for every migrated collider and vehicle wheel.
- **Collision filtering.** There is no per-body mask any more. The script builds a collision matrix from every category and mask pair it finds and writes it on the `PhysicsManager`.
- **Defaults.** Friction is 0.2 instead of 0.5, damping is 0.05 instead of 0, and `Mass = 0` means "compute it from the colliders' density".
- **Sensors.** A static sensor that moves, such as one that follows a cursor or a hand, has to be a kinematic `RigidBody`, because Jolt never reports contacts between two static bodies. Ray casts skip sensors unless the `QueryFilter` sets `IncludeSensors`.
- **Kinematic bodies** move with `MoveTo(position, orientation)`. Writing the `Transform3D` teleports them.

The migration script converts the component types and properties in code, scenes and prefabs, and reports each place where both engines do not mean the same thing: vehicles to retune, constraint limits without an exact equivalent, masks it cannot evaluate and custom query code. Read [What it leaves to you](../../physics/migrating_from_bullet.md#what-it-leaves-to-you) before you start, and run the physics checks of [Migration Checklist](../../physics/migrating_from_bullet.md#migration-checklist) after it.

> [!TIP]
> `Migrate-BulletToJolt.ps1` also works on its own, for example on a library or add-on that is not an Evergine project. `Update-EvergineProject.ps1` runs it with the same options for you.

## Breaking change: shadow bias

Shadows have been reworked: cascades no longer shimmer when the camera moves, cascades blend into each other and fade out at the shadow distance, and point light cube faces no longer show seams. Shadows are biased with two values, both measured in shadow map texels, that replace the single depth offset used before:

| Property | Default | What it does |
| --- | --- | --- |
| `ShadowDepthBias` | 0.5 | Moves the shadow receiver towards the light. |
| `ShadowNormalBias` | 1.0 | Moves the shadow receiver along its normal, scaled by the slope with respect to the light. |

`Light.ShadowBias` and `DirectionalLight.ShadowBias` are **obsolete and ignored**. Code that sets them compiles with a warning and has no effect. Do not copy the old value to the new properties: the units are different. Start from the defaults, and raise `ShadowNormalBias` if surfaces shadow themselves in stripes or lower `ShadowDepthBias` if shadows detach from their casters. The migration script removes the `ShadowBias` key from scenes and prefabs and reports every use in code.

`DirectionalLight` has new options to tune the cascades: `ShadowCascadeCount` (1 to 4), `CascadeSplitMode`, `CascadeFitMode`, `CascadeSelectionMode` and `FarCascadesUpdateInterval`. [Lights](../../graphics/lights.md#shadow-bias) explains how to tune the two biases and describes every cascade option.

### Custom effects that sample shadows

Skip this part unless you wrote your own effect that calls the engine shadow library. The migration script lists every call it finds in your `.fx` files, but it does not rewrite them.

The `DirectionalLightShadow`, `PointLightShadow` and `SpotLightShadow` functions take the **geometric normal** of the surface, in world space, instead of the `NoL` term, and the new parameter goes right after `position`:

```hlsl
// Before
float3 shadow = DirectionalLightShadow(lightProperties, position, depthVS, NoL,
    ShadowViewProjectionArray, DirectionalShadowMap, DirectionalShadowMapSampler);

// After
float3 shadow = DirectionalLightShadow(lightProperties, position, geometricNormal, depthVS,
    ShadowViewProjectionArray, DirectionalShadowMap, DirectionalShadowMapSampler);
```

> [!WARNING]
> An old call with the arguments in the old order can still compile, because HLSL silently turns a `float` into a `float3`, and then it renders wrong shadows. Check every call, not only the ones that fail to compile.

`PointLightShadow(lightProperties, position, positionToLight, NoL, ...)` becomes `PointLightShadow(lightProperties, position, geometricNormal, positionToLight, ...)`, and `SpotLightShadow(lightProperties, position, NoL, ...)` becomes `SpotLightShadow(lightProperties, position, geometricNormal, ...)`. The geometric normal is the interpolated vertex normal, normalized, not the normal-mapped one. The engine's standard effect passes `shading.tangentToWorld[2]`.

The cascade helpers changed too:

- `GetCascadeFromDepth` and `ShadowCascade` are removed. `SelectDirectionalCascade(lightProperties, position, depthVS, ShadowViewProjectionArray, out blend)` returns the cascade and the blend factor with the next one.
- The `DirectionalLightShadow` overload that takes an explicit cascade now takes `cascade` and `blend` as its last two arguments.
- `LightProperties.CascadeSplits` is a `float4` with the bounds of up to four cascades, and `LightProperties` has new fields for the normal bias, cascade blending and shadow fade-out.

Rebuild the effect in Evergine Studio after the changes.

## Breaking change: ImGui 1.92.9b

`Evergine.ImGui` now uses Dear ImGui 1.92.9b. Code that only uses `ImGuiManager` and the usual widgets keeps working. Code that calls the native API directly may need these changes:

| Before | Now | Script |
| --- | --- | --- |
| `ImDrawList_AddRect(..., rounding, flags, thickness)` | `ImDrawList_AddRect(..., rounding, thickness, flags)` | Yes |
| `ImDrawList_AddPolyline(..., col, flags, thickness)` | `ImDrawList_AddPolyline(..., col, thickness, flags)` | Yes |
| `ImDrawList_PathStroke(..., col, flags, thickness)` | `ImDrawList_PathStroke(..., col, thickness, flags)` | Yes |
| `(ImDrawFlags)1` | `ImDrawFlags.Closed`, whose value is now 512 | Yes |
| `ImDrawData.CmdListsCount` | `ImDrawData.CmdLists.Size` | Yes |
| `igSetColorEditOptions(flags)` | Set `ImGuiIO.ConfigColorEditFlags`. | Reported |
| `ImGuiCol`, `ImGuiStyleVar` or `ImPlotProp` values written as numbers | The named members. New values were inserted, so the numbers moved: for example `ImGuiCol.CheckboxSelectedBg` is now 19, which shifts `SliderGrab` and every later color by one. | Reported for casts |

```csharp
// Before
ImguiNative.ImDrawList_AddRect(drawList, min, max, color, 4.0f, ImDrawFlags.None, 2.0f);

// After: thickness comes before flags
ImguiNative.ImDrawList_AddRect(drawList, min, max, color, 4.0f, 2.0f, ImDrawFlags.None);
```

Two behavior changes affect every ImGui interface:

- **Drag, Slider and InputScalar widgets** apply a typed value when you press Enter or Tab or when the widget loses focus, not on every keystroke. Push `ImGuiItemFlags.LiveEditOnInputScalar` to restore the previous behavior.
- **`Separator()`** now reserves 1 pixel of height, so tightly packed layouts can move by a pixel per separator.

If your project references `Evergine.Bindings.Imgui` directly, it must use version 2026.10.1.34 or later.

## Other API changes

Members that were already obsolete in 2026.5.26 have been removed, along with a few others. The script rewrites the ones marked **Yes** and reports the rest with their file and line.

| Before | Now | Script |
| --- | --- | --- |
| `override void OnDetach()` in components, behaviors, services and scene managers | `override void OnDetached()`. `OnDetach` no longer exists and is no longer called. | Yes |
| `Container.RegisterType<T>(bool singleton = true)` | `Container.Register<T>(reuse: true)`. The first parameter of `Register<T>` is the factory, so a positional `bool` must become `reuse:`. | Yes |
| `Container.RegisterFactoryDelegate<T>(factory)` | `Container.Register<T>(factory)` | Yes |
| `BoundingOrientedBox.Minimum`, `Maximum` | `Min`, `Max` | Yes |
| `WavFileWriter.WriteData(samples, offset, count)` | `WriteSamples(samples, offset, count)` | Yes |
| `TouchPanelState.AddTouchLocation(id, state, x, y)` | `AddTouchLocation(id, x, y)` | Yes |
| `EnvironmentComponent` | The scene's `EnvironmentManager`. See below. | Reported |
| `ShadowMapComponent` | The scene's `ShadowMapManager`, which has the same properties. See below. | Reported |
| `ParticlesComponent.SourceEntityId` (a `Guid`) | `ParticlesComponent.SourceEntity` (an `Entity`). Scenes keep loading: the serialized key is the same. | Reported |
| `AtmosphericMaterial.SkyTint`, `AtmosphericMaterial.GroundColor`, `SkyboxMaterial.PerObject_WorldViewProj` | Removed. Setting them corrupted memory. | Reported |
| `RayStep`, `RayStepJsonConverter` | A `Ray` plus a distance, or `PhysicsManager.RayCast`. | Reported |
| `SpatialMapping.MaskBits` | Removed: filtering goes through the `PhysicsManager` collision matrix. `SpatialMapping.CollisionCategories` is now a `CollisionCategory`. | Yes, in scenes |
| `HitResult3D` in `GazeBehavior.AirTapEvent`, `GazeBehavior.GazeHitResult` and `GazeCollision.HitResult` | `RayCastHit` | Through the physics migration |
| `ParticlesEmitter.ForcesCategory`, `BaseForce.ForceCategory` (a `CollisionCategory3D`) | A `CollisionCategory` | Through the physics migration |
| `AccelerationStructureFlags` values 0 to 5 | Bit flags (`None = 0`, `AllowUpdate = 1`, ...). The names are the same, so source code compiles, but numeric values stored or compared by hand change meaning. | Reported in projects without `.weproj` |

`EnvironmentComponent` and `ShadowMapComponent` were already marked obsolete in favor of the scene managers, which you can configure in the **Scene Managers** panel of Evergine Studio. The script reports the blocks left in your scenes; move their values to the managers and delete the blocks. In code:

```csharp
// Before: an EnvironmentComponent on an entity
environment.ReflectionProbe = probe;
environment.IntensityMultiplier = 1.5f;

// After: the scene's EnvironmentManager
this.Managers.EnvironmentManager.IBLReflectionProbe = probe;
this.Managers.EnvironmentManager.IntensityMultiplier = 1.5f;

// Before: shadowMapComponent.DirectionalResolution = ...
// After: the scene's ShadowMapManager
var shadowMaps = this.Managers.FindManager<ShadowMapManager>();
shadowMaps.DirectionalResolution = ShadowMapProvider.ShadowMapSize.Size_2048;
```

### Behavior changes

These changes compile without errors but can change how an existing project looks or behaves:

- **`BackgroundImage.OrderBias`** now defaults to 1 and the value you set is honored. Before, it was always forced to 1, so a scene saved with `OrderBias: 0` now renders with 0.
- **Particles that spawn by distance** are now frame rate independent. Retune `DistanceRate` if they emit more or fewer particles than before.
- **`FreeCamera3D`** turns at the same speed at any frame rate, so the keyboard turn speed may feel different.
- **`ConstantBuffer.SetBufferData` and `GetBufferData`** throw `ArgumentOutOfRangeException` when the data does not fit in the buffer, instead of writing out of bounds.
- **`Ray.Intersects(BoundingSphere)`** returns `null` on a miss instead of 0.
- **Entity references.** Public `Entity` properties and fields of your components are now serialized as references to the entity's id.

### Rebuild add-ons and libraries

Some changes break binary compatibility without changing source code: `OpenXRGraphicBackend.GraphicsContext` and `OpenXRRuntimePlatform.GraphicsContext` are now properties, `CommandQueue.Submit()` takes an optional `Fence`, `BaseMaterialDecorator` implements `IDisposable`, and `AccelerationStructureFlags` has new values. Rebuild every library and add-on against 2026.11.12. A DLL compiled against 2026.5.26 can fail at run time with `MissingFieldException` or `MissingMethodException`.

## Third-party package updates

The new Evergine packages depend on newer versions of some third-party packages. If your project pins one of them to a lower version, restore fails with a package downgrade error (NU1605). The script raises them to these minimums:

| Package | Minimum version | Needed by |
| --- | --- | --- |
| `Microsoft.AspNetCore.Components.WebAssembly`, `.Server`, `.DevServer` | 10.0.13 | `Evergine.Web` (the web templates use 10.0.14) |
| `SkiaSharp` and its `NativeAssets` packages | 4.153.1 | `Evergine.Assets`, `Evergine.Runtimes.Image`, `Evergine.ImGui` |
| `Avalonia`, `Avalonia.Desktop`, `Avalonia.Themes.Fluent`, `Avalonia.Fonts.Inter` | 12.1.4 | `Evergine.Avalonia` |
| `Microsoft.WindowsAppSDK` | 2.5.1 | `Evergine.WinUI` |
| `Evergine.Bindings.Imgui` | 2026.10.1.34 | `Evergine.ImGui` |
| `Evergine.Bindings.Vulkan` | 2026.10.1.27 | `Evergine.Vulkan` |
| `Evergine.Bindings.OpenXR` | 2026.11.4.23 | `Evergine.OpenXR` |

`Evergine.Framework` also depends on the new `Evergine.Bindings.JoltPhysics` package, which NuGet restores for you.

SkiaSharp 4, Avalonia 12 and Windows App SDK 2 are major versions with breaking changes of their own. If your own code uses those libraries directly, check their release notes.

### Avalonia projects

The Avalonia template sets `AvaloniaVersion` to 12.1.4 and no longer references `Avalonia.Diagnostics`, which has no Avalonia 12 release. The script does both. If your code calls `AttachDevTools()`, remove the call.

### WinUI projects

Besides `Microsoft.WindowsAppSDK` 2.5.1 in both the launcher project and the packaging (`.wapproj`) project, the WinUI template changes:

- `TargetPlatformVersion` 10.0.26100.0 in the `.wapproj` file.
- `<RuntimeIdentifier>win-x64</RuntimeIdentifier>` instead of `win10-x64` in the publish profiles (`.pubxml`).
- `UndefineProperties="RuntimeIdentifier;SelfContained"` on the `ProjectReference` from the packaging project to the launcher.

The script updates the package version only. Apply the other three changes by hand, or compare with a new project created from the WinUI template.

## DirectX 12 is the default backend

DirectX 12 replaces DirectX 11 as the default on Windows, in three places:

- **Evergine Studio** starts on DirectX 12. When you update, an installation that was using DirectX 11 moves to DirectX 12. An installation where you had explicitly chosen Vulkan keeps Vulkan.
- **New projects** use the **Windows (DirectX12)** template as the required platform. Its `Windows` profile runs on `DX12GraphicsContext` and references the `Evergine.DirectX12` package.
- **DirectX 11** is still available as the optional **Windows (DirectX11)** platform, which adds a `Windows.DirectX11` profile.

You can change the backend Evergine Studio renders with in **Settings > Preferences > Editor backend (Experimental)**. The change applies after you restart Evergine Studio.

> [!IMPORTANT]
> The DirectX 12 backend works best on GPUs that support Direct3D feature level 12_2, and now falls back to lower feature levels on older GPUs. If Evergine Studio fails to start on your machine, set **Editor backend** to DirectX11 or Vulkan.

### What happens to existing projects

Nothing changes on its own. The `Windows` profile of an existing project keeps the backend recorded in its `.weproj` file and the launcher code already on disk, so a project created with DirectX 11 still builds and runs on DirectX 11. Projects that already have a `Windows.DirectX12` profile are not affected either.

### Move the Windows profile to DirectX 12 (optional)

The migration script does this with `-SwitchWindowsProfileToDirectX12`. To do it by hand, change three files.

In the `.weproj` file, set the backend of the `Windows` profile:

```yaml
# Before
    GraphicsBackend: DirectX11
    LauncherType: Default
    Name: Windows

# After
    GraphicsBackend: DirectX12
    LauncherType: Default
    Name: Windows
```

In `MyGame.Windows/MyGame.Windows.csproj`, replace the backend package:

```xml
<!-- Before -->
<PackageReference Include="Evergine.DirectX11" Version="2026.11.12.8" />

<!-- After -->
<PackageReference Include="Evergine.DirectX12" Version="2026.11.12.8" />
```

In `MyGame.Windows/Program.cs`, create a DirectX 12 context instead of a DirectX 11 one:

```csharp
// Before
GraphicsContext graphicsContext = new global::Evergine.DirectX11.DX11GraphicsContext();

// After
GraphicsContext graphicsContext = new global::Evergine.DirectX12.DX12GraphicsContext();
```

The rest of `ConfigureGraphicsContext` (swap chain description, presenter and container registration) stays the same. The template also changes the window title from `- DX11` to `- DX12`, which is cosmetic.

If the project also has a `Windows.DirectX12` profile, you now have two launchers on DirectX 12. Turn that profile into `Windows.DirectX11` (rename the profile, its folder, project and solution, and switch its package and context to DirectX 11), or remove it.

> [!TIP]
> To test on a machine without a suitable GPU, such as a build agent, create the context with `new DX12GraphicsContext(useWarpAdapter: true)`. It runs DirectX 12 on the WARP software rasterizer, which is slow but needs no GPU.

## Vulkan: `QueryHeap.ReadData` writes at absolute slot indices

`QueryHeap.ReadData(startIndex, count, results)` now writes the result of query `i` at `results[i]` on Vulkan, as it already did on every other backend. Before this release, the Vulkan backend packed the results from the start of the array, so `results[0]` held query `startIndex`.

This is a breaking change for code that reads a range that does not start at 0. The results array must hold at least `startIndex + count` elements. A shorter array now throws `ArgumentException` on every backend.

Before (only correct on Vulkan):

```csharp
// Queries 2 and 3 hold the timestamps around the second pass.
ulong[] results = new ulong[2];
this.queryHeap.ReadData(2, 2, results);
double passMs = (results[1] - results[0]) * 1000.0 / this.graphicsContext.TimestampFrequency;
```

After (correct on every backend):

```csharp
// The array is indexed by query slot, so it needs startIndex + count elements.
ulong[] results = new ulong[4];
this.queryHeap.ReadData(2, 2, results);
double passMs = (results[3] - results[2]) * 1000.0 / this.graphicsContext.TimestampFrequency;
```

If you always read from slot 0 with an array of `QueryCount` elements, as in [QueryHeap](../../graphics/low_level_api/queryheap.md), you do not need to change anything.

## Timestamp query support is now reported

`GraphicsContextCapabilities` has a new `IsTimestampQuerySupported` property. It is `false` by default, and each backend reports `true` only when it implements timestamp queries. Before this release there was no way to ask, and a backend without timestamp queries failed the first time you used them.

- **DirectX 12, DirectX 11 and Vulkan** report `true`.
- **WebGPU** reports `true` when the browser exposes the `timestamp-query` feature.
- **Metal** reports `false`, because its `QueryHeap` and `WriteTimestamp` are not implemented.
- **OpenGL** reports support only when the driver exposes `ARB_timer_query`. OpenGL ES and WebGL do not have it, so they report `false`.

If you create timestamp query heaps, check the capability first:

```csharp
using Evergine.Common.Graphics;

public class GpuTimer
{
    private readonly GraphicsContext graphicsContext;
    private QueryHeap queryHeap;

    public GpuTimer(GraphicsContext graphicsContext)
    {
        this.graphicsContext = graphicsContext;

        // Metal, OpenGL ES and WebGL report false: skip GPU timing there instead of failing.
        if (graphicsContext.Capabilities.IsTimestampQuerySupported)
        {
            var description = new QueryHeapDescription()
            {
                Type = QueryType.Timestamp,
                QueryCount = 2,
            };

            this.queryHeap = graphicsContext.Factory.CreateQueryHeap(ref description);
        }
    }

    public bool IsAvailable => this.queryHeap != null;
}
```

## Meta Quest and Pico: surface created outside the UI thread (optional)

The **Android Meta Quest (OpenXR)** and **Android Pico (OpenXR)** templates now create the Android surface with `runInUIThread` set to `false`, so the graphics loop does not run on the Android UI thread. To apply the same change to an existing project, edit `MainActivity.cs` in the Quest or Pico launcher:

```csharp
// Before
var surface = this.windowsSystem.CreateSurface(0, 0) as global::Evergine.Android.AndroidSurface;

// After
var surface = this.windowsSystem.CreateSurface(false) as global::Evergine.Android.AndroidSurface;
```

`CreateSurface(0, 0)` still works and keeps the previous behavior, because it calls `CreateSurface(true)`.

### Vulkan created through OpenXR

OpenXR can now take part in creating the Vulkan instance and device, which is how the OpenXR specification expects it to be done. The Meta Quest and Pico templates use it, and Android XR requires it. A launcher that creates the `VKGraphicsContext` on its own keeps working only on runtimes that expose the `XR_KHR_vulkan_enable` extension. On the others, OpenXR throws `This runtime requires Vulkan to be created through OpenXR`.

To update an existing Quest or Pico launcher, move the creation of the graphics context in `ConfigureGraphicsContext` of `MainActivity.cs` after the creation of the `OpenXRPlatform`, and build it from `InitializeForVulkan()`:

```csharp
// Before: at the start of ConfigureGraphicsContext
GraphicsContext graphicsContext = new global::Evergine.Vulkan.VKGraphicsContext(
    new[] { "VK_KHR_multiview", "VK_KHR_external_memory", "VK_KHR_external_memory_fd", "VK_KHR_get_memory_requirements2" },
    new[] { "VK_KHR_get_physical_device_properties2", "VK_KHR_external_memory_capabilities" });
graphicsContext.CreateDevice();
application.Container.RegisterInstance(graphicsContext);

// After: once openXRPlatform has been created, before registering it (add using System.Linq)
var openXRVulkan = openXRPlatform.InitializeForVulkan();

var graphicsContext = new global::Evergine.Vulkan.VKGraphicsContext(new global::Evergine.Vulkan.VKGraphicsContextOptions()
{
    DeviceExtensions = new[] { "VK_KHR_multiview", "VK_KHR_external_memory", "VK_KHR_external_memory_fd", "VK_KHR_get_memory_requirements2" }
        .Union(openXRVulkan.DeviceExtensions),
    InstanceExtensions = new[] { "VK_KHR_get_physical_device_properties2", "VK_KHR_external_memory_capabilities" }
        .Union(openXRVulkan.InstanceExtensions),
    CreateInstance = openXRVulkan.CreateInstance,
    SelectPhysicalDevice = openXRVulkan.SelectPhysicalDevice,
    CreateDevice = openXRVulkan.CreateDevice,
});

graphicsContext.CreateDevice();
application.Container.RegisterInstance<GraphicsContext>(graphicsContext);
application.Container.RegisterInstance(openXRPlatform);
```

The mirror display, which is created before the `OpenXRPlatform`, does not need the graphics context, so the rest of the method stays the same.

## WebGPU: frames in flight (optional)

The **Web (Experimental WebGPU)** template now limits how many frames the GPU can have queued. Without a limit, `requestAnimationFrame` keeps submitting frames at display rate even when the GPU cannot keep up, which adds input lag and reports a frame rate higher than what is presented.

The limit lives in `ts/app.ts` (`App.maxFramesInFlight`, 2 by default; set it to 0 to disable it), and `ts/helper.ts` skips a tick while the limit is reached. To get the change in an existing project, create a new project with the WebGPU template and copy its `ts/app.ts` and `ts/helper.ts` over yours. Merge by hand if you had edited those files.

## Custom graphics backends

Skip this section unless you implement your own `GraphicsContext`. The abstract classes of the low-level API gained members that every backend must implement:

| Class | New member |
| --- | --- |
| `CommandQueue` | `Submit(Fence fence = null)` replaces `Submit()`. |
| `CommandQueue` | `GetClockCalibration(out ulong gpuTimestamp, out long cpuTimestamp)` |
| `ResourceFactory` | `CreateFence()` and `CreateBufferViewInternal(...)` |
| `CommandBuffer` | `UpdateTextureData(Texture texture, IntPtr source, uint sourceSizeInBytes, uint subResource = 0)` |
| `GraphicsContextCapabilities` | `IsTimestampQuerySupported` and `IsClockCalibrationSupported` (virtual, `false` by default, so override them to report support) |

Code that only calls `CommandQueue.Submit()` keeps compiling, because the fence parameter is optional.

## New features you can adopt

These features are optional. Existing projects keep working without them.

### Physics

Besides the features that come with Jolt itself, the physics section documents [soft bodies](../../physics/soft_bodies/index.md) (cloth and deformable meshes, with pin editing in Evergine Studio), [wheeled](../../physics/vehicles/wheeled_vehicles.md) and [tracked vehicles](../../physics/vehicles/tracked_vehicles.md), a virtual [character controller](../../physics/character_controller.md), [height field terrain](../../physics/colliders/heightfield_collider.md) that deforms at run time, [buoyancy](../../physics/buoyancy.md), [sensors](../../physics/physics_bodies/sensors.md), continuous collision detection, per-axis degrees of freedom, new [constraints](../../physics/constraints/index.md) and saving and restoring the world state.

### Android XR

The new **Android XR (OpenXR)** template and the `Evergine.OpenXR.Natives.AndroidXR` package add Android XR headsets and glasses as a platform. Optical see-through devices can select the environment blend mode for a transparent background. See [Android XR](../../xr/openxr/androidxr.md).

### Evergine Studio

- **Play Mode** in the Scene Viewer runs the scene inside the editor.
- **ImGuizmo** manipulators, pixel perfect picking and a selection outline in the Scene Viewer.
- **Entity references.** Component properties of type `Entity` are serialized by id, accept entities dropped from the Scene Hierarchy and are remapped when scenes load, prefabs are instanced or entities are duplicated.
- Drag and drop of folders in the Assets tree and of assets onto the Entity Details panel.
- **Project Settings > Services** adds, removes and configures application services. See [Manage services](../../evergine_studio/settings/project_services.md).
- Close opened documents from their context menu, reset profile textures and shader values to the originals, choose the HDR range in the Texture Viewer and edit multiline string properties.

### Graphics

- **Fence.** `Fence` tells the CPU when one particular submission has finished on the GPU, instead of waiting for the whole queue with `WaitIdle()`. Create one with `Factory.CreateFence()`, pass it to `CommandQueue.Submit(fence)`, and use `IsSignaled`, `Wait` and `Reset`. `GraphicsContext.FramesInFlight` builds on fences: when it is greater than zero, `GraphicsPresenter` lets that many frames be in progress at once. See [CommandQueue](../../graphics/low_level_api/commandqueue.md).
- **GPU and CPU clock calibration.** `CommandQueue.GetClockCalibration(out ulong gpuTimestamp, out long cpuTimestamp)` samples the GPU timestamp counter and the CPU `Stopwatch` clock at the same instant, so you can place GPU timestamps on a CPU profiler timeline. Check `Capabilities.IsClockCalibrationSupported` first: DirectX 12, Vulkan and desktop OpenGL support it.
- **Buffer views.** `ResourceFactory.CreateBufferView(buffer, offset, size, format, structStride)` creates a `BufferView` over a range of a `Buffer`, which can be bound as a texel buffer through the new `ResourceType.TexelBuffer` and `ResourceType.TexelBufferReadWrite` layout entries.
- **Skinned mesh culling.** `SkinnedMeshRenderer.SkinnedBoundsMode` culls a skinned mesh against its skeleton.
- `Capabilities.IsDepthClampSupported`, and `VKGraphicsContextOptions` so another library, such as OpenXR, can create the Vulkan instance and device.

### Raw assets

`AssetsService.LoadRaw<T>(Guid id, Func<Stream, T> loader)` loads files that Evergine includes in the application without converting them, such as JSON or plain text. You provide the function that reads the stream:

```csharp
using System;
using System.IO;
using Evergine.Framework;
using Evergine.Framework.Services;

public class LoadTextFile : Component
{
    [BindService]
    private AssetsService assetsService = null;

    // Id of a raw asset, usually taken from the generated EvergineContent class.
    public Guid TextFileId { get; set; }

    public string Text { get; private set; }

    protected override void Start()
    {
        // LoadRaw does not cache: keep the result if you need it again.
        this.Text = this.assetsService.LoadRaw(this.TextFileId, stream =>
        {
            using var reader = new StreamReader(stream, leaveOpen: true);
            return reader.ReadToEnd();
        });
    }
}
```

See [Raw assets loading](../../evergine_studio/assets/use.md#load-raw-assets) for details.

### Evergine Launcher

Remove several installed versions at once, with better responsiveness and loading feedback.

The full list of changes and bug fixes is in the release notes shown by the installer.
