# Update from Evergine 2024.10.24 to Evergine 2025.3.1041

Since Evergine 2024.10.24, there are some changes that should be applied to already existing projects that want to be upgraded to this version. 

## Steps to migrate to the new version:
- Update your Evergine version using Evergine Studio.
- Review the list of breaking changes and apply the necessary modifications to your code.

## List of changes

### Bind RenderManager
In this version, the RenderManager exposed by the Drawable class and the list of managers in a scene is now a BaseRenderManager. This means that some features, such as LineBatch3D, are no longer directly accessible. If you are using them, you need to explicitly bind the specific instance of RenderManager.

Before:
```csharp
namespace Evergine.MRTK.Demo.Drawables
{
    public class BoxColliderRenderer : Drawable3D
    {
        public override void Draw(DrawContext drawContext)
        {
          ...
          this.RenderManager.LineBatch3D.DrawBoundingOrientedBox(box, Color.White);
        }
    }
}
```

After: 
```csharp
namespace Evergine.MRTK.Demo.Drawables
{
    public class BoxColliderRenderer : Drawable3D
    {
        [BindSceneManager]
        private RenderManager renderManager = null;

        public override void Draw(DrawContext drawContext)
        {
          ...
          this.renderManager.LineBatch3D.DrawBoundingOrientedBox(box, Color.White);
        }
    }
}
```

### DX compiler updated
The DX Compiler used by HLSLEverywhere has been updated, and [HLSL 2021](https://devblogs.microsoft.com/directx/announcing-hlsl-2021/) is now set as the default version. You should review your shaders to ensure they are compatible with this version.
A common change involves the ternary operator. While the new select function can be used, if you require multiplatform support, you can update your code as follows:

Before:
```csharp
      ...
	    n.xy += n.xy >= 0.0 ? -t : t;
      ...
```

After: 
```csharp
      ...
	    n.xy += float2(n.x >= 0.0 ? -t : t, n.y >= 0.0 ? -t : t);
      ...
```