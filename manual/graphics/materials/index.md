# Materials
---
![Material header](images/materials.jpg)

Materials describe the appearance of object surfaces and how they react to [light](../lights.md). This allows you to simulate properties like roughness, reflection, and specular highlights to create realistic materials such as metal, plastic, concrete, etc. 

## Material and Effects
The materials are based on an [Effect](../effects/index.md), so you first need to create one or use an existing Effect. While an effect defines all the properties and possibilities, a **Material** sets specific values for each property defined in the associated effect.

## Default Materials
The default Evergine project template imports the [ **Evergine.Core** package](../../addons/index.md), and this package includes the [Default Material](material_editor.md) that you can use to simulate a large number of surfaces. Materials are a type of [asset](../../evergine_studio/assets/index.md) and have a dedicated Editor: the [**Material Editor**](material_editor.md).

## In this section
* [Create Materials](create_materials.md)
* [Using Materials](using_materials.md)
* [Material Editor](material_editor.md)
* [Material Decorators](material_decorators.md)