# Sharpen

---

![The same frame before and after sharpening](images/Sharpen.jpg)

**Sharpen** increases the contrast of edges and fine detail. It uses RCAS (Robust Contrast Adaptive Sharpening), the sharpening pass of AMD FidelityFX Super Resolution, which sharpens low-contrast areas more than areas that are already crisp, so it adds detail without halos. Use it with effects that soften the image, such as [TAA](temporal_anti_aliasing.md) and [FSR](fidelity_super_resolution.md).

## Parameters

| Parameter | Default | Description |
| --- | --- | --- |
| **Enabled** | On | Turns the effect on. |
| **Amount** | 0.2 | Strength of the sharpening. |
