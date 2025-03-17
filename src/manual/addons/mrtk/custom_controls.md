# Creating Custom Controls
---
MRTK controls utilize custom interfaces to handle user interaction events. Most controls should be added to an entity equipped with a _BoxCollider_ component and a _StaticBody_ component to ensure correct behavior within the physics engine.

## Focus Events
Controls implementing the _IMixedRealityFocusHandler_ interface receive focus events under the following conditions:
- When a *near pointer* is close to the entity.
- When a *far pointer* targets the entity using a ray.
- The user gazes at the entity (via the _GazeProvider_).

In the default button style, focus events visually raise the icon and text, indicating focus.

## Touch Events
Controls implementing the _IMixedRealityTouchHandler_ interface receive events when the near pointer touches the entity’s collider. This interaction is central to the _PressableButton_ component, which is used in the standard button to enable its primary functionality.

## Pointer Events
Controls implementing the _IMixedRealityPointerHandler_ interface receive the following pointer events:
- **Pointer Down**: Triggered when the user grabs an object via near or far interaction (e.g., an air-tap).
- **Pointer Dragged**: Occurs while the user is holding the object, enabling position updates.
- **Pointer Up**: Triggered when the user releases the object.

Pointer events are useful in manipulation handlers, enabling users to grab and freely move, rotate, or scale objects.

## Speech Events
Controls implementing the _IMixedRealitySpeechHandler_ interface receive events for voice commands, allowing users to activate buttons or execute global actions through speech. These components don’t need a collider, as they operate independently of the physics engine.