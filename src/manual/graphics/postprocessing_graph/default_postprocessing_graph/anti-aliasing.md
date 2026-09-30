# Fast Approximate Anti-Aliasing (FXAA)

---

**Fast Approximate Anti-Aliasing** smooths jagged edges in a single full-screen pass. It finds edges by their contrast in the final image and blends across them, so it works on any edge, including those inside textures and alpha-tested geometry, and needs no extra buffers.

Because it only sees the final pixels, FXAA cannot recover detail smaller than a pixel, can soften high-contrast textures, and does not remove shimmering in motion. [TAA](temporal_anti_aliasing.md) handles those better; the default graph runs both.

## Parameters

| Parameter | Default | Description |
| --- | --- | --- |
| **Enabled** | On | Turns the effect on. |
| **Quality** | `Default` | Search quality: `Performance`, `Default` or `Extreme`. Higher quality follows edges farther, which smooths long, shallow edges better at a higher cost. |
