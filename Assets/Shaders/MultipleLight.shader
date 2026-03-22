Shader "Hong/MultipleLight"
{

    Properties
    { 
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        _Smoothness("Smoothness",Range(0.0, 1)) = 0.2
        //添加法线纹理和法线强度变量
        [Normal]_NormalMap("NormalMap", 2D) = "bump"{}
        _NormalIntensity("NormalIntensity", Range(0,1)) = 1
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

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            //光照函数库
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;  
                float2 uv           : TEXCOORD0;

            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float4 uv           : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
                float3 tangentWS    : TANGENT;
                float3 viewDirWs    : TEXCOORD2;
                float3 BTangentWS   : TEXCOORD3;
                float3 positionWS   : TEXCOORD4;

            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST, _NormalMap_ST;
                float _Smoothness, _NormalIntensity;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                //自动帮你计算positionWS positionVS positionCS NDC[0,w]
                VertexPositionInputs vertexInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = vertexInputs.positionCS;   //物体从模型空间转换到裁剪空间
                OUT.positionWS = vertexInputs.positionWS;   //物体从模型空间转换到世界空间


                //TRANSFORM_TEX主要作用是拿顶点的uv去和材质球的tiling和offset作运算， 确保材质球里的缩放和偏移设置是正确的。
                OUT.uv.xy = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.uv.zw = TRANSFORM_TEX(IN.uv, _NormalMap);

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

                
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                //获取阴影
                float4 shadow_Coords = TransformWorldToShadowCoord(IN.positionWS);
                //Light类型和GetMainLight（）在RealtimeLight.hlsl定义
                Light lihgtData = GetMainLight(shadow_Coords);
                //阴影数据
                half shadow = lihgtData.shadowAttenuation;
                //法线纹理
                half4 normalMap = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, IN.uv.zw);
                //定义TBN矩阵，将法线纹理从切线空间转换到世界空间
                float3x3 TBN = {IN.tangentWS.xyz, IN.BTangentWS.xyz, IN.normalWS.xyz};
                float3 normalTS = UnpackNormalScale(normalMap,_NormalIntensity);
                //规范化法线，好像不写也没关系
                normalTS.z = pow((1 - pow(normalTS.x,2) - pow(normalTS.y,2)),0.5);
                float3 norWS = normalize(mul(normalTS,TBN));

                //HLSL有一个新的变量类型real，定义在commom.hlsl库里。这个变量是会根据不同的平台编译float或half 
                real3 lightDir = normalize(lihgtData.direction);
                real4 lightColor = real4(lihgtData.color * lihgtData.distanceAttenuation,1) * shadow;
                
                //计算反射方向
                real3 viewDirWs = normalize(IN.viewDirWs);
                real3 halfDir = normalize(viewDirWs + lightDir);

                //Half Lambert光照模型计算，代表直射光
                half4 lambert = dot(lightDir,norWS) * lightColor;

                //BlinnPhong高光计算
                float NdotH = dot(norWS,halfDir);
                half smoothness = exp2(10 * _Smoothness + 1);
                half4 specularColor = pow(saturate(NdotH),smoothness)*lightColor;

                int additionalLightCount = GetAdditionalLightsCount();//获取额外光源数量
                for (int i = 0; i < additionalLightCount; ++i)
                {
                    lihgtData = GetAdditionalLight(i, IN.positionWS);//根据index获取额外的光源数据
                    half3 attenuatedLightColor = lihgtData.color.rgb * lihgtData.distanceAttenuation * lihgtData.shadowAttenuation;
                    //这里用URP库里的光照模型函数
                    lambert.rgb += LightingLambert(attenuatedLightColor, lihgtData.direction, norWS);
                    specularColor.rgb += LightingSpecular(attenuatedLightColor, lihgtData.direction, norWS, viewDirWs, half4(1,1,1,1), smoothness);
                }


                //添加环境光，unity_AmbientSky是unity的内置变量，可以直接添加
                half4 ambientColor = unity_AmbientSky;

                //颜色纹理
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv.xy);
                
                //shadow = 1 - shadow;
                
                return baseMap*_BaseColor*lambert + specularColor + ambientColor;
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