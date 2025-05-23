# Networking

With the networking extension, you will be able to establish a client-server communication channel across any processes running Evergine. These processes could run on the same computer or on different devices connected to a local network.

This extension relies on [a fork of the Lidgren.Network](https://github.com/EvergineTeam/lidgren-network-gen3) library, which handles in-process communication using sockets with _server-client_ and _client-client_ message delivery.

## Install Evergine.Networking Extension

To start using this extension, just add the Evergine.Networking package to your project using the NuGet package manager from Visual Studio.

```xml
<PackageReference Include="Evergine.Networking" Version="2021.11.17.2-preview" />
```

## Server Configuration

To create a networking server, you should use the built-in service named _MatchmakingServerService_. This service is part of the extension and manages server rooms, and players, and provides different events that notify you when a player (client) connects or disconnects from the server, joins or leaves a room, etc. For a complete list of events, see the [_MatchmakingServerService_ API documentation](xref:Evergine.Networking.Server.MatchmakingServerService).

Register _MatchmakingServerService_ in Evergine's dependencies container to start using it.

```csharp
this.Container.RegisterInstance(new MatchmakingServerService());
```

_MatchmakingServerService_ has a set of properties that you should use to configure your server settings. Some considerations include:
- It's recommended not to use large values for _PingInterval_ and _ConnectionTimeout_. Also, _ConnectionTimeout_ should be a multiple of _PingInterval_. Values of 4 and 8 seconds, respectively, would be suitable, depending on your requirements.
- Set a value for _ApplicationIdentifier_ that you can easily identify, such as your application name.
- Set a version value for _ClientApplicationVersion_.

```csharp
this.matchmakingServerService.PingInterval = 4;
this.matchmakingServerService.ConnectionTimeout = 8;
this.matchmakingServerService.ApplicationIdentifier = "MyApp";
this.matchmakingServerService.ClientApplicationVersion = "1.0.0";
this.matchmakingServerService.ServerName = "MyServer";
```

> [!Note]
> An exception for setting larger values for _ConnectionTimeout_ would be debugging. When a breakpoint is hit, time will still be running, and you might find clients getting disconnected. To avoid problems while developing, you can set _ConnectionTimeout_ to a temporary value of TimeSpan.FromHours(1), for example, to have enough time while debugging.

### Start a Server

Once you have your server configured, it's time to start it to enable it to receive incoming client connections.

```csharp
int port = 12345;
await this.matchmakingServerService.StartAsync(port);
```

We recommend creating a custom [Service](xref:Evergine.Framework.Services.Service) or component to contain all server initialization code and to use _MatchmakingServerService_ to log events, which is very useful for debugging purposes.

```csharp
this.matchmakingServerService.PlayerConnected += this.MatchmakingServerService_PlayerConnected;
this.matchmakingServerService.PlayerDisconnected += this.MatchmakingServerService_PlayerDisconnected;
this.matchmakingServerService.PlayerJoining += this.MatchmakingServerService_PlayerJoining;
this.matchmakingServerService.PlayerJoined += this.MatchmakingServerService_PlayerJoined;
this.matchmakingServerService.PlayerLeaving += this.MatchmakingServerService_PlayerLeaving;
this.matchmakingServerService.PlayerLeft += this.MatchmakingServerService_PlayerLeft;
this.matchmakingServerService.RoomCreated += this.MatchmakingServerService_RoomCreated;
this.matchmakingServerService.RoomDestroyed += this.MatchmakingServerService_RoomDestroyed;

// ...

private async void MatchmakingServerService_PlayerJoined(object sender, ServerPlayer e)
{
    var numberOfClients = this.matchmakingServerService.AllConnectedPlayers.Count();
    Debug.WriteLine($"A client just joined: {e.Nickname}. There are {numberOfClients} clients.");
}
```

## Client Configuration

For clients, the built-in service is _MatchmakingClientService_. As we did for the server side, you should register this service in the dependencies container. For client settings, ensure that you apply the same values that were provided for the server side.

```csharp
this.Container.RegisterInstance(new MatchmakingClientService());

// ...

this.matchmakingClientService.PingInterval = 4;
this.matchmakingClientService.ConnectionTimeout = 8;
this.matchmakingClientService.ApplicationIdentifier = "MyApp";
this.matchmakingClientService.ClientApplicationVersion = "1.0.0";
```

> [!Note]
> When creating a server, you might also want to register your own process as a client of that server. This means using _MatchmakingClientService_ to connect to the server you have created, as in a common scenario where one of the clients also acts as the server.

### Server Discovery

The networking extension provides a way of automatic discovery of servers, given that the local network infrastructure allows broadcast traffic. To discover a server, use the following line, using the same port you configured for your server. Once a server is discovered, the _ServerDiscovered_ event will be raised.

```csharp
this.matchmakingClientService.ServerDiscovered += this.MatchmakingClientService_ServerDiscovered;

// ...
int port = 12345;
this.matchmakingClientService.DiscoverServers(port);

// ...
private async void MatchmakingClientService_ServerDiscovered(object sender, HostDiscoveredEventArgs e)
{
    var connected = await this.matchmakingClientService.ConnectAsync(e.Host);
    Debug.WriteLine($"Connected to server {e.ServerName}.");
}
```

> [!Note]
> You must ensure your server can be reached by clients in the network. Some platforms, like _UWP_, require extra configuration at the application level for security reasons. On this platform, review [capabilities](https://docs.microsoft.com/en-us/windows/uwp/packaging/app-capability-declarations) and, depending on your scenario, even the [application isolation](https://docs.microsoft.com/en-us/windows/uwp/communication/interprocess-communication).

## Joining a Server Room

After connecting to a server, the next step is joining a room. Clients in the same room can share information to update their states, depending on your application requirements.

```csharp
var roomOptions = new RoomOptions
{
    RoomName = "MyRoom",
};
var joinResult = await this.matchmakingClientService.JoinOrCreateRoomAsync(roomOptions);
```

Once you have joined a room, _MatchmakingClientService_ will update its _CurrentRoom_ property with room information, including the list of connected clients (players). You can use this information, for example, to display the list of room participants in your client application.

## Message Delivery

With an existing client-server connection, you can now send information in both directions, or even to other client applications within the network. There are two mechanisms to do this. With the first one, _messages_, you can create a network message by yourself, writing scalar fields in a buffer. The second one is _network properties_, which are very useful as their values are automatically synchronized for all connected clients.

### Messages

Both _MatchmakingServerService_ and _MatchmakingClientService_ provide methods to send messages to different peers in the network.

For _MatchmakingServerService_, you have:
- _SendToClient_: sends a message to a destination client.

For _MatchmakingClientService_, you have:
- _SendToCurrentRoom_: sends a message to all clients connected to the room.
- _SendToPlayer_: sends a message to a single player in the room.
- _SendToServer_: sends a message from a client to the server.

For example, we can send a _"hello"_ message from one client to another with something like the following:

```csharp
// Client A sends hello message
var message = this.matchmakingClientService.CreateMessage();
message.Write("hello!");
this.matchmakingClientService.SendToPlayer(message, player, DeliveryMethod.ReliableOrdered);

// Client B listens for incoming messages
this.matchmakingClientService.MessageReceivedFromPlayer += this.Client_MessageReceivedFromPlayer;

private void Client_MessageReceivedFromPlayer(object sender, MessageFromPlayerEventArgs e)
{
    var message = e.ReceivedMessage.ReadString();
    Debug.WriteLine($"Received '{message}'");
}
```

### Network Properties

Network properties are a set of components provided by the _Evergine.Networking_ extension. There are two ways properties can be stored and shared among members inside a room: _room_ properties, which are shared at the room level, and _player_ (client) properties, which are attached to clients connected to a room.

As they are components, you can add them to any of the entities in your scene. Network properties require the existence of a properties provider for the component owner or its ascendants. Depending on the type of property you want to use, you need to ensure that a component of type _NetworkRoomProvider_ or _NetworkPlayerProvider_ is placed somewhere in the entity hierarchical path. This can be done manually using Evergine Studio and adding the component manually, or programmatically.

Network properties maintain an internal table of key-values to store information. There is also a size limitation for these tables: the table key type is byte, so you can't have more than 256 properties for a room or for each single client (player). In the _Evergine.Networking.Components_ namespace, you can find a set of built-in components to work with network properties of more common scalar data types and structs like numbers, strings, vectors, etc.

#### Property Synchronization

For example, imagine that we want to have an object in our scene that can be manipulated by one of the clients (move, scale, and rotate it). We also want all the clients connected to the room to see those transformations. In this case, the best option is to use a network property to synchronize the entity transform.

Below, you will find a code block showing how it works, but let's see a few notes before:
- It's recommended to have a centralized enum to easily control which room properties are already in use and avoid using the same key for different synchronization properties.
- We have used a _NetworkMatrix4x4PropertySync_ component because we want to synchronize transform information, but there are many other built-in properties.
- In this case, we are using a _room_ provider, but remember that you could also have specific properties for clients connected to the room. In that case, you should use _NetworkPropertyProviderFilter.Player_.
- The method _OnPropertyReadyToSet_ is invoked once the internal key-value table is ready to be synchronized. This also changes the _IsReady_ property to _true_. You should always check this property before trying to set a network property value.
- The method _OnPropertyRemoved_ is invoked if the property is removed from the shared table.
- The method _OnPropertyAddedOrChanged_ is invoked once the property is ready or someone within the room has changed its value.
- To update a property value, you just need to set the _PropertyValue_, as stated in the _UpdatePropertyValue_ method.

```csharp
public enum RoomProperties : byte
{
    MyObjectTransform = 0x00,
}

public class SyncLocalTransform : NetworkMatrix4x4PropertySync<RoomProperties>
{
    [BindComponent(source: BindComponentSource.Owner)]
    private Transform3D transform3d = null;

    public SyncLocalTransform()
    {
        this.ProviderFilter = NetworkPropertyProviderFilter.Room;
        this.PropertyKey = RoomProperties.MyObjectTransform;
    }

    // We should determine somehow if the current client can manipulate the object or
    // not, as only one at a time should do it.
    public bool CanManipulate { get; set; }

    protected override bool OnAttached()
    {
        this.transform3d = this.Owner.FindComponent<Transform3D>();
        this.transform3d.LocalTransformChanged += this.Transform3D_LocalTransformChanged;

        return base.OnAttached();
    }

    protected override void OnDetached()
    {
        this.transform3d.LocalTransformChanged -= this.Transform3D_LocalTransformChanged;
        base.OnDetached();
    }

    protected override void OnPropertyAddedOrChanged()
    {
        if (!this.CanManipulate)
        {
            this.transform3d.LocalPosition = this.PropertyValue.Translation;
            this.transform3d.LocalScale = this.PropertyValue.Scale;
            this.transform3d.LocalRotation = this.PropertyValue.Rotation;
        }
    }

    protected override void OnPropertyRemoved()
    {
    }

    protected override void OnPropertyReadyToSet()
    {
        base.OnPropertyReadyToSet();
        this.UpdatePropertyValue();
    }

    private void Transform3D_LocalTransformChanged(object sender, EventArgs e) =>
        this.UpdatePropertyValue();

    private void UpdatePropertyValue()
    {
        if (this.IsReady && this.CanManipulate)
        {
            this.PropertyValue = this.transform3d.LocalTransform;
        }
    }
}
```

#### Synchronization of Complex Properties

The _Evergine.Networking_ extension provides properties for more common scalars and structs, but what if we want to synchronize the data of a custom class? We can do it, but always keep in mind that it's not advisable to have large objects saved in internal key-value tables, as this affects memory consumption and network traffic bandwidth. In any case, we should implement some methods of _INetworkSerializable_ to achieve this.

For this example, imagine that our application has a map and we want to control the center and zoom level of that map. _INetworkSerializable_ requires you to implement two methods: one for data serialization and another for data deserialization. The only thing you need to remember is that you should read data in the same order as you wrote it.

```csharp
public class MapInfo : INetworkSerializable
{
    public Coordinates Center { get; set; }

    public short ZoomLevel { get; set; }

    public void Write(NetBuffer buffer)
    {
        buffer.Write(this.Center.Latitude);
        buffer.Write(this.Center.Longitude);
        buffer.Write(this.ZoomLevel);
    }

    public void Read(NetBuffer buffer)
    {
        var lat = buffer.ReadDouble();
        var lng = buffer.ReadDouble();
        this.Center = new Coordinates(lat, lng);
        this.ZoomLevel = buffer.ReadInt16();
    }

    public struct Coordinates
    {
        public Coordinates(double latitude, double longitude)
        {
            this.Latitude = latitude;
            this.Longitude = longitude;
        }

        public double Latitude { get; }

        public double Longitude { get; }
    }
}

public class SyncMapInfo : NetworkSerializablePropertySync<RoomProperties, MapInfo> 
{
    public SyncMapInfo()
    {
        this.ProviderFilter = NetworkPropertyProviderFilter.Room;
        this.PropertyKey = RoomProperties.MapInfo;
    }

    // ...
    protected override void OnPropertyAddedOrChanged() 
    {
        if (this.IsReady) 
        {
            MapInfo info = this.PropertyValue;
            // Do something with this, like updating the map
        }
    }
}
```