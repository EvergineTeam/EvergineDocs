# Themes System

The themes system in _XRV_ provides a flexible way to control the look and feel of your application by modifying colors, fonts, and text styles. If you need to customize the colors used by your application, you should know that _XRV_ uses a system for application theming. A palette of colors is defined by generic color names.

| Color | Description |
| ------ | ------------------- |
| **PrimaryColor1** | Used for window title bar plates, text color for light buttons, and the background color for selected list items. |
| **PrimaryColor2** | Color applied to scroll bars. |
| **PrimaryColor3** | This color is for global texts and for active items in a tab control. |
| **SecondaryColor1** | Color for inactive items in tab controls, backplate color for some buttons, text color for selections, some manipulators, etc. |
| **SecondaryColor2** | Color applied to some manipulators. |
| **SecondaryColor3** | Applied to accept option backplates in confirmation dialogs. |
| **SecondaryColor4** | Windows front plate gradient start and plate color for dialog buttons. |
| **SecondaryColor5** | Windows front plate gradient end. |

Associated with these built-in colors, we provide a set of materials that you should use in your custom UI elements if you need to make use of themes and change the default set of colors provided by _XRV_.

![Theme default materials](images/themes_default_materials.png)

Depending on the values indicated in the theme, these materials are modified at runtime. As material instances are shared by different _MaterialComponent_ instances, new colors will be applied application-wide. If you create your own materials, they will not be modified by the theme system. On the other hand, if you apply any of the default materials in your own UI elements, they will be modified at runtime by the theme system.

## Modifying a Theme Color

To change a theme color, just access the _ThemesSystem_ and take a look at its _CurrentTheme_ property, which you can use to modify values for the current theme or assign a new _Theme_ instance. A new _Theme_ instance has _XRV_ default colors by default. You can modify color properties to apply modifications to UI elements.

```csharp
var theme = this.xrvService.ThemesSystem.CurrentTheme;
theme.PrimaryColor1 = Color.DarkCyan;
theme.SecondaryColor4 = Color.Blue;
theme.SecondaryColor5 = Color.DarkBlue;
```

For the piece of code above, the following changes would be presented when loading _XRV_ windows and the rest of the visual elements.

![Theme custom colors](images/themes_custom_theme.png)

You can have as many theme instances as you want, and switching them in the _CurrentTheme_ property should change colors at runtime.

## Modifying a Theme Font

Themes also provide a set of fonts used in different parts of UI elements.

| Font | Description |
| ------ | ------------------- |
| **PrimaryFont1** | Used for window titles, buttons, section labels, and tab items. |
| **PrimaryFont2** | Font used for context texts, hand menus, and window buttons. |

In the same way as colors, you can change these default fonts. Just add a new font asset and assign its identifier to any of the predefined font properties.

```csharp
theme.PrimaryFont1 = EvergineContent.MyCustomFont_ttf;
theme.PrimaryFont2 = EvergineContent.MyCustomFont_ttf;
```

## Shared Text Styles

_XRV_ also tries to provide helpful ways of having uniform UI definitions. For this purpose, we have defined _text styles_ that are shared globally, allowing you to define a font type, size, and color, and reuse this definition to apply it to any number of 3D texts within the application.

In each _TextStyle_ instance, you can set the following properties.

| Property | Description |
| ------ | ------------------- |
| **Font** | You can optionally set a font asset identifier here as the text font. This will be applied if _ThemeFont_ is _null_. |
| **TextColor** | Color for the text. This will be applied if _ThemeColor_ is _null_. |
| **TextScale** | Text scale for the style. |
| **ThemeColor** | This will indicate that this style will use one of the theme-defined colors. |
| **ThemeFont** | This will indicate that this style will use one of the theme-defined fonts. |

You will also find a set of built-in components to allow your own 3D text to apply global styles.

- **Text3dStyle**: Associates a _Text3DMesh_ to a text style.
- **ButtonTextStyle**: Associates a text style to a _StandardButtonConfigurator_ instance.
- **ToggleButtonTextStyle**: Associates a text style to a _ToggleButton_. You must set a component for each toggle state.

