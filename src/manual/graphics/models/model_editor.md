# Model Editor
![Model Editor](images/ModelEditor.jpg)

The **Model Editor** allows the editing of model assets. Double-clicking a **Model** asset shown in [Assets Details](../../evergine_studio/interface.md) will open this editor. The editor is composed of five main parts:

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
Panel with all the **Model** properties. They don't depend on the profile.

| Property | Description |
|----------|-------------|
| **Swap Swinding Order** | Flips the normals of the model when activated. |
| **Generate Tangent Space** | When checked, generates the tangent coordinates of every vertex. Useful when dealing with normal mapping. |
| **Export Animations** | For exporting the animation information of the model. |
| **Export As Raw** | Will export the model as the source file (e.g., `.fbx`), instead of creating a binary **Evergine** asset.

## Animation Clip Properties
For every animation contained in the model, the following information will be shown:

| Property | Description |
|----------|-------------|
| Index | The animation order. |
| Name | The name of the clip. This string will be used in the **Animation3D** when we want to play the animation. |
| Duration | Timestamp of the duration.