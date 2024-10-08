# Voice Commands

This service allows us to register keywords that the speech recognition service will detect, enabling us to take actions when this occurs. It is based on [MRTK](../mrtk/index.md), so you should work with _SpeechHandler_ if you want to create handlers for your custom controls. If you are only interested in buttons and toggle buttons, you can use _PressableButtonSpeechHandler_ defined in _MRTK_ or _ToggleButtonSpeechHandler_ defined in _XRV_ to activate a button when the associated voice command is recognized.

> [!NOTE]
> The current implementation supports voice commands for _HoloLens 2 (UWP)_ only. The speech recognition service must be enabled, or command recognition will not occur. Please note that you should add an explicit reference to the _Evergine.Xrv.Core_ NuGet package for your UWP Mixed Reality project. This is necessary to ensure the correct implementation of the speech service for the UWP platform.

Users can also activate or deactivate voice command recognition in the _Configuration -> General_ section.

## Associate Voice Commands Programmatically

You have two options to add custom voice commands:
- Specify voice commands in the [menu button description](hand_menu.md) for module definition.

```csharp
public MyModule : Module 
{
    private const string VoiceCommandShow = "Show feature";
    private const string VoiceCommandHide = "Hide feature";

    public override IEnumerable<string> VoiceCommands => new[] { VoiceCommandShow, VoiceCommandHide };

    public override void Initialize(Scene scene)
    {
        this.HandMenuButton = new MenuButtonDescription()
        {
            VoiceCommandOff = VoiceCommandShow,
            VoiceCommandOn = VoiceCommandHide,
        };
    }
}
```
- Use the _Voice System_ API to programmatically register voice commands. Please note that this should only be invoked at application startup.

```csharp
var voiceSystem = this.xrvService.VoiceSystem;
voiceSystem.RegisterCommands(new[] { "one command", "other command" });
```

## Create a Custom Speech Handler

```csharp
public MySpeechRecognizer : SpeechHandler 
{
    protected override void InternalOnSpeechKeywordRecognized(string keyword)
    {
        base.InternalOnSpeechKeywordRecognized(keyword);
        // Perform an action depending on the matching command
    }
}
```