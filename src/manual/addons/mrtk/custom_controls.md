# Creating custom controls

---

MRTK controls react to the user through a small set of handler interfaces. Implement one or more of them in a component, add the component to an entity, and MRTK calls it when a pointer focuses, touches, grabs, or clicks that entity. This is how the built-in buttons, sliders, and scroll views work, so your own controls behave the same way.

Most controls must be added to an entity with a _BoxCollider_ component and a _StaticBody_ component, so the pointers can hit them through the physics engine.

| Interface | Called when | Methods |
| --- | --- | --- |
| `IMixedRealityFocusHandler` | A pointer or the gaze starts or stops targeting the entity. | `OnFocusEnter`, `OnFocusExit` |
| `IMixedRealityTouchHandler` | The near pointer touches the entity's collider. | `OnTouchStarted`, `OnTouchUpdated`, `OnTouchCompleted` |
| `IMixedRealityPointerHandler` | The user grabs, drags, releases, or clicks the entity with a near or far pointer. | `OnPointerDown`, `OnPointerDragged`, `OnPointerUp`, `OnPointerClicked` |
| `IMixedRealitySpeechHandler` | A registered voice command is recognized. | `OnSpeechKeywordRecognized` |

All of them live in the `Evergine.MRTK.Base.Interfaces.InputSystem.Handlers` namespace. The event data types are in `Evergine.MRTK.Base.EventDatum.Input`.

## Focus events

A component that implements `IMixedRealityFocusHandler` receives focus events when:

- A near pointer gets close to the entity.
- A far pointer targets the entity with its ray.
- The user looks at the entity, through the `GazeProvider`.

The standard button uses focus to raise its icon and text slightly, so the user knows which button is targeted.

## Touch events

A component that implements `IMixedRealityTouchHandler` receives events while the near pointer touches the entity's collider. The `PressableButton` component uses them to move the button plate with the fingertip and to detect a press.

## Pointer events

A component that implements `IMixedRealityPointerHandler` receives these events from near and far pointers:

- **OnPointerDown**: the user grabs the entity, by pinching near it or with an air-tap.
- **OnPointerDragged**: the user moves the hand while holding the entity. Use it to update position or rotation.
- **OnPointerUp**: the user releases the entity.
- **OnPointerClicked**: the user grabs and releases the entity without dragging it.

Manipulation handlers use pointer events to let users grab objects and move, rotate, or scale them.

## Speech events

A component that implements `IMixedRealitySpeechHandler` receives the recognized voice commands. Speech handlers do not need a collider, because they do not depend on the physics engine. MRTK only raises these events when your application registers an implementation of `IVoiceCommandService` in the container; the add-on does not include one for current platforms.

## Example: a control that highlights and follows the hand

The following component tints its entity while it is focused and moves the entity while the user drags it.

```csharp
using Evergine.Components.Graphics3D;
using Evergine.Framework;
using Evergine.Framework.Graphics;
using Evergine.MRTK.Base.EventDatum.Input;
using Evergine.MRTK.Base.Interfaces.InputSystem.Handlers;
using Evergine.Mathematics;

public class DraggableHighlight : Component, IMixedRealityFocusHandler, IMixedRealityPointerHandler
{
    [BindComponent]
    private Transform3D transform = null;

    [BindComponent]
    private MaterialComponent materialComponent = null;

    private Material defaultMaterial;
    private Vector3 grabOffset;

    public Material FocusedMaterial { get; set; }

    public void OnFocusEnter(MixedRealityFocusEventData eventData)
    {
        // Keep the original material so it can be restored when the focus leaves.
        this.defaultMaterial = this.materialComponent.Material;
        if (this.FocusedMaterial != null)
        {
            this.materialComponent.Material = this.FocusedMaterial;
        }
    }

    public void OnFocusExit(MixedRealityFocusEventData eventData)
    {
        this.materialComponent.Material = this.defaultMaterial;
    }

    public void OnPointerDown(MixedRealityPointerEventData eventData)
    {
        // Store the offset so the entity does not jump to the cursor position.
        this.grabOffset = this.transform.Position - eventData.Position;
    }

    public void OnPointerDragged(MixedRealityPointerEventData eventData)
    {
        this.transform.Position = eventData.Position + this.grabOffset;
    }

    public void OnPointerUp(MixedRealityPointerEventData eventData)
    {
    }

    public void OnPointerClicked(MixedRealityPointerEventData eventData)
    {
    }
}
```

> [!TIP]
> Call `eventData.SetHandled()` in a pointer handler when your control consumes the event. Handlers that check `EventHandled`, such as `SimpleManipulationHandler` and `AxisManipulationHandler`, then ignore it.
