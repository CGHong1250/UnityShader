Shader "Hong/UnityPBR"
{

    Properties
    { 
       
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)
        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        _Smoothness("Smoothness",Range(0.0, 1)) = 0.2
        
        // 法线纹理
        [NoScaleOffset][Normal]_BumpMap("NormalMap", 2D) = "bump"{}
        _BumpScale("NormalIntensity", Range(0,1)) = 1

        // 遮罩贴图
        [NoScaleOffset]_MaskMap("MaskMap", 2D) = "white"{}
        _Metallic("Metallic",Range(0,1)) = 1

        // 自发光
        [HDR] _EmissionColor("Color", Color) = (0,0,0)
        [NoScaleOffset]_EmissionMap("Emission", 2D) = "white" {}

        // 渲染状态
        [HideInInspector] _Surface("__surface", Float) = 0.0
        [HideInInspector] _Blend("__blend", Float) = 0.0
        [HideInInspector] _Cull("__cull", Float) = 2.0
        [HideInInspector] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _SrcBlendAlpha("__srcA", Float) = 1.0
        [HideInInspector] _DstBlendAlpha("__dstA", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        [HideInInspector] _ZTest("_ZTest", Float) = 4.0
        [HideInInspector] _BlendModePreserveSpecular("_BlendModePreserveSpecular", Float) = 1.0
        [HideInInspector] _AlphaToMask("__alphaToMask", Float) = 0.0

        // 阴影
        [HideInInspector] _CastShadows("_CastShadows", Float) = 1.0
        [HideInInspector] _ReceiveShadows("Receive Shadows", Float) = 1.0
        
        // 渲染队列
        [HideInInspector] _QueueControl("Queue control", Float) = 0.0
        [HideInInspector] _QueueOffset("Queue offset", Float) = 0.0

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
            Tags{ "LightMode" = "UniversalForward" }

            Blend[_SrcBlend][_DstBlend], [_SrcBlendAlpha][_DstBlendAlpha]
            ZWrite[_ZWrite]
            Cull[_Cull]
            AlphaToMask[_AlphaToMask]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // -------------------------------------
            // Material Keywords
            //用于切换半透明和不透明
            #pragma shader_feature_local_fragment _SURFACE_TYPE_TRANSPARENT
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _EMISSION


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



            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer

              


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

            };

            TEXTURE2D(_MaskMap);        SAMPLER(sampler_MaskMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor, _EmissionColor;
                float4 _BaseMap_ST;
                half _Smoothness, _BumpScale, _Metallic, _Surface, _Cutoff;
            CBUFFER_END

            //----------------自定义函数写在这里------------------
            inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
            {
                half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
                outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;
                outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);

                // 法线
                #ifdef _NORMALMAP
                half4 normalSample = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uv);
                outSurfaceData.normalTS = UnpackNormalScale(normalSample, _BumpScale);
                #else
                outSurfaceData.normalTS = half3(0.0h, 0.0h, 1.0h);
                #endif

                // 遮罩贴图
                #ifdef _MASKMAP
                half4 maskMap = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, uv);
                outSurfaceData.metallic = maskMap.r * _Metallic;
                outSurfaceData.smoothness = maskMap.g * _Smoothness;
                outSurfaceData.occlusion = maskMap.b;
                #else
                outSurfaceData.metallic = _Metallic;
                outSurfaceData.smoothness = _Smoothness;
                outSurfaceData.occlusion = 1.0h;
                #endif

                // Specular设置为0（金属工作流）
                outSurfaceData.specular = half3(0.0h, 0.0h, 0.0h);

                // 自发光
                #ifdef _EMISSION
                outSurfaceData.emission = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, uv).rgb * _EmissionColor.rgb;
                #else
                outSurfaceData.emission = half3(0, 0, 0);
                #endif

                outSurfaceData.clearCoatMask = 0.0h;
                outSurfaceData.clearCoatSmoothness = 1.0h;
            }
            
            
            void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData)
            {
                inputData = (InputData)0;
                inputData.positionWS = input.positionWS;
                inputData.positionCS = input.positionCS;
                
                half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
                inputData.viewDirectionWS = viewDirWS;
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);

                // 切线空间到世界空间
                float sgn = input.tangentWS.w; 
                float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                half3x3 tangentToWorld = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);
                inputData.tangentToWorld = tangentToWorld;
                
                inputData.normalWS = TransformTangentToWorld(normalTS, tangentToWorld);
                inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);

                // 阴影坐标
                inputData.shadowCoord = input.shadowCoord;

                // 雾
                inputData.fogCoord = input.fogFactor;

                // 顶点光照
                #ifdef _ADDITIONAL_LIGHTS_VERTEX
                inputData.vertexLighting = input.vertexLight;
                #endif

                // 全局光照
                #if defined(DYNAMICLIGHTMAP_ON)
                inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV, input.vertexSH, inputData.normalWS);
                #else
                inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.vertexSH, inputData.normalWS);
                #endif

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
            
            //----------------顶点着色器------------------
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.normalWS = normalInput.normalWS;
                
                real sign = input.tangentOS.w * GetOddNegativeScale();
                half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
                output.tangentWS = tangentWS;
                output.positionWS = vertexInput.positionWS;
                output.positionCS = vertexInput.positionCS;

                // 雾
                output.fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

                // 光照贴图
                OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
                
                #ifdef DYNAMICLIGHTMAP_ON
                output.dynamicLightmapUV = input.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
                #endif
                
                OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
                
                // 顶点光照
                #ifdef _ADDITIONAL_LIGHTS_VERTEX
                output.vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
                #endif

                // 阴影坐标
                output.shadowCoord = GetShadowCoord(vertexInput);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                #ifdef LOD_FADE_CROSSFADE
                LODFadeCrossFade(input.positionCS);
                #endif

                SurfaceData surfaceData;
                InitializeStandardLitSurfaceData(input.uv, surfaceData);

                #ifdef _ALPHATEST_ON
                clip(surfaceData.alpha - _Cutoff);
                #endif

                InputData inputData;
                InitializeInputData(input, surfaceData.normalTS, inputData);
                
                #ifdef _DBUFFER
                ApplyDecalToSurfaceData(input.positionCS, surfaceData, inputData);
                #endif

                half4 color = UniversalFragmentPBR(inputData, surfaceData);
                color.rgb = MixFog(color.rgb, inputData.fogCoord);
                color.a = OutputAlpha(color.a, IsSurfaceTypeTransparent(_Surface));
                
                return color;
            }
            ENDHLSL
        }

    Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            // Render State Commands
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor, _EmissionColor;
                float4 _BaseMap_ST;
                half _Smoothness, _BumpScale, _Metallic, _Surface, _Cutoff;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float2 texcoord     : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv           : TEXCOORD0;
                float4 positionCS   : SV_POSITION;
            };

            float3 _LightDirection;
            float3 _LightPosition;

            Varyings ShadowPassVertex(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);

                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

                #if _CASTING_PUNCTUAL_LIGHT_SHADOW
                    float3 lightDirectionWS = normalize(_LightPosition - positionWS);
                #else
                    float3 lightDirectionWS = _LightDirection;
                #endif

                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif

                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.positionCS = positionCS;
                return output;
            }

            half4 ShadowPassFragment(Varyings input) : SV_TARGET
            {
                #ifdef _ALPHATEST_ON
                half4 albedoAlpha = SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
                half alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);
                clip(alpha - _Cutoff);
                #endif
                
                return 0;
            }
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ColorMask 0
            Cull[_Cull]
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #pragma multi_compile_instancing
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            // Alpha裁剪
            #pragma shader_feature_local_fragment _ALPHATEST_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

            #if defined(LOD_FADE_CROSSFADE)
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor, _EmissionColor;
                float4 _BaseMap_ST;
                half _Smoothness, _BumpScale, _Metallic, _Surface, _Cutoff;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv           : TEXCOORD0;
                float4 positionCS   : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings DepthOnlyVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                return output;
            }

            half4 DepthOnlyFragment(Varyings input) : SV_TARGET
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                #ifdef LOD_FADE_CROSSFADE
                LODFadeCrossFade(input.positionCS);
                #endif

                #ifdef _ALPHATEST_ON
                half4 albedoAlpha = SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
                half alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);
                clip(alpha - _Cutoff);
                #endif

                return input.positionCS.z;
            }
            ENDHLSL
        }
    }
    //CustomEditor "UnityEditor.Rendering.Universal.ShaderGUI.MyPBRShaderGUI"

}