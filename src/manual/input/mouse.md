# Mouse

![The Display exposes three dispatchers; MouseDispatcher inherits PointerDispatcher, and holding the left mouse button adds pointer Id 0 to its Points](images/input_dispatchers.png)

*The mouse dispatcher is also a pointer dispatcher: the left button doubles as pointer 0.*

The mouse is the main pointing device on desktop platforms. `MouseDispatcher` reports the cursor position and how far it moved this frame, the wheel, the state of every button, and lets you change the cursor shape. It inherits from [`PointerDispatcher`](touch.md), so the left button also behaves like a finger on a touch screen, which lets the same code handle clicks and taps.

## MouseDispatcher

Get it from `display.MouseDispatcher` (see [Where input comes from](index.md#where-input-comes-from)). It lives in the `Evergine.Common.Input.Mouse` namespace, together with `MouseButtons` and `CursorTypes`. Positions are `Evergine.Mathematics.Point` values in pixels, relative to the top-left corner of the surface.

### Properties

| Member | Description |
| --- | --- |
| **Position** | Cursor position in this frame. |
| **PositionDelta** | How far the cursor moved since the previous frame: the sum of every move dispatched this frame. Zero when it did not move. |
| **ScrollDelta** | Wheel steps since the previous frame; every scroll event the platform reports counts as one step. `Y` is positive when the wheel rolls away from the user and negative toward the user. `X` is positive for a tilt to the right and negative to the left. |
| **State** | `MouseButtons` flags with every button that is down. |
| **IsMouseOver** | True while the cursor is over the surface. |
| **CursorType** | The `CursorTypes` value of the current cursor. |
| **Points** | Inherited from `PointerDispatcher`. Contains pointer `0` while the left button is held. See [The mouse as a pointer](#the-mouse-as-a-pointer). |

### Methods

| Member | Description |
| --- | --- |
| **ReadButtonState(MouseButtons button)** | Returns the [state](button_states.md) of the button in this frame. |
| **IsButtonDown(MouseButtons button)** | Returns true when the button is `Pressing` or `Pressed`. |
| **TrySetCursorPosition(Point position)** | Moves the cursor. Returns false when the platform does not allow it (Android, for example). On success `Position` is updated at once, as if the cursor had moved there, so the jump also counts in `PositionDelta`. |
| **TrySetCursorType(CursorTypes cursorType)** | Changes the cursor shape. Returns false when the platform does not support it (Android, for example). |

`MouseButtons` is a `[Flags]` enumeration: `None`, `Left`, `Middle`, `Right`, `XButton1` and `XButton2`. `CursorTypes` has `Unknown`, `None` (hidden), `Arrow`, `IBeam`, `Wait`, `Crosshair`, `WaitArrow`, `Sizing`, `No` and `Hand`.

### Events

| Event | Arguments | Description |
| --- | --- | --- |
| **MouseButtonDown** | `MouseButtonEventArgs` | A button went down. |
| **MouseButtonUp** | `MouseButtonEventArgs` | A button went up. |
| **MouseMove** | `MouseEventArgs` | The cursor moved over the surface. |
| **MouseScroll** | `MouseScrollEventArgs` | The wheel moved one step. |
| **MouseEnter** | `MouseEventArgs` | The cursor entered the surface. The first movement over the surface raises this instead of `MouseMove`. |
| **MouseLeave** | `MouseEventArgs` | The cursor left the surface. |
| **PointerDown**, **PointerUp**, **PointerMove** | `PointerEventArgs` | Inherited from `PointerDispatcher`, raised for pointer `0`. See [Touch](touch.md#events). |

| Event argument | Member | Description |
| --- | --- | --- |
| `MouseEventArgs` | **Position** | Cursor position when the event was dispatched. |
| `MouseEventArgs` | **State** | `MouseButtons` that were down when the event was dispatched. |
| `MouseButtonEventArgs` | **Button** | The button that changed. Also has `Position` and `State`. |
| `MouseButtonEventArgs` | **IsPressed** | True for `MouseButtonDown`, false for `MouseButtonUp`. |
| `MouseScrollEventArgs` | **Direction** | `MouseScrollDirections.Up`, `Down`, `Left` or `Right`. Also has `Position` and `State`. |
| `MouseScrollEventArgs` | **Delta** | The same step as a `Point`: `(0, 1)` up, `(0, -1)` down, `(1, 0)` right, `(-1, 0)` left. |

> [!NOTE]
> When the cursor leaves the surface, the dispatcher releases every button that is still down. A drag that leaves the window ends with a normal `Releasing` frame and a `MouseButtonUp` event, so your code never waits for a button that will not come back up.

## The mouse as a pointer

Because `MouseDispatcher` inherits `PointerDispatcher`, the left button also produces a pointer with Id `0`:

- Pressing the left button adds pointer `0` to `mouseDispatcher.Points` and raises `PointerDown`.
- Moving while the left button is held moves that pointer and raises `PointerMove`.
- Releasing the button raises `PointerUp`, and the pointer leaves the list after its `Releasing` frame, exactly like a finger.

The middle and right buttons do not create pointers. The pointer lives in the **mouse** dispatcher's `Points`, not in the touch dispatcher's, so code that should accept both clicks and taps has to look at both lists. The [Touch](touch.md#example-drag-and-pinch) example shows how.

## Example: drag to rotate, wheel to zoom

This behavior turns its entity around the vertical axis while the left button is dragged, scales it with the wheel, and shows a hand cursor during the drag.

```csharp
using System;
using Evergine.Common.Input;
using Evergine.Common.Input.Mouse;
using Evergine.Framework;
using Evergine.Framework.Graphics;
using Evergine.Framework.Services;
using Evergine.Mathematics;

public class MouseOrbitObject : Behavior
{
    [BindService]
    private GraphicsPresenter graphicsPresenter = null;

    [BindComponent]
    private Transform3D transform = null;

    public float RadiansPerPixel { get; set; } = 0.01f;

    public float ScalePerStep { get; set; } = 0.1f;

    protected override void Update(TimeSpan gameTime)
    {
        MouseDispatcher mouse = this.graphicsPresenter.FocusedDisplay?.MouseDispatcher;
        if (mouse == null)
        {
            return;
        }

        ButtonState left = mouse.ReadButtonState(MouseButtons.Left);

        // Change the cursor only on the edges, not every frame the button is held.
        if (left == ButtonState.Pressing)
        {
            mouse.TrySetCursorType(CursorTypes.Hand);
        }
        else if (left == ButtonState.Releasing)
        {
            mouse.TrySetCursorType(CursorTypes.Arrow);
        }

        if (mouse.IsButtonDown(MouseButtons.Left))
        {
            // PositionDelta is already "per frame", so it is not scaled by the elapsed time.
            Vector3 rotation = this.transform.LocalRotation;
            rotation.Y += mouse.PositionDelta.X * this.RadiansPerPixel;
            this.transform.LocalRotation = rotation;
        }

        if (mouse.ScrollDelta.Y != 0)
        {
            float scale = Math.Max(0.1f, this.transform.LocalScale.X + (mouse.ScrollDelta.Y * this.ScalePerStep));
            this.transform.LocalScale = new Vector3(scale);
        }
    }
}
```

## See also

* [Button states](button_states.md): what `ReadButtonState` returns and when it changes.
* [Touch](touch.md): `Points`, `PointerPoint` and the pointer events.
* [Example: camera controller](camera_controller.md): mouse-look with `PositionDelta`.
