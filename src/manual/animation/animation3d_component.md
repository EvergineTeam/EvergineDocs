# Animation 3D Component

<video autoplay loop muted width="100%" height="auto">
  <source src="images/rhino.mp4" type="video/mp4">
</video>

The **Animation3D** class in **Evergine** is a specialized component that facilitates the control and management of animations for 3D models. This class is essential for working with animated 3D characters, objects, or environments, allowing for smooth playback, looping, and synchronization of animations. Let's  explore the core features and usage of the **Animation3D** class based on its structure and common use cases.

## Properties
This component is created automatically when we instantiate a model that contains animations. It will be in the root entity. In addition, we can create our own component just knowing the following properties:

| Name | Description |
|------|-------------|
| **Clip** | (_Only Getter_) Gets the current **AnimationBlendClip** in play. |
| **AnimationLayers** | (_Only Getter_) Gets all the registered layers of **AnimationBlendClip**. |
| **BoundingBoxRefreshed** | _True_ if the bounding box of the model has been refreshed. |
| **CurrentAnimation** | Holds the **name** of the animation that is currently active. |
| **Loop** | Boolean value that determines whether the animation should restart after completion. |
| **PlaybackRate** | Controls the speed at which the animation plays. |
| **CurrentAnimationTrack** | (_Only Getter_) Gets the current animation track (from the Model asset) currently active.|
| **AnimationState** | The current status of the animation. It can be **Stopped** and **Playing**. | 
| **Frame** | The current frame of the animation in play. |
| **PlayTime** | The amount of time since the current animation started playing |
| **StartAnimationTime** | The start time (in seconds) of the animation.  |
| **EndAnimationTime** | The ending time (in seconds) of the animation.  |
| **Duration** | The duration (in seconds) of the current animation.  |
| **PlayAutomatically** | When true, the current animation will start playing on the beginning without requiring manual play. |
| **ApplyRootMotion** | Boolean that indicates whether the transform offset from the root entity will be applied to this entity. |
| **SmoothTransitions** | If true, the transition between 2 AnimationBlendClips will be using a smooth transition, opposed to the linear interpolation by default.