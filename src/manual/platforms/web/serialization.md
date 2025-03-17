# Using the Evergine.Serialization.Converters Library

The **Evergine.Serialization.Converters** library simplifies data serialization between JavaScript and C# in WebAssembly (WASM) environments. This library includes default JSON converters for many structs in `Evergine.Mathematics` and `Evergine.Common`, enabling seamless data handling between JavaScript and C# for web projects, API creation in ASP.NET Core, and other JSON-based serialization scenarios.

## Installation

For **new Evergine web projects**, the **Evergine.Serialization.Converters** package is added automatically. However, if you are updating an existing project, you’ll need to manually add the following reference in your project file:

```xml
<PackageReference Include="Evergine.Serialization.Converters" Version="EVERGINE_VERSION" />
```
> [!Note]
> Replace `EVERGINE_VERSION` with the appropriate Evergine version

Additionally, updating an existing project may require some minor code changes. Please refer to the following code example for guidance:

```csharp
public class Program
{
    // Some code here...

    public static void Main()
    {
        // Use new host configuration option (before loading WASM runtime instance)
        global::Evergine.Web.WebAssembly.HostConfiguration = new HostConfiguration();
        wasm = global::Evergine.Web.WebAssembly.GetInstance();
    }

    // Some code here...

    // Adding a host configuration class
    private class HostConfiguration : IWasmHostConfiguration
    {
        public void ConfigureHost(WebAssemblyHostBuilder builder)
        {
            // Here you can do some custom config
            // for WASM host, if you need it.
        }

        public void RegisterJsonConverters(IList<JsonConverter> converters)
        {
            // Here you can globally register  JSON converters used for JS Bridge 
            // Serialization of parameters on C# invokes.

            // Use this extension method to add most of built-in Evergine converters
            converters.AddEvergineConverters();
        }
    }
```

## Extending or Customizing Converters

This library provides default converters for a selection of Evergine structs and some common classes. However, you have flexibility to customize this setup:

- **Remove specific converters**: You can exclude converters provided by Evergine if they don’t meet your specific needs.
- **Add custom converters**: Add converters for any custom models or structs in your application.

```csharp
public class Program
{
    // Some code here...

    private class HostConfiguration : IWasmHostConfiguration
    {
        public void ConfigureHost(WebAssemblyHostBuilder builder)
        {
        }

        public void RegisterJsonConverters(IList<JsonConverter> converters)
        {
            // You always can modify this converters list to remove
            // already registered converters or register new ones. Example:

            var toRemove = converters.OfType<ColorAsHexJsonConverter>().FirstOrDefault();
            if (toRemove != null)
            {
                converters.Remove(toRemove);
            }

            // Or you can register custom converters
            converters.Add(new MyOwnConverter());
        }
    }
```
Converters registered through this library are available globally within the application, so it isn’t necessary to add the `JsonConverter` attribute to individual properties. Additionally, these converters can be used directly in JavaScript interop invoke parameters.

## Converters and Data Structure Requirements

Each converter is designed to support a specific data structure when serialized to or from JavaScript. These structures are consistent whether data is being passed from JavaScript to Evergine or vice versa, ensuring seamless communication.

Below are descriptions of each default converter along with examples of the expected JavaScript data structure for compatibility.

### Evergine.Common

#### ColorAsHexJsonConverter

Expects a color as hexadecimal string from JavaScript side.

_JavaScript_
```javascript
window.Utils.invoke("ChangeColor", '#334422');
```

_C#_
```csharp
[JSInvokable($"{BaseInvokeClassName}:ChangeColor")]
public static void ChangeColor(Color color)
```

#### ColorJsonConverter

Expects a color as object.

_JavaScript_
```javascript
window.Utils.invoke("ChangeColor", { r: 255, g: 255, b: 255, a: 255 });
```
_C#_
```csharp
[JSInvokable($"{BaseInvokeClassName}:ChangeColor")]
public static void ChangeColor(Color color)
```

### Evergine.Mathematics

#### BoundigBoxJsonConverter

Expects bounding box to be defined as following.

_JavaScript_
```javascript
window.Utils.invoke("SetBoundingBox", { 
    min: { x: 1.0, y: 2.0, z: 3.0 }, 
    max: { x: 1.0, y: 2.0, z: 3.0 } 
});
```
_C#_
```csharp
[JSInvokable($"{BaseInvokeClassName}:SetBoundingBox")]
public static void SetBoundingBox(BoundingBox bb)
```

