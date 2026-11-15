// ===========================================================================
//  NPRToon.shader  —  URP 卡通 / NPR 着色器
// ===========================================================================

Shader "Hong/NPRToon"
{
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

        // ------------------------------------------------------------
        // 基础贴图
        // ------------------------------------------------------------
        [Main(Base, _, on, off)] _BaseGroup("Base", Float) = 1
        [Tex(Base, _BaseColor)] _BaseMap("Base Map (RGB) Alpha (A)", 2D) = "white" {}
        [Sub(Base)] _BaseMap_ST("Tiling Offset", Vector) = (1,1,0,0)
        [SubToggle(Base, _ALPHATEST_ON)] _AlphaClip("Alpha Clipping", Float) = 0
        [Sub(Base_ALPHATEST_ON)] _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        // 基础色由上面 [Tex(Base, _BaseColor)] 内联显示，这里只隐藏声明
        [HideInInspector] _BaseColor("Base Color", Color) = (1,1,1,1)

        // ------------------------------------------------------------
        // 卡通阶梯（核心）
        // ------------------------------------------------------------
        [Main(Toon, _, on, off)] _ToonGroup("Toon Ramp", Float) = 1
        [Sub(Toon)] _RampSteps("Ramp Steps (1=两分 2=三分...)", Range(1.0, 6.0)) = 2.0
        [Sub(Toon)] _RampSmoothness("Ramp Smoothness", Range(0.0, 1.0)) = 0.15
        [Sub(Toon)] _ShadowOffset("Shadow Offset", Range(-0.5, 0.5)) = 0.0
        [Sub(Toon)] _ToonNormalWeight("Use Vertex Normal For Steps", Range(0.0, 1.0)) = 0.0
        [Sub(Toon)] _AmbientStrength("Ambient Strength", Range(0.0, 2.0)) = 0.5
        [Sub(Toon)] _RampTint("Ramp Tint", Color) = (1,1,1,1)
        [Sub(Toon)] _RampShadowColor("Shadow Color (无贴图时)", Color) = (0.35,0.40,0.55,1)
        [Sub(Toon)] _RampLightColor("Light Color (无贴图时)", Color) = (1,1,1,1)
        // ---- 阴影遮罩化（不使用屏幕空间阴影时的替代方案）----
        [Sub(Toon)] _ShadowRampFloor("Shadow Min Ramp (0=纯黑, 1=不压暗)", Range(0.0, 1.0)) = 0.25
        [Sub(Toon)] _ShadowTint("Shadow Tint (暗部染色)", Color) = (1, 0.85, 0.85, 1)

        [SubToggle(Toon, _RAMP_MAP)] _UseRampMap("Use Ramp Map", Float) = 0
        [Sub(Toon_RAMP_MAP)] [NoScaleOffset] _RampMap("Ramp Map (纵轴=色阶)", 2D) = "white" {}

        // ------------------------------------------------------------
        // 脸部 SDF（移植自原 NPR 的 _ISFACE_ON 分支）
        // ------------------------------------------------------------
        [Main(Face, _, on, off)] _FaceGroup("Face SDF", Float) = 1
        [SubToggle(Face, _ISFACE_ON)] _IsFace("Is Face", Float) = 0
        [Sub(Face_ISFACE_ON)] [NoScaleOffset] _FaceLightMap("Face Light Map (R:主 SDF  G:次 SDF)", 2D) = "white" {}
        [Sub(Face_ISFACE_ON)] _FaceRight("Face Right (世界空间)", Vector) = (0,-1,0,0)
        [Sub(Face_ISFACE_ON)] _FaceForward("Face Forward (世界空间)", Vector) = (-1,0,0,0)
        [Sub(Face_ISFACE_ON)] _FaceSDFSoftness("SDF Softness", Range(0.001, 1.0)) = 0.2
        [Sub(Face_ISFACE_ON)] _FaceSDFOffset("SDF Offset", Range(-1.0, 1.0)) = 0.0
        // ---- 脸部接收实时阴影的强度：0 = 脸完全不吃实时阴影（去掉刘海硬影）----
        [Sub(Face_ISFACE_ON)] _FaceShadowStrength("Face Shadow Strength (0=脸不吃实时阴影)", Range(0.0, 1.0)) = 0.5
        [SubToggle(Face, _FACEPOINT_ON)] _UseFaceShadowPoint("整脸共享阴影坐标", Float) = 0
        [HideInInspector] _FaceShadowPosWS("_FaceShadowPosWS", Vector) = (0,0,0,0)

        // ------------------------------------------------------------
        // 头发光带（N·V）
        // ------------------------------------------------------------
        [Main(Hair, _, on, off)] _HairGroup("Hair Highlight", Float) = 1
        [SubToggle(Hair, _ISHAIR_ON)] _IsHair("Is Hair", Float) = 0
        [Sub(Hair_ISHAIR_ON)] _HairHighlightPower("Highlight Power", Range(1.0, 64.0)) = 8.0
        [Sub(Hair_ISHAIR_ON)] _HairHighlightBias("Highlight Bias", Range(-1.0, 1.0)) = 0.0
        [Sub(Hair_ISHAIR_ON)] _HairHighlightScale("Highlight Scale", Range(0.0, 50.0)) = 0.6
        // ---- 刘海高光 mask：_M 的 B 通道（对应参考 URP_NPR 的 m.b）----
        [Sub(Hair_ISHAIR_ON)] [NoScaleOffset] _M("Hair Light Mask (B)", 2D) = "white" {}

        // ------------------------------------------------------------
        // 卡通高光
        // ------------------------------------------------------------
        [Main(Specular, _, on, off)] _SpecularGroup("Toon Specular", Float) = 1
        [SubToggle(Specular, _TOONSPEC_ON)] _UseToonSpecular("Enable Toon Specular", Float) = 1
        [Sub(Specular)] _SpecColor("Specular Color", Color) = (0.5,0.5,0.5,1)
        [KWEnum(Specular, Color, _SPECULAR_COLOR, Map, _SPECGLOSSMAP)] _SpecSource("Specular Source", Float) = 0
        [Tex(Specular_SPECGLOSSMAP)] _SpecGlossMap("Specular Map", 2D) = "white" {}
        [SubToggle(Specular, _GLOSSINESS_FROM_BASE_ALPHA)] _SmoothnessSource("Smoothness From Base Alpha", Float) = 0
        [Sub(Specular_TOONSPEC_ON)] _ToonSpecColor("Toon Spec Color", Color) = (1,1,1,1)
        [Sub(Specular_TOONSPEC_ON)] _ToonSpecIntensity("Spec Intensity", Range(0.0, 4.0)) = 1.0
        [Sub(Specular_TOONSPEC_ON)] _ToonSpecPower("Spec Power", Range(1.0, 256.0)) = 48.0
        [Sub(Specular_TOONSPEC_ON)] _ToonSpecThreshold("Spec Threshold", Range(0.0, 1.0)) = 0.3
        [Sub(Specular_TOONSPEC_ON)] _ToonSpecSmoothness("Spec Edge Softness", Range(0.001, 0.5)) = 0.05

        // ------------------------------------------------------------
        // MatCap
        // ------------------------------------------------------------
        [Main(MatCap, _, on, off)] _MatCapGroup("MatCap", Float) = 1
        [SubToggle(MatCap, _MATCAP_ON)] _UseMatCap("Enable MatCap", Float) = 0
        [Sub(MatCap_MATCAP_ON)] [NoScaleOffset] _MatCap("MatCap", 2D) = "black" {}
        [Sub(MatCap_MATCAP_ON)] _MatCapIntensity("MatCap Intensity", Range(0.0, 2.0)) = 1.0
        [Sub(MatCap_MATCAP_ON)] _MatCapWeight("MatCap Weight (0=PBR 1=MatCap)", Range(0.0, 1.0)) = 1.0

        // ------------------------------------------------------------
        // 边缘光
        // ------------------------------------------------------------
        [Main(Rim, _, on, off)] _RimGroup("Rim Light", Float) = 1
        [SubToggle(Rim, _RIM_ON)] _UseRim("Enable Rim", Float) = 0
        [Sub(Rim_RIM_ON)] _RimColor("Rim Color", Color) = (1,1,1,1)
        [Sub(Rim_RIM_ON)] _RimPower("Rim Power", Range(1.0, 16.0)) = 4.0
        [Sub(Rim_RIM_ON)] _RimIntensity("Rim Intensity", Range(0.0, 4.0)) = 0.5
        [Sub(Rim_RIM_ON)] _RimThreshold("Rim Threshold", Range(0.0, 1.0)) = 0.6
        [Sub(Rim_RIM_ON)] _RimSmoothness("Rim Softness", Range(0.001, 0.5)) = 0.1

        // ------------------------------------------------------------
        // 描边（外轮廓，inverted hull）
        // ------------------------------------------------------------
        [Main(Outline, _, on, off)] _OutlineGroup("Outline", Float) = 1
        [SubToggle(Outline, _ENABLE_OUTLINE)] _EnableOutline("Enable Outline", Float) = 0
        [Sub(Outline_ENABLE_OUTLINE)] _OutlineColor("Outline Color", Color) = (0,0,0,1)
        [Sub(Outline_ENABLE_OUTLINE)] _OutlineWidth("Outline Width (% 屏幕高度)", Range(0.0, 10.0)) = 1.0

        // ------------------------------------------------------------
        // 法线（只用于高光/MatCap，不影响明暗阶梯）
        // ------------------------------------------------------------
        [Main(Normal, _, on, off)] _NormalGroup("Normal", Float) = 1
        [SubToggle(Normal, _NORMALMAP)] _EnableNormalMap("Enable Normal Map", Float) = 1
        [Tex(Normal_NORMALMAP)] _BumpMap("Normal Map", 2D) = "bump" {}

        // ------------------------------------------------------------
        // 自发光
        // ------------------------------------------------------------
        [Main(Emission, _, on, off)] _EmissionGroup("Emission", Float) = 1
        [SubToggle(Emission, _EMISSION)] _EnableEmission("Enable Emission", Float) = 0
        [Tex(Emission_EMISSION, _EmissionColor)] _EmissionMap("Emission Map", 2D) = "white" {}
        [HideInInspector] [HDR] _EmissionColor("Emission Color", Color) = (0,0,0,1)
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

        // ===================================================================
        //  Pass 1: 描边（SRPDefaultUnlit + Cull Front 的 inverted hull）
        // ===================================================================
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
            Offset 1, 1

            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex OutlineVertex
            #pragma fragment OutlineFragment
            #pragma shader_feature_local _ENABLE_OUTLINE

            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/Shaders/NPRToonInput.hlsl"

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

                float4 positionCS = TransformObjectToHClip(input.positionOS.xyz);

                #ifdef _ENABLE_OUTLINE
                    // 观察空间法线：把顶点沿"屏幕投影方向"往外推
                    float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                    float3 normalVS = TransformWorldToViewDir(normalWS);

                    // 在 NDC 里等宽：x/y 分别按屏幕宽高归一化后再归一化方向，
                    // 这样横竖屏、宽银幕下描边粗细都一致。
                    float2 dir = float2(normalVS.x / _ScreenParams.x,
                                        normalVS.y / _ScreenParams.y);
                    float  d2  = dot(dir, dir);
                    dir = (d2 > 1.0e-12) ? dir * rsqrt(d2) : float2(0.0, 0.0);

                    // 乘 positionCS.w -> 透视除法后 NDC 偏移恒定，
                    // 也就是"不管远近，描边都是同样的屏幕宽度"。
                    positionCS.xy += dir * (_OutlineWidth * 0.01) * positionCS.w;
                #endif

                output.positionCS = positionCS;
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

        // ===================================================================
        //  Pass 2: 主光照
        // ===================================================================
        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Blend[_SrcBlend][_DstBlend], [_SrcBlendAlpha][_DstBlendAlpha]
            ZWrite[_ZWrite]
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex LitPassVertexSimple
            #pragma fragment LitPassFragmentSimple

            // ---- Material Keywords ----
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF
            #pragma shader_feature_local_fragment _SURFACE_TYPE_TRANSPARENT
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ _ALPHAPREMULTIPLY_ON _ALPHAMODULATE_ON
            #pragma shader_feature_local_fragment _ _SPECGLOSSMAP _SPECULAR_COLOR
            #pragma shader_feature_local_fragment _GLOSSINESS_FROM_BASE_ALPHA

            // ---- NPR 功能开关 ----
            #pragma shader_feature_local_fragment _ _RAMP_MAP
            #pragma shader_feature_local_fragment _ _ISFACE_ON
            #pragma shader_feature_local_fragment _ _FACEPOINT_ON
            #pragma shader_feature_local_fragment _ _ISHAIR_ON
            #pragma shader_feature_local_fragment _ _TOONSPEC_ON
            #pragma shader_feature_local_fragment _ _MATCAP_ON
            #pragma shader_feature_local_fragment _ _RIM_ON

            // ---- Universal Pipeline keywords ----
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

            // ---- Unity defined keywords ----
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fog
            #pragma multi_compile_fragment _ DEBUG_DISPLAY
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #define BUMP_SCALE_NOT_SUPPORTED 1

            // ---- Includes ----
            #include "Assets/Shaders/NPRToonInput.hlsl"
            #include "Assets/Shaders/ShaderLibrary/Lighting.hlsl"        // Light / InputData / GetMainLight
            #include "Assets/Shaders/ShaderLibrary/NPRToonLighting.hlsl" // 卡通光照
            #if defined(LOD_FADE_CROSSFADE)
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

            struct Attributes
            {
                float4 positionOS    : POSITION;
                float3 normalOS      : NORMAL;
                float4 tangentOS     : TANGENT;
                float2 texcoord      : TEXCOORD0;
                float2 staticLightmapUV  : TEXCOORD1;
                float2 dynamicLightmapUV : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv                        : TEXCOORD0;
                float3 positionWS                : TEXCOORD1;

                #ifdef _NORMALMAP
                    half4 normalWS               : TEXCOORD2;
                    half4 tangentWS              : TEXCOORD3;
                    half4 bitangentWS            : TEXCOORD4;
                #else
                    half3 normalWS               : TEXCOORD2;
                #endif

                #ifdef _ADDITIONAL_LIGHTS_VERTEX
                    half4 fogFactorAndVertexLight : TEXCOORD5;
                #else
                    half  fogFactor              : TEXCOORD5;
                #endif

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    float4 shadowCoord           : TEXCOORD6;
                #endif

                DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 7);

                #ifdef DYNAMICLIGHTMAP_ON
                    float2 dynamicLightmapUV     : TEXCOORD8;
                #endif

                float4 positionCS                : SV_POSITION;
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

                // ---- 关键替换：UniversalFragmentBlinnPhong -> 卡通版本 ----
                // 第三个参数传"几何法线"（不受法线贴图影响），用于稳定明暗阶梯
                half4 color = UniversalFragmentNPRToon(inputData, surfaceData,
                                                       input.normalWS.xyz, input.uv);

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

        // ===================================================================
        //  以下 Pass 与 LitToon.shader 完全一致（URP SimpleLit 系列）
        // ===================================================================
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _GLOSSINESS_FROM_BASE_ALPHA
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #include "Assets/Shaders/NPRToonInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "GBuffer"
            Tags { "LightMode" = "UniversalGBuffer" }

            ZWrite[_ZWrite]
            ZTest LEqual
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 4.5
            #pragma exclude_renderers gles3 glcore
            #pragma vertex LitPassVertexSimple
            #pragma fragment LitPassFragmentSimple

            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ _SPECGLOSSMAP _SPECULAR_COLOR
            #pragma shader_feature_local_fragment _GLOSSINESS_FROM_BASE_ALPHA
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
            #pragma multi_compile_fragment _ _RENDER_PASS_ENABLED
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #define BUMP_SCALE_NOT_SUPPORTED 1

            #include "Assets/Shaders/NPRToonInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/SimpleLitGBufferPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }

            ZWrite On
            ColorMask R
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _GLOSSINESS_FROM_BASE_ALPHA
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #include "Assets/Shaders/NPRToonInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormals"
            Tags { "LightMode" = "DepthNormals" }

            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _GLOSSINESS_FROM_BASE_ALPHA
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #include "Assets/Shaders/NPRToonInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/SimpleLitDepthNormalsPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "Meta"
            Tags { "LightMode" = "Meta" }

            Cull Off

            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMetaSimple
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _SPECGLOSSMAP
            #pragma shader_feature EDITOR_VISUALIZATION

            #include "Assets/Shaders/NPRToonInput.hlsl"
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
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON

            #include "Assets/Shaders/NPRToonInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Utils/Universal2D.hlsl"
            ENDHLSL
        }
    }

    Fallback "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "LWGUI.LWGUI"
}
