Shader "Hong/Phong"
{

    Properties
    { 
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "gray" {}
        _Smoothness("_Smoothness",Range(0.0, 1)) = 0.2
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        LOD 200

        Pass
        {
            Tags{ "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            //让雾起作用
            #pragma multi_compile_fog 

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            //光照函数库
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


            struct Attributes
            {
                float4 positionOS   : POSITION;
                float4 normalOS       : NORMAL;
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                float4 vertex       : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
                float3 viewDirWs    : TEXCOORD2;

            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
                float _Smoothness;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                //将顶点从对象空间转换到齐次裁剪空间
                OUT.vertex = TransformObjectToHClip(IN.positionOS.xyz);
                //TRANSFORM_TEX主要作用是拿顶点的uv去和材质球的tiling和offset作运算， 确保材质球里的缩放和偏移设置是正确的。
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                //将法线的对象空间转换到世界空间,函数在SpaceTransforms.hlsl库里
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS.xyz,true);
                //世界空间相机的位置减去世界空间顶点的位置就可以得到相机视角的方向
                OUT.viewDirWs = normalize(_WorldSpaceCameraPos.xyz - TransformObjectToWorld(IN.positionOS.xyz));
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                //Light类型和GetMainLight（）在RealtimeLight.hlsl定义
                Light MyLight = GetMainLight();

                //HLSL有一个新的变量类型real，定义在commom.hlsl库里。这个变量是会根据不同的平台编译float或half 
                real3 normalDir = normalize(IN.normalWS);
                real3 LightDir = normalize(MyLight.direction);
                real4 LightColor = real4(MyLight.color,1);
                
                //计算反射方向
                real3 viewDirWs = normalize(IN.viewDirWs);
                real3 ReflectDir = normalize(reflect(-LightDir,normalDir));

                //Half Lambert光照模型计算，代表直射光
                float LdotN = dot(LightDir,normalDir)*0.5+0.5;

                //Phong高光计算
                float RdotV = dot(ReflectDir,viewDirWs);
                half smoothness = exp2(10 * _Smoothness + 1);
                half specularValue = pow(saturate(RdotV),smoothness);
                //添加环境光，unity_AmbientSky是unity的内置变量，可以直接添加
                half4 ambientColor = unity_AmbientSky;

                //纹理和漫反射颜色
                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
                return color*_BaseColor*LdotN*LightColor + specularValue + unity_AmbientSky;
            }
            ENDHLSL
        }
    }
}