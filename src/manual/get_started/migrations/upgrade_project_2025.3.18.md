# Update from Evergine 2024.10.24 to Evergine 2025.3.18

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