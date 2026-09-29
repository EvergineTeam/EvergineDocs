# EntityManager

---

The **EntityManager** is the [scene manager](../../scenes/scenemanagers.md) that owns the entities of a scene. Adding an entity to it is what puts the entity in the scene: from that moment its components are attached, activated and started, and removing it runs the same steps in reverse. It is also where you look entities up, by path, by id or by tag.

Every scene has one, available as `this.Managers.EntityManager` inside components, scene managers and scene classes.

## Add and Remove Entities

```csharp
EntityManager entityManager = this.Managers.EntityManager;

// Add an entity, and all its children, to the scene.
entityManager.Add(entity);

// Add several entities at once. They are all in the scene before any of them is attached,
// so scene-wide bindings between them resolve regardless of the order of the list.
entityManager.Add(new[] { player, enemy, pickup });

// Take an entity out of the scene and destroy it, with its children and components.
entityManager.Remove(entity);

// Take an entity out of the scene but keep it, so it can be added again later.
entityManager.Detach(entity);
```

Only root entities are passed to `Add()`. To put an entity under another one, use `AddChild()` on the parent (see [Entity Hierarchy](entity_hierarchy.md)). `Remove()` and `Detach()` accept child entities too, and take them out of their parent.

> [!NOTE]
> `Add()` throws an `InvalidOperationException` when the entity has been destroyed, already has a parent, or has the same `Id` as an entity already in the scene.

## Properties and Events

| Member | Description |
| --- | --- |
| **EntityGraph** | The entities at the top of the hierarchy, the ones added with `Add()`. |
| **AllEntities** | Every entity in the scene, including all descendants. |
| **Count** | The number of entities at the top of the hierarchy. |
| **Contains(Entity)** | `true` if the entity was added to this manager. |
| **EntityAdded** | Event raised when an entity, root or child, enters the scene. |
| **EntityDetached** | Event raised when an entity leaves the scene. It is raised for removed entities too, because removing an entity detaches it first. |

## Find Entities

### By Path

The most common way to find an entity is by its [entity path](entity_hierarchy.md#entity-paths), the names from the root down to it separated by `.`:

```csharp
Entity tire = entityManager.Find("Car.Wheel1.Tire1");
```

A path without separators finds a root entity by name.

### By Id

Every entity has a unique `Id`, which is stable across saves of the scene:

```csharp
Guid id = entity.Id;
Entity sameEntity = entityManager.Find(id);
```

### By Tag

The `Tag` property groups entities. `FindAllByTag()` returns every entity with a given tag, at any depth of the hierarchy:

```csharp
IEnumerable<Entity> enemies = entityManager.FindAllByTag("Enemy");
```

All the `Find` methods return `null` (or an empty collection) when nothing matches.

## Find Components

| Method | Description |
| --- | --- |
| `FindComponentFromEntityPath<T>(string path)` | The component of type `T` on the entity at that path. |
| `FindComponentsFromEntityPath<T>(string path)` | Every component of type `T` on the entity at that path. |
| `FindFirstComponentOfType<T>(bool isExactType = true, string tag = null)` | The first component of type `T` in the whole scene, optionally only on entities with a tag. |
| `FindComponentsOfType<T>(bool isExactType = true, string tag = null)` | Every component of type `T` in the whole scene. |

> [!IMPORTANT]
> `FindFirstComponentOfType` and `FindComponentsOfType` walk the entire scene. Call them once, in `OnAttached()` or `Start()`, and keep the result, or use a [`[BindComponent(source: BindComponentSource.Scene)]`](../../bindings/bind_components.md) binding. Do not call them from `Update()`.

## Entity Tag Collections

`FindAllByTag()` returns the entities that have the tag **now**. When you need to follow a group of entities over time, such as the enemies that are still alive, ask for an `EntityManager.EntityTagCollection` instead. It is a live collection: entities join it when they are added to the scene with that tag or get the tag later, and leave it when they are removed or their tag changes.

```csharp
using System;
using System.Diagnostics;
using System.Linq;
using Evergine.Framework;
using Evergine.Framework.Managers;

namespace MyProject
{
    public class EnemyCounter : Component
    {
        private EntityManager.EntityTagCollection enemies;

        public int Remaining => this.enemies.Entities.Count();

        protected override void OnActivated()
        {
            base.OnActivated();

            this.enemies = this.Managers.EntityManager.GetEntityTagCollection("Enemy");
            this.enemies.OnEntityAdded += this.OnEnemyAdded;
            this.enemies.OnEntityRemoved += this.OnEnemyRemoved;
        }

        protected override void OnDeactivated()
        {
            base.OnDeactivated();

            // The collection belongs to the EntityManager and outlives this component.
            this.enemies.OnEntityAdded -= this.OnEnemyAdded;
            this.enemies.OnEntityRemoved -= this.OnEnemyRemoved;
        }

        private void OnEnemyAdded(object sender, Entity enemy)
        {
            Trace.WriteLine($"Enemy spawned: {enemy.EntityPath}");
        }

        private void OnEnemyRemoved(object sender, Entity enemy)
        {
            if (this.Remaining == 0)
            {
                Trace.WriteLine("Wave cleared");
            }
        }
    }
}
```

| Member | Description |
| --- | --- |
| **Tag** | The tag of the collection. |
| **Entities** | The entities that currently have the tag. |
| **OnEntityAdded** | Raised when an entity with the tag enters the scene, or an entity in the scene gets the tag. |
| **OnEntityRemoved** | Raised when an entity leaves the collection, because it was removed from the scene or its tag changed. |

`GetEntityTagCollection()` always returns the same collection for the same tag, so several components can share it.
