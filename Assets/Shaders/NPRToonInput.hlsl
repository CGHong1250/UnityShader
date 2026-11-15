#ifndef NPR_TOON_INPUT_INCLUDED
#define NPR_TOON_INPUT_INCLUDED

// ===========================================================================
//  NPRToonInput.hlsl
//  NPR 卡通着色器的材质数据层（CBUFFER + 贴图声明 + SurfaceData 初始化）
//
//  与 LitToonInput.hlsl 的关系：
//    · 保留同名函数 SampleSpecularSmoothness / InitializeSimpleLitSurfaceData，
//      因为 ShadowCaster / GBuffer / DepthNormals / Meta 这几个 Pass 直接复用
//      URP 的 SimpleLit* Pass 文件，它们依赖这两个函数名和签名。
//    · 在 UnityPerMaterial 里追加 NPR 需要的参数。
//    · 去掉了 DOTS Instancing 块（本工程用不到，留着会让 CBUFFER 更容易错位）。
//      如果以后要上 DOTS，照着 LitToonInput.hlsl 的写法补回来即可。
// ===========================================================================

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

CBUFFER_START(UnityPerMaterial)
    // ---- 基础 ----
    float4 _BaseMap_ST;
    half4  _BaseColor;
    half4  _SpecColor;
    half4  _EmissionColor;
    half   _Cutoff;
    half   _Surface;

    // ---- 描边 ----
    half4  _OutlineColor;
    half   _OutlineWidth;

    // ---- 阶梯 / Ramp ----
    half   _RampSteps;          // 阶梯数量：1 = 两分，2 = 三分 ...
    half   _RampSmoothness;     // 阶梯边缘柔化
    half4  _RampShadowColor;    // 无 Ramp 贴图时的阴影色
    half4  _RampLightColor;     // 无 Ramp 贴图时的亮部色
    half4  _RampTint;           // 整体色调（乘在 Ramp 结果上）
    half   _ShadowOffset;       // 明暗交界线偏移（+ 受光面变大）
    half   _ToonNormalWeight;   // 用顶点法线算阶梯的比例（皮肤建议 1）
    half   _AmbientStrength;    // 环境光强度（避免天光把阴影冲灰）

    // ---- 卡通高光 ----
    half4  _ToonSpecColor;
    half   _ToonSpecIntensity;
    half   _ToonSpecPower;
    half   _ToonSpecThreshold;
    half   _ToonSpecSmoothness;

    // ---- 头发光带 ----
    half   _HairHighlightBias;  // -1~1，整体提亮/压暗
    half   _HairHighlightPower; // 越大光带越窄
    half   _HairHighlightScale;

    // ---- 阴影遮罩化（替代「实时阴影直接乘进梯度」）----
    half   _ShadowRampFloor;     // 阴影最暗处落在 Ramp 的位置（0=纯黑, 1=不压暗）
    half4  _ShadowTint;          // 阴影侧染色（暖色暗部，对应参考的 _RampColor_Skin）
    half   _FaceShadowStrength;  // 脸部接收实时阴影的强度（0=脸不吃实时阴影）

    // ---- MatCap ----
    half   _MatCapIntensity;
    half   _MatCapWeight;       // 0 = 全 PBR 高光，1 = 全 MatCap

    // ---- 边缘光 ----
    half4  _RimColor;
    half   _RimPower;
    half   _RimIntensity;
    half   _RimThreshold;
    half   _RimSmoothness;

    // ---- 脸部 SDF ----
    float4 _FaceRight;          // 脸的右方向（世界空间）
    float4 _FaceForward;        // 脸的上/前方向（世界空间）
    float4 _FaceShadowPosWS;    // 整脸共享的阴影采样点（由 C# 每帧写入）
    half   _FaceSDFSoftness;
    half   _FaceSDFOffset;
CBUFFER_END

// ---------------------------------------------------------------------------
//  贴图
//  _BaseMap / _BumpMap / _EmissionMap / _SpecGlossMap 里前三个由 URP 的
//  SurfaceInput.hlsl 声明，_SpecGlossMap 在下面补声明。
// ---------------------------------------------------------------------------
TEXTURE2D(_SpecGlossMap);   SAMPLER(sampler_SpecGlossMap);

TEXTURE2D(_RampMap);        SAMPLER(sampler_RampMap);
TEXTURE2D(_FaceLightMap);   SAMPLER(sampler_FaceLightMap);
TEXTURE2D(_MatCap);         SAMPLER(sampler_MatCap);
TEXTURE2D(_M);              SAMPLER(sampler_M);

// ---------------------------------------------------------------------------
//  与 LitToonInput.hlsl 保持一致的 SurfaceData 初始化
//  （SimpleLit 系列的 Pass 文件会调用它，不要改函数名/签名）
// ---------------------------------------------------------------------------
half4 SampleSpecularSmoothness(float2 uv, half alpha, half4 specColor, TEXTURE2D_PARAM(specMap, sampler_specMap))
{
    half4 specularSmoothness = half4(0, 0, 0, 1);
#ifdef _SPECGLOSSMAP
    specularSmoothness = SAMPLE_TEXTURE2D(specMap, sampler_specMap, uv) * specColor;
#elif defined(_SPECULAR_COLOR)
    specularSmoothness = specColor;
#endif

#ifdef _GLOSSINESS_FROM_BASE_ALPHA
    specularSmoothness.a = alpha;
#endif

    return specularSmoothness;
}

inline void InitializeSimpleLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
{
    outSurfaceData = (SurfaceData)0;

    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    outSurfaceData.alpha = albedoAlpha.a * _BaseColor.a;
    outSurfaceData.alpha = AlphaDiscard(outSurfaceData.alpha, _Cutoff);

    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;
    outSurfaceData.albedo = AlphaModulate(outSurfaceData.albedo, outSurfaceData.alpha);

    half4 specularSmoothness = SampleSpecularSmoothness(uv, outSurfaceData.alpha, _SpecColor,
                                                        TEXTURE2D_ARGS(_SpecGlossMap, sampler_SpecGlossMap));
    outSurfaceData.metallic = 0.0; // SimpleLit 不使用金属度，高光走 _SpecColor
    outSurfaceData.specular = specularSmoothness.rgb;
    outSurfaceData.smoothness = specularSmoothness.a;
    outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap));
    outSurfaceData.occlusion = 1.0;
    outSurfaceData.emission = SampleEmission(uv, _EmissionColor.rgb,
                                             TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));
}

#endif // NPR_TOON_INPUT_INCLUDED
