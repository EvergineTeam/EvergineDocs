# Component-Based Architecture
---
![Component Based Architecture](images/component_based_arch.jpg)

Evergine is based on entity-oriented programming. An [**Entity**](entities/index.md) is built of Components, where each component performs a specific piece of work and is reusable across other entities.

## Overview
When creating applications in Evergine, you need to create objects to represent the entities in your scene, such as a car, a player, or sunlight.

### Traditional Deep Class Hierarchies
When you first get started, you might think the most logical approach is to create a base class called `AppObject` or something similar that contains the common code. Then you can create subclasses like `Vehicle` with all common functionalities shared between all vehicles, and maybe subclasses for specific types (`Car`, `Motorbike`, `Train`, etc.).

For simple scenarios, this works quite well and is fairly easy to program. However, as your application grows larger and more complex, this architecture begins to cause some issues in practice:
* Root classes tend to be heavier and it is difficult to split the functionality into separate subsystems.
* Class inheritance may introduce odd scenarios. For instance, if we have created `GroundVehicle` and `WaterVehicle` base classes, which class should an `AmphibianVehicle` be derived from? If it is derived from `GroundVehicle`, all water functionalities would be missing, and the same issue arises if it is derived from `WaterVehicle`.

![Class Inheritance Issue](images/class_inheritance_issue.png)

### Entities as an Aggregation of Components

To solve these issues, we have chosen the **aggregation of components** approach. In this approach, the functionality is separated into individual components that are mostly independent of one another. The old object hierarchy is replaced by an object (`Entity`) with a collection of independent components (derived from `Component`).

Each object now only has the functionality that it needs. Any distinct new functionality is implemented by adding a new component.

## Entity-Component Relationship

**Entities** are the fundamental objects in Evergine that represent characters, lights, models, and so on. An Entity without any Component has no functionality (nothing will be rendered or interacted with).

To give an Entity the properties it needs to become a Light, a Model, or a Camera, you need to add **Components** to it, depending on the type of object you wish to create.

### SceneManagers and Components

In Evergine, a **Scene** has several subsystems (called **SceneManagers**). Every SceneManager controls different aspects of the scene (for example: `RenderManager` to render and draw the scene, `BehaviorManager` to update all Behaviors, `PhysicsManager` to perform Physics simulations, and so on).

With the Component architecture, every component is responsible for registering itself into the associated SceneManager, allowing these SceneManagers to have the scope of Components in which they are interested and ignore the rest.

> [!NOTE]
> For instance: Every physics-related component (RigidBody, BoxCollider, etc.) is internally registered into the PhysicsManager when an Entity is spawned into the scene. This allows PhysicsManager to gather and control all the physics information in the scene.

### Summary Diagram

A **Scene** is composed of several [**Entities**](entities/index.md). Each one has a collection of Components that give it the required functionality or data. Every component may be registered into the different **SceneManagers** of the Scene.

The following diagram provides an overview of this:

![Component Based Architecture](images/component_arch.png)

## In This Section
* [Entities](entities/index.md)
* [Components](components/index.md)
* [Prefabs](prefabs/index.md)