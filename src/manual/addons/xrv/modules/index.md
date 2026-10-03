# XRV modules

---

Modules are reusable features that plug into XRV. Each one is an [Evergine add-on](../../index.md) that you install from the Add-ons Manager and then register in your `XrvService` with `AddModule`. A module can add a button to the [hand menu](../hand_menu.md), tabs to the [settings](../settings_system.md) and [help](../help_system.md) windows, and its own windows and entities. The [XRV samples](https://github.com/EvergineTeam/XRV/tree/develop/samples) project runs all the public modules together.

```csharp
var xrv = new XrvService()
    .AddModule(new RulerModule())
    .AddModule(new PainterModule());
```

| Module | Add-on | What it does |
| --- | --- | --- |
| [Image Gallery](imageGallery/index.md) | `Evergine.Xrv.ImageGallery` | Shows images from a storage repository, one at a time. |
| [Model Viewer](modelViewer/index.md) | `Evergine.Xrv.ModelViewer` | Loads 3D models from storage repositories and lets the user move, rotate, and scale them. |
| [Painter](painter/index.md) | `Evergine.Xrv.Painter` | Draws 3D lines in space with different colors and thicknesses. |
| [Ruler](ruler/index.md) | `Evergine.Xrv.Ruler` | Measures the distance between two points. |
| [Streaming Viewer](streamingviewer/index.md) | `Evergine.Xrv.StreamingViewer` | Shows a video stream from an MJPEG source, such as an IP camera. |
| Audio Notes | `Evergine.Xrv.AudioNotes` | Records audio notes and plays them back. |

|<img alt="Image Gallery" src="imageGallery/images/snapshot.png" height="180">|<img alt="Model Viewer" src="modelViewer/images/snapshot2.png" height="180">|<img alt="Painter" src="painter/images/snapshot2.png" height="180">|
|:--:|:--:|:--:|
| **Image Gallery** | **Model Viewer** | **Painter** |
|<img alt="Ruler" src="ruler/images/snapshot.png" height="180">|<img alt="Streaming Viewer" src="streamingviewer/images/snapshot.png" height="180">| |
| **Ruler** | **Streaming Viewer** | |

## Custom modules

If your application has specific needs, [create your own module](customModule/index.md) and reuse it in several applications.

## In this section

- [Image Gallery](imageGallery/index.md)
- [Model Viewer](modelViewer/index.md)
- [Painter](painter/index.md)
- [Ruler](ruler/index.md)
- [Streaming Viewer](streamingviewer/index.md)
- [Custom modules](customModule/index.md)
