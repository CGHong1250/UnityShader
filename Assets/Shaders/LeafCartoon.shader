Shader "Hong/LeafCartoon"
{

    Properties
    { 
        [Toggle(RECEIVE_ON)] _RECEIVE("ReceiveShadows",Int) = 0
        _FrontColor("FrontColor", Color) = (1,1,1,1)
        _BackColor("BackColor", Color) = (1,1,1,1)
        _Wind("Wind(warp,scale，offset,distance)", Vector) = (1,1,1,0.2)

        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)
        _Smoothness("Smoothness",Range(0.0, 1)) = 1
        //添加法线纹理和法线强度变量
        [NoScaleOffset][Normal]_BumpMap("NormalMap", 2D) = "bump"{}
        _BumpScale("NormalIntensity", Range(0,1)) = 1

        [NoScaleOffset]_MaskMap("MaskMap", 2D) = "white"{}
        _Metallic("Metallic",Range(0,1)) = 0

        [HDR] _EmissionColor("Color", Color) = (0,0,0)
        [NoScaleOffset]_EmissionMap("Emission", 2D) = "white" {}

    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "Queue"="AlphaTest" }
        LOD 200

        Pass
        {
            Tags{ "LightMode" = "UniversalForward" }

			Blend One Zero
            ZWrite On
			ZTest LEqual
            AlphaToMask On
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // -------------------------------------
            // Material Keywords
            #pragma multi_compile _ RECEIVE_ON

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _LIGHT_LAYERS

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fog 
            #pragma multi_compile _ LIGHTMAP_ON 
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING 
            #pragma multi_compile _ SHADOWS_SHADOWMASK 
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_fragment _ DEBUG_DISPLAY

              
            // GPU Instancing
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
                float4 color        : COLOR;
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
                half4 _BaseColor, _EmissionColor, _FrontColor, _BackColor;
                float4 _BaseMap_ST, _Wind;
                half _Smoothness, _BumpScale, _Metallic;
            CBUFFER_END

            //----------------自定义函数写在这里------------------
            inline void InitializeStandardLitSurfaceData(float2 uv, half3 FBColor, out SurfaceData outSurfaceData)
            {
                half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
                outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb * FBColor;
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

                #if defined(RECEIVE_ON)
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    inputData.shadowCoord = input.shadowCoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
                #else
                    inputData.shadowCoord = float4(0, 0, 0, 0);
                #endif
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

                float3 p = input.positionOS.xyz;
                float time = _Time.y * 1;
                p += float3(sin(time * p.x * _Wind.x), 0 ,cos(time * p.z * _Wind.x)) * input.color.r *0.1  * _Wind.y;
                p += float3(sin(time * _Wind.z), 0 ,cos(time * _Wind.z)) * input.color.r *0.1  * _Wind.w;

            
                VertexPositionInputs vertexInput = GetVertexPositionInputs(p);
                //VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
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
                    OUTPUT_SH(vertexInput.positionWS, output.normalWS.xyz, GetWorldSpaceNormalizeViewDir(vertexInput.positionWS), output.vertexSH);
                    
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

                Light MyLight = GetMainLight();
                half3 LightDir = normalize(MyLight.direction);
                half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
                half3 halfDir = normalize(viewDirWS + LightDir);
                half3 normalWS = input.normalWS;
                half LdotN = dot(halfDir,normalWS);
                half3 FBColor = lerp(_BackColor.rgb,_FrontColor.rgb,LdotN);

                
                SurfaceData surfaceData;
                InitializeStandardLitSurfaceData(input.uv, FBColor, surfaceData);

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
            Tags{"LightMode" = "ShadowCaster" "Queue"="AlphaTest"}

            Cull Off
            ZWrite On
            ZTest LEqual
            ColorMask 0

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"


            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor, _EmissionColor, _FrontColor, _BackColor;
                float4 _BaseMap_ST, _Wind;
                half _Smoothness, _BumpScale, _Metallic;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL; 
                float2 texcoord     : TEXCOORD0;
                float4 color        : COLOR;

            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
            };
            
            Varyings vert(Attributes input)
            {
                Varyings output;
                float3 p = input.positionOS.xyz;
                float time = _Time.y * 1;
                p += float3(sin(time * p.x * _Wind.x), 0 ,cos(time * p.z * _Wind.x)) * input.color.r *0.1  * _Wind.y;
                p += float3(sin(time * _Wind.z), 0 ,cos(time * _Wind.z)) * input.color.r *0.1  * _Wind.w;

                float3 positionWS = TransformObjectToWorld(p);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                // 获取阴影专用裁剪空间下的坐标
                output.positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, float3(0,0,0)));
                // 判断是否是在DirectX平台翻转过坐标
                #if UNITY_REVERSED_Z
                    output.positionCS.z = min(output.positionCS.z, output.positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    output.positionCS.z = max(output.positionCS.z, output.positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                half albedoAlpha = SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a;
                half Alpha = albedoAlpha * _BaseColor.a;
                clip(Alpha - 0.5); 
                return 0;
            }

            ENDHLSL
        }

        Pass
        {
            Tags{"LightMode" = "DepthOnly"}

            //Cull Off
            //ZWrite On
            //ZTest LEqual
            //ColorMask 0

            HLSLPROGRAM

            // Shader Stages
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment


            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer

            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #if defined(LOD_FADE_CROSSFADE)
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor, _EmissionColor, _FrontColor, _BackColor;
                float4 _BaseMap_ST, _Wind;
                half _Smoothness, _BumpScale, _Metallic;
            CBUFFER_END

            struct Attributes
            {
                float4 position     : POSITION;
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
                output.positionCS = TransformObjectToHClip(input.position.xyz);
                return output;
            }

            half DepthOnlyFragment(Varyings input) : SV_TARGET
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, 0);

            #ifdef LOD_FADE_CROSSFADE
                LODFadeCrossFade(input.positionCS);
            #endif

                return input.positionCS.z;
            }
            ENDHLSL
        }
    }
}