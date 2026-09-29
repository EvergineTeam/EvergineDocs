# Subsurface Scattering (SSS)

---

<!-- CAPTURE: images/sss.png; the same skin material side by side without and with the SSS post-processing effect, lit from one side, showing the softer light falloff and red translucency -->

In materials such as skin, marble, wax or leaves, light enters the surface, scatters inside and comes out somewhere else. That is what gives skin its soft look and makes ears glow red against the light. **Subsurface scattering** reproduces it in screen space: it blurs the lighting of the marked materials along their surface, with a profile that lets red light travel farther than green and blue.

It works together with a material that uses the **SSS effect** (`SSSEffect`) of the Evergine.Core package. The material marks its pixels in the GBuffer; the post-processing effect then blurs only those pixels, following the depth of the surface so the blur does not bleed onto the background.

## Set it up

1. Create a material with the **SSSEffect** effect and enable its **SSSScatter** directive in the [Material Editor](../../materials/material_editor.md). Enable **SSSTranslucency** too if light should shine through thin parts.
2. In the post-processing volume, enable **SSS** in the default graph.

> [!IMPORTANT]
> The SSS mask is written in the GBuffer pass, so the effect only works where that pass runs: on Windows, for cameras with an intermediate buffer.

## Material parameters

These belong to materials created from `SSSEffect`:

| Parameter | Default | Description |
| --- | --- | --- |
| **SSSScatter** | 0.03 | How far light scatters under the surface. |
| **SSSIntensity** | 0.1 | Strength of the scattering. |
| **SSSTranslucency** | (0.64, 0.094, 0.063) | Color of the light that goes through thin parts, with the `SSSTranslucency` directive. The default is a skin red. |
| **SSSBias** | 0.005 | Depth bias used to estimate thickness for translucency. |

## Post-processing parameters

| Parameter | Default | Description |
| --- | --- | --- |
| **Enabled** | Off | Turns the effect on. |
| **Quality** | `SSS_QUALITY_2` | Number of blur samples: `SSS_QUALITY_OFF`, `SSS_QUALITY_1` or `SSS_QUALITY_2`. |
| **SSSWidthFactor** | 0.15 | Width of the blur in world space. Larger values give a softer, waxier look. |
