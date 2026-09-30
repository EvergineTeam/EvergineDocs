# Motion Blur

---

**Motion Blur** blurs the image in the direction the camera moves, the way a real camera smears the picture during its exposure. It makes fast camera movement look smoother, especially at low frame rates. It reads the motion vectors of the GBuffer pass.

## Parameters

| Parameter | Default | Description |
| --- | --- | --- |
| **Enabled** | On | Turns the effect on. |
| **Decay Factor** | 0.945 | How quickly the weight of each sample falls along the blur, from 0 to 1. Values closer to 1 give longer trails. |
| **Num. Samples** | 9 | Samples taken along the motion vector, from 1 to 20. |
