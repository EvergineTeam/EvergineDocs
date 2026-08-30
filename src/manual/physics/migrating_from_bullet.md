# Migrating from Bullet

![Migrating](images/physics.png)

Evergine's physics has been rebuilt on **[Jolt Physics](https://github.com/jrouwe/JoltPhysics)**, replacing Bullet. Every component has a new name, several have been merged, and a few concepts work differently.

This page is the map from the old API to the new one.

## What changed and why

| | Before | Now |
| --- | --- | --- |
| Engine | Bullet, through the `Evergine.Bullet` package | Jolt, built into `Evergine.Framework` |
| Namespace | `Evergine.Framework.Physics3D` | `Evergine.Framework.Physics` |
| Suffix | `RigidBody3D`, `BoxCollider3D`, `HingeJoint3D` | `RigidBody`, `BoxCollider`, `HingeConstraint` |
| Backend | An abstract manager with a Bullet implementation | One concrete `PhysicsManager` |
| Package | `Evergine.Bullet` had to be installed | Nothing to install |

Three things come with the change: the solver is built to use several cores, it can be made deterministic, and it brings [soft bodies](soft_bodies/index.md), [tracked vehicles](vehicles/tracked_vehicles.md), [height fields](colliders/heightfield_collider.md) and [plane colliders](colliders/plane_collider.md), none of which existed before.

## The Manager

```csharp
// Before
this.Managers.AddManager<PhysicManager3D>(new Evergine.Bullet.BulletPhysicManager3D());

// Now
this.Managers.AddManager(new Evergine.Framework.Physics.PhysicsManager());
```

There is no abstract base and no backend to choose. `SceneManagers.PhysicManager3D` is gone too — bind to the manager instead:

```csharp
[BindSceneManager]
private PhysicsManager physicsManager = null;
```

## Bodies

| Bullet | Jolt | Notes |
| --- | --- | --- |
| `RigidBody3D` | `RigidBody` | `BodyType = Dynamic` or `Kinematic`. |
| `StaticBody3D` | `RigidBody` | `BodyType = Static`. The two components are now one. |
| `BulletGhostBody3D` | `RigidBody` | `IsSensor = true`. |
| `PhysicBodyType3D` | `RigidBodyType` | Now has three members, `Static` included. |

| Property | Bullet | Jolt |
| --- | --- | --- |
| Axis locking | `LinearFactor`, `AngularFactor` (0…1 per axis) | `AllowedDegreesOfFreedom` — a flags enum that locks an axis **exactly** rather than scaling it. |
| Per-body gravity | `OverrideGravity` + `Gravity` (a vector) | `GravityFactor` — a scalar multiplying the world's gravity. |
| Inertia | `LocalInertia` (a tensor) | `InertiaMultiplier` — a scalar scaling the inertia computed from the shape. |
| Rolling friction | `RollingFriction` | *Removed.* Use `AngularDamping` to stop things rolling for ever. |
| Mass | `Mass`, default 1 | `Mass`, default **0**, which means "work it out from the colliders' `Density`". |
| Friction | default 0.5 | default **0.2**. |
| Damping | default 0 | default **0.05** for both linear and angular. |
| Collision filtering | `CollisionCategory` + `MaskBit` per body | `CollisionCategory` per body, plus one [collision matrix](collision_filtering.md) on the world. |

### Methods

| Bullet | Jolt |
| --- | --- |
| `ApplyForce(force)` | `ApplyForce(force)` |
| `ApplyForceAtPosition(force, position)` | `ApplyForce(force, worldPosition)` |
| `ApplyImpulse(impulse)` | `ApplyImpulse(impulse)` |
| `ApplyImpulseAtPosition(impulse, position)` | `ApplyImpulse(impulse, worldPosition)` |
| `ApplyTorque(torque)` | `ApplyTorque(torque)` |
| `ApplyTorqueImpulse(impulse)` | `ApplyAngularImpulse(impulse)` |
| `ClearForces()` | *Removed.* Forces are cleared at the end of each step. |
| — | `MoveTo`, `Teleport`, `ApplyBuoyancy`, `GetPointVelocity`, `InvalidateShape` |

> [!IMPORTANT]
> Kinematic bodies now have a proper way to be moved: `MoveTo(position, orientation)`. It generates the velocity needed to get there this step, so the body pushes and carries as it should. Writing the `Transform3D` teleports it and drops whatever was standing on it.

## Colliders

