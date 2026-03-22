Shader "Hong/Lambert"
{

    Properties
    { 
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "gray" {}
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalForward" }
        LOD 200

        Pass
        {
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

            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                //将顶点从对象空间转换到齐次裁剪空间
                OUT.vertex = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                //将法线的对象空间转换到世界空间,函数在SpaceTransforms.hlsl库里
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS.xyz,true);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                //Light类型和GetMainLight（）在RealtimeLight.hlsl定义
                Light MyLight = GetMainLight();
                //HLSL有一个新的变量类型real，定义在commom.hlsl库里。这个变量是会根据不同的平台编译float或half 
                real3 normalDir = normalize(IN.normalWS);
                real4 LightColor = real4(MyLight.color,1);
                float3 LightDir = normalize(MyLight.direction);
                //兰伯特光照模型算法 = (光源颜色 × 漫反射颜色)max(0, dot(normalWS,LightDir))
                //float LdotN = dot(LightDir,normalDir);
                //半兰伯特
                float LdotN = dot(LightDir,normalDir)*0.5+0.5;
                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);

                //添加环境光，unity_AmbientSky是unity的内置变量，可以直接添加
                half4 ambientColor = unity_AmbientSky;

                return color*_BaseColor*LightColor*LdotN + unity_AmbientSky;
            }
            ENDHLSL
        }
    }
}