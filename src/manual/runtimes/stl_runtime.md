# STL Runtime

---

The **Evergine.Runtimes.STL** package reads `.stl` files while the application runs and turns them into a `Model`, the same asset type that Evergine Studio produces when it imports a model. STL is the format CAD tools and 3D printing slicers export: geometry only, with no hierarchy, materials or textures. Use this runtime to show parts and prints that the user picks or that your application downloads.

| | |
| --- | --- |
| **Package** | `Evergine.Runtimes.STL` |
| **Namespace** | `Evergine.Runtimes.STL` |
| **Class** | `STLRuntime` (derives from `ModelRuntime`) |
| **Formats** | Binary and ASCII STL (`.stl`) |
| **Returns** | `Task<Model>` |
| **Platforms** | All Evergine platforms |

`ModelRuntime` lives in `Evergine.Framework.Runtimes`. `STLRuntime.Instance` is a ready-to-use singleton that resolves the graphics context and the assets service from the application container the first time it reads a file.

## What the runtime reads

`STLRuntime` reads both variants of the format. It looks at the 80-byte header to tell binary files from ASCII ones, so the file extension does not matter when you read from a stream.

* Each facet keeps the normal stored in the file, which gives the model a flat-shaded look.
* Coordinates are converted from the Z-up convention of most CAD tools to the Y-up convention of Evergine.
* STL files carry no material, so the whole model uses one white material (`STLMaterialData`: metallic 0, roughness 1).

## Load a model from a file

`Read(string filePath, ...)` opens the file through the application's `AssetsDirectory`, so the path is **relative to the `Content` folder of the running application**. Absolute paths are rejected with an `ArgumentException`.

A `.stl` file placed in the project's `Content` folder is normally imported by Evergine Studio and exported in the Evergine asset format. To read the original file with the runtime, mark the file with **Set to export as raw** in the [Assets Details panel](../evergine_studio/assets/edit.md). Raw assets keep their name and folder in the output, so `Content/Models/Bracket.stl` is read with the path `Models/Bracket.stl`.

```csharp
using Evergine.Framework;
using Evergine.Framework.Graphics;
using Evergine.Framework.Services;
using Evergine.Runtimes.STL;

public class MyScene : Scene
{
    protected override async void CreateScene()
    {
        var assetsService = Application.Current.Container.Resolve<AssetsService>();

        Model bracket = await STLRuntime.Instance.Read("Models/Bracket.stl");

        // A Model is only data: InstantiateModelHierarchy builds the entities that render it.
        Entity bracketEntity = bracket.InstantiateModelHierarchy("bracket", assetsService);
        this.Managers.EntityManager.Add(bracketEntity);
    }
}
```

> [!TIP]
> `CreateScene` is `async void`, so an exception thrown by `Read` does not reach any caller. Wrap the loading code in `try`/`catch` and log the error, or the model silently fails to appear.

## Load a model from a stream

`Read(Stream stream, ...)` reads from any stream that is **readable and seekable**. Use it for files outside the `Content` folder and for downloads.

For a file anywhere on disk, open it with `File.OpenRead`, which returns a seekable `FileStream`:

```csharp
using var stream = File.OpenRead(@"C:\Models\Bracket.stl");
Model model = await STLRuntime.Instance.Read(stream);
```

A network stream is not seekable: copy the response into a `MemoryStream` and set its `Position` back to 0 before reading it. The [GLB runtime page](glb_runtime.md#load-a-model-from-a-stream) has a complete download example; replace `GLBRuntime` with `STLRuntime` to use it for STL files.

## Custom materials

Pass a material assigner as the second argument of either `Read` overload to choose the material yourself, for example to show a part in the color of the plastic it will be printed in. The runtime describes the single material as an `STLMaterialData` (a `MaterialData`), and your function returns the `Material` to use. The [GLB runtime page](glb_runtime.md#materials-and-the-material-assigner) explains `MaterialData` and has a complete assigner.

```csharp
Model model = await STLRuntime.Instance.Read("Models/Bracket.stl", this.AssignMaterial);
```

`STLMaterialData` always reports `HasVertexNormal = true`, because every facet carries its normal, and no texture coordinates or textures.
