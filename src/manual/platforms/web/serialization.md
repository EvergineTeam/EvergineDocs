# Serialization across the JavaScript bridge

---

![Architecture of an Evergine web application, with the JavaScript bridge between the page and the .NET runtime](images/web_architecture.png)

Every value that crosses the JavaScript bridge is serialized to JSON with `System.Text.Json`. Without help, Evergine structs such as `Vector3` or `Color` would not survive the trip: their data lives in public fields, which `System.Text.Json` ignores by default. The **Evergine.Serialization.Converters** package adds JSON converters for the common types of `Evergine.Mathematics` and `Evergine.Common`, so you can pass them to `[JSInvokable]` methods and to `Invoke` calls as plain JavaScript objects.

The converters are regular `JsonConverter<T>` classes, so you can also use them outside the browser, for example in an ASP.NET Core API that exchanges the same types.

## Register the converters

New web projects reference the package and register the converters in the launcher's `Program.cs`. The `HostConfiguration` class is assigned before the WebAssembly instance is created, because the converters are added to the JSON options of the Blazor runtime when that instance starts:

```csharp
using Evergine.Serialization.Converters;
using Evergine.Web;
using Microsoft.AspNetCore.Components.WebAssembly.Hosting;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace MyProject.Web
{
    public class Program
    {
        private static global::Evergine.Web.WebAssembly wasm;

        public static void Main()
        {
            // Must be set before GetInstance(), which builds the host and reads it.
            global::Evergine.Web.WebAssembly.HostConfiguration = new HostConfiguration();
            wasm = global::Evergine.Web.WebAssembly.GetInstance();
        }

        private class HostConfiguration : IWasmHostConfiguration
        {
            public void ConfigureHost(WebAssemblyHostBuilder builder)
            {
                // Register services on the Blazor host here if you need them.
                // Do not call builder.Build(): Evergine builds the host itself.
            }

            public void RegisterJsonConverters(IList<JsonConverter> converters)
            {
                // Adds every converter marked for automatic registration.
                converters.AddEvergineConverters();
            }
        }
    }
}
```

If you upgrade an older project, add the package reference to the client project and add the `HostConfiguration` class above:

```xml
<PackageReference Include="Evergine.Serialization.Converters" Version="EVERGINE_VERSION" />
```

Replace `EVERGINE_VERSION` with the Evergine version of the rest of your packages.

> [!NOTE]
> The WebXR template does not register the converters. Add the `HostConfiguration` class and the package if you need them there.

## Converters

