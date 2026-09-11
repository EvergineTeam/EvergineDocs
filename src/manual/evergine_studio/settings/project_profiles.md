# Manage Profiles

As a cross-platform engine, _Evergine_ provides a way to create different launcher projects for supported platforms. For each platform, a _C#_ project will be added to your filesystem. You can create more than one project for a given platform, but each one of these projects will be considered a different profile.

If you did not add all the platforms you wanted in the project creation window, you can do so from _Evergine Studio_ once your project is loaded. Just go to the _Settings > Project Settings_ menu to open a dialog to manage your project profiles. By default, an Evergine project includes _Windows_ as a platform. This platform is required for _Evergine Studio_ to work, so you cannot remove it.

![Scene update for managers](images/profile_add-profile.jpg)

To add a new platform profile, use the _Add_ button. A new window will open, where you can select the platform you want to add. By default, a profile name will be proposed, but you can change it if you prefer. As described above, you can even have more than one profile for the same platform. This will create separate C# projects for each of these platforms.

![Scene update for managers](images/profile_search-profile.jpg)

Similar to the launcher creation form, we have added some filters here to make it easier to find a template. Just use the free text input and platform dropdown selector to limit template results.

## Profile Management

For each profile, a different set of settings is applied. Once you add a new platform profile, a default set of values will be added for that platform. For example, on platforms like _Windows_, shaders are compiled at runtime by default, but other platforms like _Web_ or _Android_ require shaders to be precompiled due to performance and platform limitations.

![Scene update for managers](images/profile_edit-profile.jpg)

Profile settings can be customized at any time you want. Changes will be saved once you press the _Update_ button. The list of options that you can configure is described below.

### Textures

Controls the texture compression to be used in a given profile. This is important to optimize textures to be loaded in graphics hardware, which may be limited on platforms like mobile devices.

You can specify both alpha and non-alpha compression formats. A list of available formats is provided by the [PixelFormat](xref:Evergine.Common.Graphics.PixelFormat) enum.

### Shaders

You can enable shaders to be precompiled and included in the platform package. This may increase build time but will reduce loading time while running the application.

Additionally, you can configure your own directive specifications that best fit your project. For each directive, you can choose to enable or disable it. Once enabled, you can also add each directive to a directive combination. At the bottom, there is a read-only text area that presents the configured directive combinations.

## Open Platform Projects

For each profile registered within your project, you will find a new entry in the _File > Open C# editor_ menu. When clicking on one of the provided options, the platform-specific _Visual Studio_ solution will open.

![Scene update for managers](images/profile_open-project.jpg)