![Using text styles](images/themes_use_text_styles.png)

In the next table, you can see the list of default text styles. As you may notice, they are all attached to theme fonts and colors.

> [!NOTE]
> Please note that in this case, changing text style values will only work at application startup. We don't have support right now to do this at runtime.

| Style key | Default values |
| ------ | ------------------- |
| **Xrv.Primary1.Size1** | font: ThemeFont.PrimaryFont1, scale = 0.012f, color = ThemeColor.PrimaryColor3 |
| **Xrv.Primary1.Size2** | font: ThemeFont.PrimaryFont1, scale = 0.01f, color = ThemeColor.PrimaryColor3 |
| **Xrv.Primary1.Size3** | font: ThemeFont.PrimaryFont1, scale = 0.008f, color = ThemeColor.PrimaryColor3 |
| **Xrv.Primary2.Size1** | font: ThemeFont.PrimaryFont2, scale = 0.007f, color = ThemeColor.PrimaryColor3 |
| **Xrv.Primary2.Size2** | font: ThemeFont.PrimaryFont2, scale = 0.006f, color = ThemeColor.PrimaryColor3 |
| **Xrv.Primary2.Size3** | font: ThemeFont.PrimaryFont2, scale = 0.005f, color = ThemeColor.PrimaryColor3 |

### Add or Modify an Existing Text Style
If you need to add new styles, or modify an existing one, you can do so by implementing _ITextStyleRegistration_. Its single method named _Register_ receives the global styles dictionary as a parameter: you can add new entries or modify existing ones. 

```csharp
public class MyTextStylesRegistration : ITextStyleRegistration
{
    public void Register(Dictionary<string, TextStyle> registrations)
    {
        // Override a default style
        if (registrations.ContainsKey(DefaultTextStyles.XrvPrimary1Size1))
        {
            var defaultStyle = registrations[DefaultTextStyles.XrvPrimary1Size1];
            defaultStyle.TextScale = 0.015f;
        }

        // Add a new style with a theme-independent color
        registrations["RedStyle"] = new TextStyle
        {
            ThemeFont = ThemeFont.PrimaryFont1,
            TextScale = 0.013f,
            Color = Color.Red,
        };
    }
}
```

As these registrations are scanned by _XRV_, you can add your own text styles, and they will be available for text styling built-in components.

## How to Respond to Theme Changes
You may be wondering what happens with custom-defined materials and theme changes. As we said above, the _Theme System_ will not update these materials. Don't worry, as you can create your own code to control changes for themes at runtime. _ThemeSystem_ includes an event named _ThemeUpdated_ that will be invoked on theme changes. It has arguments of type _ThemeUpdatedEventArgs_ that contain information about theme changes.

| Property | Description |
| ------ | ------------------- |
| **IsNewThemeInstance** | Indicates if the message has been sent by a complete theme change (a new instance of the theme has been set). |
| **Theme** | Theme instance that is being applied at the moment of message emission. |
| **UpdatedColor** | If just one of the theme colors has been updated, it indicates which one of the themed colors has been involved. |

So, if you want your component to listen for changes in the current theme (for example, to change a custom material tint color), you will need something like the following code.

```csharp
public class MyComponent : Component
{
    [BindService]
    private XrvService xrvService = null;
    
    private ThemesSystem themes => this.xrvService.ThemesSystem;

    protected override bool OnAttached()
    {
        bool attached = base.OnAttached();
        if (attached)
        {
            this.themes.ThemeUpdated += this.ThemesSystem_ThemeUpdated;
        }

        return attached;
    }

    protected override void OnDetached()
    {        
        base.OnDetached();
        this.themes.ThemeUpdated -= this.ThemesSystem_ThemeUpdated;
    }
  
    private void ThemesSystem_ThemeUpdated(object sender, ThemeUpdatedEventArgs args)
    {
        if (args.IsNewThemeInstance)
        {
            // Respond to theme instance changes
            return;
        }

        switch (args.UpdatedColor)
        {
            case ThemeColor.PrimaryColor1:
                // Respond to PrimaryColor1 changes
                break;
            // ...
            default:
                break;
        }
    }
}
```