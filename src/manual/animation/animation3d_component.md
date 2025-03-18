# Animation 3D Component

<video autoplay loop muted width="100%" height="auto">
  <source src="images/rhino.mp4" type="video/mp4">
</video>

The **Animation3D** class in **Evergine** is a specialized component that facilitates the control and management of animations for 3D models. This class is essential for working with animated 3D characters, objects, or environments, allowing for smooth playback, looping, and synchronization of animations. Let's  explore the core features and usage of the **Animation3D** class based on its structure and common use cases.

## Properties
This component is created automatically when we instantiate a model that contains animations. It will be in the root entity. In addition, we can create our own component just knowing the following properties:

| Property | Description |
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

## Methods
The following methods allow us to fully control the animation.

| Property | Description |
|------|-------------|
| **PlayAnimation** | Starts the playback of an animation. The new animation can be defined by the **AnimationTrackClip** name from the **Model** asset, or directly providing the **AnimationBlendClip** if we want more specific animation, like a blend tree (more information in **[this section](animation_blend_tree.md))**.|
| **StopAnimation** |  Stops the animation entirely and it keeps there. |
| **ResumeAnimation** | Resumes the animation playback from the moment it time it got stopped. |

## Sample Code

The following code explores some of the methods.
```csharp

Animation3D  animation3D; // this object can be acquired through [BindComponent] aswell.

// We plays the 'walking' animation, in loop mode, at double speed and transitioning over 1 second.
animation3D.PlayAnimation("walking", loop: true, transitionTime: 1, playbackRate: 2);

// We plays only a window slice of the 'full_track' animation (from seconds 1 to 5), in loop mode.
animation3D.PlayAnimation("full_track", loop: true, startTime: 1, endTime: 5);

// We can also play directly an AnimationBlendClip.
animation3D.PlayAnimation(animationBlendClip);

// Stops the animation.
animation3D.StopAnimation();

```

## Working with Animation node hierarchies

When dealing with skeletal animations, creating a hierarchy of **AnimationBlendClips** becomes particularly useful. This feature ensures that complex models with multiple moving parts (such as characters with arms, legs, and head movement) behave correctly as the animation plays. Each node in the model’s hierarchy is mapped to a corresponding bone or joint in the animation, ensuring proper deformation and movement of the model. In [this article](animation_blend_tree.md) we explain in detail how to create your own animation blend tree.

## Conclusions

The **Animation3D** class in **Evergine** provides a robust set of tools for controlling 3D model animations. Whether you're developing character animations or animating complex mechanical systems, the class offers essential features such as looping, playback control, and node hierarchy mapping. By mastering these properties and methods, developers can create lifelike and responsive animations that enhance the visual and interactive quality of their projects.