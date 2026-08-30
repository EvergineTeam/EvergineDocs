# Physics
---

![Physics](images/physics.png)

Evergine provides **real-time physics simulation**: rigid bodies that fall, collide and rest, constraints that hold them together, characters that walk up steps, vehicles that drive, and soft bodies that deform. This section explains how the simulation is put together, how to add it to a scene, and how to drive it from your own components.

## Built-in Physics Engine

Evergine is built on **[Jolt Physics](https://github.com/jrouwe/JoltPhysics)**, a multicore-friendly rigid body engine written for games. Its [architecture documentation](https://jrouwe.github.io/JoltPhysics/) is the reference for how the solver itself behaves; everything in this section describes the Evergine components that sit on top of it.

Everything lives in the `Evergine.Framework.Physics` namespace and ships with `Evergine.Framework`, so there is no extra package to install.

## Key concepts

| Concept | What it is |
| --- | --- |
| **Physics world** | One [`PhysicsManager`](physics_manager.md) per scene. It owns gravity, the fixed time step, the collision matrix and every query. |
| **Body** | A [`RigidBody`](physics_bodies/rigid_body.md) turns an entity into something the simulation moves. Static, kinematic and dynamic bodies are all the same component with a different `BodyType`. |
| **Collider** | A [`Collider`](colliders/index.md) gives a body its shape. A body collects the colliders on its own entity *and on its descendants*, so a compound shape is just a hierarchy. |
| **Constraint** | A [`Constraint`](constraints/index.md) ties two bodies together: a hinge, a slider, a rope, a gear train. |
| **Category** | Every body belongs to one of 32 [collision categories](collision_filtering.md), and a matrix on the world says which pairs of categories touch. |
| **Query** | A [ray cast, shape cast or overlap test](queries.md) asks the world what is there without moving anything. |

> [!NOTE]
> Coming from the previous Bullet-based API? Every component has been renamed and several have been merged. See [Migrating from Bullet](migrating_from_bullet.md) for the full table of equivalences.

## In this section
* [Physics Manager](physics_manager.md)
* [Physics Bodies](physics_bodies/index.md)
* [Colliders](colliders/index.md)
* [Collision Filtering](collision_filtering.md)
* [Queries](queries.md)
* [Constraints](constraints/index.md)
* [Ragdolls](ragdolls.md)
* [Character Controller](character_controller.md)
* [Vehicles](vehicles/index.md)
* [Buoyancy and Water](buoyancy.md)
* [Soft Bodies](soft_bodies/index.md)
* [Debug Rendering](debug_rendering.md)
* [Migrating from Bullet](migrating_from_bullet.md)
