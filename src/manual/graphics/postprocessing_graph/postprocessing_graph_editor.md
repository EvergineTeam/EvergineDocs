# Post-Processing Graph Editor

---

![The Post-Processing Graph Editor with the default graph: graph editor, viewport and available effects](images/PostprocessingGraphEditor.png)


The **Post-Processing Graph Editor** edits post-processing graph assets. Double-click a graph asset in [Assets Details](../../evergine_studio/interface.md) to open it. The editor has three parts:
* Graph Editor
* Compute Effects Collection
* Viewport

## **Graph Editor**

The **Graph Editor** allows you to create graph nodes to connect the start node (_Render_) with the last node (_Screen_). The nodes are computed effects, and their parameters, inputs, and outputs are defined by their ResourceLayout block.

| Node Elements | Description |
| ------------- | ----------- |
| **Name**          | Located at the top of the Node is the name of the compute effect used. |
| **Divisors**      | Allows configuring the ThreadGroupDivisor X, Y, and Z to dispatch the compute effect. |
| **Parameters**    | Allows configuring constant buffer or structure buffer properties for the compute effect. |
| **Input**         | Allows setting Textures and Samplers for the compute effect. |
| **Output**        | Allows setting RWTextures for the compute effect. |

![Node Parts](images/PostprocessingNode.jpg)

> [!TIP]
>The node inputs can only be connected with a single node output, but a node output can be connected with multiple node inputs.

### **Toolbox**

The toolbox is located at the top of the graph editor and allows you to manipulate the graph view.

| Icon  | Description |
| ----- | ----------- |
|![Delete](images/deleteIcon.jpg)| Delete the selected node. |
|![Relocate](images/relocateIcon.jpg)    | Execute an algorithm to relocate nodes and avoid node overlapping. |
|![Zoom In](images/zoomInIcon.jpg) ![Zoom Out](images/zoomOutIcon.jpg) | Zoom in/out the graph. |
|![Center](images/centerIcon.jpg) | Center the view over the graph. |

| Actions | Description |
|---------| ----------- |
| **Left mouse button** | Selection tool. Allows selecting single or multiple nodes.|
| **Right mouse button** | Cut tool. Allows you to draw a cut line to break connections.|
| **Middle mouse button** | Pan tool. Allows you to move along the graph.|
| **Mouse wheel** | Allows you to zoom in/out over the graph.  |

## **Compute Effects Collection**
In this panel, you can find all compute effects existing in the project and drag an effect to the graph editor to use it.

## **Viewport**
The viewport allows you to inspect the result of the postprocessing graph applied to the scene:

> [!NOTE]
> To refresh the graph changes in the viewport, you need to save all graph changes.

| Icon  | Description |
| ----- | ----------- |
|![Select scene](images/sceneIcon.jpg)| The combobox allows selecting the current scene for the viewport.|
|![Camera settings](images/cameraIcon.jpg)    | Opens the camera settings to configure all its parameters. The camera changes are not stored, so it is only for testing purposes. |

The viewport allows you a simple interaction to easily inspect the scene:

| Actions | Description |
|---------| ----------- |
| `W`, `S`, `D`, `A` | Move camera along the scene.|
| **Right mouse button** | Rotates camera. |
| **Middle mouse button** | Camera panning. |
| **Mouse wheel** | Camera zoom in/out.  |