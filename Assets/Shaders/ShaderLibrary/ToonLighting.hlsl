#ifndef TOON_LIGHTING_INCLUDED
#define TOON_LIGHTING_INCLUDED

// 材质参数（_ToonXxx / _RimXxx）都在 CartonnInput.hlsl 的 UnityPerMaterial 里
#include "Assets/Shaders/CartonnInput.hlsl"

// ===========================================================================
//  卡通（Toon / Cel）光照
// ---------------------------------------------------------------------------
//  设计思路：
//    PBR 用 "NdotL * 光照颜色" 做连续过渡；卡通渲染要把光照结果量化成若干段
//    （赛璐璐的明暗交界线），再配一块硬边高光 + 一条边缘光。
//
//    流程： NdotL -> 半兰伯特 -> 阴影偏移 -> 乘阴影/距离衰减 -> 阶梯量化 -> 明暗色
//
//  依赖：
//    · URP  Lighting.hlsl  (Light / InputData / SurfaceData / GetMainLight ...)
//    · CartonnInput.hlsl   (_ToonXxx / _RimXxx 材质属性)
//
//  调用：
//    half4 color = UniversalFragmentToon(inputData, surfaceData, normalize(input.normalWS));
// ===========================================================================

// ---------------------------------------------------------------------------
//  工具函数
// ---------------------------------------------------------------------------

// 硬边判断：value 超过 threshold 输出 1，softness 控制过渡宽度
half ToonHardStep(half value, half threshold, half softness)
{
    // 防止 softness == 0 时 smoothstep 内部除零产生 NaN
    half edge = max(softness, 1.0e-4);
    return smoothstep(threshold - edge, threshold + edge, value);
}

// 把 [0,1] 的连续光照梯度量化成 _ToonSteps 段阶梯
//   gradient : 光照梯度（0 = 全暗，1 = 全亮）
//   steps    : 段数，1 = 经典两分（亮/暗），2 = 三分，以此类推
//   softness : 0 = 硬边赛璐璐，1 = 接近平滑渐变
half ToonQuantize(half gradient, half steps, half softness)
{
    steps = max(steps, 1.0);

    half scaled = saturate(gradient) * steps;

    // 每一段的中间位置切换，softness 控制切换宽度（占一段的比例）
    half w = max(saturate(softness) * 0.5, 1.0e-4);
    half t = smoothstep(0.5 - w, 0.5 + w, frac(scaled));

    return (floor(scaled) + t) / steps;
}

// 由光照梯度得到"明暗系数"（不含光源颜色 / albedo）
half3 ToonRampColor(half gradient)
{
    half stepped = ToonQuantize(gradient, _ToonSteps, _ToonSmoothness);

    // 亮部色 <-> 阴影色
    half3 ramp = lerp(_ToonShadowColor.rgb, _ToonLightColor.rgb, stepped);

#ifdef _TOONRAMP_MAP
    // Ramp 贴图：横轴固定取 0.5，纵轴用阶梯值索引
    // 这样一张 1D 渐变贴图就能画出"彩色明暗带"（比如皮肤的红润阴影）
    ramp *= SAMPLE_TEXTURE2D(_ToonRampMap, sampler_ToonRampMap, float2(0.5, stepped)).rgb;
#endif

    return ramp;
}

// ---------------------------------------------------------------------------
//  漫反射：半兰伯特 x（阴影 x 距离衰减）-> 阶梯
//  shadingNormal：用来算明暗阶梯的法线。皮肤建议传顶点法线（_ToonNormalWeight = 1），
//                 否则法线贴图的细节会把明暗交界线打碎成一堆噪点
//  注意：AO 不参与直射光，只压暗环境光（和 URP 的 PBR 保持一致）
// ---------------------------------------------------------------------------
half3 ToonDiffuse(Light light, half3 shadingNormal, half3 albedo)
{
    half NdotL = dot(shadingNormal, light.direction);

    // 半兰伯特：把 [-1,1] 映到 [0,1]，暗部不会死黑，过渡更柔和
    half halfLambert = NdotL * 0.5 + 0.5;

    // 阴影偏移：正数把交界线往暗部推，受光面变大（脸显得更亮更干净）
    half shifted = saturate(halfLambert + _ToonShadowOffset);

    // 实时阴影 + 距离衰减一起进入梯度：
    // 这样"投影阴影"和"背光面"走同一条阶梯，明暗形状更统一
    half attenuation = light.shadowAttenuation * light.distanceAttenuation;
    half gradient = shifted * attenuation;

    return albedo * ToonRampColor(gradient) * light.color;
}

