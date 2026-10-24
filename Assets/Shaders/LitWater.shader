Shader "Hong/LitWater"
{
    Properties
    {
        [Preset(LWGUI_Preset_CustomBlendMode)] _Surface("Blend Mode Preset", Float) = 1 
        [KWEnum(_, Specular, _SPECULAR_SETUP)]
        _WorkflowMode("WorkflowMode", Float) = 0
        
        //基础
        [Sub(_)] _BaseColor("Color", Color) = (1,1,1,1)
        [Sub(_)]_Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
        [Sub(_)]_SpecColor("Specular", Color) = (0.2, 0.2, 0.2)
        [HideInInspector]_OcclusionStrength("Occlusion Strength", Range(0.0, 1.0)) = 1.0
        [HideInInspector] _Metallic("Metallic", Float) = 0.0

        // Blending state
        [Enum(UnityEngine.Rendering.CullMode)]_Cull("Cull", Float) = 2.0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", Float) = 5 
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Float) = 10 
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlendAlpha("Src Blend Alpha", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlendAlpha("Dst Blend Alpha", Float) = 10
        [Toggle(_)]_ZWrite("ZWrite ", Float) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)]_ZTest("ZTest", Float) = 4 
        [HideInInspector] _BlendModePreserveSpecular("_BlendModePreserveSpecular", Float) = 1.0
        [HideInInspector] _AlphaToMask("__alphaToMask", Float) = 0.0

        [ToggleUI] _ReceiveShadows("Receive Shadows", Float) = 1.0

        [Main(MainTeture)]_group1("MainTeture",float)=1
        [Tex(MainTeture,_BaseColor)]_BaseMap("Albedo", 2D) = "white" {}
        [SubToggle(MainTeture,_NORMALMAP)] _EnableNormalMap("Enable Normal Map", float) = 1
        [Tex(MainTeture_NORMALMAP,_BumpScale)]_BumpMap("Normal Map", 2D) = "bump" {}
        [HideInInspector]_BumpScale("Normal Intensity", Range(0, 2)) = 1
        [Sub(MainTeture)]_NormalTiling("Normal Tiling", float) = 1
        
        [HideInInspector] _AlphaTest("Alpha Test", Float) = 0
        [HideInInspector] _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        [HideInInspector] _Enable_Emission("Enable Emission", Float) = 0
        [HideInInspector] _EmissionColor("Color", Color) = (0,0,0)
        [HideInInspector]_EmissionMap("Emission", 2D) = "white" {}


        // MatCap
        [SubToggle(MainTeture,_MATCAP_ON)] _EnableMatcap("Enable Matcap", Float) = 0
        [Tex(MainTeture_MATCAP_ON)] _MatcapTex("Matcap Tex", 2D) = "black" {}
        [Sub(MainTeture_MATCAP_ON)] _MatcapIntensity("Matcap Intensity", Range(0.0, 32.0)) = 1.0
        [Sub(MainTeture_MATCAP_ON)] _MatcapScale("Matcap Scale", Float) = 1.0
        [Sub(MainTeture_MATCAP_ON)] _MatcapOffset("Matcap Offset", Vector) = (0,0,0,0)

                // --- 水面特效组 ---
        [Main(WaterSettings)] _WaterSettings("Water Settings", Float) = 1
        
        // 深度与颜色
        [Sub(WaterSettings)] _ShallowWater("Shallow Color", Color) = (1.0, 1.0, 1.0, 1.0)
        [Sub(WaterSettings)] _DeepWater("Deep Color", Color) = (1.0, 1.0, 1.0, 1.0)
        [Sub(WaterSettings)] _DepthDistance("Depth Distance", Range(0,10)) = 2
        [Sub(WaterSettings)] _DepthFogDistance("Depth Fog Distance", Range(0,100)) = 20
        [Sub(WaterSettings)] _Refraction("Refraction", Float) = 1.0

        //泡沫
        [SubToggle(WaterSettings,_ENABLEFOAM)] _EnableFoam("Enable Foam", Float) = 0
        [Sub(WaterSettings_ENABLEFOAM)] _FoamWidth("Foam Width", Range(0, 2)) = 0.5
        [Sub(WaterSettings_ENABLEFOAM)] _FoamThreshold("Foam Threshold", Range(0, 1)) = 1
        [Sub(WaterSettings_ENABLEFOAM)] _FoamTiling("Foam Tiling", Float) = 1.0
        [Sub(WaterSettings_ENABLEFOAM)] _FoamWaveScale("Foam Wave Scale", Range(0, 1)) = 1.0
        [Sub(WaterSettings_ENABLEFOAM)] _FoamWaveNumber("Foam Wave Number", Range(0, 3)) = 2

        // 焦散 (Caustic)
        [Tex(WaterSettings)] _CausticTexture("Caustic Texture", 2D) = "black" {}
        [Sub(WaterSettings)] _CausticIntensity("Caustic Intensity", Range(0, 10)) = 1.0
        [Sub(WaterSettings)] _CausticScale("Caustic Scale", Float) = 1.0
        [Sub(WaterSettings)] _CausticSpeed("Caustic Speed", Float) = 0.1
        
        // 流动贴图
        [Tex(WaterSettings)] _FlowMap("Flow (RG, A noise)", 2D) = "black" {}
        [Sub(WaterSettings)] _UJump("U Jump", Range(-0.25, 0.25)) = 0.25
        [Sub(WaterSettings)] _VJump("V Jump", Range(-0.25, 0.25)) = 0.25
        [Sub(WaterSettings)] _FlowMapTiling("Flow Tiling", Float) = 1
        [Sub(WaterSettings)] _Speed("Flow Speed", Float) = 1
        [Sub(WaterSettings)] _FlowStrength("Flow Strength", Float) = 1
        [Sub(WaterSettings)] _DistortStrength("Distort Refraction Strength", Float) = 0.05
        
        // 顶点波浪
        [Sub(WaterSettings)] _WaveA("Wave A (dirX, dirY, steepness, wavelength)", Vector) = (1,0,0.5,10)
        [Sub(WaterSettings)] _WaveB("Wave B", Vector) = (0,1,0.25,20)

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
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
            "UniversalMaterialType" = "Lit"
            "IgnoreProjector" = "True"
        }
        LOD 300 

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            Cull[_Cull]
            AlphaToMask[_AlphaToMask]

            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _MATCAP_ON
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ _ALPHAPREMULTIPLY_ON _ALPHAMODULATE_ON
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _SURFACE_TYPE_TRANSPARENT
            #pragma shader_feature_local_fragment _SPECULAR_SETUP
            #pragma shader_feature_local_fragment _ENABLEFOAM

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fog

            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl" // 加入深度图声明
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl" // 加入不透明图声明用于折射
            
            #include "Assets/Shaders/ShaderLibrary/Lighting.hlsl"
            #include "Assets/Shaders/LitWaterInput.hlsl"

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
                float4 color        : COLOR;
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
                half4 tangentWS                : TEXCOORD3;
            #endif
                half  fogFactor                 : TEXCOORD5;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                float4 shadowCoord              : TEXCOORD6;
            #endif
                DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 8);
            #ifdef DYNAMICLIGHTMAP_ON
                float2  dynamicLightmapUV : TEXCOORD9;
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
                float sgn = input.tangentWS.w;
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
                inputData.fogCoord = InitializeInputDataFog(float4(input.positionWS, 1.0), input.fogFactor);
            #if defined(DYNAMICLIGHTMAP_ON)
                inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV, input.vertexSH, inputData.normalWS);
            #else
                inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.vertexSH, inputData.normalWS);
            #endif
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
                inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);
            }

            Varyings LitPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                // ================= 融合顶点波浪动画 =================
                float3 tangent = float3(1, 0, 0);
                float3 binormal = float3(0, 0, 1);
                float3 gridPoint = input.positionOS.xyz;
                float3 p = gridPoint;
                p += GerstnerWave(_WaveA, p, tangent, binormal);
                p += GerstnerWave(_WaveB, gridPoint, tangent, binormal);
                float3 waveNormal = normalize(cross(binormal, tangent));

                VertexPositionInputs vertexInput = GetVertexPositionInputs(p);
                VertexNormalInputs normalInput = GetVertexNormalInputs(waveNormal, float4(tangent, 1));
                // ====================================================

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
                output.fogFactor = fogFactor;

            #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                output.positionWS = vertexInput.positionWS;
            #endif

            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                output.shadowCoord = GetShadowCoord(vertexInput);
            #endif

            OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
            #ifdef DYNAMICLIGHTMAP_ON
                output.dynamicLightmapUV = input.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
            #endif
                OUTPUT_SH(output.normalWS, output.vertexSH);


                output.positionCS = vertexInput.positionCS;
                return output; 
            }

            void LitPassFragment(
                Varyings input
                , out half4 outColor : SV_Target0
            )
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                // 1. 调用原本的基础函数，获取基础的 Albedo、Emission、Alpha 裁剪等
                SurfaceData surfaceData;
                InitializeStandardLitSurfaceData(input.uv, surfaceData);

                // ================= 水面特效覆盖 =================
                // 2. 计算深度
                float2 screenUV = input.positionCS.xy / _ScreenParams.xy;
                float rawDepth = SampleSceneDepth(screenUV);
                float sceneEyeDepth = LinearEyeDepth(rawDepth, _ZBufferParams);
                float waterEyeDepth = -TransformWorldToView(input.positionWS).z;
                
                float depthDiff = sceneEyeDepth - waterEyeDepth;
                float depthFog = saturate(depthDiff / _DepthFogDistance);
                float depthWater = saturate((depthDiff / _DepthDistance));

                // 3. 计算流动 UV
                float2 jump = float2(_UJump, _VJump);
                float3 uvwA = FlowUV(input.uv, jump, _FlowMapTiling, _Speed, _FlowStrength, _Time.y, false);
                float3 uvwB = FlowUV(input.uv, jump, _FlowMapTiling, _Speed, _FlowStrength, _Time.y, true);
                float2 uvA = uvwA.xy;
                float2 uvB = uvwB.xy;

                // 4. 采样流动的 Albedo 和 Normal
                half4 DepthColor = lerp(_ShallowWater, _DeepWater, depthFog);
                half4 albedoAlphaA = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uvA);
                half4 albedoAlphaB = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uvB);
                half4 albedoAlpha = albedoAlphaA * uvwA.z + albedoAlphaB * uvwB.z;
                
                half3 n1 = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uvA * _NormalTiling * 0.75), _BumpScale) * uvwA.z;
                half3 n2 = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uvB * _NormalTiling), _BumpScale) * uvwB.z;
                half3 n = normalize(n1 + n2);

                // 5. 覆盖基础数据 (保留原本的 emission 不被覆盖)
                surfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb * DepthColor.rgb;
                surfaceData.alpha = albedoAlpha.a * _BaseColor.a;
                surfaceData.normalTS = n;
                // ================================================

                // 6. 使用被水覆盖后的 normalTS 重新计算 InputData
                InputData inputData;
                InitializeInputData(input, surfaceData.normalTS, inputData);
                SETUP_DEBUG_TEXTURE_DATA(inputData, input.uv, _BaseMap);

                // ================= 融合：深度边缘泡沫 (沿用 FlowMap, 纯白泡沫) =================
                // 计算梯度（使用 _FoamWidth 控制深度渐变范围）
                #if _ENABLEFOAM
                    float gradientWave = 1.0 - smoothstep(0.0, _FoamWaveScale, depthDiff);
                    
                    // 世界空间 UV 投影
                    float2 worUV = input.positionWS.xz / 512.0;
                    
                    // 流动 UV（利用你已有的 _Speed 控制流动速度）
                    float2 flowSpeed = float2(_Time.y * _Speed, _Time.y * _Speed);
                    float2 foamUV1 = worUV * _FoamTiling - float2(gradientWave * 0.5, 0.0) + flowSpeed;
                    float2 foamUV2 = worUV * _FoamTiling + flowSpeed;

                    // 沿用 FlowMap 采样噪声
                    half noise1 = SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap, foamUV1).r;
                    half noise2 = SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap, foamUV2).r;

                    float edgeWidth = 0.02;
                    float foamMask = 0.0;

                    if (depthDiff > -0.1) {
                        // 核心泡沫遮罩
                        foamMask = 1.0 - smoothstep(-edgeWidth, _FoamWidth + edgeWidth, depthDiff);
                        foamMask = max(foamMask - ((1.0 - foamMask) * noise1 * foamMask * 4.0), 0.0);
                        foamMask = smoothstep(0.0, _FoamThreshold, foamMask);
                        
                        // 正弦波公式（使用 _FoamWaveScale 和 _FoamWaveNumber）
                        float waveMath = (_FoamWaveNumber * 6) - ((1.0 - gradientWave) * gradientWave * (_FoamWaveNumber * 6 * 2.0));
                        float Coastline = clamp(pow(smoothstep(0.0, 1.0, sin((gradientWave - noise2) * waveMath + _Time.y * 5.0)), 100.0 - _FoamWidth * 100.0), 0.0, 1.0);
                        
                        Coastline = lerp(0.0, clamp(Coastline * (10.0 - _FoamThreshold * 10.0) * gradientWave, 0.0, 1.0), (1.0 - gradientWave));
                        foamMask = max(Coastline, foamMask);
                        
                    }
                #endif 
                // ======================================================================

                // 7. 水面折射处理
                float3 viewNormal = TransformWorldToViewDir(inputData.normalWS);
                float2 refractOffset = viewNormal.xy * _Refraction * 0.1;
                // 让 FlowMap 的 UV 随时间缓慢滚动，产生持续的扭曲扰动
                float2 flowNoiseUV = input.uv * _FlowMapTiling + _Time.y * _Speed * 0.1; 
                float2 flowNoise = SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap, flowNoiseUV).rg;
                // 将 0~1 的 RG 映射到 -1~1，并乘以扭曲强度
                float2 distortOffset = (flowNoise * 2.0 - 1.0) * _DistortStrength;

                //合并偏移并采样屏幕颜色
                float2 refractUV = screenUV + refractOffset + distortOffset;
                float3 refractColor = SampleSceneColor(refractUV);
                
                // 根据水深混合：浅水区看清折射的水底，深水区被水面颜色覆盖
                surfaceData.albedo = lerp(surfaceData.albedo, refractColor, _Refraction * (1.0 - depthWater));

                // ================= 焦散处理 (深度投射) =================
                // 1. 利用屏幕 UV 和深度图，重构水底的世界坐标
                float3 sceneWorldPos = ComputeWorldSpacePosition(screenUV, rawDepth, UNITY_MATRIX_I_VP);
                // 2. 提取水底世界坐标的 XZ 平面作为焦散 UV
                float2 causticUV = sceneWorldPos.xz;
                // 3. 获取焦散颜色
                float3 causticColor = GetCausticColor(causticUV);
                // 4. 水浅的地方焦散强，水深的地方焦散弱 (用 depthWater 衰减)
                float causticFade = saturate(1.0 - depthWater);
                // 5. 将焦散叠加到自发光 (Emission) 中
                surfaceData.emission += causticColor * causticFade;

                #if _ENABLEFOAM
                    // 混合纯白颜色
                    surfaceData.albedo = lerp(surfaceData.albedo, float3(1.0, 1.0, 1.0), foamMask);
                    surfaceData.emission = lerp(surfaceData.emission, float3(1.0, 1.0, 1.0), foamMask);
                #endif

                // MatCap
                #if defined(_MATCAP_ON)
                    ApplyMatCap(surfaceData, inputData.normalWS, inputData.viewDirectionWS);
                #endif

                    half4 color = UniversalFragmentPBR(inputData, surfaceData);
                    color.rgb = MixFog(color.rgb, inputData.fogCoord);
                    color.a = OutputAlpha(color.a, IsSurfaceTypeTransparent(_Surface));

                    outColor = color;
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

            #include "Assets/Shaders/LitWaterInput.hlsl"
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

            #include "Assets/Shaders/LitWaterInput.hlsl"
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

            #include "Assets/Shaders/LitWaterInput.hlsl"
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

            #include "Assets/Shaders/LitWaterInput.hlsl"
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
            

            #include "Assets/Shaders/LitWaterInput.hlsl"
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

            #include "Assets/Shaders/LitWaterInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Utils/Universal2D.hlsl"
            ENDHLSL
        }
        
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "LWGUI.LWGUI"
}