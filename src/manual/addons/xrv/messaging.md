# Messaging

_XRV_ provides a straightforward implementation of the publisher-subscriber pattern, allowing different parts of your application to communicate via messages. This system can be used in components, services, or any other elements as needed. You can emit any type of message; however, it's recommended to create specific message types that contain any relevant information.

To send a message, create a custom message class and use the _Publish_ method.

```csharp
public class MyMessage 
{
    public MyMessage(string data1, int data2) 
    {
        this.Data1 = data1;
        this.Data2 = data2;
    }

    public string Data1 { get; private set; }

    public int Data2 { get; private set; }
}

var pubSub = this.xrvService.Services.Messaging;
var message = new MyMessage("my-data", 1234);
pubSub.Publish(message);
```
\
To receive messages of a specific type, use the _Subscribe_ method. It returns a subscription token, which you should save to enable unsubscribing when necessary. For example, if you want to use it in a _Component_, the standard approach is to subscribe in _OnAttach/OnActivated_ and unsubscribe in _OnDetach/OnDeactivated_.

```csharp
public class MyComponent : Component 
{
    [BindService]
    private XrvService xrvService = null;

    private PubSub pubSub => this.xrvService.Services.Messaging;
    private Guid subscription;

    protected override bool OnAttached()
    {
        bool attached = base.OnAttached();
        if (attached)
        {
            this.subscription = this.pubSub.Subscribe<MyMessage>(this.OnMyMessageReceived);
        }

        return attached;
    }

    protected override void OnDetach()
    {
        base.OnDetach();
        this.pubSub.Unsubscribe(this.subscription);
    }

    private void OnMyMessageReceived(MyMessage message) 
    {
        // Do something
    }
}
```