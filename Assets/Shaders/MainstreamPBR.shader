Shader "Hong/MainstreamPBR"
{

    Properties
    { 
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        _Smoothness("Smoothness",Range(0.0, 1)) = 0.2
        //添加法线纹理和法线强度变量
        [Normal]_NormalMap("NormalMap", 2D) = "bump"{}
        _NormalIntensity("NormalIntensity", Range(0,1)) = 1

        _MaskMap("MaskMap", 2D) = "white"{}
        _Metallic("Metallic",Range(0,1)) = 1

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
            //让雾起作用
            #pragma multi_compile_fog 
            //添加接收阴影必要关键字，主光阴影、联级阴影、屏幕空间阴影
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            //软阴影
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            //添加多光源阴影关键字
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            //开启额外其它光源计算
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            //LightMap支持
            #pragma multi_compile _ LIGHTMAP_ON      

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            //光照函数库
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;  
                float2 uv           : TEXCOORD0;
                float2 staticLightmapUV   : TEXCOORD1;

            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
                float3 tangentWS    : TANGENT;
                float3 viewDirWs    : TEXCOORD2;
                float3 BTangentWS   : TEXCOORD3;
                float3 positionWS   : TEXCOORD4;
                half fogCoord       : TEXCOORD5;
                float2 staticLightmapUV   : TEXCOORD6;

            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);
            TEXTURE2D(_MaskMap);
            SAMPLER(sampler_MaskMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST, _NormalMap_ST,  _MaskMap_ST;
                float _Smoothness, _NormalIntensity, _Metallic;
            CBUFFER_END

            //----------------自定义函数写在这里------------------

            //D项
            float Distribution(float roughness, float NdotH)
            {
                float lerpSquareRoughness = pow(lerp(0.01,1, roughness),2);
                float D = lerpSquareRoughness/(pow(pow(NdotH,2)*(lerpSquareRoughness-1)+1,2)*PI);
                return D;
            }

            //G子项
            inline real G_subSection(half dot, half k)
            {
                return dot/lerp(dot,1,k);
            }
            //G的函数
            float Geometry(float roughness, float NdotL, float NdotV, float k)
            {
                float gLeft = G_subSection(NdotL,k);
                float gRight = G_subSection(NdotV,k);
                float G = gLeft * gRight;
                return G;
            }

            //F项
            //直接光 F的函数
            float3 DirectFresnelEquation(float3 F0, float LdotH)
            {
                float3 F = F0 + (1 - F0) * exp2((-5.55473 * LdotH - 6.98316) * LdotH);
                return F;
            }
            //间接光 F的函数
            float3 IndirectFresnelEquation(float3 F0, float NdotV, float roughness)
            {
                float Fre = exp2((-5.55473 * NdotV - 6.98316) * NdotV);
                return F0 + Fre * saturate(1 - roughness - F0);
            }

            //间接光高光 反射探针
            real3 IndirectSpeCube(float3 normalWS, float3 viewWS, float roughness, float AO)
            {
                float3 reflectDirWS = reflect(-viewWS, normalWS);                                                  // 计算出反射向量
                roughness = roughness * (1.7 - 0.7 * roughness);                                                   // Unity内部不是线性 调整下拟合曲线求近似
                float MidLevel = roughness * 6;                                                                    // 把粗糙度remap到0-6 7个阶级 然后进行lod采样
                float4 speColor = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDirWS, MidLevel);//根据不同的等级进行采样
            #if !defined(UNITY_USE_NATIVE_HDR)
                return DecodeHDREnvironment(speColor, unity_SpecCube0_HDR) * AO;//用DecodeHDREnvironment将颜色从HDR编码下解码。可以看到采样出的rgbm是一个4通道的值，最后一个m存的是一个参数，解码时将前三个通道表示的颜色乘上xM^y，x和y都是由环境贴图定义的系数，存储在unity_SpecCube0_HDR这个结构中。
            #else
                return speColor.xyz*AO;
            #endif
            }

            half3 IndirectSpeFactor(half roughness, half smoothness, half3 BRDFspe, half3 F0, half NdotV)
            {
                #ifdef UNITY_COLORSPACE_GAMMA
                half SurReduction = 1 - 0.28 * roughness * roughness;
                #else
                half SurReduction = 1 / (roughness * roughness + 1);
                #endif
                #if defined(SHADER_API_GLES) // Lighting.hlsl 261 行
                half Reflectivity = BRDFspe.x;
                #else
                half Reflectivity = max(max(BRDFspe.x, BRDFspe.y), BRDFspe.z);
                #endif
                half GrazingTSection = saturate(Reflectivity + smoothness);
                half fre = Pow4(1 - NdotV);
                // Lighting.hlsl 第 501 行
                // half fre = exp2((-5.55473 * NdotV - 6.98316) * NdotV); // Lighting.hlsl 第 501 行，他是 4 次方，我们是 5 次方
                return lerp(F0, GrazingTSection, fre) * SurReduction;
            }
            
            
            //在场景中创建球型光照，使用函数获取球型光照的颜色 
            real3 SH_IndirectionDiff(float3 normal)
            {
                real4 SHCoefficients[7];
                SHCoefficients[0] = unity_SHAr;
                SHCoefficients[1] = unity_SHAg;
                SHCoefficients[2] = unity_SHAb;
                SHCoefficients[3] = unity_SHBr;
                SHCoefficients[4] = unity_SHBg;
                SHCoefficients[5] = unity_SHBb;
                SHCoefficients[6] = unity_SHC;
                float3 Color = SampleSH9(SHCoefficients, normal);
                return max(0, Color);
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                //自动帮你计算positionWS positionVS positionCS NDC[0,w]
                VertexPositionInputs vertexInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = vertexInputs.positionCS;   //物体从模型空间转换到裁剪空间
                OUT.positionWS = vertexInputs.positionWS;   //物体从模型空间转换到世界空间


                //TRANSFORM_TEX主要作用是拿顶点的uv去和材质球的tiling和offset作运算， 确保材质球里的缩放和偏移设置是正确的。
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.uv = TRANSFORM_TEX(IN.uv, _NormalMap);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MaskMap);

                //将法线的对象空间转换到世界空间
                //GetVertexNormalInputs（float3 normalOS, float4 tangentOS）函数，在ShaderVariablesFunctions.hlsl库里
                VertexNormalInputs normalInput = GetVertexNormalInputs(IN.normalOS, IN.tangentOS);
                OUT.normalWS = normalInput.normalWS;

                //将顶点切线从对象空间转换到世界空间
                OUT.tangentWS = normalInput.tangentWS;

                //计算副切线时，叉乘法线，切线，并在乘切线的w值判断正负，在乘负奇数缩放影响因子
                OUT.BTangentWS = normalInput.bitangentWS;

                //世界空间相机的位置减去世界空间顶点的位置就可以得到相机视角的方向
                OUT.viewDirWs = normalize(_WorldSpaceCameraPos.xyz - TransformObjectToWorld(IN.positionOS.xyz));

                //雾效
                OUT.fogCoord = ComputeFogFactor(OUT.positionCS.z);

                OUT.staticLightmapUV = IN.staticLightmapUV.xy * unity_LightmapST.xy + unity_LightmapST.zw;

                
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                //====================直接光、阴影数据====================
                float4 shadow_Coords = TransformWorldToShadowCoord(IN.positionWS);
                Light lihgtData = GetMainLight(shadow_Coords);
                half shadow = lihgtData.shadowAttenuation;
                real4 lightColor = real4(lihgtData.color * lihgtData.distanceAttenuation,1) * shadow;

                //====================纹理====================
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv)*_BaseColor;
                half4 normalMap = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, IN.uv);
                half4 maskMap = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, IN.uv);
                baseMap *= maskMap.b;

                float roughness = (1 - _Smoothness)*maskMap.g;
                half k1 = pow(roughness + 1,2)/8.0;          // 直接光的K值
                half k2 = pow(roughness,2)/2;                // 间接光的K值
                
                //k1 = pow(1 + roughness, 2) / 0.5;
                //k2 = pow(1 + roughness, 2) / 0.5;

                half metallic = _Metallic * maskMap.r;

                float3 F0 = lerp(0.04,baseMap.rgb,metallic);

                //====================法线====================
                float3x3 TBN = {IN.tangentWS.xyz, IN.BTangentWS.xyz, IN.normalWS.xyz};
                float3 normalTS = UnpackNormalScale(normalMap,_NormalIntensity);
                //规范化法线，好像不写也没关系
                normalTS.z = pow((1 - pow(normalTS.x,2) - pow(normalTS.y,2)),0.5);
                
                //====================计算方向====================
                real3 viewDirWs = normalize(IN.viewDirWs);
                real3 lightDir = normalize(lihgtData.direction);
                real3 halfDir = normalize(viewDirWs + lightDir);
                float3 normalDir = normalize(mul(normalTS,TBN));

                float NdotH = max(saturate(dot(normalDir, halfDir)), 0.0001);
                float NdotL = max(saturate(dot(normalDir, lightDir)),0.01);
                float NdotV = max(saturate(dot(normalDir, viewDirWs)),0.01);
                float HdotL = max(saturate(dot(halfDir, lightDir)), 0.0001);


                
                //====================直接光镜面反射====================
                float D = Distribution(roughness,NdotH);

                float G1 = Geometry(roughness,NdotL,NdotV,k1);
                float G2 = Geometry(roughness,NdotL,NdotV,k2);

                float3 F = DirectFresnelEquation(F0,HdotL);

                half3 SpecularResult = (D * G1 * F) / (NdotV * NdotL * 4);
                half3 SpecColor = saturate(SpecularResult * lightColor.rgb * NdotL); 


                //===================直接光漫反射=====================
                float3 ks = F;
                float3 kd = (1- ks) * (1 - metallic);                   // 计算kd

                half3 diffColor = kd * baseMap.rgb * lightColor.rgb * NdotL; 

                //===================多光源=====================
                int additionalLightCount = GetAdditionalLightsCount();//获取额外光源数量
                for (int i = 0; i < additionalLightCount; ++i)
                {
                    lihgtData = GetAdditionalLight(i, IN.positionWS);//根据index获取额外的光源数据
                    //====================多光源数据====================
                    float NdotAddL = max(saturate(dot(normalDir, lihgtData.direction)),0.01);
                    float HdotAddL = max(saturate(dot(halfDir, lihgtData.direction)), 0.0001);
                    half3 attenuatedLightColor = lihgtData.color.rgb * lihgtData.distanceAttenuation * lihgtData.shadowAttenuation;
                    //====================多光源镜面反射====================
                    //这里用的是间接光的方法
                    float G_Add = Geometry(roughness,NdotAddL,NdotV,k2);
                    float3 F_Add = IndirectFresnelEquation(F0,NdotV,roughness);

                    SpecularResult += (D * G_Add * F_Add) / (NdotV * NdotAddL * 4);
                    SpecColor += saturate(SpecularResult * attenuatedLightColor * NdotAddL); 

                    //===================多光源漫反射=====================
                    float3 ks_Add = F_Add;
                    float3 kd_Add = (1- ks_Add) * (1 - metallic);              
                    diffColor += kd_Add * baseMap.rgb * attenuatedLightColor * NdotAddL;

                }

                //直接光合并
                half3 directLightResult = diffColor + SpecColor; 


                //====================间接光漫反射====================
                half3 shcolor = SH_IndirectionDiff(normalDir);                                         // 这里可以AO
                half3 indirect_ks = IndirectFresnelEquation(F0,NdotV,roughness);                          // 计算 ks
                half3 indirect_kd = (1 - indirect_ks) * (1 - metallic);                        // 计算kd
                half3 indirectDiffColor = shcolor * indirect_kd * baseMap.rgb;
                //half3 indirectDiffColor = indirect_kd  ;

                //====================间接光高光反射====================
                half3 IndirectSpecularResult = (D * G2 * F) / (NdotV * NdotL * 4);
                half3 IndirectSpeCubeColor = IndirectSpeCube(normalDir, viewDirWs, roughness, 1.0);
                half3 IndirectSpeCubeFactor = IndirectSpeFactor(roughness, _Smoothness, IndirectSpecularResult, F0, NdotV);
                half3 IndirectSpeColor = IndirectSpeCubeColor * IndirectSpeCubeFactor;
                //间接光
                half3 IndirectColor = IndirectSpeColor + indirectDiffColor;
                
                //half4 ambientColor = unity_AmbientSky;
                //====================合并光====================
                half3 finalCol = (IndirectColor + directLightResult);
                finalCol.rgb = MixFog(finalCol.rgb, IN.fogCoord);
                half3 bakeGI = SampleLightmap(IN.staticLightmapUV,normalDir);
                //finalCol *= bakeGI;

                
                return half4(finalCol.rgb,1);
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