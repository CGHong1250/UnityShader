Shader "Hong/BlinnPhongNoramalTexture"
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
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;  
                float2 uv           : TEXCOORD0;

            };

            struct Varyings
            {
                float4 vertex       : SV_POSITION;
                float4 uv           : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
                float3 tangentWS    : TANGENT;
                float3 viewDirWs    : TEXCOORD2;
                float3 BTangentWS   : TEXCOORD3;

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
                //将顶点从对象空间转换到齐次裁剪空间
                OUT.vertex = TransformObjectToHClip(IN.positionOS.xyz);

                //TRANSFORM_TEX主要作用是拿顶点的uv去和材质球的tiling和offset作运算， 确保材质球里的缩放和偏移设置是正确的。
                OUT.uv.xy = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.uv.zw = TRANSFORM_TEX(IN.uv, _NormalMap);

                //将法线的对象空间转换到世界空间,函数在SpaceTransforms.hlsl库里
                //也可以用GetVertexNormalInputs（float3 normalOS, float4 tangentOS）函数，在ShaderVariablesFunctions.hlsl库里
                VertexNormalInputs normalInput = GetVertexNormalInputs(IN.normalOS, IN.tangentOS);
                //OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS.xyz,true);
                OUT.normalWS = normalInput.normalWS;

                //将顶点切线从对象空间转换到世界空间
                //OUT.tangentWS.xyz = TransformObjectToWorldDir(IN.tangentOS.xyz);
                OUT.tangentWS = normalInput.tangentWS;

                //计算副切线时，叉乘法线，切线，并在乘切线的w值判断正负，在乘负奇数缩放影响因子
                //unity_WorldTransformParams.w  ：定义于unityShaderVariables.cginc中.模型的Scale值是三维向量，即xyz,当这三个值中有奇数个值为负时（1个或者3个值全为负时），unity_WorldTransformParams.w=-1,否则为1
                //有关unity_WorldTransformParams的解释：https://www.cnblogs.com/MoFishLi/p/14700008.html
                //OUT.BTangentWS.xyz = cross(OUT.normalWS.xyz, OUT.tangentWS.xyz) * IN.tangentOS.w * unity_WorldTransformParams.w;
                OUT.BTangentWS = normalInput.bitangentWS;

                //世界空间相机的位置减去世界空间顶点的位置就可以得到相机视角的方向
                OUT.viewDirWs = normalize(_WorldSpaceCameraPos.xyz - TransformObjectToWorld(IN.positionOS.xyz));
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                //Light类型和GetMainLight（）在RealtimeLight.hlsl定义
                Light MyLight = GetMainLight();

                //法线纹理
                half4 normalMap = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, IN.uv.zw);
                //定义TBN矩阵，将法线纹理从切线空间转换到世界空间
                float3x3 TBN = {IN.tangentWS.xyz, IN.BTangentWS.xyz, IN.normalWS.xyz};
                float3 normalTS = UnpackNormalScale(normalMap,_NormalIntensity);
                //规范化法线，好像不写也没关系
                normalTS.z = pow((1 - pow(normalTS.x,2) - pow(normalTS.y,2)),0.5);
                float3 norWS = normalize(mul(normalTS,TBN));

                //HLSL有一个新的变量类型real，定义在commom.hlsl库里。这个变量是会根据不同的平台编译float或half 
                real3 normalDir = normalize(IN.normalWS);
                real3 LightDir = normalize(MyLight.direction);
                real4 LightColor = real4(MyLight.color * MyLight.distanceAttenuation,1);
                
                //计算反射方向
                real3 viewDirWs = normalize(IN.viewDirWs);
                real3 halfDir = normalize(viewDirWs + LightDir);

                //Half Lambert光照模型计算，代表直射光
                float LdotN = dot(LightDir,norWS)*0.5+0.5;

                //BlinnPhong高光计算
                float NdotH = dot(norWS,halfDir);
                half smoothness = exp2(10 * _Smoothness + 1);
                half4 specularValue = pow(saturate(NdotH),smoothness)*LightColor;
                //添加环境光，unity_AmbientSky是unity的内置变量，可以直接添加
                half4 ambientColor = unity_AmbientSky;
                
                //颜色纹理
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv.xy);
                
                return baseMap*_BaseColor*LdotN * LightColor + specularValue + ambientColor;
            }
            ENDHLSL
        }
    }
}