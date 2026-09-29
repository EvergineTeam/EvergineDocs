# Create Text3D

![Text3D header](images/createText3D.jpg)
**Text3D** is a component that allows you to render text in 3D space. You can render anything from a simple header to a large paragraph, and configure text limits, wrapping, and ellipsis.

## Create a Text3D in Evergine Studio
You can create a Text3D by clicking the ![Plus Icon](../images/plusIcon.jpg) button in the [Entity Hierarchy](../../evergine_studio/interface.md) panel to deploy a menu of creation options, and then selecting the _"Text3D"_ option.

![Create new Text3D menu option](images/EntitiesHierarchyMenu.jpg)

A Text3D entity will be added to your scene.

![Text3D entity](images/Text3DEntity.jpg)

In the **Text3DMesh** component of your Text3D entity, you will find the following properties:

| Property                       | Description |
|-------------------------------|-------------|
| **Font**           | The font asset used (Font family). |
| **Layer**          | RenderLayer used to render the text. |
| **Text**           | The text to be drawn. Use **/n** to insert a line break. |
| **Color**          | The text color. |
| **Size**           | The canvas size or area. Enable the _DebugMode_ property in the **Text3DRenderer** component to show this area _(blue rectangle)_. |
| **ScaleFactor**    | The text scale factor. |
| **Wrapping**       | Word wrapping. If this option is enabled, line breaks will be created automatically when the current line doesn't have enough space for more words. |
| **Ellipsis**       | If this option is enabled, three ellipses will be shown at the end of the text when there isn't enough canvas space for additional letters. |
| **HorizontalAlignment** | Align the text horizontally. The available values are: _Left_, _Center_, and _Right_. |
| **VerticalAlignment**   | Align the text vertically. The available values are: _Top_, _Center_, and _Bottom_. |
| **Origin**              | Configure the origin of the Text3D entity. The value is a vector2 with values between [0-1]. |
| **LineSpacing**         | Configure the space between text lines. |
| **Softness**            | Configure the anti-aliasing effect. The value is a float between [0-2]. |

## Create a Text3D from code
The following code shows the list of components necessary to convert an entity into a Text3D entity.

```csharp
public class MyScene : Scene
{
    protected override void CreateScene()
    {                       
        var assetsService = Application.Current.Container.Resolve<AssetsService>();

        var defaultFont = assetsService.Load<Font>(DefaultResourcesIDs.DefaultFontID);

        var text = new Entity()
            .AddComponent(new Transform3D())
            .AddComponent(new Text3DMesh()
            {
                Font = defaultFont,
                Text = "Hello World!",
            })
            .AddComponent(new Text3DRenderer());

        this.Managers.EntityManager.Add(text);
    }
}
```

The result:

![Font entity](images/TextFromCode.jpg)

## Enable debug mode

Sometimes it is useful to enable the _DebugMode_ property in the **Text3DRenderer** component to draw the debug information for our Text3D entity. The canvas space will be shown as a blue rectangle. The text space will be shown as a yellow rectangle, and a red point will be rendered on each character origin.

![Debug Mode animation](images/debugMode.gif)