// ---------------------------------------------------------------------------
//  高光：Blinn-Phong + 阈值判断，得到"一块"而不是"一片"的硬高光
//  smoothness（PBR 贴图 G 通道）控制锐度；metallic（R 通道）让高光带上基色
// ---------------------------------------------------------------------------
half3 ToonSpecular(Light light, half3 normalWS, half3 viewDirWS, half NdotL,
                   half smoothness, half metallic, half3 albedo)
{
    half3 halfDir = SafeNormalize(light.direction + viewDirWS);
    half NdotH = saturate(dot(normalWS, halfDir));

    // smoothness 0.5 时等于 _ToonSpecPower；越小高光越大越糊，越大越锐越小
    half power = max(_ToonSpecPower * exp2((saturate(smoothness) - 0.5) * 4.0), 1.0);

    half spec = pow(NdotH, power);

    // 只保留超过阈值的那一块，边缘用 _ToonSpecSmoothness 柔化
    half specMask = ToonHardStep(spec, _ToonSpecThreshold, _ToonSpecSmoothness);

    // 背光面不出高光
    specMask *= smoothstep(0.0, 0.05, NdotL);

    // 阴影里保留一点高光，避免画面太死板
    specMask *= lerp(0.35, 1.0, light.shadowAttenuation);

    // 金属的高光带基色（metallic 越大越接近 albedo）
    half3 specColor = lerp(_ToonSpecColor.rgb, albedo, saturate(metallic));

    return specColor * specMask * _ToonSpecIntensity * light.color;
}

// ---------------------------------------------------------------------------
//  边缘光：菲涅尔 + 阈值，卡通边缘光通常是一条清晰的亮边
//  （在 ForwardLit 里被累加进 surfaceData.emission）
// ---------------------------------------------------------------------------
half3 ToonRim(half3 normalWS, half3 viewDirWS)
{
    half NdotV = saturate(dot(normalWS, viewDirWS));

    // _RimScale 控制菲涅尔的锐度（越大边缘越窄）
    half fresnel = pow(1.0 - NdotV, max(_RimScale, 1.0e-4));

    half rim = ToonHardStep(fresnel, _RimThreshold, _RimSmoothness);

    return _RimColor.rgb * rim * _RimLightness;
}

// ---------------------------------------------------------------------------
//  卡通版 UniversalFragmentPBR
//  geometricNormalWS：顶点法线（不含法线贴图），用来稳定明暗交界线
// ---------------------------------------------------------------------------
half4 UniversalFragmentToon(InputData inputData, SurfaceData surfaceData, half3 geometricNormalWS)
{
    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);

    uint meshRenderingLayers = GetMeshRenderingLayer();
    Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);

    half3 albedo = surfaceData.albedo;

    // 两套法线：
    //   shadingNormal -> 算明暗阶梯（可用 _ToonNormalWeight 逐渐换成顶点法线）
    //   detailNormal  -> 算法线细节 / 高光（保留法线贴图的凹凸感）
    half3 detailNormal  = inputData.normalWS;
    half3 shadingNormal = normalize(lerp(detailNormal, geometricNormalWS, saturate(_ToonNormalWeight)));

    half3 viewDirWS = inputData.viewDirectionWS;
    half  NdotL     = dot(detailNormal, mainLight.direction);

    half3 mainDiffuse  = half3(0.0, 0.0, 0.0);
    half3 mainSpecular = half3(0.0, 0.0, 0.0);

    bool mainLightVisible = true;
#ifdef _LIGHT_LAYERS
    mainLightVisible = IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers);
#endif

    if (mainLightVisible)
    {
        mainDiffuse = ToonDiffuse(mainLight, shadingNormal, albedo);

#ifdef _TOONSPEC_ON
        mainSpecular = ToonSpecular(mainLight, detailNormal, viewDirWS, NdotL,
                                    surfaceData.smoothness, surfaceData.metallic, albedo);
#endif
    }

    // ---- 附加光源：同样走阶梯，保证多灯下风格统一 ----
    half3 additionalDiffuse = half3(0.0, 0.0, 0.0);

#if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();

#if USE_FORWARD_PLUS
    for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

#ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
        {
            additionalDiffuse += ToonDiffuse(light, shadingNormal, albedo);
        }
    }
#endif

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

#ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
        {
            additionalDiffuse += ToonDiffuse(light, shadingNormal, albedo);
        }
    LIGHT_LOOP_END
#endif

#if defined(_ADDITIONAL_LIGHTS_VERTEX)
    additionalDiffuse += inputData.vertexLighting * albedo;
#endif

    // ---- 环境光：卡通不追求物理正确，只给一个整体底色 ----
    // _ToonAmbientStrength 调小可以避免天光把阴影冲成灰色（皮肤尤其明显）
    half3 giColor = inputData.bakedGI * albedo * _ToonAmbientStrength * aoFactor.indirectAmbientOcclusion;

    // ---- 自发光 / 边缘光 ----
    half3 emission = surfaceData.emission;

    half3 finalColor = mainDiffuse + mainSpecular + additionalDiffuse + giColor + emission;

    finalColor = MixFog(finalColor, inputData.fogCoord);

    return half4(finalColor, surfaceData.alpha);
}

#endif // TOON_LIGHTING_INCLUDED
