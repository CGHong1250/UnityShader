Shader "Hong/TranslucencyPBR"
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

    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue"="Transparent"  "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        Pass
        {
            Tags{ "LightMode" = "UniversalForward" }
            
             // 传统透明度
            Blend SrcAlpha OneMinusSrcAlpha 

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

            };

            TEXTURE2D(_MaskMap);        SAMPLER(sampler_MaskMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor, _EmissionColor;
                float4 _BaseMap_ST;
                half _Smoothness, _BumpScale, _Metallic;
            CBUFFER_END

            //----------------自定义函数写在这里------------------
            inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
            {
                half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
                outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;
                outSurfaceData.alpha = albedoAlpha.a * _BaseColor.a;

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

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {

                SurfaceData surfaceData;
                InitializeStandardLitSurfaceData(input.uv, surfaceData);

                #ifdef LOD_FADE_CROSSFADE
                    LODFadeCrossFade(input.positionCS);
                #endif

                InputData inputData;
                InitializeInputData(input, surfaceData.normalTS, inputData);
                SETUP_DEBUG_TEXTURE_DATA(inputData, input.uv, _BaseMap);
                
                #ifdef _DBUFFER
                    ApplyDecalToSurfaceData(input.positionCS, surfaceData, inputData);
                #endif

                half4 color = UniversalFragmentPBR(inputData, surfaceData);
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