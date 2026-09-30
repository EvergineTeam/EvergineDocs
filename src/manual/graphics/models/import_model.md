# Import a Model

![Drag and Drop Asset](images/ModelImport.png)

In **Evergine Studio**, importing a 3D model file will create a **Model** asset, as explained in [this article](../../evergine_studio/assets/create.md).

## Embedded Assets

Depending on the 3D model file, when importing a **Model**, it may also import other embedded assets. A new folder will be created at the same level as the 3D file, with the name **`[ModelName]_Embedded`** (e.g., the file `car.fbx` will generate a folder named `car_Embedded`). 

| Asset     | Location                              | Description                                                                                                                                         |
|-----------|---------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|
| **Material** | `[ModelName]_Embedded/Materials`     | The most common one. Every material that the 3D file uses is generated as a specific **Material** asset and referenced in the **Model**.             |
| **Texture**   | `[ModelName]_Embedded/Textures`      | Some 3D file formats can embed textures. For every embedded **Texture**, an asset is generated.                                                      |
| **Sampler**   | `[ModelName]_Embedded/Samplers`      | Some 3D file formats specify the sampler states for their textures. In this case, **Samplers** are generated.                                        |

## Inspect Models in Asset Details

You can find the model assets in the *Assets Details* panel when you select a folder in the *Project Explorer*.

![Texture view](images/ModelGallery.png)

The picture shows both the **Model** asset and the **Embedded** folder for all the generated assets.

## Model Files in Content Directory

**Models** imported in **Evergine** create an additional metadata `.wemd` file.

![Model files](images/ModelFiles.png)

## Supported Formats

**Evergine** supports the following model formats:

| Extension          | Description                                                                                                                                                                                                                                                                                                                                                                                                                         |
|--------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `.gltf`, `.glb`    | <div><p>Open source format. The [Kronos Group](https://www.khronos.org/) created this format for 3D web, AR, VR, games, and 3D advertising. It’s the first really well-defined standard for 3D. This file format supports geometry, materials, textures, colors, and animations, including PBR (Physical Based Rendering).</p> <p>**GLTF** is based on JSON, so it stores some data in external files like textures (JPEG or PNG), shaders (GLSL), or geometry and animation data (BIN). **GLB** files store all this data internally. The Kronos Group is continually improving and updating this file format. It is quickly becoming the standard for 3D shopping. </p></div> |
| `.fbx`             | **FBX** is a proprietary 3D file format. AutoDesk purchased it in 2006 and continued supporting FBX. It is widely used in the film and video game industry. It supports geometry, appearance (color and texture), as well as animations (skeletal and morphs). FBX is most popular for animation and is used as an exchange format between different programs like Maya, 3DSMax, AutoCAD, Roman’s CAD, and others.                                                                                         |
| `.obj`             | An **OBJ** file contains information about the geometry of 3D objects. Developers use the file format for exchanging information and in CAD and 3D printing applications. OBJ files can support unlimited colors, and one file can define multiple objects. The current version is 3.0. The objects in an OBJ file are defined by polygon faces and normals, curves, texture maps, and surfaces. OBJ is a vector file, which makes the defined objects scalable.                                                |
| `.3ds`             | A **3DS** file is a 3D image format used by Autodesk 3D Studio. It contains mesh data, material attributes, bitmap references, smoothing group data, viewport configurations, camera locations, and lighting information. 3DS files may also include object animation data.                                                                                  |
| `.dae`             | A **DAE** file is a Digital Asset Exchange file format that is used for exchanging data between interactive 3D applications. This file format is based on the COLLADA (COLLAborative Design Activity) XML schema, an open standard XML schema for the exchange of digital assets among graphics software applications.                                                                         |