| Bullet | Jolt | Notes |
| --- | --- | --- |
| `Collider3D` | `Collider` | |
| `BoxCollider3D` | [`BoxCollider`](colliders/box_collider.md) | |
| `SphereCollider3D` | [`SphereCollider`](colliders/sphere_collider.md) | |
| `CapsuleCollider3D` | [`CapsuleCollider`](colliders/capsule_collider.md) | |
| `CylinderCollider3D` | [`CylinderCollider`](colliders/cylinder_collider.md) | |
| `ConeCollider3D` | [`TaperedCylinderCollider`](colliders/tapered_cylinder_collider.md) | With `TopRadius = 0`. A cone is a tapered cylinder. |
| `MeshCollider3D` | [`MeshCollider`](colliders/mesh_collider.md) | `MeshType = TriangleMesh`. |
| `BulletConvexHullCollider3D` | [`MeshCollider`](colliders/mesh_collider.md) | `MeshType = ConvexHull`, which is the default. |
| `BulletCompoundCollider3D` | *Removed.* | A body builds a compound from every collider on its entity and its descendants, automatically. |
| — | [`TaperedCapsuleCollider`](colliders/tapered_capsule_collider.md) | New. |
| — | [`PlaneCollider`](colliders/plane_collider.md) | New. |
| — | [`HeightFieldCollider`](colliders/heightfield_collider.md) | New, and deformable at run time. |

| Property | Bullet | Jolt |
| --- | --- | --- |
| Collision margin | `Margin`, 0.04 | `ConvexRadius`, 0.05, on the shapes that have one. |
| Density | — | `Density`, 1000 kg/m³, which is what a body's mass is computed from. |

## Joints become Constraints

| Bullet | Jolt |
| --- | --- |
| `FixedJoint3D` | [`FixedConstraint`](constraints/fixed_constraint.md) |
| `PointToPointJoint3D` | [`PointConstraint`](constraints/point_constraint.md) |
| `HingeJoint3D` | [`HingeConstraint`](constraints/hinge_constraint.md) |
| `SliderJoint3D` | [`SliderConstraint`](constraints/slider_constraint.md) |
| `ConeTwistJoint3D` | [`SwingTwistConstraint`](constraints/swing_twist_constraint.md) |
| `GearJoint3D` | [`GearConstraint`](constraints/gear_constraint.md) |
| `Generic6DofJoint3D` | [`SixDOFConstraint`](constraints/six_dof_constraint.md) |
| `Generic6DofSpringJoint3D` | [`SixDOFConstraint`](constraints/six_dof_constraint.md) with `LimitsSpring` |
| `SpringJoint3D` | *No direct equivalent.* Springs are a property of a limit: `LimitsSpring` on a hinge, slider or distance constraint, or a six DOF constraint. |
| — | [`DistanceConstraint`](constraints/distance_constraint.md), [`ConeConstraint`](constraints/cone_constraint.md), [`RackAndPinionConstraint`](constraints/rack_and_pinion_constraint.md), [`PulleyConstraint`](constraints/pulley_constraint.md) — all new. |

The `IXxxJoint3D` interfaces and the `XxxJointDef3D` structs are gone: a constraint is a component and nothing else.

| Property | Bullet | Jolt |
| --- | --- | --- |
| Breaking | `BreakPoint` | `IsBreakable` + `BreakForce` + `BreakTorque`, plus a `Broken` event. |
| Auto anchor | `AutoConfigureConnected` | `AutoConfigureConnectedAnchor` |
| Motors | `UseMotor`, `MotorTargetVelocity`, `MotorTargetImpulse` | `MotorMode` (`Off`/`Velocity`/`Position`), `TargetAngularVelocity`/`TargetVelocity`, `TargetAngle`/`TargetPosition`, `MaxMotorTorque`/`MaxMotorForce`. |
| Soft limits | `LimitSoftness`, `LimitBiasFactor`, `LimitRelaxationFactor` | `LimitsSpring`, a `SpringParameters` in frequency-and-damping or stiffness-and-damping terms. |

## Character Controller

| Bullet | Jolt |
| --- | --- |
| `CharacterController3D` | [`CharacterController`](character_controller.md) |
| `StepHeight` | `StepHeight` |
| `MaxSlope` (45°) | `MaxSlopeAngle` (π/4, in **radians**) |
| `FallSpeed`, `Gravity` | `ApplyGravity`, plus the world's gravity |
| `JumpSpeed` | An argument to `Jump(speed)` |
| `SetVelocity(v)` | `LinearVelocity` |
| `Teleport(p)` | `Teleport(p)` |

Three real differences:

* It is built on Jolt's `CharacterVirtual` and is **not a rigid body**. Do not add a `RigidBody` or a `Collider` to the same entity.
* The entity's origin is at the character's **feet**, not the middle of its capsule.
* Write only the **horizontal** part of `LinearVelocity`. The component owns the vertical.

## Vehicles

