Shader "Hong/LitCustom"
{
    Properties
    {
        // Specular vs Metallic workflow
        //[Main(Workflow)]_Workflow("Workflow",float)=1
        [Preset(LWGUI_Preset_CustomBlendMode)] _Surface("Blend Mode Preset", Float) = 0.0
        [KWEnum(_, Specular, _SPECULAR_SETUP, Metallic, _METALLIC)]
        _WorkflowMode("WorkflowMode", Float) = 1.0
        [Sub(_)] _BaseColor("Color", Color) = (1,1,1,1)
        [Sub(_)]_Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
        [Sub(__METALLIC)]_Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        [Sub(__SPECULAR_SETUP)]_SpecColor("Specular", Color) = (0.2, 0.2, 0.2)
        [Sub(_)]_OcclusionStrength("Occlusion Strength", Range(0.0, 1.0)) = 1.0

        // Blending state
        [Enum(UnityEngine.Rendering.CullMode)]_Cull("Cull", Float) = 2.0

        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", Float) = 5 // 默认 SrcAlpha
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Float) = 10 // 默认 OneMinusSrcAlpha
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlendAlpha("Src Blend Alpha", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlendAlpha("Dst Blend Alpha", Float) = 10
        
        [Toggle(_)]_ZWrite("ZWrite ", Float) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)]_ZTest("ZTest", Float) = 4 // 4 is LEqual
        [HideInInspector] _BlendModePreserveSpecular("_BlendModePreserveSpecular", Float) = 1.0
        [HideInInspector] _AlphaToMask("__alphaToMask", Float) = 0.0

        [ToggleUI] _ReceiveShadows("Receive Shadows", Float) = 1.0

        [Main(MainTeture)]_group1("MainTeture",float)=1
        [Tex(MainTeture,_BaseColor)]_BaseMap("Albedo", 2D) = "white" {}


        [Tex(MainTeture)]_ColorMaskMap("Color Mask (White:Use HSB, Black:Disable)", 2D) = "white" {}
        [Sub(MainTeture)]_HueShift("Hue Shift", Range(0.0, 1.0)) = 0.0
        [Sub(MainTeture)]_Saturation("Saturation", Range(0.0, 2.0)) = 1.0
        [Sub(MainTeture)]_Brightness("Brightness", Range(0.0, 2.0)) = 1.0

        //perlingNoise
        [Tex(MainTeture)]_NoiseTex("Noise Texture", 2D) = "white" {}
        [Sub(MainTeture)]_TilingSpeed("Tiling Speed", vector) = (1,1,0,0)
        [Sub(VertexAnima)]_WarpStrength("Warp Strength", Float) = 0.1

        [SubToggle(MainTeture,_ALPHATEST_ON)] _AlphaTest("Alpha Test", Float) = 0
        [Sub(MainTeture_ALPHATEST_ON)] _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        [Space]
        [SubToggle(MainTeture,_NORMALMAP)]_EnableNormalMap("Enable Normal Map",float)=0
        [Tex(MainTeture_NormalMap,_BumpScale)]_BumpMap("Normal Map", 2D) = "bump" {}
        [HideInInspector]_BumpScale("Scale", Range(0.0, 5.0)) = 1.0

        [SubToggle(MainTeture,_PBRMAP)]_EnablePBRMap("Enable PBR Map",float)=0
        [Tex(MainTeture_PBRMAP)]_PBRMap("PBR Map (R:Metallic, G:Smoothness, B:Occlusion)", 2D) = "white" {}

        [SubToggle(MainTeture,_PARALLAXMAP)]_EnableParallaxMap("Enable Parallax Map",float)=0
        [HideInInspector]_Parallax("Scale", Range(0.005, 0.08)) = 0.005
        [Tex(MainTeture_PARALLAXMAP,_Parallax)]_ParallaxMap("Height Map", 2D) = "black" {}

        [SubToggle(MainTeture,_EMISSION)] _Enable_Emission("Enable Emission", Float) = 0
        [HideInInspector][HDR] _EmissionColor("Color", Color) = (0,0,0)
        [Tex(MainTeture_EMISSION,_EmissionColor)]_EmissionMap("Emission", 2D) = "white" {}
        [SubToggle(MainTeture,_ENABLERIM)]_EnableRim("Enable Rim", Float) = 1
        [Sub(MainTeture_ENABLERIM)]_RimScale("Rim Scale", Float) = 1
        [Sub(MainTeture_ENABLERIM)]_RimLightness("Rim Lightness", Range(0.0, 10.0)) = 1

        [Space]
        //顶点混合
        [Main(LayerBlend)] _EnableLayerBlend("Layer blend", Float) = 1
        //混合顶点颜色R
        [Tex(LayerBlend,_LayerColorR)]_LayerMapR("BlendMap01", 2D) = "white" {}
        [HideInInspector]_LayerColorR("Color", Color) = (1,1,1,1)
        [Sub(LayerBlend)]_HueShiftLayerR("Hue Shift", Range(0.0, 1.0)) = 0.0
        [Sub(LayerBlend)]_SaturationLayerR("Saturation", Range(0.0, 2.0)) = 1.0
        [Sub(LayerBlend)]_BrightnessLayerR("Brightness", Range(0.0, 2.0)) = 1.0
        //顶点色R混合法线
        [HideInInspector]_BumpScaleLayerR("Scale", Float) = 1.0
        [Tex(LayerBlend,_BumpScaleLayerR)]_BumpMapLayerR("Normal Map", 2D) = "bump" {}
        //顶点色R混合PBR
        [Tex(LayerBlend)]_PBRMaLayerR("PBR Map (R:Metallic, G:Smoothness, B:Occlusion)", 2D) = "white" {}
        [Sub(LayerBlend)]_SmoothnessLayerR("Smoothness", Range(0.0, 1.0)) = 0.5
        [Sub(LayerBlend)]_MetallicLayerR("Metallic", Range(0.0, 1.0)) = 0.0
        [Sub(LayerBlend)]_SpecColorLayerR("Specular", Color) = (0.2, 0.2, 0.2)
        [Sub(LayerBlend)]_OcclusionStrengthLayerR("Strength", Range(0.0, 1.0)) = 1.0

        //混合顶点颜色G
        [SubToggle(LayerBlend,_ENABLE_LAYER_BLEDN_LAYER02)] _EnableLayerBlendLayer02("Enable layer blend layer02", Float) = 0
        [Tex(LayerBlend_ENABLE_LAYER_BLEDN_LAYER02,_LayerColorG)] _LayerMapG("BlendMap02", 2D) = "white" {}
        [HideInInspector] _LayerColorG("Color", Color) = (1,1,1,1)
        [Sub(LayerBlend_ENABLE_LAYER_BLEDN_LAYER02)] _HueShiftLayerG("Hue Shift", Range(0.0, 1.0)) = 0.0
        [Sub(LayerBlend_ENABLE_LAYER_BLEDN_LAYER02)] _SaturationLayerG("Saturation", Range(0.0, 2.0)) = 1.0
        [Sub(LayerBlend_ENABLE_LAYER_BLEDN_LAYER02)] _BrightnessLayerG("Brightness", Range(0.0, 2.0)) = 1.0
        //顶点色G混合法线
        [HideInInspector]_BumpScaleLayerG("Scale", Float) = 1.0
        [Tex(LayerBlend_ENABLE_LAYER_BLEDN_LAYER02,_BumpScaleLayerG)] _BumpMapLayerG("Normal Map", 2D) = "bump" {}
        //顶点色G混合PBR
        [Tex(LayerBlend_ENABLE_LAYER_BLEDN_LAYER02)]_PBRMaLayerG("PBR Map (R:Metallic, G:Smoothness, B:Occlusion)", 2D) = "white" {}
        [Sub(LayerBlend_ENABLE_LAYER_BLEDN_LAYER02)]_SmoothnessLayerG("Smoothness", Range(0.0, 1.0)) = 0.5
        [Sub(LayerBlend_ENABLE_LAYER_BLEDN_LAYER02)]_MetallicLayerG("Metallic", Range(0.0, 1.0)) = 0.0
        [Sub(LayerBlend_ENABLE_LAYER_BLEDN_LAYER02)]_SpecColorLayerG("Specular", Color) = (0.2, 0.2, 0.2)
        [Sub(LayerBlend_ENABLE_LAYER_BLEDN_LAYER02)]_OcclusionStrengthLayerG("Strength", Range(0.0, 1.0)) = 1.0

        //混合顶点颜色B
        [SubToggle(LayerBlend,_ENABLE_LAYER_BLEDN_LAYER03)] _EnableLayerBlendLayer03("Enable layer blend layer03", Float) = 0
        [Tex(LayerBlend_ENABLE_LAYER_BLEDN_LAYER03,_LayerColorB)]_LayerMapB("BlendMap03", 2D) = "white" {}
        [HideInInspector]_LayerColorB("Color", Color) = (1,1,1,1)
        [Sub(LayerBlend_ENABLE_LAYER_BLEDN_LAYER03)]_HueShiftLayerB("Hue Shift", Range(0.0, 1.0)) = 0.0
        [Sub(LayerBlend_ENABLE_LAYER_BLEDN_LAYER03)]_SaturationLayerB("Saturation", Range(0.0, 2.0)) = 1.0
        [Sub(LayerBlend_ENABLE_LAYER_BLEDN_LAYER03)]_BrightnessLayerB("Brightness", Range(0.0, 2.0)) = 1.0
        //顶点色G混合法线
        [HideInInspector]_BumpScaleLayerB("Scale", Float) = 1.0
        [Tex(LayerBlend_ENABLE_LAYER_BLEDN_LAYER03,_BumpScaleLayerB)]_BumpMapLayerB("Normal Map", 2D) = "bump" {}
        //顶点色G混合PBR
        [Tex(LayerBlend_ENABLE_LAYER_BLEDN_LAYER03)]_PBRMaLayerB("PBR Map (R:Metallic, G:Smoothness, B:Occlusion)", 2D) = "white" {}
        [Sub(LayerBlend_ENABLE_LAYER_BLEDN_LAYER03)]_SmoothnessLayerB("Smoothness", Range(0.0, 1.0)) = 0.5
        [Sub(LayerBlend_ENABLE_LAYER_BLEDN_LAYER03)]_MetallicLayerB("Metallic", Range(0.0, 1.0)) = 0.0
        [Sub(LayerBlend_ENABLE_LAYER_BLEDN_LAYER03)]_SpecColorLayerB("Specular", Color) = (0.2, 0.2, 0.2)
        [Sub(LayerBlend_ENABLE_LAYER_BLEDN_LAYER03)]_OcclusionStrengthLayerB("Strength", Range(0.0, 1.0)) = 1.0

        //混合顶点颜色AA
        [SubToggle(LayerBlend,_ENABLE_LAYER_BLEDN_LAYER04)] _EnableLayerBlendLayer04("Enable layer blend layer04", Float) = 0
        [Tex(LayerBlend_ENABLE_LAYER_BLEDN_LAYER04,_LayerColorA)]_LayerMapA("BlendMap04", 2D) = "white" {}
        [HideInInspector]_LayerColorA("Color", Color) = (1,1,1,1)
        [Sub(LayerBlend_ENABLE_LAYER_BLEDN_LAYER04)] _HueShiftLayerA("Hue Shift", Range(0.0, 1.0)) = 0.0
        [Sub(LayerBlend_ENABLE_LAYER_BLEDN_LAYER04)]_SaturationLayerA("Saturation", Range(0.0, 2.0)) = 1.0
        [Sub(LayerBlend_ENABLE_LAYER_BLEDN_LAYER04)]_BrightnessLayerA("Brightness", Range(0.0, 2.0)) = 1.0
        //顶点色G混合法线
        [HideInInspector]_BumpScaleLayerA("Scale", Float) = 1.0
        [Tex(LayerBlend_ENABLE_LAYER_BLEDN_LAYER04,_BumpScaleLayerA)]_BumpMapLayerA("Normal Map", 2D) = "bump" {}
        //顶点色G混合PBR
        [Tex(LayerBlend_ENABLE_LAYER_BLEDN_LAYER04)]_PBRMaLayerA("PBR Map (R:Metallic, G:Smoothness, B:Occlusion)", 2D) = "white" {}
        [Sub(LayerBlend_ENABLE_LAYER_BLEDN_LAYER04)]_SmoothnessLayerA("Smoothness", Range(0.0, 1.0)) = 0.5
        [Sub(LayerBlend_ENABLE_LAYER_BLEDN_LAYER04)]_MetallicLayerA("Metallic", Range(0.0, 1.0)) = 0.0
        [Sub(LayerBlend_ENABLE_LAYER_BLEDN_LAYER04)]_SpecColorLayerA("Specular", Color) = (0.2, 0.2, 0.2)
        [Sub(LayerBlend_ENABLE_LAYER_BLEDN_LAYER04)]_OcclusionStrengthLayerA("Strength", Range(0.0, 1.0)) = 1.0

        //顶点动画功能
        [Main(VertexAnima)]_VertexAnima("Vertex Anima",float)=1
        [SubToggle(VertexAnima,_VERTEXANIMA)]_EnableVertexAnima("Enable Vertex Anima",float)=1
        [Sub(VertexAnima_VERTEXANIMA)]_AnimaTilingSpeed("Anima Tiling Speed", vector) = (1,1,0,0)
        [Sub(VertexAnima_VERTEXANIMA)]_AnimaWarpStrength("_Anima Warp Strength", Float) = 0.1

        // 卡通描边功能
        [Main(Outline)]_Outline("Outline",float)=1
        [SubToggle(Outline,_ENABLE_OUTLINE)] _EnableOutline("Enable Outline", Float) = 0
        [Sub(Outline_ENABLE_OUTLINE)]_OutlineColor("Outline Color", Color) = (0,0,0,1)
        [Sub(Outline_ENABLE_OUTLINE)]_OutlineWidth("Outline Width", Range(0.0, 10)) = 0.03

        // ObsoleteProperties
        [HideInInspector] _MainTex("BaseMap", 2D) = "white" {}
        [HideInInspector] _Color("Base Color", Color) = (1, 1, 1, 1)
        [HideInInspector] _GlossMapScale("Smoothness", Float) = 0.0
        [HideInInspector] _Glossiness("Smoothness", Float) = 0.0
        [HideInInspector] _GlossyReflections("EnvironmentReflections", Float) = 0.0

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
            "UniversalMaterialType" = "Lit"
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

            #include "Assets/Shaders/LitInput.hlsl"
            
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

            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            Cull[_Cull]
            AlphaToMask[_AlphaToMask]

            HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PBRMAP
            #pragma shader_feature_local _COLORMASKMAP
            #pragma shader_feature_local _CUTOFF_ON
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF
            //顶点动画开关
            #pragma shader_feature_local  _VERTEXANIMA
            #pragma shader_feature_local_fragment _SURFACE_TYPE_TRANSPARENT
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ _ALPHAPREMULTIPLY_ON _ALPHAMODULATE_ON
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _ENABLERIM
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local_fragment _SPECULAR_SETUP
            #pragma shader_feature_local_fragment _METALLIC
            // 添加颜色调整功能开关
            #pragma shader_feature_local_fragment _COLOR_ADJUST 

            //顶点混合的总开关
            #pragma shader_feature_local_fragment _ENABLE_LAYER_BLEDN
            //顶点混合02层开关
            #pragma shader_feature_local_fragment _ENABLE_LAYER_BLEDN_LAYER02
            //顶点混合03层开关
            #pragma shader_feature_local_fragment _ENABLE_LAYER_BLEDN_LAYER03
            //顶点混合04层开关
            #pragma shader_feature_local_fragment _ENABLE_LAYER_BLEDN_LAYER04




            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _LIGHT_LAYERS
            #pragma multi_compile _ _FORWARD_PLUS
            #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_fog
            #pragma multi_compile_fragment _ DEBUG_DISPLAY

            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"

      
     
            #include "Assets/Shaders/ShaderLibrary/Lighting.hlsl"
            #include "Assets/Shaders/LitInput.hlsl"

            #if defined(LOD_FADE_CROSSFADE)
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

            #if defined(_PARALLAXMAP) && !defined(SHADER_API_GLES)
            #define REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR
            #endif

            #if (defined(_NORMALMAP) || (defined(_PARALLAXMAP) && !defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)))
            #define REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR
            #endif

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 texcoord     : TEXCOORD0;
                float4 color        : COLOR;        // 添加顶点颜色
                float2 staticLightmapUV   : TEXCOORD1;
                float2 dynamicLightmapUV  : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv                       : TEXCOORD0;

            #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                float3 positionWS               : TEXCOORD1;
            #endif

                float3 normalWS                 : TEXCOORD2;
            #if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
                half4 tangentWS                : TEXCOORD3;    // xyz: tangent, w: sign
            #endif
            
            #ifdef ENABLE_LAYER_BLEDN
            float4 vertexColor              : TEXCOORD4;  // 添加顶点颜色
            #endif

            #ifdef _ADDITIONAL_LIGHTS_VERTEX
                half4 fogFactorAndVertexLight   : TEXCOORD5; // x: fogFactor, yzw: vertex light
            #else
                half  fogFactor                 : TEXCOORD5;
            #endif

            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                float4 shadowCoord              : TEXCOORD6;
            #endif

            #if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
                half3 viewDirTS                : TEXCOORD7;
            #endif

                DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 8);
            #ifdef DYNAMICLIGHTMAP_ON
                float2  dynamicLightmapUV : TEXCOORD9; // Dynamic lightmap UVs
            #endif


                float4 positionCS               : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData)
            {
                inputData = (InputData)0;

            #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                inputData.positionWS = input.positionWS;
            #endif

                half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
            #if defined(_NORMALMAP)
                float sgn = input.tangentWS.w;      // should be either +1 or -1
                float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                half3x3 tangentToWorld = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);

                inputData.tangentToWorld = tangentToWorld;
                inputData.normalWS = TransformTangentToWorld(normalTS, tangentToWorld);
            #else
                inputData.normalWS = input.normalWS;
            #endif

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

            Varyings LitPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                #ifdef _VERTEXANIMA
                    //扭曲和顶点动画相关
                    // 使用对象空间位置和法线（保证物体移动时纹理不会在表面滑动）
                    float3 posOS = input.positionOS.xyz;
                    float3 normalOS = input.normalOS;
                    // 提取 Tiling 和 Speed (假设 xy 是 Tiling，zw 是速度)
                    float2 tiling = _AnimaTilingSpeed.xy; 
                    float2 speed = _Time.y * _AnimaTilingSpeed.zw;
                    //计算三个平面的 UV
                    float2 uvX = posOS.zy * tiling + speed;
                    float2 uvY = posOS.xz * tiling + speed;
                    float2 uvZ = posOS.xy * tiling + speed;
                    //采样三个平面的噪声值 (使用 LOD 0)
                    half texX = SAMPLE_TEXTURE2D_LOD(_NoiseTex, sampler_NoiseTex, uvX, 0).r;
                    half texY = SAMPLE_TEXTURE2D_LOD(_NoiseTex, sampler_NoiseTex, uvY, 0).r;
                    half texZ = SAMPLE_TEXTURE2D_LOD(_NoiseTex, sampler_NoiseTex, uvZ, 0).r;
                    //计算混合权重 (基于法线方向)
                    // 取绝对值，并用 pow 增加对比度，让平面过渡更锐利（可根据需要调整 4.0）
                    float3 blendWeights = pow(abs(normalOS), 4.0);
                    // 归一化权重
                    blendWeights /= (blendWeights.x + blendWeights.y + blendWeights.z);
                    //混合噪声值
                    half noiseValue = texX * blendWeights.x + texY * blendWeights.y + texZ * blendWeights.z;
                    //应用位移
                    half displacement = (noiseValue - 0.5) * _AnimaWarpStrength;
                    input.positionOS.xyz += input.normalOS * displacement;
                    //顶点动画结束
                #endif

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);

            #ifdef ENABLE_LAYER_BLEDN
                output.vertexColor = input.color;
            #endif

                half fogFactor = 0;
                #if !defined(_FOG_FRAGMENT)
                    fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
                #endif

                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.normalWS = normalInput.normalWS;
                
            #if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR) || defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
                real sign = input.tangentOS.w * GetOddNegativeScale();
                half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
            #endif
            #if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
                output.tangentWS = tangentWS;
            #endif

            #if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
                half3 viewDirWS = GetWorldSpaceNormalizeViewDir(vertexInput.positionWS);
                half3 viewDirTS = GetViewDirectionTangentSpace(tangentWS, output.normalWS, viewDirWS);
                output.viewDirTS = viewDirTS;
            #endif

                OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
            #ifdef DYNAMICLIGHTMAP_ON
                output.dynamicLightmapUV = input.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
            #endif
            
            #ifdef _ADDITIONAL_LIGHTS_VERTEX
                output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
            #else
                output.fogFactor = fogFactor;
            #endif

            #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                output.positionWS = vertexInput.positionWS;
            #endif

            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                output.shadowCoord = GetShadowCoord(vertexInput);
            #endif

                output.positionCS = vertexInput.positionCS;

                return output;
            }

            void LitPassFragment(
                Varyings input
                , out half4 outColor : SV_Target0
            #ifdef _WRITE_RENDERING_LAYERS
                , out float4 outRenderingLayers : SV_Target1
            #endif
            )
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);

            #if defined(_PARALLAXMAP)
            #if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
                half3 viewDirTS = input.viewDirTS;
            #else
                half3 viewDirTS = GetViewDirectionTangentSpace(input.tangentWS, input.normalWS, viewDirWS);
            #endif
                ApplyPerPixelDisplacement(viewDirTS, input.uv);
            #endif
                float4 vertexColor = float4(0,0,0,0);
            #ifdef ENABLE_LAYER_BLEDN
                float4 vertexColor = input.vertexColor;
            #endif

                SurfaceData surfaceData;
                InitializeStandardLitSurfaceData(input.uv,vertexColor, surfaceData);

            #ifdef LOD_FADE_CROSSFADE
                LODFadeCrossFade(input.positionCS);
            #endif

                InputData inputData;
                InitializeInputData(input, surfaceData.normalTS, inputData);
                SETUP_DEBUG_TEXTURE_DATA(inputData, input.uv, _BaseMap);

            #ifdef _DBUFFER
                ApplyDecalToSurfaceData(input.positionCS, surfaceData, inputData);
            #endif

            //有一些需要靠后计算的放这里
            #if _ENABLERIM
                // 此时 inputData.normalWS 已经包含了法线贴图的效果
                float3 N = inputData.normalWS;
                float3 V = inputData.viewDirectionWS;
                
                half NdotV = saturate(dot(N, V));
                // 这里的 3.0 控制边缘光的粗细，你可以把它改成属性暴露出来
                half rim = pow(1.0 - NdotV, _RimScale) *_RimLightness; 
                
                // 叠加到自发光通道（如果你之前设置了 _RimScale）
                surfaceData.emission *= rim; 
            #endif


                half4 color = UniversalFragmentPBR(inputData, surfaceData);
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

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #include "Assets/Shaders/LitInput.hlsl"
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

            ZWrite[_ZWrite]
            ZTest LEqual
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 4.5

            #pragma exclude_renderers gles3 glcore

            #pragma vertex LitGBufferPassVertex
            #pragma fragment LitGBufferPassFragment

            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local_fragment _COLOR_ADJUST

            #pragma shader_feature_local_fragment _SPECULAR_SETUP
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile_fragment _ _RENDER_PASS_ENABLED
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT

            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #include "Assets/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitGBufferPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            ZWrite On
            ColorMask R
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #include "Assets/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #include "Assets/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }

            Cull Off

            HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMetaLit

            #pragma shader_feature_local_fragment _SPECULAR_SETUP
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local_fragment _COLOR_ADJUST
            #pragma shader_feature EDITOR_VISUALIZATION
            

            #include "Assets/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitMetaPass.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "Universal2D"
            Tags
            {
                "LightMode" = "Universal2D"
            }

            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local_fragment _COLOR_ADJUST

            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #include "Assets/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Utils/Universal2D.hlsl"
            ENDHLSL
        }
        
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    //CustomEditor "UnityEditor.Rendering.Universal.ShaderGUI.LitShaderCustom"
    CustomEditor "LWGUI.LWGUI"
}