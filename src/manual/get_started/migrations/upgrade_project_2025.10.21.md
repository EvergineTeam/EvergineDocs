Changes to the handling of gamma correction
-------------------------------------------
There are major breaking changes related to gamma correction.
If you update your existing Evergine project you will notice that textures look brighter than they used to. Some textures may fail to load too.
Before, all imported textures had linear format. Gamma decoding was performed in the shader, if needed, depending on the usage.
This is an expensive operation for the pixel shader and it's innacurate when combined with mipmapping and pixel interpolation.
In the new version, we leverage hardware decoding, so sRGB textures need to be marked as so.

How to fix your textures
------------------------
We provide a python3 script to help you port exiting projects.
It will automatically detect the usage of textures and determine if the need to be sRGB or not.

Steps:
1) Update your project from the launcher as usual
2) Open the project and notice that textures look brighter than usual
3) Download the [migration-2025.10.21.py](.\migration-2025.10.21.py) script to a folder
4) Run the command `python3 migration-2025.10.21.py path/to/my_evergine.weproj`
5) Now the textures should look correct

Gamma framebuffers
------------------
The following is not a breaking change, but an optimization to your project.
Previously, gamma encoding was performed in the pixel shader before writing to the framebuffer.
All the project templates had linear framebuffers.
Now both linear and sRGB framebuffers are supported. But it's recommended to use sRGB framebuffers for improved performance.

In order to change your framebuffers to sRGB, go to your Program.cs, and change the following line:

```cs
ColorTargetFormat = PixelFormat.R8G8B8A8_UNorm,
```

to:

```cs
ColorTargetFormat = PixelFormat.R8G8B8A8_UNorm_SRgb,
```