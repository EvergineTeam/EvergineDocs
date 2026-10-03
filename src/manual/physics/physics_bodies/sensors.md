# Sensors

<video autoplay loop muted playsinline width="100%" height="auto">
  <source src="images/sensors_overlap.mp4" type="video/mp4">
</video>

A **sensor** is a body that notices what passes through it without pushing back. Trigger volumes, checkpoints, pickup radii and damage zones are all sensors.

There is no separate component for it. A sensor is a [`StaticBody`](static_body.md) or a [`RigidBody`](rigid_body.md) with one property set, which both inherit from `PhysicsBody`:

| Property | Default | Description |
| --- | --- | --- |
| **IsSensor** | false | The body detects overlaps and raises its collision events, but produces no contact response. Other bodies pass straight through. |

## Creating a Sensor

```csharp
Entity checkpoint = new Entity("checkpoint")
    .AddComponent(new Transform3D() { Position = new Vector3(0f, 1.5f, 0f) })
    .AddComponent(new StaticBody() { IsSensor = true })
    .AddComponent(new BoxCollider() { Size = new Vector3(4f, 3f, 1f) });

this.Managers.EntityManager.Add(checkpoint);
```

A sensor that stays put is a `StaticBody`; one that moves, following a hand or a cursor, is a kinematic `RigidBody`. Either way it is usually invisible: it needs no mesh at all. Turn on [debug rendering](../debug_rendering.md) while placing one, or give it a translucent material as the picture above does.

## Detecting Bodies

Sensors raise the ordinary [collision events](collisions.md), so a trigger zone is a pair of handlers:

```csharp
public class TriggerZone : Behavior
{
    // PhysicsBody rather than StaticBody, so the same zone works whether or not it moves.
    [BindComponent(isExactType: false)]
    private PhysicsBody body = null;

    private int inside;

    protected override void OnActivated()
    {
        base.OnActivated();

        this.body.CollisionStarted += this.OnEnter;
        this.body.CollisionEnded += this.OnExit;
    }

    protected override void OnDeactivated()
    {
        base.OnDeactivated();

        this.body.CollisionStarted -= this.OnEnter;
        this.body.CollisionEnded -= this.OnExit;
    }

    private void OnEnter(object sender, CollisionInfo info)
    {
        // Counted rather than treated as a switch: several bodies can be inside a zone at once, and a
        // door that closes when the first of three players leaves is a door with a bug in it.
        if (++this.inside == 1)
        {
            this.Open();
        }
    }

    private void OnExit(object sender, CollisionInfo info)
    {
        if (--this.inside == 0)
        {
            this.Close();
        }
    }
}
```

> [!NOTE]
> `CollisionEnded` carries no contact point or normal. By the time it fires there is no contact left to describe, so only `OtherBody` and `OtherEntity` are meaningful.

## Sensors and Other Body Types

A **static** sensor notices dynamic bodies, which covers most uses. It never notices other static bodies, because Jolt never pairs two static bodies, so a sensor that has to be swept across the level is a **kinematic** `RigidBody`. That one needs one more property to notice static and kinematic bodies as well:

| Property | Default | Description |
| --- | --- | --- |
| **CollideKinematicVsNonDynamic** | false | Lets a kinematic body report contacts against static and other kinematic bodies. Without it, a kinematic sensor only ever sees dynamic ones. |

> [!NOTE]
> This is the case the [migration tool](../migrating_from_bullet.md#migration-tool) flags most often: a Bullet ghost body that followed the cursor, a controller or a hand was static, and worked because Bullet paired static ghosts with everything. Under Jolt it has to be kinematic, with the property above set.

## Sensors and Queries

[Queries](../queries.md) skip sensors by default, which is nearly always right: a ray fired at the world should not stop at an invisible trigger volume. To include them, say so in the filter:

```csharp
QueryFilter filter = QueryFilter.Default;
filter.IncludeSensors = true;

if (this.physicsManager.RayCast(origin, direction, 50f, filter, out RayCastHit hit))
{
    // Trigger volumes are candidates for this hit too.
}
```
