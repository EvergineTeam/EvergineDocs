# Messaging

---

XRV includes a publisher-subscriber service, `PubSub`, that lets parts of your application talk to each other without holding references to one another. Components, services, and modules can publish messages of any type, and any code that subscribed to that type receives them. XRV itself uses it, for example to notify [hand menu](hand_menu.md) button presses and [culture changes](localization.md).

Access the service through `XrvService.Services.Messaging`.

| `PubSub` method | Description |
| --- | --- |
| `Publish<TMessage>(TMessage message)` | Sends a message to every subscriber of `TMessage`. |
| `Subscribe<TMessage>(Action<TMessage> action)` | Registers a callback for messages of type `TMessage` and returns a `Guid` subscription token. |
| `Unsubscribe(Guid token)` | Removes the subscription that matches the token. |

## Publish a message

Any type can be a message, but a dedicated class per message makes the intent clear and carries the data the subscribers need.

```csharp
public class ModelLoadedMessage
{
    public ModelLoadedMessage(string modelName, int triangleCount)
    {
        this.ModelName = modelName;
        this.TriangleCount = triangleCount;
    }

    public string ModelName { get; private set; }

    public int TriangleCount { get; private set; }
}
```

```csharp
// xrvService is an XrvService field bound with [BindService], as in the next example.
var pubSub = this.xrvService.Services.Messaging;
pubSub.Publish(new ModelLoadedMessage("Engine", 125000));
```

## Subscribe to a message

`Subscribe` returns a token. Keep it, and pass it to `Unsubscribe` when you no longer want messages. In a component, subscribe in `OnAttached` or `OnActivated`, and unsubscribe in the matching `OnDetached` or `OnDeactivated`.

```csharp
using System;
using Evergine.Framework;
using Evergine.Xrv.Core;
using Evergine.Xrv.Core.Services.Messaging;

public class ModelStats : Component
{
    [BindService]
    private XrvService xrvService = null;

    private Guid subscription;

    private PubSub PubSub => this.xrvService.Services.Messaging;

    protected override bool OnAttached()
    {
        bool attached = base.OnAttached();
        if (attached)
        {
            this.subscription = this.PubSub.Subscribe<ModelLoadedMessage>(this.OnModelLoaded);
        }

        return attached;
    }

    protected override void OnDetached()
    {
        base.OnDetached();

        // Without this, the service keeps a reference to the component after it is removed.
        this.PubSub.Unsubscribe(this.subscription);
    }

    private void OnModelLoaded(ModelLoadedMessage message)
    {
        // React to the message, for example by updating a 3D text.
    }
}
```

> [!NOTE]
> Subscriptions match the exact message type: subscribing to a base class does not receive messages of derived classes.
>
> `Publish` calls the subscribers synchronously, on the thread that publishes the message. If you publish from a background task, move any work that touches entities to the main thread.