#### BoundingFrustumJsonConverter

Expects frustum to be defined as following.

_JavaScript_
```javascript
window.Utils.invoke("SetBoundingFrustum", { 
    matrix: [
        [1.0, 2.0, 3.0, 4.0],
        [1.0, 2.0, 3.0, 4.0],
        [1.0, 2.0, 3.0, 4.0],
        [1.0, 2.0, 3.0, 4.0]
    ]
});
```
_C#_
```csharp
[JSInvokable($"{BaseInvokeClassName}:SetBoundingFrustum")]
public static void SetBoundingFrustum(BoundingFrustum frustum)
```

#### BoundingOrientedBoxJsonConverter

Expects bounding box to be defined as following.

_JavaScript_
```javascript
window.Utils.invoke("SetBoundingOrientedBox", { 
    center: { x: 1.0, y: 2.0, z: 3.0 },
    halfExtent: { x: 1.0, y: 2.0, z: 3.0 },
    orientation: { x: 1.0, y: 2.0, z: 3.0, w: 4.0 }
});
```
_C#_
```csharp
[JSInvokable($"{BaseInvokeClassName}:SetBoundingOrientedBox")]
public static void SetBoundingOrientedBox(BoundingOrientedBox bb)
```

#### BoundingSphereJsonConverter

Expects bounding sphere to be defined as following.

_JavaScript_
```javascript
window.Utils.invoke("SetBoundingSphere", { 
    center: { x: 1.0, y: 2.0, z: 3.0 },
    radius: 3.0,
});
```

#### Byte4JsonConverter

Expects _Byte4_ be defined as following.

_JavaScript_
```javascript
window.Utils.invoke("SetByte4", { x: 1.0, y: 2.0, z: 3.0, w: 4.0 });
```
_C#_
```csharp
[JSInvokable($"{BaseInvokeClassName}:SetByte4")]
public static void SetByte4(Byte4 b4)
```

#### Matrix3x3JsonConverter

Expects _Matrix3x3_ be defined as following.

_JavaScript_
```javascript
window.Utils.invoke("SetMatrix3x3", [
    [1.0, 2.0, 3.0],
    [1.0, 2.0, 3.0],
    [1.0, 2.0, 3.0]
]);
```
_C#_
```csharp
[JSInvokable($"{BaseInvokeClassName}:SetMatrix3x3")]
public static void SetMatrix3x3(Matrix3x3 matrix)
```

#### Matrix4x4JsonConverter

Expects _Matrix4x4_ be defined as following.

_JavaScript_
```javascript
window.Utils.invoke("SetMatrix4x4", [
    [1.0, 2.0, 3.0, 4.0],
    [1.0, 2.0, 3.0, 4.0],
    [1.0, 2.0, 3.0, 4.0],
    [1.0, 2.0, 3.0, 4.0]
]);
```
_C#_
```csharp
[JSInvokable($"{BaseInvokeClassName}:SetMatrix4x4")]
public static void SetMatrix4x4(Matrix4x4 matrix)
```

#### PlaneJsonConverter

Expects plane be defined as following.

_JavaScript_
```javascript
window.Utils.invoke("SetPlane", {
   normal: { x: 1.0, y: 2.0, z: 3.0},
   d: 3.0 
});
```
_C#_
```csharp
[JSInvokable($"{BaseInvokeClassName}:SetPlane")]
public static void SetPlane(Plane plane)
```

#### PointJsonConverter

Expects point be defined as following.

_JavaScript_
```javascript
window.Utils.invoke("SetPoint", { x: 1.0, y: 2.0 });
```
_C#_
```csharp
[JSInvokable($"{BaseInvokeClassName}:SetPoint")]
public static void SetPoint(Point point)
```

#### QuaternionJsonConverter

Expects quaternion be defined as following.

_JavaScript_
```javascript
window.Utils.invoke("SetQuaternion", { x: 1.0, y: 2.0, z: 3.0, w: 4.0 });
```
_C#_
```csharp
[JSInvokable($"{BaseInvokeClassName}:SetQuaternion")]
public static void SetQuaternion(Quaternion quaternion)
```

#### RayHit3DJsonConverter

