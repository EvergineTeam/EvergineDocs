# OpenGL

![OpenGL API](images/opengl.jpg)

Open Graphics Library (OpenGL) is the most widely adopted 2D and 3D graphics API in the industry, cross-platform. Silicon Graphics Inc. began developing OpenGL in 1991 and released it on June 30, 1992. Now, it is a technology maintained by the **Khronos Group**.

**Evergine** uses the OpenGL graphics API on the Web platform and Windows desktop but is deprecating this technology in favor of [Vulkan](vulkan.md), the new modern graphics API created by the **Khronos Group**.

**OpenGL** is used on the Web platform by **Evergine** through a version named **WebGL**, which is the default version supported in the most popular browsers.

* Chrome, Edge, and Firefox support WebGL 2.0.
* Safari supports WebGL 1.0.

## Supported OpenGL devices

* Windows 8/10/11 x64/x86 desktop
* Web Browsers on desktop, tablet, and mobile devices.

## Checking OpenGL version

If you are running Windows 7 or later, the **OpenGL** library has already been installed on your system.

To check the **OpenGL** version available on your system, locate the control panel of your graphics card or download the [OpenGL Hardware Capability Viewer](https://opengl.gpuinfo.org/download.php).

## Create a Graphics Context

To create a graphics context based on **OpenGL**, simply write:

```csharp
GraphicsContext graphicsContext = new Evergine.OpenGL.GLGraphicsContext();
graphicsContext.CreateDevice();
```

To create a graphics context based on **WebGL**, simply write:

```csharp
GraphicsContext graphicsContext = new Evergine.OpenGL.GLGraphicsContext(GraphicsBackend.WebGL2);
graphicsContext.CreateDevice();
```

## Build & Run

You can select **OpenGL** API support during the new project creation from the **Evergine** launcher.

### Desktop

If the project already exists, you can add **OpenGL** support from **Evergine Studio** by clicking on Settings -> Project Settings.

![Settings](images/dx12_support_0.JPG)

Select and add the profile for Windows (OpenGL).

![Settings](images/gl_support_1.JPG)

![Settings](images/gl_support_2.JPG)

You can run on **OpenGL** by clicking on File -> Build & Run -> Windows.OpenGL.

![Settings](images/gl_support_3.JPG)

### WebGL

To support Web platforms based on **WebGL** versions, you also need to add the WebGL Template from the project settings, selecting WebGL 2.0 or 1.0 depending on your project needs.

![Settings](images/gl_support_4.JPG)