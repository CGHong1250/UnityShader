#ifndef UNIVERSAL_LIT_INPUT_INCLUDED
#define UNIVERSAL_LIT_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"

CBUFFER_START(UnityPerMaterial)
    float4 _BaseMap_ST;
    float4 _BaseColor;
    float4 _SpecColor;
    float4 _EmissionColor;
    float _Cutoff;
    float _Smoothness;
    float _BumpScale;
    float _Metallic;
    float _OcclusionStrength;
    float _Surface;

    // MatCap
    float _MatcapIntensity;
    float _MatcapScale;
    float4 _MatcapOffset;

    // 水面特效
    float4 _ShallowWater;
    float4 _DeepWater;
    float _DepthDistance;
    float _DepthFogDistance;
    float _Refraction;
    float _UJump;
    float _VJump;
    float _FlowMapTiling;
    float _Speed;
    float _FlowStrength;
    float _DistortStrength;
    float _NormalTiling;
    float4 _WaveA;
    float4 _WaveB;
    //泡沫
    float _FoamWidth;
    float _FoamThreshold;
    float _FoamTiling;
    float _FoamWaveScale;
    float _FoamWaveNumber;
    // 焦散
    float _CausticIntensity;
    float _CausticScale;
    float _CausticSpeed;

CBUFFER_END

TEXTURE2D(_PerlingNoise); SAMPLER(sampler_PerlingNoise);
TEXTURE2D(_MatcapTex); SAMPLER(sampler_MatcapTex);
TEXTURE2D(_FlowMap); SAMPLER(sampler_FlowMap); // 水的流动贴图
TEXTURE2D(_CausticTexture); SAMPLER(sampler_CausticTexture);

// 强制高光工作流的采样函数
half4 SampleMetallicSpecGloss()
{
    half4 specGloss;
    specGloss.rgb = _SpecColor.rgb;
    return specGloss;
}

// 主渲染函数：删掉了 PBRMap 和顶点混合，强制 Specular
inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
{
    // 采样基础纹理
    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor.a, _Cutoff);
    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;

    // 高光工作流写死
    half4 specGloss = SampleMetallicSpecGloss();
    outSurfaceData.metallic = 0.0;
    outSurfaceData.specular = specGloss.rgb;

    // 平滑度和AO（去掉了PBR贴图，直接用常量，后续你可以改成采样Mask）
    outSurfaceData.smoothness = _Smoothness;
    outSurfaceData.occlusion = _OcclusionStrength;
    
    // 采样基础法线
    outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);

    outSurfaceData.albedo = AlphaModulate(outSurfaceData.albedo, outSurfaceData.alpha);

    // 采样自发光纹理
#if _EMISSION
    half3 emissionCol = SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));
    outSurfaceData.emission = emissionCol;
#else
    outSurfaceData.emission = half3(0.0, 0.0, 0.0);
#endif
    
    outSurfaceData.clearCoatMask = half(0.0);
    outSurfaceData.clearCoatSmoothness = half(0.0);
}

// ================= MatCap 工具函数 =================
void ApplyMatCap(inout SurfaceData surfaceData, float3 normalWS, float3 viewDirWS)
{
    half3 worldUp = abs(viewDirWS.y) > 0.999 ? half3(0.0, 0.0, 1.0) : half3(0.0, 1.0, 0.0);
    half3 viewRight = normalize(cross(worldUp, viewDirWS));
    half3 viewUp = normalize(cross(viewDirWS, viewRight));

    half3 normalInView;
    normalInView.x = dot(normalWS, viewRight);
    normalInView.y = dot(normalWS, viewUp);
    normalInView.z = dot(normalWS, viewDirWS);

    half2 matcapUV = normalInView.xy * 0.5 + 0.5;
    matcapUV.y = 1.0 - matcapUV.y; 
    
    matcapUV = (matcapUV - 0.5) * _MatcapScale + 0.5;
    matcapUV += _MatcapOffset.xy;
    matcapUV = clamp(matcapUV, 0.001, 0.999);

    half3 matcapColor = SAMPLE_TEXTURE2D(_MatcapTex, sampler_MatcapTex, matcapUV).rgb;
    matcapColor *= _MatcapIntensity;
    
    surfaceData.albedo = surfaceData.albedo + surfaceData.albedo * matcapColor;
}

 // ================= 水面核心函数 =================
    float3 FlowUV (float2 uv, float2 jump, float tiling, float speed, float flowStrength, float time, bool flowB)
    {
        float3 uvw;
        float phaseOffset = flowB ? 0.5 : 0;
        float4 flowMap = SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap, uv);
        float2 flowVector = flowMap.rg * 2 - 1;
        flowVector *= flowStrength;
        float noise = flowMap.a;
        time = time * speed + noise;
        float progress = frac(time + phaseOffset);
        uvw.xy = uv - flowVector * progress;
        uvw.xy *= tiling;
        uvw.xy += phaseOffset;
        uvw.xy += (time - progress) * jump;
        uvw.z = 1 - abs(1 - 2 * progress);
        return uvw;
    }

    float3 GerstnerWave (float4 wave, float3 p, inout float3 tangent, inout float3 binormal) 
    {
        float steepness = wave.z;
        float wavelength = wave.w;
        float k = 2 * PI / wavelength;
        float c = sqrt(9.8 / k);
        float2 d = normalize(wave.xy);
        float f = k * (dot(d, p.xz) - c * _Time.y);
        float a = steepness / k;
        tangent += float3(-d.x * d.x * (steepness * sin(f)), d.x * (steepness * cos(f)), -d.x * d.y * (steepness * sin(f)));
        binormal += float3(-d.x * d.y * (steepness * sin(f)), d.y * (steepness * cos(f)), -d.y * d.y * (steepness * sin(f)));
        return float3(d.x * (a * cos(f)), a * sin(f), d.y * (a * cos(f)));
    }
// ===============================================

// ================= 焦散算法 =================
#ifndef PI
#define PI 3.14159265359
#endif

float2 CausticPanner(float2 uv, float direction, float speed, float2 offset, float tiling) {
    direction = direction * 2.0 - 1.0;
    float2 dir = normalize(float2(cos(PI * direction), sin(PI * direction)));
    return (dir * _Time.y * speed) + offset + (uv * tiling);
}

float3 CausticRgbSplit(float split, float2 uv) {
    float2 uv_r = uv + float2(split, split);
    float2 uv_g = uv + float2(split, -split);
    float2 uv_b = uv + float2(-split, -split);

    float4 r = SAMPLE_TEXTURE2D(_CausticTexture, sampler_CausticTexture, uv_r);
    float4 g = SAMPLE_TEXTURE2D(_CausticTexture, sampler_CausticTexture, uv_g);
    float4 b = SAMPLE_TEXTURE2D(_CausticTexture, sampler_CausticTexture, uv_b);
    return float3(r.r, g.g, b.b);
}

float3 GetCausticColor(float2 uv) {
    float strength = _CausticIntensity;
    float split =   0.01;
    float speed = _CausticSpeed;
    float scale = _CausticScale/16;

    float3 texture1 = CausticRgbSplit(split, CausticPanner(uv, 1.0, speed, float2(0.0, 0.0), 1.0 * scale));
    float3 texture2 = CausticRgbSplit(split, CausticPanner(uv, 1.0, speed, float2(0.0, 0.0), -1.0 * scale));
    float3 textureCombined = min(texture1, texture2);

    return strength * textureCombined;
}
// ============================================



#endif // UNIVERSAL_LIT_INPUT_INCLUDED