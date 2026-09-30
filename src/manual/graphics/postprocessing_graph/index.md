# Post-Processing Graph

---

![Post-processing graph](images/PostProcessingGraph.jpg)

**Post-processing** applies screen-space effects to a camera's image after the scene has been rendered and before it reaches the screen: tone mapping, anti-aliasing, ambient occlusion, reflections, depth of field, bloom and more. In Evergine these effects are organized as a **post-processing graph**, a network of nodes where each node is a [compute effect](../effects/create_effects.md) that reads textures produced by earlier nodes and writes new ones.

| Post-processing disabled | Post-processing enabled |
| --- | --- |
| ![The scene without post-processing: flat lighting and hard edges](images/PostProcessingGraphBefore.jpg) | ![The same scene with the default graph: ambient occlusion, bloom, tone mapping and anti-aliasing](images/PostProcessingGraphAfter.jpg) |

## How it runs

A graph starts at the **Render** node, which provides the camera's color and depth, and ends at the **Screen** node. Every node between them is dispatched in dependency order on the GPU.

The graph runs as the last step of the camera's `Default` pass (see [Rendering Overview](../rendering_overview.md)), so it needs the camera's intermediate buffer, and effects that read normals or motion vectors also need the GBuffer pass. Both are available on the default Windows configuration; a camera rendering straight to its target skips post-processing.

A graph is applied to the scene by a **post-processing volume**: an entity with a `PostProcessingGraphRenderer` component. The volume can affect every camera or only the cameras inside it. See [Using the Post-Processing Graph](using_postprocessing_graphs.md).

## The default graph

The Evergine.Core package includes a ready-made graph with the most common effects, each behind a switch, and new volumes use it unless you choose another. Most projects only tune its parameters; you build your own graph to add new effects or to strip the chain down for performance. See [Default Post-Processing Graph](default_postprocessing_graph/index.md).

## In this section

* [Create a Post-Processing Graph](create_postprocessing_graphs.md)
* [Using the Post-Processing Graph](using_postprocessing_graphs.md)
* [Post-Processing Graph Editor](postprocessing_graph_editor.md)
* [Default Post-Processing Graph](default_postprocessing_graph/index.md)
* [Custom Post-Processing Graph](custom_postprocessing_graph.md)
* [Create a Post-Processing Graph from Code](create_postprocessing_graphs_from_code.md)