`AddEvergineConverters()` adds every converter marked as auto-registered. The two that are not, `ColorJsonConverter` and `ByteArrayJsonConverter`, must be added by hand: see [Choose between converters](#choose-between-converters) and [Use the converters outside the bridge](#use-the-converters-outside-the-bridge).

Blazor serializes property names in camelCase, so the JavaScript keys are lowercase (`x`, `halfExtent`), whatever the case of the C# field.

| Converter | .NET type | JavaScript shape | Auto-registered |
|-----------|-----------|------------------|-----------------|
| `ColorAsHexJsonConverter` | `Color` | `"#RRGGBBAA"`; `"#RRGGBB"` is also read, as opaque | Yes |
| `ColorJsonConverter` | `Color` | `{ r, g, b, a }`, each 0 to 255 | No |
| `ByteArrayJsonConverter` | `byte[]` | `[0, 128, 255]` | No |
| `Vector2JsonConverter` | `Vector2` | `{ x, y }` | Yes |
| `Vector3JsonConverter` | `Vector3` | `{ x, y, z }` | Yes |
| `Vector4JsonConverter` | `Vector4` | `{ x, y, z, w }` | Yes |
| `QuaternionJsonConverter` | `Quaternion` | `{ x, y, z, w }` | Yes |
| `UInt2JsonConverter` | `UInt2` | `{ x, y }` | Yes |
| `UInt3JsonConverter` | `UInt3` | `{ x, y, z }` | Yes |
| `Byte4JsonConverter` | `Byte4` | `{ x, y, z, w }` | Yes |
| `PointJsonConverter` | `Point` | `{ x, y }` | Yes |
| `RectangleJsonConverter` | `Rectangle` | `{ x, y, width, height }` | Yes |
| `RectangleFJsonConverter` | `RectangleF` | `{ x, y, width, height }` | Yes |
| `Matrix3x3JsonConverter` | `Matrix3x3` | Array of 3 rows: `[[m11, m12, m13], [m21, m22, m23], [m31, m32, m33]]` | Yes |
| `Matrix4x4JsonConverter` | `Matrix4x4` | Array of 4 rows: `[[m11, m12, m13, m14], ..., [m41, m42, m43, m44]]` | Yes |
| `PlaneJsonConverter` | `Plane` | `{ normal: {x, y, z}, d }` | Yes |
| `RayJsonConverter` | `Ray` | `{ position: {x, y, z}, direction: {x, y, z} }` | Yes |
| `RayStepJsonConverter` | `RayStep` | `{ origin: {x, y, z}, terminus: {x, y, z} }` | Yes |
| `RayHit3DJsonConverter` | `RayHit3D` | `{ location: {x, y, z}, normal: {x, y, z}, t }` | Yes |
| `BoundigBoxJsonConverter` | `BoundingBox` | `{ min: {x, y, z}, max: {x, y, z} }` | Yes |
| `BoundingSphereJsonConverter` | `BoundingSphere` | `{ center: {x, y, z}, radius }` | Yes |
| `BoundingOrientedBoxJsonConverter` | `BoundingOrientedBox` | `{ center: {x, y, z}, halfExtent: {x, y, z}, orientation: {x, y, z, w} }` | Yes |
| `BoundingFrustumJsonConverter` | `BoundingFrustum` | `{ matrix: [[...], [...], [...], [...]] }`, the 4x4 view-projection matrix | Yes |
| `SplineJsonConverter` | `Spline` | `{ a, b, c, d }` | Yes |

The two color converters live in the `Evergine.Serialization.Converters.Common.Graphics` namespace, the math converters in `Evergine.Serialization.Converters.Mathematics`, and `ByteArrayJsonConverter` in `Evergine.Serialization.Converters`. `BoundigBoxJsonConverter` is spelled that way in the library.

Nested values use the converter of their own type, so the `min` of a `BoundingBox` has the same shape as a `Vector3`.

## Examples

### Pass a vector from JavaScript to C#

In the HTML5 template, `app.program.invoke` calls a static method on the launcher's `Program` class. The identifier follows the template's `<Namespace>.Program:<Method>` pattern (see [Getting started](getting_started.md#how-the-method-identifiers-are-built)):

```csharp
// In MyProject.Web/Program.cs, inside the Program class.
// Requires: using Evergine.Mathematics; using Microsoft.JSInterop;
[JSInvokable("MyProject.Web.Program:LogPosition")]
public static float LogPosition(Vector3 position)
{
    Console.WriteLine($"Received {position}");
    return position.Length();
}
```

```javascript
const length = app.program.invoke("LogPosition", { x: 1, y: 2, z: 2 });
console.log(length); // 3
```

### Return an Evergine type from C# to JavaScript

Return values use the same converters, so JavaScript receives the documented shape:

```csharp
// In MyProject.Web/Program.cs, inside the Program class.
[JSInvokable("MyProject.Web.Program:GetBounds")]
public static BoundingBox GetBounds()
{
    return new BoundingBox(new Vector3(-1, 0, -1), new Vector3(1, 2, 1));
}
```

```javascript
const bounds = app.program.invoke("GetBounds");
console.log(bounds.max.y - bounds.min.y); // 2
```

### Choose between converters

Registration order matters: for a given type, `System.Text.Json` uses the first converter in the list that can handle it. To send colors as objects instead of hexadecimal strings, remove `ColorAsHexJsonConverter` and add `ColorJsonConverter`. Add your own converters in the same method:

```csharp
using Evergine.Serialization.Converters;
using Evergine.Serialization.Converters.Common.Graphics;
using Evergine.Web;
using Microsoft.AspNetCore.Components.WebAssembly.Hosting;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json.Serialization;

namespace MyProject.Web
{
    internal class HostConfiguration : IWasmHostConfiguration
    {
        public void ConfigureHost(WebAssemblyHostBuilder builder)
        {
        }

        public void RegisterJsonConverters(IList<JsonConverter> converters)
        {
            converters.AddEvergineConverters();

            // Colors as { r, g, b, a } instead of "#RRGGBBAA".
            var hexConverter = converters.OfType<ColorAsHexJsonConverter>().FirstOrDefault();
            if (hexConverter != null)
            {
                converters.Remove(hexConverter);
            }

            converters.Add(new ColorJsonConverter());
        }
    }
}
```

> [!NOTE]
> Converters registered here apply to every call across the bridge, in both directions. You do not need `[JsonConverter]` attributes on your own types' properties when their types are covered by a registered converter.

### Use the converters outside the bridge

The converters work with any `JsonSerializerOptions`, for example in an ASP.NET Core API or when you save data to a file. That is also where `ByteArrayJsonConverter` is useful: `System.Text.Json` writes `byte[]` as a base64 string by default, and this converter writes a number array instead. Across the bridge itself, Blazor already passes `byte[]` as a JavaScript `Uint8Array`, so prefer that there.

```csharp
using Evergine.Mathematics;
using Evergine.Serialization.Converters;
using System.Text.Json;

public static class SnapshotSerializer
{
    private static readonly JsonSerializerOptions Options = CreateOptions();

    public static string Serialize(Vector3 position, byte[] payload) =>
        // {"position":{"x":1,"y":2,"z":3},"payload":[0,128,255]}
        JsonSerializer.Serialize(new { position, payload }, Options);

    private static JsonSerializerOptions CreateOptions()
    {
        // Match the camelCase keys that Blazor uses on the bridge.
        var options = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
        options.Converters.AddEvergineConverters();
        options.Converters.Add(new ByteArrayJsonConverter());
        return options;
    }
}
```
