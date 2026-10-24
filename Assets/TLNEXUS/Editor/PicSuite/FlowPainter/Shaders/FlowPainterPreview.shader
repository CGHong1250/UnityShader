Shader "Hidden/PicSuite/FlowPainterPreview"
{
    Properties
    {
        _MainTex ("Source", 2D) = "white" {}
        _FlowMapTex ("Flow Map", 2D) = "gray" {}
        _Phase0 ("Phase 0", Float) = 0
        _Phase1 ("Phase 1", Float) = 0.5
        _BlendFactor ("Blend Factor", Float) = 0
        _FlowStrength ("Flow Strength", Float) = 0.08
        _RepeatMode ("Repeat Mode", Float) = 1
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Overlay" }
        Cull Off
        ZWrite Off
        ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _FlowMapTex;
            float _Phase0;
            float _Phase1;
            float _BlendFactor;
            float _FlowStrength;
            float _RepeatMode;

            float2 AdjustUv(float2 uv)
            {
                if (_RepeatMode > 0.5)
                {
                    return frac(uv);
                }

                return saturate(uv);
            }

            fixed4 SampleSource(float2 uv)
            {
                return tex2D(_MainTex, AdjustUv(uv));
            }

            fixed4 frag(v2f_img i) : SV_Target
            {
                float2 uv = i.uv;
                float2 flowSample = tex2D(_FlowMapTex, uv).rg;
                if (all(abs(flowSample - (128.0 / 255.0)) < (0.25 / 255.0)) || _FlowStrength <= 0.0001)
                {
                    return SampleSource(uv);
                }

                float2 flow = (0.5 - flowSample) * _FlowStrength;
                fixed4 sample0 = SampleSource(uv + flow * _Phase0);
                fixed4 sample1 = SampleSource(uv + flow * _Phase1);
                return lerp(sample0, sample1, _BlendFactor);
            }
            ENDCG
        }
    }
}

/*
Homepage: www.tlnexus.com
Author: T·L
Email: 455471553@qq.com
WeChat Official Account: tlnexus
WeChat: Jxay_TL
*/
