# Compute Tasks

---

**Compute tasks** run general-purpose programs on the GPU, outside the vertex and pixel pipeline. They suit massively parallel algorithms, such as image processing, simulation or procedural generation, and can also accelerate parts of rendering.

A compute task is always built from a [compute effect](../effects/create_effects.md), the same way a material is built from a graphics effect. The nodes of the [post-processing graph](../postprocessing_graph/index.md) are compute effects too.

## In this section

* [Create Compute Tasks](create_computetasks.md)
* [Using Compute Tasks](using_computetasks.md)
