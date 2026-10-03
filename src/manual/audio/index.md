# Audio

---

![Audio Section](images/AudioHeader.jpg)

Evergine plays sound effects and music, positioned in 3D or not. You import audio files as assets, place `SoundEmitter3D` and `SoundListener3D` components in your scene, and the engine handles distance attenuation, panning and the Doppler effect for you. When you need more control, the same audio device is available from code, down to feeding it raw PCM samples you generate yourself.

## How audio flows through Evergine

1. An audio file (`.wav`, `.mp3` or `.ogg`) added to the project becomes a **sound asset**. Its profile decides the channels, sample rate and sample size it is exported with. See [Import Audio](import_audio.md) and [Audio Editor](audio_editor.md).
2. At run time, the asset loads as an `AudioBuffer`: a block of PCM data in one `WaveFormat`.
3. An `AudioSource` plays a queue of buffers. The `AudioDevice` registered by your platform launcher creates sources and buffers and sends the result to the speakers.
4. `SoundEmitter3D` wraps a source for one entity. `SoundListener3D` moves the device's listener with another entity, usually the camera. See [Using Audio from Evergine Studio](using_audio_from_editor.md).

Everything from step 2 onwards is also available from your own components. See [Using Audio from Code](using_audio_from_code.md).

## Platform support

Audio needs an `AudioDevice` service. The launcher project of each profile creates it and registers it in the application container, so what you get depends on the template the profile was created from:

| Project template | Audio device registered | Package |
| --- | --- | --- |
| Windows (DirectX12), Windows (DirectX11), Windows (Vulkan), Windows (OpenGL), Windows OpenXR (DirectX11), WinUI (DirectX11) | `XAudioDevice` (XAudio2) | `Evergine.XAudio2` |
| Avalonia | `XAudioDevice` when running on Windows. On macOS and Linux the template throws `NotImplementedException`. | `Evergine.XAudio2` |
| Android, Android Meta Quest (OpenXR), Android Pico (OpenXR) | `ALAudioDevice` (OpenAL Soft) | `Evergine.OpenAL` |
| MAUI | `ALAudioDevice` on Android. None on Windows (the package is referenced but no device is registered) or iOS. | `Evergine.OpenAL`, `Evergine.XAudio2` |
| iOS .NET 10 | None | |
| Web (WebGL2.0), React SPA (WebGL2.0), WebXR (Experimental AR), Web (Experimental WebGPU) | None | |

> [!IMPORTANT]
> `SoundEmitter3D` and `SoundListener3D` bind the `AudioDevice` service as a required dependency, and sound assets need it to load. On a profile that registers no device, these components are not attached and your scene is silent. To add audio to such a profile, create the device in its launcher and register it with `application.Container.RegisterInstance(...)`, as the Windows and Android launchers do.

## In this section

* [Import Audio](import_audio.md)
* [Audio Editor](audio_editor.md)
* [Using Audio from Evergine Studio](using_audio_from_editor.md)
* [Using Audio from Code](using_audio_from_code.md)
