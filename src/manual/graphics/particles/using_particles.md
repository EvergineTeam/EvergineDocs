# Using Particles

![Particles header](images/particles.jpg)

In this document, you will learn how to load and use **Particle Systems** in your applications.

## How to create particle systems from Evergine Studio

To instantiate a **Particle System** in a **Scene**, simply drag the particle system asset from the *Asset Details Panel* into your **Scene**.

![Dragging a Particle System](images/drag_particles.jpg)

This will create a new entity in the **Scene**.

![New Particle System](images/new_particles.jpg)

The newly created entity has a **Transform3D** component and two new components:

#### ParticlesComponent

This component loads the **Particle System** asset and manages its simulation and resources.

It has the following methods:

| Method | Description |
| --------- | --------- |
| **StartEmitting ()**  | Starts the particle system emission if it was stopped |
| **StopEmitting ()**  | Stops the particle system emission if it was already emitting |
| **Reset ()**  | Resets all particles to their initial state |

And the following properties:

| Property | Type | Description |
| --------- | --------- | --------------- |
| **ParticleSystem**  | _ParticleSystem_ | Selects the particle system asset for this entity.
| **Force CPU Particles** | _boolean_ | Forces the particle system to use CPU simulation, even if the platform supports GPU particles. _(false by default)_
| **Emit Automatically** | _boolean_ | When _true_, starts emitting particles when the scene is loaded. If _false_, it will be idle until it is manually started. _(true by default)_
| **Life Factor** | _float_ | Factor applied to the lifetime of the particles. A value of 2 will cause the particles' life to be reduced by half. _(1 by default)_
| **Time Factor** | _float_ | Time factor applied to the **whole particle simulation**. A value of 2 will cause particles to move at double speed, while 0.5 will slow down particles to half speed. _(1 by default)_

## Load Particle System from code

This scene loads a particle system asset and adds it to an entity:

```csharp
using Evergine.Framework;
using Evergine.Framework.Graphics;
using Evergine.Framework.Particles.Asset;
using Evergine.Framework.Particles.Components;

public class MyScene : Scene
{
    protected override void CreateScene()
    {
        ParticleSystem particlesAsset = this.Managers.AssetSceneManager.Load<ParticleSystem>(EvergineContent.Particles.MyParticleSystem);

        Entity particlesEntity = new Entity("particles")
            .AddComponent(new Transform3D())
            .AddComponent(new ParticlesComponent() { ParticleSystem = particlesAsset })
            .AddComponent(new ParticlesRenderer());

        this.Managers.EntityManager.Add(particlesEntity);
    }
}
```