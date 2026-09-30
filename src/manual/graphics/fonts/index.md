# Fonts and Texts
---
![Fonts and Texts](../images/fonts.jpg)

Fonts are an asset that represents a TrueType font that can be used to draw text in your project. The available font file formats supported are .ttf and .otf.

## Font Atlas
Evergine uses the **Multi-channel Signed Distance Field** technique to generate a pre-rendered sprite font atlas from the original font file. A font atlas is typically stored in texture memory and used to draw text in real-time rendering contexts. The main issue with the traditional sprite atlas is that the glyphs are pre-rendered at a specified resolution, so if you use this sprite atlas to render a large text or if the camera is close to the text, it is possible to detect a loss of resolution and aliasing on the text. Multi-channel Signed Distance Field allows rendering font glyphs while minimizing the loss of resolution with different font sizes and even when the camera is close to the text. Follow this [link](https://github.com/Chlumsky/msdfgen) to read more details about this technique.

## Default Font
The default Evergine project template imports the [Evergine.Core package](../evergine_core.md), which includes the [Arial Font](font_editor.md). The Text3D component uses the Arial font by default. You can create your own font asset and change it in the Text3D component. Fonts are a type of [asset](../../evergine_studio/assets/index.md) and have a dedicated editor [**Font Editor**](font_editor.md).

## In this section
* [Import Font](import_fonts.md)
* [Font Editor](font_editor.md)
* [Create Text3D](create_text3D.md)