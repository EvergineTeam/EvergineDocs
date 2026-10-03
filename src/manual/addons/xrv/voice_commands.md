# Voice commands

---

XRV lets modules declare voice commands, keywords that a speech recognizer detects to trigger actions such as showing the settings window or toggling a module. It builds on the voice infrastructure of [MRTK](../mrtk/index.md): speech handlers react to keywords, and a voice command service does the recognition.

> [!IMPORTANT]
> Voice commands are not available on the platforms Evergine supports today. The implementation that recognized speech was only available for UWP (HoloLens), which Evergine no longer supports. XRV keeps the API, so modules can still declare their keywords, but no keyword is recognized: XRV does not include an `IVoiceCommandService` for current devices and does not pass the keywords it collects to one.

## Declare voice commands in a module

A module declares its keywords in the `VoiceCommands` property. XRV collects them from every module during `Initialize`. The `VoiceCommandOn` and `VoiceCommandOff` properties of the module's [hand menu button](hand_menu.md#button-properties) associate keywords with each toggle state.

```csharp
using System.Collections.Generic;
using Evergine.Framework;
using Evergine.Xrv.Core.Modules;
using Evergine.Xrv.Core.UI.Buttons;
using Evergine.Xrv.Core.UI.Tabs;

public class MyModule : Module
{
    private const string VoiceCommandShow = "Show feature";
    private const string VoiceCommandHide = "Hide feature";

    public override string Name => "My module";

    public override ButtonDescription HandMenuButton { get; protected set; }

    public override TabItem Help { get; protected set; }

    public override TabItem Settings { get; protected set; }

    public override IEnumerable<string> VoiceCommands => new[] { VoiceCommandShow, VoiceCommandHide };

    public override void Initialize(Scene scene)
    {
        this.HandMenuButton = new ButtonDescription
        {
            IsToggle = true,
            TextOn = () => "Hide",
            TextOff = () => "Show",
            VoiceCommandOff = VoiceCommandShow,
            VoiceCommandOn = VoiceCommandHide,
        };
    }

    public override void Run(bool turnOn)
    {
    }
}
```

The core library also declares keywords of its own: "Detach menu", "Show settings", and "Show help".

## Speech handlers

To react to a keyword in a control, use a speech handler component:

- `PressableButtonSpeechHandler` (MRTK) presses a button when one of its `SpeechKeywords` is recognized.
- `ToggleButtonSpeechHandler` (XRV, namespace `Evergine.Xrv.Core.VoiceCommands`) toggles a button: `OnKeywords` turn it on and `OffKeywords` turn it off.
- `SpeechHandler` (MRTK) is the base class for your own handlers. `SpeechHandlerFireCondition` decides when it fires: always (`Global`), only while its entity is enabled (`Enabled`), or only while it is enabled and focused (`EnabledAndFocus`).

```csharp
using Evergine.MRTK.SDK.Features.Input.Handlers;

public class MySpeechHandler : SpeechHandler
{
    protected override void InternalOnSpeechKeywordRecognized(string keyword)
    {
        base.InternalOnSpeechKeywordRecognized(keyword);

        // Run the action that matches the recognized keyword.
    }
}
```

Speech handlers only receive keywords when an `IVoiceCommandService` is registered in the application container, as the fake service of the [MRTK demo project](../mrtk/demo_project.md#voice-commands) does.

The **General** tab of the [settings window](settings_system.md) includes a toggle that enables or disables the voice command service, when one is registered.