| Bullet | Jolt |
| --- | --- |
| `PhysicVehicle3D` | [`WheeledVehicleController`](vehicles/wheeled_vehicles.md) |
| `PhysicWheel3D` | [`VehicleWheel`](vehicles/vehicle_wheel.md) |
| `ApplyEngineForce`, `SetSteeringValue`, `SetBrake` | One call: `SetDriverInput(forward, right, brake, handBrake)` |
| `SearchVehicle`, `PhysicVehicleEntityPath` | *Removed.* Wheels are child entities and are found by walking the hierarchy. |
| `SuspensionStiffness`, `SuspensionCompression` | `SuspensionSpring`, a `SpringParameters`. |
| `MaxSuspensionTravel`, `SuspensionRestLength` | `SuspensionMinLength`, `SuspensionMaxLength`. |
| `IsSteerableWheel` | `MaxSteerAngle` — zero means it does not steer. |
| `IsDriveWheel` | `FrontWheelDrive` / `RearWheelDrive` on the controller. |
| `IsBrakableWheel` | `MaxBrakeTorque` — zero means it does not brake. |
| — | [`TrackedVehicleController`](vehicles/tracked_vehicles.md), new. |

## Queries

| Bullet | Jolt |
| --- | --- |
| `RayCast(ref from, ref to, filterMask)` | `RayCast(origin, direction, maxDistance, in filter, out hit)` |
| `RayCastAll(...)` | `RayCastAll(origin, direction, maxDistance, results, in filter)` |
| `ConvexSweepTest(...)` | `ShapeCast`, `SphereCast`, `BoxCast` |
| `ConvexSweepTestAll(...)` | `ShapeCastAll(...)` |
| `PointTest(...)` | `OverlapPoint`, `OverlapPointAll` |
| `ContactTest(...)` | `OverlapSphere`, `OverlapBox`, `OverlapShape`, `OverlapAABox` |
| `ContactPairTest(...)` | `WereBodiesInContact(first, second)` |
| `HitResult3D` | `RayCastHit`, `ShapeCastHit`, `OverlapHit` |
| A category mask argument | A [`QueryFilter`](queries.md#query-filters) struct: categories, sensors, an ignored body and a predicate. |

Rays are now given an **origin, a direction and a distance** rather than two points, and hits carry both `Distance` and `Fraction`.

## Collisions

| Bullet | Jolt |
| --- | --- |
| `BeginCollision` | `CollisionStarted` |
| `UpdateCollision` | `CollisionUpdated` |
| `EndCollision` | `CollisionEnded` |
| `CollisionInfo3D` | `CollisionInfo` |
| `ContactPoint3D` | Folded into `CollisionInfo`: `Point`, `Normal`, `PenetrationDepth`, `PointCount`. |

Events are now raised **once per pair of bodies** rather than per pair of sub-shapes, and always on the main thread after the step.

## Manager Settings

| Bullet | Jolt |
| --- | --- |
| `PerformPhysicSteps` | `IsSimulationEnabled` |
| `MaxSubSteps` | `MaxStepsPerFrame` |
| `PhysicWorldResolution` | `CollisionSteps` |
| `FixedTimeStep` | `FixedTimeStep` |
| `ApplySpeculativeContactRestitution` | `SpeculativeContactDistance` |
| `DrawFlags` / `DebugDrawFlags` | [`DebugFlags`](debug_rendering.md), a `PhysicsDebugFlags` |
| `SetDebugDraw()` / `DebugDraw()` | *Removed.* One property does it. |
| `InternalWorld` | `NativePhysicsSystem`, `NativeBodyInterface` |
| `OnPhysicStep` | `PhysicsStepStarting`, `PhysicsStepCompleted`, `SimulationUpdated` |

## Migration Checklist

1. **Remove the `Evergine.Bullet` package reference.** Nothing replaces it; the new physics ships in `Evergine.Framework`.
2. **Change the manager registration** to `new Evergine.Framework.Physics.PhysicsManager()`.
3. **Change the using** from `Evergine.Framework.Physics3D` to `Evergine.Framework.Physics`.
4. **Rename the components** using the tables above. Existing `.wescene` files carry the old type names and will need re-authoring — the components are not the same types, so the converter cannot map them.
5. **Replace `StaticBody3D`** with `RigidBody` + `BodyType = Static`.
6. **Replace `LinearFactor`/`AngularFactor`** with `AllowedDegreesOfFreedom`, and `OverrideGravity` with `GravityFactor`.
7. **Move collision filtering** from per-body mask bits to the world's [collision matrix](collision_filtering.md).
8. **Rework the queries**: two points become an origin, a direction and a distance, and the mask argument becomes a `QueryFilter`.
9. **Check the defaults.** Friction is 0.2 rather than 0.5, damping is 0.05 rather than 0, and `Mass = 0` now means "compute from density" rather than "static".
10. **Turn on [debug rendering](debug_rendering.md)** and look at the scene. Shapes that were subtly wrong under the old margins and defaults are visible at a glance.
