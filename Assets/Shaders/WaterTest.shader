Shader "Hong/WaterTest"
{

     Properties
    {
        _ShallowWater ("shallowColor", Color) = (1.0, 1.0, 1.0, 1.0)
        _DeepWater ("DeepColor", Color) = (1.0, 1.0, 1.0, 1.0)
        _DepthDdgeSize("_DepthDdgeSize",Range(0,100)) = 0.005
        [Space(30)]
        _NoiseTexture ("_NoiseTexture", 2D) = "white" {}                        //噪波贴图

        _WaterNoiseSize("_WaterNoiseSize", float) = 1.0                            //水面噪波强度
        _WaterSpeed("_WaterSpeed",float ) = 1.0                                    //水面移动速度
        _SceneMoveDepth("_SceneMoveDepth",float) = 1.0                            //折射噪音影响深度效果
        _WaterStrength("_WaterStrength",Range(0,0.5)) = 0.1
        [Space(30)]
        _RefractionSpeedU("_RefractionSpeed_U",float) = 1.0
        _RefractionSpeedV("_RefractionSpeed_V",float) = 1.0

        _RefractionScale("_RefractionScale",float) = 1.0

        _NoiseInfluenceX("_NoiseInfluenceX",float) = 1.0
        _NoiseInfluenceZ("_NoiseInfluenceZ",float) = 1.0
        [Space(30)]
        _FoamColor("_FoamColor",Color) = (1.0, 1.0, 1.0, 1.0)
        _FoamSpeed_U("_FoamSpeed_U",float) = 0.0
        _FoamSpeed_V("_FoamSpeed_V",float) = 0.0

        _FoamScale("_FoamScale",float) = 1.0

        _FoamAmount("_FoamAmount",float) = 1.0
        _FoamCutoff("_FoamCutoff",float) = 1.0
        _FoamAlpha("_FoamAlpha",float) = 1.0

        [Space(30)]
        [Normal]_NormalTex ("_NormalTex", 2D) = "bump"{}
        _NormalScale("_NormalScale",float) = 1.0

        [Space(30)]
        _Metallic ("_Metallic", range(0.0, 1.0)) = 1.0
        _Roughness ("_Roughness", range(0.0, 1.0)) = 1.0

    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }

        HLSLINCLUDE


        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"        //增加光照函数库
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float _DepthDdgeSize,_WaterNoiseSize,_WaterSpeed,_SceneMoveDepth,_WaterStrength,_RefractionScale,_FoamScale;
        float4 _ShallowWater,_DeepWater,_FoamColor;
        float _NoiseInfluenceX,_NoiseInfluenceZ,_RefractionSpeedU,_RefractionSpeedV,_FoamSpeed_U,_FoamSpeed_V;
        float4 _NoiseTexture_ST,_NormalTex_ST;
        float _FoamAlpha,_FoamCutoff,_FoamAmount,_NormalScale,_Roughness,_Metallic;
        CBUFFER_END


        TEXTURE2D(_CameraDepthTexture);
        SAMPLER(sampler_CameraDepthTexture);                       //获取深度贴图

        TEXTURE2D(_NoiseTexture);                            //获取颜色贴图
        SAMPLER(sampler_NoiseTexture);                       //获取深度贴图

        TEXTURE2D (_NormalTex);
        SAMPLER(sampler_NormalTex);

        // 顶点着色器的输入
        struct a2v
        {
            float3 positionOS : POSITION;
            float4 normalOS : NORMAL;
            float2 texcoord :TEXCOORD0;
        };

        // 顶点着色器的输出
        struct v2f
        {
            float2 uv : TEXCOORD0;
            float4 positionCS : SV_POSITION;
            float3 positionWS:TEXCOORD1;
            float3 normalWS : NORMAL;
            float3 tangentWS : TANGENT;
            float3 bitangentWS : TEXCOORD2;
        };
        ENDHLSL

        Pass
        {
            Name "Pass"
            Tags
            {
                "LightMode" = "UniversalForward"
                "RenderType"="Transparent"
            }

            Blend SrcAlpha OneMinusSrcAlpha


            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            /*
             那么屏幕坐标的计算方法
             screenPosX = ((x / w) * 0.5 + 0.5) * width
             screenPosY = ((y / w) * 0.5 + 0.5) * height

             变换后的结果 unity代码类似
             o.x = (pos.x * 0.5 + pos.w * 0.5)
             o.y = (pos.y * 0.5 * _ProjectionParams.x + pos.w * 0.5)
            */
            float4 ComputeScreenPos(float4 pos, float projectionSign)                          //齐次坐标变换到屏幕坐标
            {
                float4 o = pos * 0.5f;
                o.xy = float2(o.x,o.y * projectionSign) + o.w;
                o.zw = pos.zw;
                return o;
			}


            //获取环境_CameraOpaqueTexture贴图
            float3 GetSceneColor(float3 WorldPos,float2 uv_move)
            {
		         float4 ScreenPosition = ComputeScreenPos(TransformWorldToHClip(WorldPos), _ProjectionParams.x);
		         return SampleSceneColor((ScreenPosition.xy + uv_move) / ScreenPosition.w);
            }

            //获取深度值
            float CustomSampleSceneDepth(float2 uv)
            {
                return SAMPLE_TEXTURE2D_X_LOD(_CameraDepthTexture,sampler_CameraDepthTexture,UnityStereoTransformScreenSpaceTex(uv),1.0).r;
			}

            //输入世界空间   WorldPos
            float GetDepthFade(float3 WorldPos, float Distance)
            {
                float4 posCS = TransformWorldToHClip(WorldPos);                                            //转换成齐次坐标
                float4 ScreenPosition = ComputeScreenPos(posCS, _ProjectionParams.x);                      //齐次坐标系下的屏幕坐标值
                //从齐次坐标变换到屏幕坐标， x,y的分量 范围在[-w,w]的范围   _ProjectionParams 用于在使用翻转投影矩阵时（此时其值为-1.0）翻转y的坐标值。
                //这里
                float screenDepth = CustomSampleSceneDepth(ScreenPosition.xy / ScreenPosition.w);        //计算屏幕深度 是非线性

                float EyeDepth = LinearEyeDepth(screenDepth,_ZBufferParams);                            //深度纹理的采样结果转换到视角空间下的深度值
                return saturate((EyeDepth - ScreenPosition.w)/ Distance);                               //使用视角空间下所有深度 减去模型顶点的深度值
			}


            //UV动画
            float2 UVMovement(float2 uv,half U,half V, float scale)
            {
		        float2 newUV = uv * scale + (_Time.y * (half2(U,V)));
		        return newUV;
            }




            //==================================================================================================================================================================

            //DGF 的 D
            float DistributionGGX(float NoH, float a)
            {
                float a2 = a * a;
                float NoH2 = NoH * NoH;

                float nom = a2;
                float denom = NoH2 * (a2 - 1) + 1;
                denom = denom * denom * PI;
                return nom / denom;
            }

            //DGF 的 小G
            float GeometrySchlickGGX(float NoV, float k)
            {
                float nom = NoV;
                float denom = NoV * (1.0 - k) + k;
                return nom / denom;
            }
            //DGF 的 G
            float GeometrySmith(float NoV, float NoL, float k)
            {
                float ggx1 = GeometrySchlickGGX(NoV, k);
                float ggx2 = GeometrySchlickGGX(NoL, k);
                return ggx1 * ggx2;
            }

            //DGF 的 F
            float3 FresnelSchlick(float cosTheta, float3 F0)
            {
                return F0 + pow(1.0 - cosTheta, 5.0);
            }


            //==================================================================================================================================================================


















            // 顶点着色器
            v2f vert(a2v v)
            {
                v2f o;
                float2 NoiseUV = v.texcoord * _WaterNoiseSize + (_WaterSpeed * _Time.y);                   //噪波贴图uv
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);                                      //获取世界空间下顶点位置
                float ReflactionSceneMoveDepth = GetDepthFade(o.positionWS, _SceneMoveDepth);                 //获取边缘深度图
                float posDepth = saturate(1.0 - saturate(ReflactionSceneMoveDepth));

                //float sineTime = sin((_Time.y * _WaterSpeed) + o.positionWS) * _WaterNoiseSize;

                float noise = (SAMPLE_TEXTURE2D_LOD(_NoiseTexture, sampler_NoiseTexture,NoiseUV,1.0).r - 0.5f) * posDepth;
                //v.positionOS.y += noise * _WaterStrength;
                //v.positionOS.y  += sineTime;


                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;                          //获取裁剪空间位置

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS.xyz);
                o.normalWS.xyz = NormalInputs.normalWS;                                //  获取世界空间下法线信息
                o.tangentWS    = NormalInputs.tangentWS;
                o.bitangentWS  = NormalInputs.bitangentWS;

                o.uv = TRANSFORM_TEX(v.texcoord,_NoiseTexture);
                return o;
            }

            // 片段着色器
            half4 frag (v2f i) : SV_Target
            {
                //watercolor
                float depthfade = GetDepthFade(i.positionWS, _DepthDdgeSize);
                float4 watercolor = lerp(_DeepWater,_ShallowWater,depthfade);
                watercolor.a = 1;

                //Screen Color
                float2 ReflactionMoveUV = UVMovement(i.uv, _RefractionSpeedU,_RefractionSpeedV,_RefractionScale);
                float ReflactionNoise = SAMPLE_TEXTURE2D(_NoiseTexture,sampler_NoiseTexture,ReflactionMoveUV).r;
                float ReflactionSceneMoveDepth = GetDepthFade(i.positionWS, _SceneMoveDepth);
                float3 SceneColor = GetSceneColor(i.positionWS,float2(ReflactionNoise * _NoiseInfluenceX,ReflactionNoise * _NoiseInfluenceZ) * ReflactionSceneMoveDepth);


                //边缘
                float2 FilterMoveUV = UVMovement(i.uv,_FoamSpeed_U,_FoamSpeed_V,_FoamScale);
                float FilterNoise = SAMPLE_TEXTURE2D(_NoiseTexture,sampler_NoiseTexture,FilterMoveUV).r;
                float filterSceneMoveDepth = GetDepthFade(i.positionWS, _FoamAmount) * _FoamCutoff;
                float WaterFilter = step(filterSceneMoveDepth,FilterNoise) * _FoamAlpha;



                //==================================================================================================================================================================
                //输入法线
                float4 NormaldataTex = float4(ReflactionNoise * 0.5f, ReflactionNoise * 0.5f, 1.0f, 1.0f);
                float3 Normaldata  = UnpackNormal(NormaldataTex);

                //half4 NormalTex = SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,i.uv.zw);   //法线贴图
                //float3 Normaldata = UnpackNormalScale(NormalTex,_NormalScale);               //控制法线强度
                //Normaldata.z = pow((1 - pow(normalTS.x,2) - pow(normalTS.y,2)),0.5);         //规范化法线

                //Light
                //float4 SHADOW_COORDS = TransformWorldToShadowCoord(i.positionWS);            //输入世界空间顶点位置
                //Light mainLight = GetMainLight(SHADOW_COORDS);

                Light mylight = GetMainLight();                                //获取场景主光源
                real4 LightColor = real4(mylight.color,1);                     //获取主光源的颜色


                //输入向量
                float3 worldpos = i.positionWS;
                float3 N = normalize(Normaldata.x * i.tangentWS * _NormalScale + Normaldata.y * i.bitangentWS * _NormalScale + i.normalWS);
                float3 V = normalize(_WorldSpaceCameraPos - i.positionWS);
                float3 L = mylight.direction;
                float3 H = normalize(V + L);
                float3 R = reflect(-V, N);

                //==============================================================================================================================
                //反射
                float3 IndirSpecularBaseColor = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0,samplerunity_SpecCube0,R,1.0).rgb;
                float3 F0 = lerp(0.04, IndirSpecularBaseColor, _Metallic);

                float NdotV = max(saturate(dot(N, V)), 0.000001);
                float NdotL = max(saturate(dot(N, L)), 0.000001);
                float HdotV = max(saturate(dot(H, V)), 0.000001);
                float NdotH = max(saturate(dot(H, N)), 0.000001);
                float LdotH = max(saturate(dot(H, L)), 0.000001);


                //===============================================================================================================================
                //DGF
                float D = DistributionGGX(NdotH,_Roughness);
                float K = pow(1 + _Roughness,2)/8;
                float G = GeometrySmith(NdotV,NdotL,K);
                float F = FresnelSchlick(LdotH,F0);               //这里需要F0

                //================================================直接光高光==========================================================================
                float3 specular = D * G * F/(4 * NdotV * NdotL);

                //================================================直接光漫反射============================================================================

                float3 ks = F;
                float3 kd = (1-ks) * (1 - _Metallic);
                float3 diffuse = kd * IndirSpecularBaseColor / PI;
                float3 DirectColor = (diffuse + specular) * NdotL * PI * mylight.color;

                //================================================合并输出============================================================================
                float4 final_color = lerp(watercolor,_FoamColor,WaterFilter);                   //水花水体输出
                final_color.rgb = lerp(SceneColor,final_color.rgb,final_color.a) + DirectColor;

                float4 col = float4(final_color.rgb,1);


                return watercolor;
            }
            ENDHLSL
        }
    }

}