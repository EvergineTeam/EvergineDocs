# Extensions

---

The core packages, `Evergine.Framework` and `Evergine.Components`, contain the services, managers and components that every application needs. **Extensions** are the pieces that are too specific to live there: an integration with a third-party library, a networking layer, or a build-time tool. Each one ships as its own NuGet package, versioned together with the rest of Evergine, so a project only carries the extensions it uses.

| Extension | Package | What it gives you |
| --- | --- | --- |
| [ImGui](imgui/index.md) | `Evergine.ImGui` | Dear ImGui, ImPlot, ImNodes and ImGuizmo drawn over your scene, for debug panels and in-app tools. |
| [Networking](networking.md) | `Evergine.Networking` | A matchmaking server and client, with rooms, messages and synchronized properties over UDP. |
| [HLSLEverywhere](hlsleverywhere.md) | `Evergine.HLSLEverywhere` | Translates HLSL shaders to SPIR-V, GLSL, ESSL, Metal and WGSL so one effect runs on every graphics backend. |
| [CodeScenes](codescenes.md) | `Evergine.CodeScenes` | A source generator that turns `.wescene` and `.weprefab` files into C# at build time. |

> [!NOTE]
> The XR extensions, `Evergine.OpenXR`, `Evergine.OpenVR` and `Evergine.WebXR`, are documented in their own section. Start at [XR](../xr/index.md), then read [XR Platform](../xr/xrplatform.md) and [OpenXR](../xr/openxr/index.md).

## In this section

* [ImGui](imgui/index.md)
* [Networking](networking.md)
* [HLSLEverywhere](hlsleverywhere.md)
* [CodeScenes](codescenes.md)
