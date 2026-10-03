# Particle System Editor

---

![The Particle System Editor: viewport, toolbar, playback controls and properties](images/particles_editor.png)


The **Particle System Editor** allows the editing of particle system assets. Double-clicking on a **Particle System** asset shown in [Assets Details](../../evergine_studio/interface.md) will open this editor. The editor is composed of 4 main parts:

## Viewport
Shows the **Particle System** with the current configuration. The user can orbit, zoom, and pan the camera.
![Particles Viewport](images/particles_viewport.png)

| Actions | Description |
|---------| ----------- |
| Left mouse button | Rotates the camera around the particle system. |
| Right mouse button | Rotates two lights around the particle system. |
| Mouse wheel | Zooms the camera in/out. |

## Toolbar
![Toolbar controls](images/particles_toolbar.png)

Controls what the viewport shows:

| Item | Description |
| ---- | ----------- |
| ![toggle grid](images/toggleGrid.png) | Toggles the **Grid** visualization. |
| ![toggle_gizmo](images/toggle_gizmo.png) | Toggles the **Emitter shape gizmo** visualization. |
| ![bounding box](images/toggle_force_cpu.png) | Forces particle simulation to use the **CPU** instead of the **GPU** when this option is activated, even if GPU particles are available. |
| ![reset camera](images/resetCameraIcon.png) | Resets the camera position. |
| ![change background](images/changeBackground.png) | Changes the background color. |

## Playback Controls
![Simulation controls](images/particle_simulation_controls.png)

This bar controls some aspects of the particle simulation life.

| Control | Description |
| ---- | ----------- |
| ![reset](images/reset_icon.png) | Resets the particle system. |
| ![play](images/play_icon.png) / ![stop](images/stop_icon.png) | Starts or stops the emission. |
| ![Time factor](images/time_factor.png) | Controls the **Time Factor** of the particle system, similar to the **Particles Component** property. |

## Particle Properties
A panel with all the **Particle System** properties. These properties do not depend on the profile.

![Particles Properties](images/particles_properties.png)