# Animation

<video autoplay loop muted playsinline width="100%" height="auto">
  <source src="images/animation.mp4" type="video/mp4">
</video>

Evergine plays the animations that come with your 3D models. The importer reads every animation track of a model file into an animation clip, and the `Animation3D` component plays those clips on the entities of the model, whether they move the bones of a skinned character, the nodes of a machine or the morph target weights of a face.

On top of playing one clip at a time, the animation system crossfades between clips, blends them by a weight you control, adds one on top of another and plays several at once in layers.

## The three parts

- **[Animation Clip](animation_clip.md)**: the data. A clip is a set of channels, each animating one property of one node through a curve of keyframes, plus the keyframe events that mark points of the clip.
- **[Animation3D Component](animation3d_component.md)**: the player. It lives on the root entity of the model, plays clips by name, raises the keyframe events and holds the animation layers.
- **[Animation Blend Tree](animation_blend_tree.md)**: the combinations. Clip nodes such as `TransitionClip`, `SynchronizedTransitionClip` and `AdditiveBlendingClip` blend other clips into one pose, and layers apply several of those poses in order.

## Quick start

Drag an animated model into a scene in Evergine Studio: its root entity gets an `Animation3D` component. Then play a clip from a component on that entity:

```csharp
using Evergine.Components.Animation;
using Evergine.Framework;

public class PlayWalk : Component
{
    [BindComponent]
    private Animation3D animation3D = null;

    protected override void Start()
    {
        base.Start();

        // Clip names are the ones listed in the Model Editor.
        this.animation3D.PlayAnimation("walk", loop: true);
    }
}
```

## In this section
* [Animation Clip](animation_clip.md)
* [Animation3D Component](animation3d_component.md)
* [Animation Blend Tree](animation_blend_tree.md)
