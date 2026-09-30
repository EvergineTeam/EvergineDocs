# Preview: manual improvements

---

This local build is `next-release` plus a merge of the twelve `docs/improve-*` branches. Every branch is pushed to origin without a pull request and only touches its own section folder. Physics and Graphics > Low-level API are not part of this pass. The preview also merges `NewJoltPhysics`, so the [Physics](physics/index.md) section shows the new Jolt documentation.

Every section was checked against Engine `develop` (edac0841e) and the 2026.9.29.192 nightly. Each branch builds with DocFX without errors, and the link checker finds no broken link, wrong-case image or orphan media in any section.

| Section | Branch | Commits | Pages touched | New or replaced media |
| --- | --- | --- | --- | --- |
| [Get started](get_started/index.md) | `docs/improve-get-started` | 7 | 11 | 2 |
| [Basics](basics/index.md) | `docs/improve-basics` | 6 | 29 | 15 |
| [Evergine Studio](evergine_studio/index.md) | `docs/improve-evergine-studio` | 6 | 14 | 8 |
| [Platforms](platforms/index.md) | `docs/improve-platforms` | 4 | 9 | 5 |
| [Graphics](graphics/index.md) | `docs/improve-graphics` | 14 | 80 | 22 |
| [Input](input/index.md) | `docs/improve-input` | 2 | 6 | 6 |
| [Audio](audio/index.md) | `docs/improve-audio` | 4 | 5 | 5 |
| [Animation](animation/index.md) | `docs/improve-animation` | 3 | 4 | 5 |
| [XR](xr/index.md) | `docs/improve-xr` | 6 | 18 | 6 |
| [Runtimes](runtimes/index.md) | `docs/improve-runtimes` | 8 | 8 | 2 |
| [Extensions](extensions/index.md) | `docs/improve-extensions` | 4 | 11 | 9 |
| [Add-ons](addons/index.md) | `docs/improve-addons` | 8 | 43 | 6 |

## Get started

- New [2026.10 upgrade guide](get_started/migrations/upgrade_project_2026.10.md): DirectX 12 by default, Vulkan query slots, template changes and the new optional features.
- The [2026.5.26 guide](get_started/migrations/upgrade_project_2026.5.26.md) now uses `TextureDescription.ArraySize`, because `Layers` does not exist.
- [Install](get_started/install.md) has a requirements table and troubleshooting. [Open in Visual Studio](get_started/open_in_vs.md) has a diagram of one solution per profile and a Visual Studio 2026 capture.

## Basics

- Code that did not compile is fixed, such as `OnDetached` returning `void`, `[BindEntity]` and `AssetSceneManager`.
- [Entity hierarchy](basics/component_arch/entities/entity_hierarchy.md) is rewritten without the path syntax that does not exist.
- [Container](basics/application/container.md) documents the real API. New diagrams cover the lifecycle, the frame loop, navigation, binding search and NuGet packages.
- [Scene Editor](basics/scenes/scene_editor.md) has an annotated capture and a navigation video. Prefabs and Scene Managers have new captures.

## Evergine Studio

- [Interface](evergine_studio/interface.md) has an annotated main window, every menu, preferences with defaults and a grid of all asset editors.
- The asset pages take their extension tables from the importers. The page also has an asset pipeline diagram and a compiling `LoadRaw` example.
- Project Settings, profiles and services match develop. There is a services precedence diagram, and the RenderDoc page covers DirectX 12.
- 25 image paths with the wrong case are fixed. They broke on GitHub Pages.

## Platforms

- [Platforms](platforms/index.md) has the real template matrix from `templates.json`, without UWP or Linux, as a diagram and as a table.
- Android, iOS and the web pages are rewritten against the current templates.
- [Serialization](platforms/web/serialization.md) replaces 48 near-identical blocks with a converter table.
- New diagrams show the web architecture and the startup call sequence.

## Graphics

- New [Rendering overview](graphics/rendering_overview.md), [Samplers](graphics/samplers.md), [Lines 3D](graphics/lines_3d.md), [Evergine.Core](graphics/evergine_core.md) and [Subsurface Scattering](graphics/postprocessing_graph/default_postprocessing_graph/subsurface_scattering.md) pages.
- [Effect metatags](graphics/effects/effect_metatags.md) match the shader analyzer. Lights, cameras, backends and post-processing list the develop defaults.
- Twelve diagrams cover the render pipeline, the class model, the graphics stack, effect compilation, light shapes, shadow cascades, projection, the default graph, IBL and backends.
- New develop captures show every asset editor, ShadowMapManager, the six line primitives and a post-processing volume.

## Input

- Every page has a hero diagram, API tables and a complete example.
- [Touch](input/touch.md) uses `TouchDispatcher`, and `ButtonState` is documented as a `[Flags]` enum.
- The new [camera controller](input/camera_controller.md) page builds a WASD and mouse-look camera.

## Audio

- The import, editor, component and code pages are aligned with develop, with a platform support table.
- A new spatial audio diagram joins a redrawn AudioSource diagram. New captures show the Audio Editor and the SoundEmitter3D inspector.

## Animation

- [Animation3D](animation/animation3d_component.md) documents every `PlayAnimation` overload. The `int?` overload takes seconds, not frames.
- The blend tree page covers animation layers. The clip, blend tree and layer diagrams are redrawn.
- New captures show the Model Editor clip list and the Animation3D inspector.

## XR

- The spatial mapping, spatial anchors, trackable items and eye gaze pages are deleted, because no platform in develop implements them.
- New [OpenXR Platform](xr/openxr/openxr_platform.md), OpenVR, WebXR and Windows OpenXR pages. XR Platform lists every property.
- New diagrams show the architecture, the Quest and Pico setup and the passthrough layer stack. New captures show TrackXRController, XRPassthroughLayerComponent and the articulated hand setup.

## Runtimes

- The index has comparison tables of every runtime and a load pipeline diagram.
- The GLB, STL, OBJ, USD, CAD, IFC, Image and Video pages are rewritten with file and HTTP examples.

## Extensions

- The ImGui pages are rewritten for the current binding. New captures from ImGui-Demo show Dear ImGui, ImPlot, ImNodes and ImGuizmo.
- [Networking](extensions/networking.md) documents the full API, with topology and message flow diagrams.
- New [HLSLEverywhere](extensions/hlsleverywhere.md) and [CodeScenes](extensions/codescenes.md) pages.

## Add-ons

- MRTK, XRV, Gaussian Splatting, DICOM, Point Cloud and Cesium are checked against their add-on repositories. Code that did not compile is fixed.
- The index has a table of every add-on and a develop capture of the Add-Ons tab. Gaussian Splatting has a capture of the SplatRender sample.

## Not done

- **Captures that need a running headset, device or special scene:** add-profile dialogs (empty template list in the nightly), post-processing before and after comparisons, runtime test apps, the web app, and the MRTK, XRV, DICOM, Point Cloud and Cesium demos.
- **Videos of the model editor animation preview:** the preview does not animate in the nightly.
