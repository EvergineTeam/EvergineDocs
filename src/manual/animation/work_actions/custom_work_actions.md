# Custom Work Actions

The built-in work actions wait, call methods, check conditions and interpolate values. When a step of your sequence is something else, such as playing an animation clip to its end, waiting for a button or a network reply, or fading a sound, write it as a work action of your own, and it composes with `ContinueWith`, `WaitAll` and the rest like any other.

There are three ways to do it, from the least to the most code:

| Class | Use it when |
| --- | --- |
| **ActionWorkAction** | The step is one method call that finishes at once. `CreateWorkActionFromAction` and `ContinueWithAction` create one for you. |
| **BasicWorkAction** | The step starts something that finishes later and tells you through a callback or an event. No subclass needed. |
| **A subclass of WorkAction** | The step needs its own state, per-frame updates, or its own behavior when it is canceled or skipped. |

## BasicWorkAction

`BasicWorkAction` raises `OnRun` when it starts and completes when you call `NotifyActionCompleted()`. That turns any event into a step of a sequence:

```csharp
var waitForConfirm = new BasicWorkAction(this.Owner.Scene);

EventHandler onClicked = null;
onClicked = (sender, args) =>
{
    this.confirmButton.Clicked -= onClicked;
    waitForConfirm.NotifyActionCompleted();
};

waitForConfirm.OnRun += () => this.confirmButton.Clicked += onClicked;

IWorkAction step = scene.CreateWorkActionFromAction(() => this.ShowPanel())
    .ContinueWith(waitForConfirm)
    .ContinueWith(new ScaleTo3DWorkAction(this.panel, Vector3.Zero, TimeSpan.FromSeconds(0.3), EaseFunction.BackInEase));

step.Run();
```

`NotifyActionCompleted()` does nothing unless the action is running, so a late callback after a cancel is harmless. `BasicWorkAction` has no hook for a cancel, though: if you cancel it, unsubscribe from the event yourself.

## Derive from WorkAction

Derive from `WorkAction` and override the steps of its [lifecycle](composing_work_actions.md#lifecycle):

| Member | Description |
| --- | --- |
| **WorkAction(Scene scene = null)** | Constructor for an action created on its own. Pass the scene it belongs to, so it is [canceled with its scene](composing_work_actions.md#work-actions-and-scenes). |
| **WorkAction(IWorkAction parent)** | Constructor for an action that runs after another one. It takes the scene of the parent and starts in `Waiting`. |
| **PerformRun()** | Required. Called when the action starts. Start the work here, then call `PerformCompleted()` when it is done, now or later. |
| **PerformCompleted()** | Call it to finish. It sets the state to `Finished` and raises `Completed`, which starts the next step. It does nothing unless the action is running. |
| **PerformCancel()** | Called by `Cancel()`. Override it to stop the work, then call the base method, which sets the state to `Aborted` and raises `Canceled`. |
| **PerformSkip()** | Called by `TrySkip()`. Override it to jump to the end state of the work, then return the base method, which checks `IsSkippable`, sets the state to `Finished` and raises `Skipped` and `Completed`. |

### Per-frame updates

To do something every frame while the action runs, also implement `IUpdatableWorkAction`, from `Evergine.Framework.Services`. The `WorkActionScheduler` calls its `Update(TimeSpan gameTime)` once per frame, from the moment the action starts until it finishes or is canceled.

> [!NOTE]
> The animation work actions derive from `UpdatableWorkAction`, but that class is updated by the `WorkActionUpdaterBehavior`, whose registration methods are internal to the engine. A subclass of `UpdatableWorkAction` of your own is never updated. Implement `IUpdatableWorkAction` instead.

## Example: play an animation clip to its end

`Animation3D` has no event for the end of a clip. This work action plays a clip once and completes when its duration has elapsed, so a sequence can play a clip, wait for it and go on. Skipping it jumps to the last pose of the clip, and canceling it pauses the model where it is:

```csharp
using System;
using Evergine.Components.Animation;
using Evergine.Components.WorkActions;
using Evergine.Framework.Services;

public class PlayClipWorkAction : WorkAction, IUpdatableWorkAction
{
    private readonly Animation3D animation3D;
    private readonly string clipName;
    private readonly float playbackRate;
    private float remainingSeconds;

    public PlayClipWorkAction(Animation3D animation3D, string clipName, float playbackRate = 1)
        : base(animation3D.Owner.Scene)
    {
        this.animation3D = animation3D;
        this.clipName = clipName;
        this.playbackRate = playbackRate;
    }

    protected override void PerformRun()
    {
        this.remainingSeconds = (float)this.animation3D.GetDuration(this.clipName) / this.playbackRate;
        this.animation3D.PlayAnimation(this.clipName, loop: false, playbackRate: this.playbackRate);
    }

    public void Update(TimeSpan gameTime)
    {
        this.remainingSeconds -= (float)gameTime.TotalSeconds;
        if (this.remainingSeconds <= 0)
        {
            this.PerformCompleted();
        }
    }

    protected override void PerformCancel()
    {
        this.animation3D.StopAnimation();
        base.PerformCancel();
    }

    protected override bool PerformSkip()
    {
        if (!this.IsSkippable)
        {
            return false;
        }

        this.animation3D.PlayTime = (float)this.animation3D.GetDuration(this.clipName);
        return base.PerformSkip();
    }
}
```

An extension method makes it read like the built-in steps:

```csharp
public static class PlayClipWorkActionExtensions
{
    public static IWorkAction ContinueWithClip(this IWorkAction parent, Animation3D animation3D, string clipName, float playbackRate = 1)
    {
        return parent.ContinueWith(new PlayClipWorkAction(animation3D, clipName, playbackRate));
    }
}
```

```csharp
// Move to the door, play the clip that opens it, and go through.
IWorkAction enter = new MoveTo3DWorkAction(character, doorPosition, TimeSpan.FromSeconds(2))
    .ContinueWithClip(animation3D, "open_door")
    .ContinueWith(new MoveTo3DWorkAction(character, insidePosition, TimeSpan.FromSeconds(1.5)));

enter.Run();
```