Expects _RayHit3D_ be defined as following.

_JavaScript_
```javascript
window.Utils.invoke("SetRayHit3D", { 
    location: { x:1.0, y: 2.0, z: 3.0 },
    normal: { x:1.0, y: 2.0, z: 3.0 },
    t: 1.0
});
```
_C#_
```csharp
[JSInvokable($"{BaseInvokeClassName}:SetRayHit3D")]
public static void SetRayHit3D(RayHit3D hit)
```

#### RayJsonConverter

Expects _Ray_ be defined as following.

_JavaScript_
```javascript
window.Utils.invoke("SetRay", { 
    position: { x:1.0, y: 2.0, z: 3.0 },
    direction: { x:1.0, y: 2.0, z: 3.0 }
});
```
_C#_
```csharp
[JSInvokable($"{BaseInvokeClassName}:SetRay")]
public static void SetRay(Ray ray)
```

#### RayStepJsonConverter

Expects _RayStep_ be defined as following.

_JavaScript_
```javascript
window.Utils.invoke("SetRayStep", { 
    origin: { x:1.0, y: 2.0, z: 3.0 },
    terminus: { x:1.0, y: 2.0, z: 3.0 }
});
```
_C#_
```csharp
[JSInvokable($"{BaseInvokeClassName}:SetRayStep")]
public static void SetRayStep(RayStep step)
```

#### RectangleFJsonConverter

Expects _RectangleF_ be defined as following.

_JavaScript_
```javascript
window.Utils.invoke("SetRectangleF", {x: 1.0, y: 0, width: 100, height: 100 });
```
_C#_
```csharp
[JSInvokable($"{BaseInvokeClassName}:SetRectangleF")]
public static void SetRectangleF(RectangleF rectangle)
```

#### RectangleJsonConverter

Expects _Rectangle_ be defined as following.

_JavaScript_
```javascript
window.Utils.invoke("SetRectangle", {x: 1.0, y: 1.0, width: 100, height: 100 });
```
_C#_
```csharp
[JSInvokable($"{BaseInvokeClassName}:SetRectangle")]
public static void SetRectangle(Rectangle rectangle)
```

#### SplineJsonConverter

Expects spline be defined as following.

_JavaScript_
```javascript
window.Utils.invoke("SetSpline", {a: 1.0, b: 2.0, c: 3.0, d: 4.0 });
```
_C#_
```csharp
[JSInvokable($"{BaseInvokeClassName}:SetSpline")]
public static void SetSpline(Spline spline)
```

#### UInt2JsonConverter

Expects _UInt2_ be defined as following.

_JavaScript_
```javascript
window.Utils.invoke("SetUInt2", {x: 1.0, y: 2.0 });
```
_C#_
```csharp
[JSInvokable($"{BaseInvokeClassName}:SetUInt2")]
public static void SetUInt2(UInt2 uint2)
```

#### UInt3JsonConverter

Expects _UInt3_ be defined as following.

_JavaScript_
```javascript
window.Utils.invoke("SetUInt3", {x: 1.0, y: 2.0, z: 3.0 });
```
_C#_
```csharp
[JSInvokable($"{BaseInvokeClassName}:SetUInt3")]
public static void SetUInt3(UInt3 uint3)
```

#### Vector2JsonConverter

Expects vector be defined as following.

_JavaScript_
```javascript
window.Utils.invoke("SetVector2", {x: 1.0, y: 2.0 });
```
_C#_
```csharp
[JSInvokable($"{BaseInvokeClassName}:SetVector2")]
public static void SetVector2(Vector2 vector)
```

#### Vector3JsonConverter

Expects vector be defined as following.

_JavaScript_
```javascript
window.Utils.invoke("SetVector3", {x: 1.0, y: 2.0, z: 3.0 });
```
_C#_
```csharp
[JSInvokable($"{BaseInvokeClassName}:SetVector3")]
public static void SetVector3(Vector3 vector)
```

#### Vector4JsonConverter

Expects vector be defined as following.

_JavaScript_
```javascript
window.Utils.invoke("SetVector4", {x: 1.0, y: 2.0, z: 3.0, w: 4.0 });
```
_C#_
```csharp
[JSInvokable($"{BaseInvokeClassName}:SetVector4")]
public static void SetVector4(Vector4 vector)
```