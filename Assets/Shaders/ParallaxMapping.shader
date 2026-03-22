Shader "Hong/ParallaxMapping"
{

    Properties
    { 
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)
        _Smoothness("Smoothness",Range(0.0, 1)) = 0.2
        //添加法线纹理和法线强度变量
        [Normal]_BumpMap("NormalMap", 2D) = "bump"{}
        _BumpScale("NormalIntensity", Range(0,1)) = 1

        _MaskMap("MaskMap", 2D) = "white"{}
        _Metallic("Metallic",Range(0,1)) = 1

        [HDR] _EmissionColor("Color", Color) = (0,0,0)
        _EmissionMap("Emission", 2D) = "white" {}

        _ParallaxMap("Height Map", 2D) = "black" {}
        _ParallaxScale("Parallax Scale", float) = 0.01
        _MinLayerCount("Min Layer Count",int) = 5
        _MaxLayerCount("Max Layer Count",int) = 20

        _MinSelfShadowLayerCount("Min Self Shadow Layer Count",int) = 5
        _MaxSelfShadowLayerCount("Max Self Shadow Layer Count",int) = 10

        _ShadowIntensity("Shadow Intensity",Float) = 1
        [Toggle] _SoftShadow("Soft Shadow",Float) = 1
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        Pass
        {
            Tags{ "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // -------------------------------------
            // Material Keywords


            // -------------------------------------
            // Universal Pipeline keywords
            //_MAIN_LIGHT_SHADOWS:用于无级联阴影的关键字。 _MAIN_LIGHT_SHADOWS_CASCADE:用于带有级联阴影的关键字。 _MAIN_LIGHT_SHADOWS_SCREEN:用于屏幕空间阴影的关键字。
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            //_SHADOWS_SOFT:用于软阴影的关键字。  _SHADOWS_SOFT_LOW:用于低质量软阴影的关键字。  _SHADOWS_SOFT_MEDIUM:用于中等质量软阴影的关键字。 _SHADOWS_SOFT_HIGH:用于高质量软阴影的关键字。
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            //添加多光源阴影关键字
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            //_ADDITIONAL_LIGHTS_VERTEX:用于每个顶点附加灯光的关键字。  _ADDITIONAL_LIGHTS:用于每个像素附加灯光的关键字。
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            //用于 DBuffer 中第一、二、三个目标的关键字。
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            //用于 Light Cookies 的关键字。
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            //用于 Light Layers 的关键字。
            #pragma multi_compile _ _LIGHT_LAYERS

            // -------------------------------------
            // Unity defined keywords
            //让雾起作用
            #pragma multi_compile_fog 
            //LightMap支持
            #pragma multi_compile _ LIGHTMAP_ON 
            //用于混合光照贴图阴影的关键字。
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING 
            //用于 Shadowmask 的关键字。
            #pragma multi_compile _ SHADOWS_SHADOWMASK 
            //用于组合定向光照贴图的关键字。
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            //用于动态光照贴图的关键字。
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            //用于 LOD Crossfade 的关键字。
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            //用于调试显示的关键字。
            #pragma multi_compile_fragment _ DEBUG_DISPLAY

              


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            //光照函数库
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"

            #if defined(LOD_FADE_CROSSFADE)
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif


            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 texcoord     : TEXCOORD0;
                float2 staticLightmapUV   : TEXCOORD1;
                float2 dynamicLightmapUV  : TEXCOORD2;

            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
                float4 tangentWS    : TEXCOORD2;
                float3 positionWS   : TEXCOORD3;
                half fogFactor       : TEXCOORD4;
                    DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 5);
                #ifdef DYNAMICLIGHTMAP_ON
                float2  dynamicLightmapUV : TEXCOORD6; // Dynamic lightmap UVs
                #endif
                float4 shadowCoord   : TEXCOORD7;
                float3 viewTS : TEXCOORD8; 
                float3 lightTS : TEXCOORD9; 

            };

            TEXTURE2D(_MaskMap);        SAMPLER(sampler_MaskMap);
            TEXTURE2D(_ParallaxMap);    SAMPLER(sampler_ParallaxMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor, _EmissionColor;
                float4 _BaseMap_ST;
                half _Smoothness, _BumpScale, _Metallic;
                float4 _ParallaxMap_ST;
                half _ParallaxScale;
                int _MinLayerCount;
                int _MaxLayerCount;
                int _MinSelfShadowLayerCount;
                int _MaxSelfShadowLayerCount;
                half _ShadowIntensity;
            CBUFFER_END

            //----------------自定义函数写在这里------------------
            inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
            {
                half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
                outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;
                outSurfaceData.alpha = albedoAlpha.a;

                half4 n = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uv);
                outSurfaceData.normalTS = UnpackNormalScale(n, _BumpScale);

                half4 maskMap = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, uv);
                outSurfaceData.specular = 0.5;
                outSurfaceData.metallic = maskMap.r * _Metallic;
                outSurfaceData.smoothness = maskMap.g * _Smoothness;
                outSurfaceData.occlusion = maskMap.b;
                outSurfaceData.emission = SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));

                outSurfaceData.clearCoatMask = 0;
                outSurfaceData.clearCoatSmoothness = 1;
            }
            
            
            void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData)
            {
                inputData = (InputData)0;

                inputData.positionWS = input.positionWS;

                half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);

                float sgn = input.tangentWS.w; 
                float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                half3x3 tangentToWorld = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);
                inputData.tangentToWorld = tangentToWorld;
                
                inputData.normalWS = TransformTangentToWorld(normalTS, tangentToWorld);
                inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);

                inputData.viewDirectionWS = viewDirWS;


                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    inputData.shadowCoord = input.shadowCoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
                #else
                    inputData.shadowCoord = float4(0, 0, 0, 0);
                #endif

                #ifdef _ADDITIONAL_LIGHTS_VERTEX
                    inputData.fogCoord = InitializeInputDataFog(float4(input.positionWS, 1.0), input.fogFactorAndVertexLight.x);
                    inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
                #else
                    inputData.fogCoord = InitializeInputDataFog(float4(input.positionWS, 1.0), input.fogFactor);
                #endif

                #if defined(DYNAMICLIGHTMAP_ON)
                    inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV, input.vertexSH, inputData.normalWS);
                #else
                    inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.vertexSH, inputData.normalWS);
                #endif

                    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
                    inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);

                    #if defined(DEBUG_DISPLAY)
                        #if defined(DYNAMICLIGHTMAP_ON)
                        inputData.dynamicLightmapUV = input.dynamicLightmapUV;
                        #endif
                        #if defined(LIGHTMAP_ON)
                        inputData.staticLightmapUV = input.staticLightmapUV;
                        #else
                        inputData.vertexSH = input.vertexSH;
                        #endif
                    #endif

            }

            half GetParallaxMapHeight(half2 uv)
            {
                //具体参见 ParallaxMapping.hlsl的ParallaxMapping函数
                half lod = 0;
                return SAMPLE_TEXTURE2D_LOD(_ParallaxMap, sampler_ParallaxMap, uv,lod).r;
            }
            //简单的视差映射 参考ParallaxMapping.hlsl中的ParallaxOffset1Step函数
            //Unity URP中的计算方式 amplitude参数解释为应用于Heightmap高度的乘数，等同与下面自定函数中的heightScale的作用
            //amplitude的建议值是[0.005,0.08]
            //注意实际上URP的做法个人感觉要比很多资料中直接乘以一个scale要好得多
            //但是为了方便对比学习，之后的函数依旧是使用heightScale而不是amplitude
            half2 URPParallaxMapping(half2 uv, half amplitude, half3 viewDirTS)
            {
                half height = GetParallaxMapHeight(uv);
                //amplitude如果等于0.08，那么height的范围是[0,1]，正好最后计算后的height的范围是[-0.04,0.04]
                //这可能也是为什么叫amplitude（振幅）的原因
                height = height * amplitude - amplitude / 2.0;
                half3 v = normalize(viewDirTS);
                v.z += 0.42;
                half2 uvOffset = height * (v.xy / v.z);
                return uv + uvOffset;
            }

            //简单的视差映射 Parallax Mapping
            //可以看到简单的视察映射，并不会消耗太多的性能，但是效果要大打折扣
            //当高度较为陡峭视角与表面角度较大时，会出现明显的走样
            half2 ParallaxMapping(half2 uv, half heightScale, half3 viewDirTS)
            {
                half height = GetParallaxMapHeight(uv);
                half3 v = normalize(viewDirTS);
                //这里v.xy/v.z,并不是一定要除z。想象一下在TBN空间下，z越大视角越接近法线，所需要的偏移越小，如果视角与法线平行说明可以指直接看到，不需要偏移了;
                //同样的当视角与法线接近垂直的时候，z接近无限小,从而增加纹理坐标的偏移；这样做在视角上会获得更大的真实度。
                //但也会因为在某些角度看会不好看所以也可以不除z，不除z的技术叫做 Parallax Mapping with Offset Limiting（有偏移量限制的视差贴图）
                half2 uvOffset = v.xy / v.z * (height * heightScale);
                return uv + uvOffset;
            }

            //陡峭视差映射 Steep Parallax Mapping
            //我在URP的PerPixelDisplacement.hlsl找到了相关实现
            //使用raymarch也就是步进采样法，从摄像机开始往下找，也就是从上往下找
            //因为上面的简单的视差是直接近似，所以在高度陡峭变化的情况下效果不好，这次我们把高度分层，寻找最接近的位置，而不是直接使用近似值
            //提高采样数量提高精确性
            //层数越多结果越准确，性能消耗也越大
            half2 SteepParallaxMapping(half2 uv, int numLayers, half heightScale, half3 viewDirTS)
            {
                //高度图整体范围 [0,1]
                //numLayers 表示分了多少层
                //stepSize 每层的间隔
                viewDirTS = normalize(viewDirTS);
                half stepSize = 1.0 / (half)numLayers;
                //这一步和简单的视差映射一样
                //但是我们想要从视角往下找,视角向量是一个指向视点的向量，我们想要从视点开始找
                //所以这里除以的-z，但是无所谓反正把视角向量反过来就行
                half2 parallaxMaxOffsetTS = (viewDirTS.xy / -viewDirTS.z)* heightScale;
                //求出每一层的偏移，然后我们要逐层判断
                half2 uvOffsetPerStep = stepSize * parallaxMaxOffsetTS;

                //初始化当前偏移
                half2 uvOffsetCurrent = uv;
                //GetParallaxMapHeight是自定义函数就在该文件的上面
                half prevMapHeight = GetParallaxMapHeight(uvOffsetCurrent);
                uvOffsetCurrent += uvOffsetPerStep;
                half currMapHeight = GetParallaxMapHeight(uvOffsetCurrent);
                half layerHeight = 1 - stepSize; 

                //遍历所有层查找估计偏差点（采样高度图得到的uv点的高度 > 层高的点）
                //unable to unroll loop, loop does not appear to terminate in a timely manner
                //上面这个错误是在循环内使用tex2D导致的，需要加上unroll来限制循环次数或者改用tex2Dlod
                for (int stepIndex = 0; stepIndex < numLayers; ++stepIndex)
                {
                    //我们找到了估计偏差点
                    if (currMapHeight > layerHeight)
                        break;

                    prevMapHeight = currMapHeight;
                    layerHeight -= stepSize;
                    uvOffsetCurrent += uvOffsetPerStep;

                    currMapHeight = GetParallaxMapHeight(uvOffsetCurrent);
                }
                return uvOffsetCurrent;
            }

            //视差遮蔽映射 Parallax Occlusion Mapping (POM)
            //我在URP的 PerPixelDisplacement.hlsl找到了相关实现
            //你会发现陡峭视差映射，其实也有问题，结果不应该直接就用找到的估计偏差点
            //因为我们知道准确的偏移在 估计偏差点和估计偏差点的前一个点之间
            //所以我们可以插值这2个点来得到更好的结果。
            half2 ParallaxOcclusionMapping(half2 uv, int minNumLayers,int maxNumLayers, half heightScale, half3 viewDirTS)
            {
                viewDirTS = normalize(viewDirTS);
                //这里稍微做了一个优化
                //因为在TBN空间，视角越接近(0,0,1)也就是法线，需要采样的次数越少
                half numLayers = lerp((half)maxNumLayers,(half)minNumLayers,abs(dot(half3(0.0, 0.0, 1.0), viewDirTS)));
                //这个部分和SteepParallaxMapping上面的一模一样（为了方便阅读我直接复制粘贴，没有用函数包装）
                ////-----------------------------------SteepParallaxMapping（陡峭视差映射）一模一样 |开始|-------------------
                 //高度图整体范围 [0,1]
                //numLayers 表示分了多少层
                //stepSize 每层的间隔
                half stepSize = 1.0 / numLayers;
                //这一步和简单的视差映射一样
                //但是我们想要从视角往下找,视角向量是一个指向视点的向量，我们想要从视点开始找
                //所以这里除以的-z，但是无所谓反正把视角向量反过来就行
                half2 parallaxMaxOffsetTS = (viewDirTS.xy / -viewDirTS.z)* heightScale;
                //求出每一层的偏移，然后我们要逐层判断
                half2 uvOffsetPerStep = stepSize * parallaxMaxOffsetTS;

                //初始化当前偏移
                half2 uvOffsetCurrent = uv;
                //GetParallaxMapHeight是自定义函数就在该文件的上面
                half prevMapHeight = GetParallaxMapHeight(uvOffsetCurrent);
                uvOffsetCurrent += uvOffsetPerStep;
                half currMapHeight = GetParallaxMapHeight(uvOffsetCurrent);
                half layerHeight = 1 - stepSize; 

                //遍历所有层查找估计偏差点（采样高度图得到的uv点的高度 > 层高的点）
                //unable to unroll loop, loop does not appear to terminate in a timely manner
                //上面这个错误是在循环内使用tex2D导致的，需要加上unroll来限制循环次数或者改用tex2Dlod
                for (int stepIndex = 0; stepIndex < numLayers; ++stepIndex)
                {
                    //我们找到了估计偏差点
                    if (currMapHeight > layerHeight)
                        break;

                    prevMapHeight = currMapHeight;
                    layerHeight -= stepSize;
                    uvOffsetCurrent += uvOffsetPerStep;

                    currMapHeight = GetParallaxMapHeight(uvOffsetCurrent);
                }
                ////-----------------------------------SteepParallaxMapping（陡峭视差映射）一模一样 |结束|-------------------


                //线性插值
                half delta0 = currMapHeight - layerHeight;
                half delta1 = (layerHeight + stepSize) - prevMapHeight;
                half ratio = delta0 / (delta0 + delta1);
                //这里就是比较常见的插值写法。
                //uvOffsetCurrent - uvOffsetPerStep 表示上一步的偏移
                //half2 finalOffset = (uvOffsetCurrent - uvOffsetPerStep) * ratio + uvOffsetCurrent * (1 - ratio);
                //这里是URP里面的写法（算是一个小优化，其实就是化简上面这个式子）
                half2 finalOffset = uvOffsetCurrent - ratio * uvOffsetPerStep;
                
                return finalOffset;
            }

            //浮雕映射 Relief Parallax Mapping
            //但是后来出现了一个比2分查找更快的算法 Secant Method - Eric Risser，既 割线法，加速求解
            //URP的也使用了割线法，参考 PerPixelDisplacement.hlsl
            half2 ReliefParallaxMapping(half2 uv, int minNumLayers,int maxNumLayers, half heightScale, half3 viewDirTS,out half outLayerHeight)
            {
                viewDirTS = normalize(viewDirTS);
                outLayerHeight = 0;
                //这里稍微做了一个优化
                //因为在TBN空间，视角越接近(0,0,1)也就是法线，需要采样的次数越少
                half numLayers = lerp((half)maxNumLayers,(half)minNumLayers,abs(dot(half3(0.0, 0.0, 1.0), viewDirTS)));
                //这个部分和SteepParallaxMapping上面的一模一样（为了方便阅读我直接复制粘贴，没有用函数包装）
                ////-----------------------------------SteepParallaxMapping（陡峭视差映射）一模一样 |开始|-------------------
                 //高度图整体范围 [0,1]
                //numLayers 表示分了多少层
                //stepSize 每层的间隔
                half stepSize = 1.0 / numLayers;
                //这一步和简单的视差映射一样
                //但是我们想要从视角往下找,视角向量是一个指向视点的向量，我们想要从视点开始找
                //所以这里除以的-z，但是无所谓反正把视角向量反过来就行
                half2 parallaxMaxOffsetTS = (viewDirTS.xy / -viewDirTS.z)* heightScale;
                //求出每一层的偏移，然后我们要逐层判断
                half2 uvOffsetPerStep = stepSize * parallaxMaxOffsetTS;

                //初始化当前偏移
                half2 uvOffsetCurrent = uv;
                //GetParallaxMapHeight是自定义函数就在该文件的上面
                half prevMapHeight = GetParallaxMapHeight(uvOffsetCurrent);
                uvOffsetCurrent += uvOffsetPerStep;
                half currMapHeight = GetParallaxMapHeight(uvOffsetCurrent);
                half layerHeight = 1 - stepSize; 

                //遍历所有层查找估计偏差点（采样高度图得到的uv点的高度 > 层高的点）
                //unable to unroll loop, loop does not appear to terminate in a timely manner
                //上面这个错误是在循环内使用tex2D导致的，需要加上unroll来限制循环次数或者改用tex2Dlod
                for (int stepIndex = 0; stepIndex < numLayers; ++stepIndex)
                {
                    
                    //我们找到了估计偏差点
                    if (currMapHeight > layerHeight)
                        break;

                    prevMapHeight = currMapHeight;
                    layerHeight -= stepSize;
                    uvOffsetCurrent += uvOffsetPerStep;
                    currMapHeight = GetParallaxMapHeight(uvOffsetCurrent);
                }
                ////-----------------------------------SteepParallaxMapping（陡峭视差映射）一模一样 |结束|-------------------

               
                //一般来说这里应该指定一个查询次数,用二分法查询，但是后来出现了割线法，可以更加快速近似

                half pt0 = layerHeight + stepSize;
                half pt1 = layerHeight;
                half delta0 = pt0 - prevMapHeight;
                half delta1 = pt1 - currMapHeight;

                half delta;
                half2 finalOffset;


                // Secant method to affine the search
                // Ref: Faster Relief Mapping Using the Secant Method - Eric Risser
                // Secant Method - Eric Risser，割线法
                for (int i = 0; i < 3; ++i)
                {
                    // intersectionHeight is the height [0..1] for the intersection between view ray and heightfield line
                    half intersectionHeight = (pt0 * delta1 - pt1 * delta0) / (delta1 - delta0);
                    outLayerHeight = intersectionHeight;
                    // Retrieve offset require to find this intersectionHeight
                    finalOffset = (1 - intersectionHeight) * uvOffsetPerStep * numLayers;

                    currMapHeight = GetParallaxMapHeight(uv + finalOffset);

                    delta = intersectionHeight - currMapHeight;

                    if (abs(delta) <= 0.01)
                        break;

                    // intersectionHeight < currHeight => new lower bounds
                    if (delta < 0.0)
                    {
                        delta1 = delta;
                        pt1 = intersectionHeight;
                    }
                    else
                    {
                        delta0 = delta;
                        pt0 = intersectionHeight;
                    }
                }
                return uv + finalOffset;
            }

            half ParallaxSelfShadowing(half2 uv,half layerHeight, int minNumLayers,int maxNumLayers,half heightScale, half3 lightDirTS)
            {
                lightDirTS = normalize(lightDirTS);
                //如果没有点被遮挡的时候应该是1
                half shadowMultiplier = 1;
                if(dot(half3(0, 0, 1), lightDirTS) > 0)
                {
                    half numSamplesUnderSurface = 0;

                    #if defined(_SOFTSHADOW_ON)
                        //因为软阴影下面要取最大值所以设置为0
                        shadowMultiplier = 0;
                    #endif
                    //这里稍微做了一个优化
                    //因为在TBN空间，光线越接近(0,0,1)也就是法线，需要判断的次数也越少
                    half numLayers = lerp((half)maxNumLayers,(half)minNumLayers,abs(dot(half3(0.0, 0.0, 1.0), lightDirTS)));
                    //高度图整体范围 [0,1]
                    //numLayers 表示分了多少层
                    //stepSize 每层的间隔
                    //重新分层是从视差映射得到的结果开始分层，所以这里不是1/numLayers，而我是当作高度图，所以用1减去
                    //------------------ 1
                    //
                    //------------------ 0
                    half stepSize = (1 - layerHeight) / numLayers;
                    //因为我们要找被多少层挡住了，所以直接延光源方向找，所以不需要除-z（不需要反转光源方向）
                    half2 parallaxMaxOffsetTS = (lightDirTS.xy / lightDirTS.z)* heightScale;
                    //求出每一层的偏移，然后我们要逐层判断
                    half2 uvOffsetPerStep = stepSize * parallaxMaxOffsetTS;

                    //初始化当前偏移
                    half2 uvOffsetCurrent = uv + uvOffsetPerStep;
                    //GetParallaxMapHeight是自定义函数就在该文件的上面
                    half currMapHeight = GetParallaxMapHeight(uvOffsetCurrent);
                    half currLayerHeight = layerHeight + stepSize;

                    #if defined(_SOFTSHADOW_ON)
                        int shadowStepIndex = 1;
                    #endif

                    //unable to unroll loop, loop does not appear to terminate in a timely manner
                    //上面这个错误是在循环内使用tex2D导致的，需要加上unroll来限制循环次数或者改用tex2Dlod
                    for (int stepIndex = 0; stepIndex < numLayers; ++stepIndex)
                    {
                        if (currLayerHeight >0.99)
                            break;

                        if(currMapHeight > currLayerHeight)
                        {
                            //防止在0到1范围外的影子出现，如果不处理当影子较长时边缘会有多余的影子
                            if(uvOffsetCurrent.x >= 0 && uvOffsetCurrent.x <= 1.0 && uvOffsetCurrent.y >= 0 &&uvOffsetCurrent.y <= 1.0)
                            {
                                numSamplesUnderSurface += 1; //被遮挡的层数
                            #if defined(_SOFTSHADOW_ON) 
                                //想象一下软阴影的特征，越靠近边缘，影子越浅
                                half newShadowMultiplier = (currMapHeight - currLayerHeight) * (1 - shadowStepIndex / numLayers);
                                shadowMultiplier = max(shadowMultiplier, newShadowMultiplier);
                            #endif
                            }
                        }

                        #if defined(_SOFTSHADOW_ON)
                            shadowStepIndex += 1;
                        #endif

                        currLayerHeight += stepSize;
                        uvOffsetCurrent += uvOffsetPerStep;

                        currMapHeight = GetParallaxMapHeight(uvOffsetCurrent);
                    }
                    #if defined(_SOFTSHADOW_ON)
                        shadowMultiplier = numSamplesUnderSurface < 1 ? 1.0 :(1 - shadowMultiplier);
                    #else
                        shadowMultiplier = 1 - numSamplesUnderSurface / numLayers; //根据被遮挡的层数来决定阴影深浅
                    #endif

                    
                }
                return shadowMultiplier;
            }
            
            //----------------顶点着色器------------------
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                
                half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);

                half fogFactor = 0;
                    fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
                output.fogFactor = fogFactor;

                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

                output.normalWS = normalInput.normalWS;
                real sign = input.tangentOS.w * GetOddNegativeScale();
                half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
                output.tangentWS = tangentWS;

                    OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
                #ifdef DYNAMICLIGHTMAP_ON
                    output.dynamicLightmapUV = input.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
                #endif
                    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
                    
                #ifdef _ADDITIONAL_LIGHTS_VERTEX
                    output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
                #else
                    output.fogFactor = fogFactor;
                #endif

                    output.positionWS = vertexInput.positionWS;
                    output.shadowCoord = GetShadowCoord(vertexInput);
                    output.positionCS = vertexInput.positionCS;
                

                float3 viewWS = GetWorldSpaceViewDir(output.positionWS);
                float3x3 tangentSpaceTransform = float3x3(normalInput.tangentWS,normalInput.bitangentWS,normalInput.normalWS);
                output.viewTS = mul(tangentSpaceTransform,  viewWS);
                Light light = GetMainLight();
                output.lightTS = mul(tangentSpaceTransform, light.direction);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                //视差贴图处理
                half outLayerHeight;
                half2 finalUV = ReliefParallaxMapping(input.uv,_MinLayerCount,_MaxLayerCount,_ParallaxScale,input.viewTS,outLayerHeight);

                //这个作用本质上就是裁掉周围的东西，因为如果图片的Wrap Mode 设置的是Repeat模式，你会在边缘看到重复平铺的图像
                if(finalUV.x > 1.0 || finalUV.y > 1.0 || finalUV.x < 0.0 || finalUV.y < 0.0) //去掉边上的一些古怪的失真
                    discard;

                //视差自阴影处理
                half shadowMultiplier = ParallaxSelfShadowing(finalUV,outLayerHeight,_MinSelfShadowLayerCount,_MaxSelfShadowLayerCount,_ParallaxScale,input.lightTS);

                
                
                SurfaceData surfaceData;
                InitializeStandardLitSurfaceData(finalUV, surfaceData);

                #ifdef LOD_FADE_CROSSFADE
                    LODFadeCrossFade(input.positionCS);
                #endif

                InputData inputData;
                InitializeInputData(input, surfaceData.normalTS, inputData);
                SETUP_DEBUG_TEXTURE_DATA(inputData, finalUV, _BaseMap);
                
                #ifdef _DBUFFER
                    ApplyDecalToSurfaceData(input.positionCS, surfaceData, inputData);
                #endif

                half4 color = UniversalFragmentPBR(inputData, surfaceData) * pow(abs(shadowMultiplier),_ShadowIntensity);
                color.rgb = MixFog(color.rgb, inputData.fogCoord);
                
                return color;
            }
            ENDHLSL
        }

        Pass
        {
            Tags{"LightMode" = "ShadowCaster"}

            //Cull Off
            //ZWrite On
            //ZTest LEqual
            //ColorMask 0

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL; 

            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
            };
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(IN.normalOS);
                // 获取阴影专用裁剪空间下的坐标
                OUT.positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, float3(0,0,0)));
                // 判断是否是在DirectX平台翻转过坐标
                #if UNITY_REVERSED_Z
                    OUT.positionCS.z = min(OUT.positionCS.z, OUT.positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    OUT.positionCS.z = max(OUT.positionCS.z, OUT.positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                return 0;
            }

            ENDHLSL
        }

    }
}