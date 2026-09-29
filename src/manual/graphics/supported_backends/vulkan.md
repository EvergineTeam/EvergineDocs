# Vulkan

![Vulkan API](images/vulkan.jpg)

**Vulkan** is a low-overhead cross-platform API. It is the most recent API created by **Khronos Group** and targets high-performance real-time 3D graphics applications. Compared with DirectX 11 and OpenGL, **Vulkan** offers higher performance and more balanced CPU and GPU usage. It provides a considerably lower-level API and parallel tasking for the application.

**Khronos Group** announced this API for the first time at GDC 2015, referred to as the "next generation OpenGL initiative" or "OpenGL next," but they eventually renamed it **Vulkan**. **Vulkan** is not backward compatible with OpenGL and is derived from AMD's Mantle API, which was donated by AMD to Khronos to try to standardize a low-level API across the industry. Ray tracing support was recently added to **Vulkan**, and the API is very similar to the **DirectX12** Raytracing API, so Vulkan supports the **Evergine** ray tracing API.

## Supported Vulkan devices

* Windows 8/10/11 x64/x86 desktop
* Linux x64/x86 desktop
* Android ARMv7/ARM64 tablet and mobile
* macOS x64/x86/ARM64 desktop (using MoltenVK)
* iOS ARM64 tablet and mobile (using MoltenVK)

## Checking Vulkan version

To ensure that you can visualize the rendering options Vulkan has available on your development PC, you will need to download and install the latest version of video card drivers for your graphics card. Download them from:

* [Nvidia](https://www.nvidia.com/Download/index.aspx)
* [AMD](https://www.amd.com/en/support)

It is highly recommended to download [LunarSDK](https://vulkan.lunarg.com/) to install the latest development and debugging tools for the **Vulkan** graphics API.

## Create a Graphics Context

To create a graphics context based on **Vulkan**, just write:

```csharp
GraphicsContext graphicsContext = new Evergine.Vulkan.VKGraphicsContext();
graphicsContext.CreateDevice();
```

## Build & Run

You can select **Vulkan** API support during new project creation from the **Evergine** launcher.

If the project already exists, you can add **Vulkan** support from **Evergine Studio** by clicking on Settings -> Project Settings.

![Settings](images/dx12_support_0.JPG)

Select and add the profile for Windows (Vulkan).

![Settings](images/vk_support_1.JPG)

![Settings](images/vk_support_2.JPG)

You can run on **Vulkan** by clicking on File -> Build & Run -> Windows.Vulkan.

![Settings](images/vk_support_3.JPG)