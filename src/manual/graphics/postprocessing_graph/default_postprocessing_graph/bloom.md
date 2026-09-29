# Bloom, Dirt, Light Shaft, and Lens Flare

In this section, multiple effects are explained because the process steps to calculate them are similar, and they were implemented together for performance reasons.

## Bloom

This effect produces fringes (or feathers) of light extending from the borders of bright areas in an image, contributing to the illusion of an extremely bright light overwhelming the camera or eye capturing the scene.

![Bloom](images/Bloom.jpg)

| Parameter        | Description                                                                 |
| ---------------- | --------------------------------------------------------------------------- |
| **Threshold**    | Pixels with a luminance higher than the threshold value will apply the effect. |
| **Color Intensity** | Defines the bloom color intensity in the final blended image.                 |
| **Intensity**    | Defines how the rendered image and the bloom output will be blended.         |

## Dirt

This effect tries to simulate when the camera lens is dirty and some lens stains are visible.

| Parameter      | Description                                              |
| -------------- | -------------------------------------------------------- |
| **Texture**    | Dirt texture used.                                       |
| **Intensity**  | Dirt intensity or how the rendered image and dirt output will be blended. |

## Light Shaft

**Light Shaft**, also known as **God Rays**, allows the viewer to see beams of light shining across the environment.

| Parameter       | Description                                                         |
| --------------- | ------------------------------------------------------------------- |
| **Min. Threshold** | Minimum luminance of the pixel to be affected by the effect.         |
| **Max. Threshold** | Maximum luminance of the pixel to be affected by the effect.         |
| **Scale**       | Size of the effect.                                                 |
| **Intensity**   | Defines how the rendered image and the bloom output will be blended. |

## Lens Flare

A **Lens Flare** happens when light is scattered or flared in a lens system, often in response to bright light, producing a sometimes undesirable artifact in the image. This occurs through light scattered by the imaging mechanism itself, for example through internal reflection and forward scatter from material imperfections in the lens.

![Lens Flare](images/LensFlare.jpg)

| Parameter               | Description                                                                   |
| ----------------------- | ----------------------------------------------------------------------------- |
| **Ghost Count**         | The number of ghost images.                                                   |
| **Ghost Spacing**       | The distance between ghost elements.                                          |
| **Ghost Threshold**     | Pixels with a luminance value above the threshold will be used to generate the ghost elements. |
| **Halo Radius**         | External halo radius.                                                         |
| **Halo Thickness**      | External halo thickness.                                                      |
| **Halo Threshold**      | Pixels with a luminance value above the threshold will be used to generate the halo. |
| **Halo Chromatic Aberration** | Amount of chromatic aberration.                                              |
| **Intensity**           | Defines how the rendered image and the bloom output will be blended.           |