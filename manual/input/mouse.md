# Mouse

The **Mouse** is the most common input device on desktop platforms. You can access the mouse state by using the `MouseDispatcher`.

## MouseDispatcher

The `MouseDispatcher` is a class used to track mouse button events. It inherits from [`PointerDispatcher`](touch.md), so it can be used to produce touch events using the mouse.

```csharp
public abstract class MouseDispatcher : PointerDispatcher
{
    public MouseButtons State { get; }
    public Point ScrollDelta { get; }
    public Point PositionDelta { get; }
    public Point Position { get; }
    public abstract CursorTypes CursorType { get; }
    public bool IsMouseOver { get; }

    public event EventHandler<MouseButtonEventArgs> MouseButtonUp;
    public event EventHandler<MouseButtonEventArgs> MouseButtonDown;
    public event EventHandler<MouseEventArgs> MouseLeave;
    public event EventHandler<MouseEventArgs> MouseEnter;
    public event EventHandler<MouseEventArgs> MouseMove;
    public event EventHandler<MouseScrollEventArgs> MouseScroll;

    public bool IsButtonDown(MouseButtons button);
    public ButtonState ReadButtonState(MouseButtons button);
    public bool TrySetCursorPosition(Point position);
    public abstract bool TrySetCursorType(CursorTypes cursorType);
}
```

### Properties

It provides you with the following properties:

| Properties | Description |
| --- | --- |
| **State** | Gets a flag enum that indicates which mouse buttons are pressed at the current frame.|
| **Position** | Gets the mouse's absolute screen position at the current frame. |
| **PositionDelta** | Gets the mouse's delta position since the last frame. In other words, it describes how much the mouse has moved. | 
| **ScrollDelta** | Gets the mouse's scroll increment since the last frame. <ul><li>The value **X** indicates a horizontal scroll increment. The value is positive if the mouse wheel is rotated to the right and negative if the mouse wheel is rotated to the left.</li><li>The value **Y** indicates a vertical scroll increment. The value is positive if the mouse wheel is rotated in an upward direction (away from the user) and negative if the mouse wheel is rotated in a downward direction (toward the user).</li></ul> |
| **CursorType** | Gets the mouse's active cursor type. |
| **IsMouseOver** | Indicates if the mouse is over the `Surface`. |

### Events

You can subscribe to events to be notified when the mouse state changes:

| Events | Description |
| --- | --- |
| **MouseMove** and **MouseScroll** | These events track changes in mouse position and scroll. |
| **MouseButtonDown** and **MouseButtonUp** | These events track mouse button presses, but it is recommended to use the `IsButtonDown` and `ReadButtonState` methods: <ul><li>**IsButtonDown**: Gets a value indicating whether the current state of a mouse button is [Pressing](button_states.md) or [Pressed](button_states.md).</li><li>**ReadButtonState**: Gets the current [state](button_states.md) of a mouse button.</li></ul> |
| **MouseLeave** and **MouseEnter** | These events indicate if the mouse has entered or left the `Surface`, thereby tracking changes in the `IsMouseOver` property. |

### Useful Methods

| Methods | Description |
| --- | --- |
| **TrySetCursorPosition** | Attempts to update the cursor position. When this method is supported by the platform, it will return *true*. |
| **TrySetCursorType** | Attempts to update the cursor type. When this method is supported by the platform, it will return *true*. |

### Using MouseDispatcher

The `MouseDispatcher` can be found within the `Display` or `Surface` objects. The following sample code can be used to access the mouse dispatcher from a Component or Service.

```csharp
[BindService]
protected GraphicsPresenter graphicsPresenter;

protected override void Update(TimeSpan time)
{
    MouseDispatcher mouseDispatcher = this.graphicsPresenter.FocusedDisplay?.MouseDispatcher;

    if (mouseDispatcher?.ReadButtonState(MouseButtons.Left) == ButtonState.Pressing)
    {
        // Do something
    }
}
```