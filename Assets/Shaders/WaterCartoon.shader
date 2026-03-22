Shader "Hong/WaterCartoon"
{

    Properties
    { 
        [HideInInspector] [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [HideInInspector] [MainColor] _BaseColor("Color", Color) = (1,1,1,1)
        _Smoothness("Smoothness",Range(0.0, 1)) = 1
        //添加法线纹理和法线强度变量
        [NoScaleOffset][Normal]_BumpMap("NormalMap", 2D) = "bump"{}
        _BumpScale("NormalIntensity", Range(0,1)) = 1
        _NormalTiling("NormalTiling",float) = 1

        [HideInInspector] [NoScaleOffset]_MaskMap("MaskMap", 2D) = "white"{}
        _Metallic("Metallic",Range(0,1)) = 0

        [HideInInspector] [HDR] _EmissionColor("Color", Color) = (0,0,0)
        [HideInInspector] [NoScaleOffset]_EmissionMap("Emission", 2D) = "white" {}

        _ShallowWater ("shallowColor", Color) = (1.0, 1.0, 1.0, 1.0)
        _DeepWater ("DeepColor", Color) = (1.0, 1.0, 1.0, 1.0)

        _Refraction ("Refraction",  Float) = 1.333
        _DepthDistance ("DepthDistance",  Range(0,10)) = 2
        _DepthFogDistance ("DepthFogDistance",  Range(0,100)) = 20
        
        //----------------湖水相关变量----------------
        [NoScaleOffset] _FlowMap ("Flow (RG,foam)", 2D) = "black" {}
        _UJump ("U jump per phase", Range(-0.25, 0.25)) = -0.2
		_VJump ("V jump per phase", Range(-0.25, 0.25)) = 0.25
        _FlowMapTiling ("FlowMapTiling", Float) = 0.1
        _FlowScale ("FlowScale", Float) = 1
        _Speed ("Speed", Float) = 1
        _FlowStrength ("Flow Strength", Float) = 1

        _WaveA ("Wave A (dir, steepness, wavelength)", Vector) = (1,1,0.05,2)
        _WaveB ("Wave B", Vector) = (0,1,0.025,4)

        //泡沫
        [NoScaleOffset]_FoamMap("FoamMap", 2D) = "black" {}
        _FoamTiling("FoamTiling",Range(0,10)) = 0.25
        _FoamRange("FoamRange",Range(0,10)) = 2.5
        _FoamNoise("FoamNoise",Range(0,10)) = 1.5

        //焦散
        [NoScaleOffset]_CausticMap("CausticMap", 2D) = "black" {}
        _CausticLightness("CausticLightness", range(0,10)) = 2
        _CausticTiling("CausticTiling",Range(0,10)) = 0.1


        

    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue"="Transparent "  "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        Pass
        {
            Tags{ "LightMode" = "UniversalForward" }
            
             // 传统透明度
            //Blend SrcAlpha OneMinusSrcAlpha 

            Cull off

            ZWrite On

            ZTest LEqual


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
                float3 positionVS    : TEXCOORD8;

            };

            TEXTURE2D(_MaskMap);        SAMPLER(sampler_MaskMap);
            TEXTURE2D(_FlowMap);        SAMPLER(sampler_FlowMap);
            TEXTURE2D(_FoamMap);        SAMPLER(sampler_FoamMap);
            TEXTURE2D(_CausticMap);        SAMPLER(sampler_CausticMap);
            //URP内置变量，参考DeclareOpaqueTexture.hlsl
            TEXTURE2D(_CameraOpaqueTexture);SAMPLER(sampler_CameraOpaqueTexture);
            //URP内置变量，参考DeclareDepthTexture.hlsl
            TEXTURE2D(_CameraDepthTexture);SAMPLER(sampler_CameraDepthTexture);


            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor, _EmissionColor, _DeepWater, _ShallowWater;
                float4 _BaseMap_ST, _WaveA, _WaveB;
                //float2 _Direction;
                float _UJump, _VJump, _FlowMapTiling, _Speed, _FlowStrength, _FlowScale, _CausticLightness, 
                    _NormalTiling, _Refraction, _DepthDistance, _DepthFogDistance, _FoamNoise ,_CausticTiling, _FoamTiling;
                //float _Steepness,_Frequency;
                half _Smoothness, _BumpScale, _Metallic, _FoamRange;
            CBUFFER_END

            //================自定义函数写在这里================
            
            //水面纹理变形,参考文章：https://catlikecoding.com/unity/tutorials/flow/texture-distortion/
            float3 FlowUV (float4 flowMap, float2 uv, float2 jump, float flowScale, float speed, float flowStrength, float time, bool flowB)
            {
                float3 uvw;
                float phaseOffset = flowB ? 0.5 : 0;
                float2 flowVector =  flowMap.rg * 2 - 1;
                flowVector *= flowStrength;
                float noise = flowMap.b;
                time = time * speed + noise;
                float progress = frac(time + phaseOffset);
                uvw.xy = uv - flowVector * progress;
                uvw.xy *= flowScale;
                uvw.xy += +phaseOffset;
                uvw.xy += (time - progress) * jump;
                uvw.z = 1 - abs(1 - 2 * progress);;
                return uvw;
            }
            
            //顶点动画，盖斯特纳波，参考文章：https://catlikecoding.com/unity/tutorials/flow/waves/
            float3 GerstnerWave (float4 wave, float3 p, inout float3 tangent, inout float3 binormal) 
            {
                float steepness = wave.z;
                float wavelength = wave.w;
                float k = 2 * PI / wavelength;
                float c = sqrt(9.8 / k);
                float2 d = normalize(wave.xy);
                float f = k * (dot(d, p.xz) - c * _Time.y);
                float a = steepness / k;
                tangent += float3( -d.x * d.x * (steepness * sin(f)), d.x * (steepness * cos(f)), -d.x * d.y * (steepness * sin(f)));
                binormal += float3(-d.x * d.y * (steepness * sin(f)), d.y * (steepness * cos(f)), -d.y * d.y * (steepness * sin(f)));
                return float3(d.x * (a * cos(f)), a * sin(f), d.y * (a * cos(f)));

		    }
            
            float4 RefractionColor(float4 positionCS, float3 normalTS, float3 positionVS, float refraction, out float2 uv, out float dethScene)
            {
                float4 screenPos = positionCS/_ScreenParams;
                float3 normal =normalTS;
                float2 uvOffset = normal.xy * refraction;
                uv = screenPos.xy + uvOffset/ screenPos.w;
                //uv = screenPos.xy + uvOffset;
                float2 screenUV = screenPos.xy;
                float depthTex = SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture,uv).r;
                dethScene = LinearEyeDepth(depthTex,_ZBufferParams);
                float depthWater = dethScene + positionVS.z;
                if(depthWater<0) uv = screenUV;

                float4 refractionColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture ,sampler_CameraOpaqueTexture, uv);
                return refractionColor;
            }

            //水下深度雾
            float DepthFog (float3 positionWS, float Depth)
            {
                float4 positionCS = TransformWorldToHClip(positionWS);
                //转换成齐次坐标
                float4 ScreenPosition = ComputeScreenPos(positionCS);
                // XY 除以 W 才能得到最终的深度纹理坐标。
                float2 uv = ScreenPosition.xy / ScreenPosition.w;
                //背景深度进行采样
                float backgroundDepth = LinearEyeDepth(SAMPLE_TEXTURE2D_X_LOD(_CameraDepthTexture,sampler_CameraDepthTexture,UnityStereoTransformScreenSpaceTex(uv),1.0).r, _ZBufferParams);
                //这是相对于屏幕的深度，而不是相对于水面的深度。所以我们还需要知道水和屏幕之间的距离。通过获取 Z 分量转换为线性深度
                float surfaceDepth = ComputeFogFactor(ScreenPosition.z);
                
                //水下深度是通过从背景深度中减去表面深度得出
                float depthDifference = backgroundDepth - surfaceDepth;
                //float depthDifference = backgroundDepth - ScreenPosition;

                return depthDifference/Depth;
            }
            
             //水面深度，与物体交接处
            float DepthWater(float4 positionCS, float3 positionVS, float Depth)
            {
                float2 screenUV = positionCS.xy/_ScreenParams.xy;
                float depthTex = SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture,screenUV).r;
                float dethScene = LinearEyeDepth(depthTex,_ZBufferParams);
                float depthWater = dethScene + positionVS.z;
                return saturate(depthWater/Depth);

            }

            //创建个结构体，方便给光照模型传参
            struct MaterialInput
            {
                //FlowMap数据
                float4 flowMap;
                float time;
                float speed;
                float flowStrength;
                float flowScale;
                float normalTiling;
                float2 jump;

                //深度数据
                float depthFog;
                float depthWater;
                half4 shallowWater;
                half4 deepWater;

                //泡沫
                half4 foam;
                half foamRange;
            };
            
            inline void MaterialInputData(float time, float speed, float4 flowMap, float flowStrength, float flowScale, float normalTiling, float2 jump, float depthFog, float depthWater, half4 shallowWater, half4 deepWater, half4 foam, half foamRange, out MaterialInput outMaterialInput)
            {
                outMaterialInput = (MaterialInput)0;
                //FlowMap数据赋值
                outMaterialInput.time = time;
                outMaterialInput.speed = speed;
                outMaterialInput.flowMap = flowMap;
                outMaterialInput.flowStrength = flowStrength;
                outMaterialInput.flowScale = flowScale;
                outMaterialInput.normalTiling = normalTiling;
                outMaterialInput.jump = jump;
                //深度数据赋值
                outMaterialInput.depthFog = depthFog;
                outMaterialInput.depthWater = depthWater;
                outMaterialInput.shallowWater = shallowWater;
                outMaterialInput.deepWater = deepWater;

                //泡沫
                outMaterialInput.foam = foam;
                outMaterialInput.foamRange = foamRange;
            }

            //光照模型相关
            inline void InitializeStandardLitSurfaceData(float2 uv, MaterialInput MaterialInput , out SurfaceData outSurfaceData)
            {
                float3 uvwA = FlowUV(MaterialInput.flowMap, uv, MaterialInput.jump, MaterialInput.flowScale, MaterialInput.speed, MaterialInput.flowStrength, MaterialInput.time, false);
                float3 uvwB = FlowUV(MaterialInput.flowMap, uv, MaterialInput.jump, MaterialInput.flowScale, MaterialInput.speed, MaterialInput.flowStrength, MaterialInput.time, true);
                float2 uvA = uvwA.xy;
                float2 uvB = uvwB.xy;
                
                half4 DepthColor = lerp(MaterialInput.shallowWater, MaterialInput.deepWater, MaterialInput.depthFog);

                half4 albedoAlphaA = SampleAlbedoAlpha(uvA, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
                half4 albedoAlphaB = SampleAlbedoAlpha(uvB, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
                half4 albedoAlpha = albedoAlphaA * uvwA.z + albedoAlphaB * uvwB.z;
                half3 color = albedoAlpha.rgb * _BaseColor.rgb * DepthColor.rgb;
                half3 foam = saturate(MaterialInput.foam.rgb + color);
                half foamAlpha = MaterialInput.foam.r;
                outSurfaceData.albedo = lerp(color, foam, foamAlpha);


                half alpha = albedoAlpha.a * _BaseColor.a * max(0.25,MaterialInput.depthWater);
                //outSurfaceData.alpha = lerp(alpha, MaterialInput.foam.rgb, foamAlpha);
                outSurfaceData.alpha = 1;

                half3 n1 = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uvA * MaterialInput.normalTiling * 0.75), _BumpScale) * uvwA.z;
                half3 n2 = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uvB * MaterialInput.normalTiling), _BumpScale) * uvwB.z;
                //half3 n = BlendNormal(n1, n2);
                half3 n = normalize(n1 + n2);
                //outSurfaceData.normalTS = UnpackNormalScale(n, _BumpScale);
                outSurfaceData.normalTS = n;

                half4 maskMap = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, uv);
                outSurfaceData.specular = 0.5;
                outSurfaceData.metallic = lerp(maskMap.r * _Metallic, 0 ,MaterialInput.foam.r);
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

                //顶点动画
                float3 tangent = float3(1, 0, 0);
                float3 binormal = float3(0, 0, 1);
                float4 wave = _WaveA;
                float3 gridPoint = input.positionOS.xyz;
                float3 p = gridPoint;
                p += GerstnerWave (wave, p, tangent, binormal);
                p += GerstnerWave(_WaveB, gridPoint, tangent, binormal);
                float3 normal = normalize(cross(binormal, tangent));


                VertexPositionInputs vertexInput = GetVertexPositionInputs(p);
                //VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                //VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                VertexNormalInputs normalInput = GetVertexNormalInputs(normal, float4(tangent,1));
                
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
                    output.positionVS = vertexInput.positionVS;
                    

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float2 jump = float2(_UJump, _VJump);
                float4 flowMap =  SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap,input.positionWS.xz * _FlowMapTiling );
                float4 foamMap =  SAMPLE_TEXTURE2D(_FoamMap, sampler_FoamMap,input.positionWS.xz * _FoamTiling + _Time.y*0.05 );

                

                //深度数据
                half depthFog = saturate(DepthFog(input.positionWS, _DepthFogDistance));
                half depthWater = DepthWater(input.positionCS, input.positionVS, _DepthDistance);

                //泡沫
                half foamRange = _FoamRange * depthWater;
                float2 foamUV = input.positionWS.xz * float2(0.5,1);
                half4 foam = foamMap;
                foam.rgb = pow(abs(foam.rgb),_FoamNoise); 
                foam.rgb = step(foamRange,foam.rgb);

                MaterialInput MaterialInput;
                MaterialInputData(_Time.y, _Speed, flowMap, _FlowStrength, _FlowScale, _NormalTiling, jump, 
                                    depthFog, depthWater, _ShallowWater, _DeepWater, foam, foamRange, MaterialInput);

                SurfaceData surfaceData;
                InitializeStandardLitSurfaceData(input.positionWS.xz, MaterialInput, surfaceData);
                
                //水下扭曲效果
                float2 screenUV = 1;
                float dethScene = 1;
                half4 refColor = RefractionColor(input.positionCS,surfaceData.normalTS, input.positionVS, _Refraction, screenUV, dethScene);

                //水下焦散
                float4 depthVS = 1;
                depthVS.xy = input.positionVS.xy * dethScene / -input.positionVS.z;
                depthVS.z = dethScene;
                float4 depthWS = mul(unity_CameraToWorld,depthVS);
                float2 causticMapUV1 = float2(depthWS.x*0.5 + depthWS.y*0.2 + _Time.y*0.1  ,depthWS.z + depthWS.y*0.2 - _Time.y*0.55) * _CausticTiling;
                float2 causticMapUV2 = float2(depthWS.x + depthWS.y*0.2 -_Time.y*0.55 ,depthWS.z*0.5 + depthWS.y*0.2 + _Time.y*0.1) * _CausticTiling;
                float4 causticMap1 =  SAMPLE_TEXTURE2D(_CausticMap, sampler_CausticMap,causticMapUV1);
                float4 causticMap2 =  SAMPLE_TEXTURE2D(_CausticMap, sampler_CausticMap,causticMapUV2);
                float4 causticMap = min(causticMap1, causticMap2)*_CausticLightness;



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

                half3 colorRef = lerp(refColor.rgb, color.rgb, depthWater);
                color.rgb = lerp(colorRef, color.rgb, foam.r) + causticMap.rgb;
                
                //return depthWater;
                return color;
            }
            ENDHLSL
        }


    }
}