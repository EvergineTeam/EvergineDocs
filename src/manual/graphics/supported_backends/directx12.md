# DirectX 12

![Microsoft DirectX12 API](images/directx12.jpg)

**DirectX 12** is the latest **Microsoft** graphics API available on all devices running Windows 10/11. **Microsoft** announced this version at GDC on March 20, 2014, and it was officially launched alongside Windows 10 on July 29, 2015. On October 2, 2018, DirectX Raytracing support was added to the API. It quickly became popular, and currently, all the latest GPUs from Nvidia and AMD come with Raytracing support. This is also supported on the **Evergine** low-level API, so **DirectX 12** supports **Evergine's** raytracing API.

## Supported DirectX 12 devices

* Windows 10/11 x64/x86 desktop
* Windows 10/11 ARM64/x86 tablet

## Checking DirectX 12 version

The DxDiag tool reports detailed information about the DirectX components and drivers installed on your Windows system. It is available on Windows 10/11. To get the latest DirectX version on your system, use Windows Update.

For more information, visit [Microsoft support.](https://support.microsoft.com/en-us/windows/checking-your-version-of-directx-7b71e74f-02e8-456f-72c7-9a1c1bbf0e9a)

## Create a Graphics Context

To create a graphics context based on **DirectX 12**, simply write:

```csharp
GraphicsContext graphicsContext = new Evergine.DirectX12.DX12GraphicsContext();
graphicsContext.CreateDevice();
```

## Build & Run

You can select **DirectX 12** API support during the new project creation from the **Evergine** launcher.

If the project already exists, you can add **DirectX 12** support from **Evergine Studio** by clicking on Settings -> Project Settings.

![Settings](images/dx12_support_0.JPG)

Select and add the profile for Windows (DirectX 12).

![Settings](images/dx12_support_1.JPG)

![Settings](images/dx12_support_2.JPG)

You can run on **DirectX 12** by clicking on File -> Build & Run -> Windows.DirectX12.

![Settings](images/dx12_support_3.JPG)