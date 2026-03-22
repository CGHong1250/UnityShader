Shader "Hong/Unlit"
{

    Properties
    { 
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "gray" {}
    }

    SubShader
    {
        //Subshader使用标签，这段代码描述 RenderType（渲染顺序）使用Opaque（不透明）
        //RenderPipeline（渲染管线）使用UniversalPipeline（URP管线），解决URP和SRP Batcher属性显示不兼容问题。
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            // HLSL代码，Unity SRP使用HLSL语言。
            HLSLPROGRAM
            // 这一行定义了顶点着色器的名称。
            #pragma vertex vert
            // 这一行定义了片段着色器的名称。
            #pragma fragment frag

            // Core.hlsl 文件包含常用 HLSL 的定义宏和函数，还包含对其他的 #include 引用HLSL 文件（例如 Common.hlsl、SpaceTransforms.hlsl 等
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


            // 此示例使用 Attributes 结构作为顶点着色器中的输入结构。
            struct Attributes
            {
                 // positionOS 变量包含对象空间中的顶点位置。
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                // 此结构中的位置必须具有 SV_POSITION 语义
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
            };

            // 将纹理定义为 2D 纹理并为其指定采样器
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            //为了使平铺和偏移正常工作，必须在“CBUFFER”块中声明带有_ST后缀的纹理属性
            //为了确保Unity着色器与SRP批处理兼容，在CBUFFER块中声明材质属性，命名为UnityPerMaterial
            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
            CBUFFER_END

            // 顶点着色器定义及其在 Varyings 结构中定义的属性。 vert 函数的类型必须与其返回的类型（结构）匹配。
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                // TransformObjectToHClip 函数将顶点位置从对象空间转换到同质剪辑空间。
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            // 片段着色器定义。
            half4 frag(Varyings IN) : SV_Target
            {
                // 使用SAMPLE_TEXTURE2D 宏给定的采样器对纹理进行采样
                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
                return color*_BaseColor;
            }
            ENDHLSL
        }
    }
}