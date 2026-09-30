# Model Editor

---

![The Model Editor with an animated model: viewport, toolbar, playback controls and properties](images/ModelEditor.png)


The **Model Editor** previews a model and edits its import settings. Double-click a model in [Assets Details](../../evergine_studio/interface.md) to open it. It has four parts: the viewport, the toolbar, the playback controls and the properties.

## Viewport
Shows the **Model** with the current configuration. If the model is animated, it will show the current animation state on the *animation toolbar*.

## Toolbar

![Toolbar controls](images/modelToolbar.png)

Assists with the model visualization. It has the following options:

| Item | Description |
| ---- | ----------- |
| ![toggle grid](images/toggleGrid.png) | Toggles the **Grid** visualization. |
| ![solid](images/solidIcon.png) /  ![wireframe](images/wireframeIcon.png)| <p>Toggles the visualization from **Solid** (default) to **Wireframe**. </p> ![Wireframe](images/wireframe.png) |
| ![bounding box](images/boundingBoxIcon.png) | <p>Toggles the **Bounding box** visualization of the model.</p> ![Bounding Box](images/boundingBox.png) |
| ![hierarchy](images/hierarchyIcon.png) | <p>Toggles the **Hierarchy** visualization of the model.</p> ![Hierarchy](images/hierarchy.png) |
| ![normals](images/normalIcon.png) | <p>Toggles the **Normals** visualization of the vertices.</p> ![Normals](images/normals.png) |
| ![uv](images/uvCheckerIcon.png) | <p>Toggles the **UV checker** visualization of the model.</p> ![UV Checker](images/checker.png) |
| ![reset camera](images/resetCameraIcon.png) | Resets the camera position. |
| ![change background](images/changeBackground.png) | Changes the background color. |

## Playback Controls

![Playback controls](images/playbackToolbar.png)

If the model has animations, the *Playback Toolbar* allows playing the selected clip.

| Control | Description |
| ---- | ----------- |
| ![play](images/playIcon.png) /  ![stop](images/stopIcon.png) | Plays / Stops the current clip animations. |
| ![timeline](images/slider.png) | The timeline slider. The handle will mark the current time in the animation, and its position can be modified. |
| ![speed](images/velocity.png) | Controls the **Speed Factor** of the reproduction. The default is **1.00**. |

## Properties
The import settings of the model, shared by every profile:

| Property | Description |
|----------|-------------|
| **Swap Winding Order** | Reverses the winding of every triangle, which flips which side faces outwards. Use it when a model shows its inside, as happens with some exporters. Off by default. |
| **Generate Tangent Space** | Generates tangents for every vertex, which normal maps need. On by default. |
| **Export Animations** | Exports the animation clips of the model. On by default. |
| **Export As Raw** | Exports the source file (for example the `.fbx`) as is, instead of converting it to an Evergine asset. |

## Animation Clip Properties
For every animation contained in the model, the following information will be shown:

| Property | Description |
|----------|-------------|
| Index | The animation order. |
| Name | The name of the clip. This string will be used in the **Animation3D** when we want to play the animation. |
| Duration | Timestamp of the duration.