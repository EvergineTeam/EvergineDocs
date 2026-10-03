# Create a Post-Processing Graph from Code

---

Graphs are easiest to build in the [Post-Processing Graph Editor](postprocessing_graph_editor.md), but you can also build one in code: create the start and end nodes, add a node per compute effect, connect their ports and wrap the description in a `PostProcessingGraph`. This example builds the red-channel filter of [Custom Post-Processing Graph](custom_postprocessing_graph.md).

```csharp
using Evergine.Common.Graphics;
using Evergine.Components.Graphics3D;
using Evergine.Framework;
using Evergine.Framework.Graphics;
using Evergine.Framework.Graphics.Effects;

public class MyScene : Scene
{
    protected override void CreateScene()
    {
        var graphicsContext = Application.Current.Container.Resolve<GraphicsContext>();      

        // Create compute effect
        var shaderSource = @"
                    [Begin_ResourceLayout]

                        Texture2D input : register(t0);
                        RWTexture2D<float4> Output : register(u0);

                        SamplerState Sampler : register(s0);

                    [End_ResourceLayout]

                    [Begin_Pass:Default]

                        [Profile 11_0]
                        [Entrypoints CS = CS]

                        [numthreads(8, 8, 1)]
                        void CS(uint3 threadID : SV_DispatchThreadID)
                        {
                            float2 outputSize;
                            Output.GetDimensions(outputSize.x, outputSize.y);
                            float2 uv = (threadID.xy + 0.5) / outputSize;        

                            float4 color = input.SampleLevel(Sampler, uv, 0);

                            Output[threadID.xy] = float4(color.x, 0, 0, 1);    
                        }

                    [End_Pass]
                    ";

        Effect computeEffect = new EffectFromCode(graphicsContext, shaderSource);

        // Create Postprocessing Graph
        PostProcessingGraphDescription graphDescription = new PostProcessingGraphDescription();

        // Create start node
        PostProcessingNode render = new PostProcessingNode();
        var renderColorTextureOPort = new PostProcessingOutputNodePort("ColorTexture", new PostProcessingNodePortLoadableType<Texture>());
        var renderDepthTextureOPort = new PostProcessingOutputNodePort("DepthTexture", new PostProcessingNodePortLoadableType<Texture>());
        render.AddOutputPort(renderColorTextureOPort);
        render.AddOutputPort(renderDepthTextureOPort);
        graphDescription.StartNode = render;
        render.IntegrityNodeCheck(graphDescription);

        // Create end node
        PostProcessingNode screen = new PostProcessingNode();
        var screenColorTextureIPort = new PostProcessingInputNodePort("ColorTexture", new PostProcessingNodePortLoadableType<Texture>());
        screen.AddInputPort(screenColorTextureIPort);
        graphDescription.EndNode = screen;
        screen.IntegrityNodeCheck(graphDescription);

        // Create my custom node
        PostProcessingNode myNode = new PostProcessingNode(computeEffect);
        myNode.ThreadGroupDivisorX = 8;
        myNode.ThreadGroupDivisorY = 8;
        myNode.ThreadGroupDivisorZ = 1;
        graphDescription.AddNode(myNode);

        // Connect nodes
        myNode.GetInputPortByName("input").AddConnection(new PostProcessingPortConnection(renderColorTextureOPort));
        myNode.GetOutputPortByName("Output").AddConnection(new PostProcessingPortConnection(screenColorTextureIPort));

        PostProcessingGraph graph = new PostProcessingGraph(graphDescription);

        // Add postprocessing graph to scene
        Entity postprocessingVolume = new Entity()
            .AddComponent(new Transform3D())
            .AddComponent(new PostProcessingGraphRenderer() { ppGraph = graph });

        this.Managers.EntityManager.Add(postprocessingVolume);
    }
}
```

> [!NOTE]
> The thread group divisors must match the `[numthreads(...)]` of the compute effect: the graph divides the output size by them to get the number of groups to dispatch. 