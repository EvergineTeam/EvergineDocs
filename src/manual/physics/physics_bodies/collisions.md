# Collisions

![Collisions](../images/physics.png)

Every [`RigidBody`](rigid_body.md) reports what it touches. The three collision events are how gameplay hangs off the simulation: a shot registers a hit, a trigger opens a door, a car scrapes a wall and plays a sound.

## Collision Events

| Event | When it fires |
| --- | --- |
| **CollisionStarted** | The first step in which the two bodies are touching. |
| **CollisionUpdated** | Once per step for as long as they stay touching. |
| **CollisionEnded** | The step in which they stop touching. Its `CollisionInfo` carries no point, normal or depth — there is no longer a contact to describe. |

Two things are worth knowing about how they are delivered:

* They are raised **on the main thread**, after the step has finished. The solver produces contacts on its worker threads and they are buffered until it is safe to hand them out, so it is fine to create entities, load assets or touch the scene from a handler.
* They are raised **once per pair of bodies**, not once per pair of overlapping sub-shapes. A compound body of eight boxes landing flat on the floor reports one collision, not eight.

## CollisionInfo

| Property | Description |
| --- | --- |
| **OtherBody** | The body on the other side of the contact. |
| **OtherEntity** | Its entity, which is usually what gameplay code wants. |
| **ThisCollider** | Which of this body's colliders took part, when it can be resolved. |
| **OtherCollider** | The same for the other body. |
| **Point** | A contact point, in world space. |
| **Normal** | The contact normal, pointing away from the body raising the event. |
| **PenetrationDepth** | How far the two shapes overlap, in metres. |
| **PointCount** | How many points the contact manifold has. |

`CollisionInfo` is a readonly struct, so it can be kept as it arrives: nothing else will mutate the instance you were handed.

## Using Collision Events

```csharp
public class Breakable : Behavior
{
    [BindComponent]
    private RigidBody body = null;

    public float ImpactThreshold { get; set; } = 6f;

    protected override void OnActivated()
    {
        base.OnActivated();

        this.body.CollisionStarted += this.OnCollisionStarted;
    }

    protected override void OnDeactivated()
    {
        base.OnDeactivated();

        // Always unsubscribed. The body outlives the handler only if the handler forgets to let go,
        // and a scene reloaded a few times then reports the same collision to a dozen dead listeners.
        this.body.CollisionStarted -= this.OnCollisionStarted;
    }

    private void OnCollisionStarted(object sender, CollisionInfo info)
    {
        // How hard the hit was, rather than that there was one at all: everything resting on the floor
        // raises this event once, and a crate that shatters when it is set down is not a crate.
        float speed = (this.body.LinearVelocity - info.OtherBody.LinearVelocity).Length();

        if (speed < this.ImpactThreshold)
        {
            return;
        }

        this.Spawn(info.Point, info.Normal);
        this.Managers.EntityManager.Remove(this.Owner);
    }
}
```

## Contact Validation

The [collision matrix](../collision_filtering.md) decides which pairs of categories touch at all. For rules it cannot express — a platform you can jump up through but not fall down through, an enemy that ignores its own projectiles — the world offers a callback consulted for every pair before a contact is made:

```csharp
// A platform solid only from above: a contact is allowed when the other body is moving downwards.
this.physicsManager.ContactValidator = (first, second) =>
{
    RigidBody platform = first.Owner.Tag == "oneway" ? first : second;
    RigidBody other = ReferenceEquals(platform, first) ? second : first;

    if (platform.Owner.Tag != "oneway")
    {
        return true;
    }

    return other.LinearVelocity.Y <= 0f;
};
```

> [!IMPORTANT]
> `ContactValidator` runs on the solver's worker threads, for every candidate pair, every step. It must be cheap, must not allocate, and must not touch the scene. Anything more involved belongs in a collision event handler, which runs on the main thread afterwards.
