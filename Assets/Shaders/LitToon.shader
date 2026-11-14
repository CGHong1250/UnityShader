// Shader targeted for low end devices. Single Pass Forward Rendering.
Shader "Hong/LitToon"
{
    // Keep properties of StandardSpecular shader for upgrade reasons.
    Properties
    {
        // ------------------------------------------------------------
        // 混合模式预设（LWGUI Shader Property Preset）
        // ------------------------------------------------------------
        [Preset(LWGUI_Preset_CustomBlendMode)] _Surface("Blend Mode Preset", Float) = 0.0

        // ------------------------------------------------------------
        // 渲染状态
        // ------------------------------------------------------------
        [Main(Rendering, _, off, off)] _RenderingGroup("Rendering", Float) = 1
        [SubEnum(Rendering, UnityEngine.Rendering.CullMode)] _Cull("Cull", Float) = 2.0
        [SubEnum(Rendering, UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", Float) = 1
        [SubEnum(Rendering, UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Float) = 0
        [SubEnum(Rendering, UnityEngine.Rendering.BlendMode)] _SrcBlendAlpha("Src Blend Alpha", Float) = 1
        [SubEnum(Rendering, UnityEngine.Rendering.BlendMode)] _DstBlendAlpha("Dst Blend Alpha", Float) = 0
        [SubToggle(Rendering, _)] _ZWrite("ZWrite", Float) = 1
        [SubToggle(Rendering, _RECEIVE_SHADOWS_OFF)] _DisableShadows("Disable Shadows", Float) = 0
        [Sub(Rendering)] _QueueOffset("Queue Offset", Float) = 0

        // ------------------------------------------------------------
        // 基础贴图
        // ------------------------------------------------------------
        [Main(Base, _, on, off)] _BaseGroup("Base", Float) = 1
        [Tex(Base, _BaseColor)] _BaseMap("Base Map (RGB) Smoothness / Alpha (A)", 2D) = "white" {}
        [Sub(Base)] _BaseMap_ST("Tiling Offset", Vector) = (1,1,0,0)
        [SubToggle(Base, _ALPHATEST_ON)] _AlphaClip("Alpha Clipping", Float) = 0
        [Sub(Base_ALPHATEST_ON)] _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        // ------------------------------------------------------------
        // 高光
        // ------------------------------------------------------------
        [Main(Specular, _, on, off)] _SpecularGroup("Specular", Float) = 1
        [Sub(Specular)] _SpecColor("Specular Color", Color) = (0.5, 0.5, 0.5, 0.5)
        [KWEnum(Specular, Color, _SPECULAR_COLOR, Map, _SPECGLOSSMAP)] _SpecSource("Specular Source", Float) = 0
        [Tex(Specular_SPECGLOSSMAP)] _SpecGlossMap("Specular Map", 2D) = "white" {}
        [SubToggle(Specular, _GLOSSINESS_FROM_BASE_ALPHA)] _SmoothnessSource("Smoothness From Base Alpha", Float) = 0

        // ------------------------------------------------------------
        // 法线
        // ------------------------------------------------------------
        [Main(Normal, _, on, off)] _NormalGroup("Normal", Float) = 1
        [SubToggle(Normal, _NORMALMAP)] _EnableNormalMap("Enable Normal Map", Float) = 1
        [Tex(Normal_NORMALMAP, _BumpScale)] _BumpMap("Normal Map", 2D) = "bump" {}
        [HideInInspector] _BumpScale("Scale", Float) = 1.0

        // ------------------------------------------------------------
        // 自发光
        // ------------------------------------------------------------
        [Main(Emission, _, on, off)] _EmissionGroup("Emission", Float) = 1
        [SubToggle(Emission, _EMISSION)] _EnableEmission("Enable Emission", Float) = 0
        [Tex(Emission_EMISSION, _EmissionColor)] _EmissionMap("Emission Map", 2D) = "white" {}
        [HideInInspector][HDR] _EmissionColor("Emission Color", Color) = (0,0,0,0)

        // 卡通描边功能
        [Main(Outline,_, on, off)]_Outline("Outline",float)=1
        [SubToggle(Outline,_ENABLE_OUTLINE)] _EnableOutline("Enable Outline", Float) = 0
        [Sub(Outline_ENABLE_OUTLINE)]_OutlineColor("Outline Color", Color) = (0,0,0,1)
        [Sub(Outline_ENABLE_OUTLINE)]_OutlineWidth("Outline Width", Range(0.0, 10)) = 0.03

        // ------------------------------------------------------------
        // 隐藏属性 / 兼容旧数据
        // ------------------------------------------------------------
        [HideInInspector] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [HideInInspector] _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
        [HideInInspector] _SpecularHighlights("Specular Highlights", Float) = 1.0
        [HideInInspector] _Blend("__blend", Float) = 0.0
        [HideInInspector] _BlendModePreserveSpecular("_BlendModePreserveSpecular", Float) = 1.0
        [HideInInspector] _AlphaToMask("__alphaToMask", Float) = 0.0
        [HideInInspector] _ReceiveShadows("Receive Shadows", Float) = 1.0

        // ObsoleteProperties
        [HideInInspector] _MainTex("BaseMap", 2D) = "white" {}
        [HideInInspector] _Color("Base Color", Color) = (1, 1, 1, 1)
        [HideInInspector] _Shininess("Smoothness", Float) = 0.0
        [HideInInspector] _GlossinessSource("GlossinessSource", Float) = 0.0

        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "UniversalMaterialType" = "SimpleLit"
            "IgnoreProjector" = "True"
        }
        LOD 300

        Pass
        {
            Name "Outline"
            Tags
            {
                "LightMode" = "SRPDefaultUnlit"
                "RenderType" = "Opaque"
            }
            
            Cull Front
            ZWrite On
            ZTest LEqual
            Offset 1, 1  // 深度偏移：第一个参数是单位偏移，第二个参数是斜率偏移
            
            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex OutlineVertex
            #pragma fragment OutlineFragment
            #pragma shader_feature_local _ENABLE_OUTLINE
            
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #include "Assets/Shaders/LitToonInput.hlsl"
            
            struct OutlineAttributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct OutlineVaryings
            {
                float4 positionCS   : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            
            OutlineVaryings OutlineVertex(OutlineAttributes input)
            {
                OutlineVaryings output = (OutlineVaryings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                #ifdef _ENABLE_OUTLINE
                    // 使用UnityObjectToClipPos来获取裁剪空间位置
                    float4 positionCS = TransformObjectToHClip(input.positionOS.xyz);
                    
                    // 将法线转换到世界空间
                    float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                    
                    // 将世界空间法线转换到观察空间
                    float3 normalVS = TransformWorldToViewDir(normalWS);
                    
                    // 获取观察空间位置
                    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                    float3 positionVS = TransformWorldToView(positionWS);
                    
                    // 在观察空间计算扩展
                    // 方法1：简单的屏幕空间扩展
                    // positionCS.xy += normalize(TransformWorldToHClipDir(normalWS)).xy * _OutlineWidth * positionCS.w * 0.001;
                    
                    // 方法2：在观察空间扩展（更稳定）
                    float3 viewNormal = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, input.normalOS));
                    float3 outlineOffset = viewNormal * _OutlineWidth * 0.01;
                    
                    // 将观察空间偏移转换到裁剪空间
                    float4 offsetCS = mul(UNITY_MATRIX_P, float4(outlineOffset, 0.0));
                    positionCS.xy += offsetCS.xy;
                    
                    output.positionCS = positionCS;
                #else
                    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                #endif
                
                return output;
            }
            
            half4 OutlineFragment(OutlineVaryings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                #ifdef _ENABLE_OUTLINE
                    return _OutlineColor;
                #else
                    discard;
                    return half4(0, 0, 0, 0);
                #endif
            }
            
            ENDHLSL
        }
        
        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            // -------------------------------------
            // Render State Commands
            // Use same blending / depth states as Standard shader
            Blend[_SrcBlend][_DstBlend], [_SrcBlendAlpha][_DstBlendAlpha]
            ZWrite[_ZWrite]
            Cull[_Cull]
            AlphaToMask[_AlphaToMask]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex LitPassVertexSimple
            #pragma fragment LitPassFragmentSimple

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF
            #pragma shader_feature_local_fragment _SURFACE_TYPE_TRANSPARENT
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ _ALPHAPREMULTIPLY_ON _ALPHAMODULATE_ON
            #pragma shader_feature_local_fragment _ _SPECGLOSSMAP _SPECULAR_COLOR
            #pragma shader_feature_local_fragment _GLOSSINESS_FROM_BASE_ALPHA

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ _LIGHT_LAYERS
            #pragma multi_compile _ _FORWARD_PLUS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fog
            #pragma multi_compile_fragment _ DEBUG_DISPLAY
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            //--------------------------------------
            // Defines
            #define BUMP_SCALE_NOT_SUPPORTED 1

            // -------------------------------------
            // Includes
            #include "Assets/Shaders/LitToonInput.hlsl"
            
            #include "Assets/Shaders/ShaderLibrary/Lighting.hlsl"
            #if defined(LOD_FADE_CROSSFADE)
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

            struct Attributes
            {
                float4 positionOS    : POSITION;
                float3 normalOS      : NORMAL;
                float4 tangentOS     : TANGENT;
                float2 texcoord      : TEXCOORD0;
                float2 staticLightmapUV    : TEXCOORD1;
                float2 dynamicLightmapUV    : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv                       : TEXCOORD0;

                float3 positionWS                  : TEXCOORD1;    // xyz: posWS

                #ifdef _NORMALMAP
                    half4 normalWS                 : TEXCOORD2;    // xyz: normal, w: viewDir.x
                    half4 tangentWS                : TEXCOORD3;    // xyz: tangent, w: viewDir.y
                    half4 bitangentWS              : TEXCOORD4;    // xyz: bitangent, w: viewDir.z
                #else
                    half3  normalWS                : TEXCOORD2;
                #endif

                #ifdef _ADDITIONAL_LIGHTS_VERTEX
                    half4 fogFactorAndVertexLight  : TEXCOORD5; // x: fogFactor, yzw: vertex light
                #else
                    half  fogFactor                 : TEXCOORD5;
                #endif

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    float4 shadowCoord             : TEXCOORD6;
                #endif

                DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 7);

            #ifdef DYNAMICLIGHTMAP_ON
                float2  dynamicLightmapUV : TEXCOORD8; // Dynamic lightmap UVs
            #endif

                float4 positionCS                  : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData)
            {
                inputData = (InputData)0;

                inputData.positionWS = input.positionWS;

                #ifdef _NORMALMAP
                    half3 viewDirWS = half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w);
                    inputData.tangentToWorld = half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz);
                    inputData.normalWS = TransformTangentToWorld(normalTS, inputData.tangentToWorld);
                #else
                    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(inputData.positionWS);
                    inputData.normalWS = input.normalWS;
                #endif

                inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
                viewDirWS = SafeNormalize(viewDirWS);

                inputData.viewDirectionWS = viewDirWS;

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    inputData.shadowCoord = input.shadowCoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
                #else
                    inputData.shadowCoord = float4(0, 0, 0, 0);
                #endif

                #ifdef _ADDITIONAL_LIGHTS_VERTEX
                    inputData.fogCoord = InitializeInputDataFog(float4(inputData.positionWS, 1.0), input.fogFactorAndVertexLight.x);
                    inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
                #else
                    inputData.fogCoord = InitializeInputDataFog(float4(inputData.positionWS, 1.0), input.fogFactor);
                    inputData.vertexLighting = half3(0, 0, 0);
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
                inputData.dynamicLightmapUV = input.dynamicLightmapUV.xy;
                #endif
                #if defined(LIGHTMAP_ON)
                inputData.staticLightmapUV = input.staticLightmapUV;
                #else
                inputData.vertexSH = input.vertexSH;
                #endif
                #endif
            }

            ///////////////////////////////////////////////////////////////////////////////
            //                  Vertex and Fragment functions                            //
            ///////////////////////////////////////////////////////////////////////////////

            // Used in Standard (Simple Lighting) shader
            Varyings LitPassVertexSimple(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

            #if defined(_FOG_FRAGMENT)
                    half fogFactor = 0;
            #else
                    half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
            #endif

                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.positionWS.xyz = vertexInput.positionWS;
                output.positionCS = vertexInput.positionCS;

            #ifdef _NORMALMAP
                half3 viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);
                output.normalWS = half4(normalInput.normalWS, viewDirWS.x);
                output.tangentWS = half4(normalInput.tangentWS, viewDirWS.y);
                output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.z);
            #else
                output.normalWS = NormalizeNormalPerVertex(normalInput.normalWS);
            #endif

                OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
            #ifdef DYNAMICLIGHTMAP_ON
                output.dynamicLightmapUV = input.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
            #endif
                OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

                #ifdef _ADDITIONAL_LIGHTS_VERTEX
                    half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
                    output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
                #else
                    output.fogFactor = fogFactor;
                #endif

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    output.shadowCoord = GetShadowCoord(vertexInput);
                #endif

                return output;
            }

            // Used for StandardSimpleLighting shader
            void LitPassFragmentSimple(
                Varyings input
                , out half4 outColor : SV_Target0
            #ifdef _WRITE_RENDERING_LAYERS
                , out float4 outRenderingLayers : SV_Target1
            #endif
            )
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                SurfaceData surfaceData;
                InitializeSimpleLitSurfaceData(input.uv, surfaceData);

            #ifdef LOD_FADE_CROSSFADE
                LODFadeCrossFade(input.positionCS);
            #endif

                InputData inputData;
                InitializeInputData(input, surfaceData.normalTS, inputData);
                SETUP_DEBUG_TEXTURE_DATA(inputData, input.uv, _BaseMap);

            #ifdef _DBUFFER
                ApplyDecalToSurfaceData(input.positionCS, surfaceData, inputData);
            #endif

                half4 color = UniversalFragmentBlinnPhong(inputData, surfaceData);
                color.rgb = MixFog(color.rgb, inputData.fogCoord);
                color.a = OutputAlpha(color.a, IsSurfaceTypeTransparent(_Surface));

                outColor = color;

            #ifdef _WRITE_RENDERING_LAYERS
                uint renderingLayers = GetMeshRenderingLayer();
                outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
            #endif
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _GLOSSINESS_FROM_BASE_ALPHA

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            // -------------------------------------
            // Includes
            #include "Assets/Shaders/LitToonInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "GBuffer"
            Tags
            {
                "LightMode" = "UniversalGBuffer"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite[_ZWrite]
            ZTest LEqual
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 4.5

            // Deferred Rendering Path does not support the OpenGL-based graphics API:
            // Desktop OpenGL, OpenGL ES 3.0, WebGL 2.0.
            #pragma exclude_renderers gles3 glcore

            // -------------------------------------
            // Shader Stages
            #pragma vertex LitPassVertexSimple
            #pragma fragment LitPassFragmentSimple

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            //#pragma shader_feature _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local_fragment _ _SPECGLOSSMAP _SPECULAR_COLOR
            #pragma shader_feature_local_fragment _GLOSSINESS_FROM_BASE_ALPHA
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            //#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            //#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
            #pragma multi_compile_fragment _ _RENDER_PASS_ENABLED
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            //--------------------------------------
            // Defines
            #define BUMP_SCALE_NOT_SUPPORTED 1

            // -------------------------------------
            // Includes
            #include "Assets/Shaders/LitToonInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/SimpleLitGBufferPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            ColorMask R
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _GLOSSINESS_FROM_BASE_ALPHA

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "Assets/Shaders/LitToonInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        // This pass is used when drawing to a _CameraNormalsTexture texture
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _GLOSSINESS_FROM_BASE_ALPHA

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            // Universal Pipeline keywords
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "Assets/Shaders/LitToonInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/SimpleLitDepthNormalsPass.hlsl"
            ENDHLSL
        }

        // This pass it not used during regular rendering, only for lightmap baking.
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }

            // -------------------------------------
            // Render State Commands
            Cull Off

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMetaSimple

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _SPECGLOSSMAP
            #pragma shader_feature EDITOR_VISUALIZATION

            // -------------------------------------
            // Includes
            #include "Assets/Shaders/LitToonInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/SimpleLitMetaPass.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "Universal2D"
            Tags
            {
                "LightMode" = "Universal2D"
                "RenderType" = "Transparent"
                "Queue" = "Transparent"
            }

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex vert
            #pragma fragment frag

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON

            // -------------------------------------
            // Includes
            #include "Assets/Shaders/LitToonInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Utils/Universal2D.hlsl"
            ENDHLSL
        }
    }

    Fallback  "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "LWGUI.LWGUI"
}
