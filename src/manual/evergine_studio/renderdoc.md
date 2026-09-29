# Profile with RenderDoc

---
![Graphics](Images/RenderDoc_0.JPG)

RenderDoc is a graphics debugger currently available for Vulkan, DirectX 11/12, and OpenGL development on Windows, Linux, and Android. It is integrated into **Evergine Studio** to make it easy to debug your application during the development process.

To install the latest RenderDoc version, visit the project's [website](https://renderdoc.org/).

## Loading RenderDoc

First, you need to load the RenderDoc assembly to allow the graphical commands sent to the GPU to be captured. In the settings menu of the Editor, you will find an option called "Enable RenderDoc." This will reload the graphics device, so you must save any changes. Afterward, RenderDoc will be ready to capture the scene.

![Graphics](Images/RenderDoc_1.JPG)

## Capturing a frame with RenderDoc

Once RenderDoc is enabled in **Evergine Studio**, a new button will appear on the right side of the toolbar in the scene view.

![Graphics](Images/RenderDoc_2.JPG)

Pressing this button will trigger a capture of the next frame of rendering for the view, and a new RenderDoc instance will be launched to show the capture. From there, you can open the capture and debug using the tool.

![Graphics](Images/RenderDoc_3.JPG)

## Naming objects

The **Evergine** low-level API allows you to name all the different object types available. This includes samplers, buffers, pipelines, and much more. These names can then be displayed on RenderDoc to help debug the application.

To set an object name, such as in a buffer, just set it as a parameter in the factory constructor or set the property Name.

```csharp
this.graphicsContext.Factory.CreateBuffer(ref Description, "Buffer_Name");
```

or

```csharp
buffer.Name = "Buffer_Name";
```

![Graphics](Images/RenderDoc_4.JPG)

## Debug markers and regions

In addition to naming, the **Evergine** low-level API also adds the ability to place debug markers inside command buffers. These can be used to mark points of interest and highlight specific areas inside the command buffer.

> [!Tip]
> Note that contrary to naming objects, debug markers (and regions) have to be placed inside an active command buffer.

```csharp
commandBuffer.BeginDebugMarker("Region_Name");
// Stuff
commandBuffer.EndDebugMarker();
```

![Graphics](Images/RenderDoc_5.JPG)

## Including shader debug information

By default, to optimize the size of DirectX shaders, debugging information is stripped out. This means that constants and resources will have no names, and the shader source will not be available. To include this debugging information in your shader, you need to set the debug mode inside the pass shader code by adding the `[Mode Debug]` line:

```csharp
[Begin_Pass:Default]

    [Mode Debug]
    [Profile 10_0]
    [Entrypoints VS=VS PS=PS]

    // ...
```

## Alternative graphics debugging techniques

If you build a desktop Windows application using DirectX, you can capture a frame and debug it using the [Visual Studio graphics debugger](https://docs.microsoft.com/en-us/visualstudio/debugger/graphics/visual-studio-graphics-diagnostics?view=vs-2019), [NVidia Nsight Graphics](https://developer.nvidia.com/nsight-graphics), or [PIX on Windows](https://devblogs.microsoft.com/pix/introduction/).