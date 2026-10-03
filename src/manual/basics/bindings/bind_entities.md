# Bind Entities

---

The **[BindEntity]** attribute gives a component a reference to an [entity](../component_arch/entities/index.md), found by its `Tag`. Use it when a component needs a whole entity rather than one of its components: the player to follow, the spawn points of a level, the pickups under a group.

```csharp
// The first entity in the scene tagged "Player".
[BindEntity(tag: "Player")]
private Entity player;

// Every entity in the scene tagged "Item".
[BindEntity(tag: "Item")]
private List<Entity> items;
```

> [!NOTE]
> `[BindEntity]` only works inside components, because the search starts from the owner entity of the component.

## Parameters

| Parameter | Default | Description |
| --- | --- | --- |
| `tag` | `null` | The tag of the entities to find. Always set it: entities are matched by tag, and the default `Scene` source fails without one. |
| `source` | `BindEntitySource.Scene` | Where to search. See [source](#source). |
| `isRequired` | `true` | When `true`, the component does not attach unless an entity is found. When `false`, the member is left `null` if nothing matches. |
| `isRecursive` | `true` | For the `Children` and `Parents` sources, `true` searches all descendants or ancestors, and `false` only the direct children or the direct parent. |

### source

| Source | Searches |
| --- | --- |
| `Scene` (default) | Every entity of the scene. |
| `Owner` | The owner entity only: the binding matches when the owner itself has the tag. |
| `Children` | The owner entity and its descendants. |
| `ChildrenSkipOwner` | The descendants of the owner entity, **without** the owner. |
| `Parents` | The owner entity and its ancestors. |
| `ParentsSkipOwner` | The ancestors of the owner entity, **without** the owner. |

The `Children` sources search level by level, and the `Parents` sources from the nearest ancestor up. A single member gets the first match.

### isRequired

Works as in [Bind Components](bind_components.md#isrequired): a missing required entity keeps the component from attaching.

## Example

This behavior makes its entity look at the player, and collects the waypoints placed as its own children:

```csharp
using System;
using System.Collections.Generic;
using Evergine.Framework;
using Evergine.Framework.Graphics;

namespace MyProject
{
    public class Sentry : Behavior
    {
        [BindComponent]
        private Transform3D transform;

        // Anywhere in the scene.
        [BindEntity(tag: "Player")]
        private Entity player;

        // Only below this entity, so each sentry gets its own patrol route.
        [BindEntity(tag: "Waypoint", source: BindEntitySource.ChildrenSkipOwner)]
        private List<Entity> waypoints;

        private Transform3D playerTransform;

        protected override void Start()
        {
            base.Start();
            this.playerTransform = this.player.FindComponent<Transform3D>();
        }

        protected override void Update(TimeSpan gameTime)
        {
            this.transform.LookAt(this.playerTransform.Position);
        }
    }
}
```

> [!TIP]
> A list binding is filled once, when the component attaches. To follow entities that are added or retagged later, use an [entity tag collection](../component_arch/entities/entity_manager.md#entity-tag-collections).
