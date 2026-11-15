#ifndef NPR_TOON_LIGHTING_INCLUDED
#define NPR_TOON_LIGHTING_INCLUDED

// ===========================================================================
//  NPRToonLighting.hlsl
//  卡通光照的核心算法层（只管"怎么算颜色"，不碰 Pass、不碰 CBUFFER 定义）
//
//  依赖：调用方必须先 include
//        · NPRToonInput.hlsl
//        · ShaderLibrary/Lighting.hlsl （提供 Light / InputData / GetMainLight ...）
//
//  设计要点（对照 URP_NPR.shader 的思路）：
//    1. 明暗 = Ramp 查表：把 N·L 量化成 N 档，再去采样一张 1D Ramp 贴图。
//       "半兰伯特 + 阴影 + 阶梯" 三步合一，一次采样出结果。
//    2. 阴影不单独乘，而是并进 Ramp 的采样坐标，让投影阴影和背光面走同一套色阶。
//    3. 脸部不用 N·L，用预烘焙的 SDF 图 + 光照角度比较（见 NPRFaceGradient）。
//    4. 头发高光用 N·V（视线角）而不是 N·H，得到"沿轮廓的一圈光带"。
//    5. MatCap 用视空间法线当 UV，金属靠它而不是物理高光。
//    6. 光源颜色只乘一次（原 NPR 在三个地方各乘一次，这是要避免的坑）。
// ===========================================================================

#include "Assets/Shaders/NPRToonInput.hlsl"

#if defined(_INNER_EDGE_ON)
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
#endif

// ---------------------------------------------------------------------------
//  1. 阶梯量化
//     把 [0,1] 的连续光照梯度压成 _RampSteps 段
//     softness = 0 是硬边赛璐璐，越大越接近平滑
// ---------------------------------------------------------------------------
half NPRQuantize(half gradient, half steps, half softness)
{
    steps = max(steps, 1.0);

    half scaled = saturate(gradient) * steps;

    // 每段的中间位置切换；w 是切换宽度（占一段的比例）
    half w = max(saturate(softness) * 0.5, 1.0e-4);
    half t = smoothstep(0.5 - w, 0.5 + w, frac(scaled));

    return (floor(scaled) + t) / steps;
}

// ---------------------------------------------------------------------------
//  2. Ramp 采样：横轴固定 0.5，只用纵轴 —— 本质是 1D LUT
//     没开 _RAMP_MAP 时退化成"阴影色 <-> 亮部色"两色插值
// ---------------------------------------------------------------------------
half3 NPRSampleRamp(half t)
{
#ifdef _RAMP_MAP
    half3 ramp = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(0.5, saturate(t))).rgb;
#else
    half3 ramp = lerp(_RampShadowColor.rgb, _RampLightColor.rgb, saturate(t));
#endif
    return ramp * _RampTint.rgb;
}

// ---------------------------------------------------------------------------
//  3. 光照梯度：半兰伯特 -> 交界线偏移 -> 乘阴影/距离衰减
//     注意 AO 不参与这里（AO 只压环境光），和 URP 的 PBR 约定一致
// ---------------------------------------------------------------------------
half NPRGradient(Light light, half3 shadingNormal)
{
    half NdotL = dot(shadingNormal, light.direction);

    // 半兰伯特：暗部不会死黑，交界线更可控
    half halfLambert = NdotL * 0.5 + 0.5;

    // _ShadowOffset 为正当于把交界线往暗部推（脸更亮更干净）
    half shifted = saturate(halfLambert + _ShadowOffset);

    return shifted * saturate(light.shadowAttenuation) * light.distanceAttenuation;
}

// ---------------------------------------------------------------------------
//  4. 脸部 SDF
//     思路：SDF 图里存的不是"亮度"，而是"该像素从亮变暗的临界角度"。
//           运行时拿 |L·Right|² 当查询值，跟图里的阈值比较，得到干净的交界线。
//     关键细节：
//       · 按 faceNL 正负做 UV 左右镜像 —— 一张图同时管左光和右光
//       · FL 项处理背光：光在头后方时整脸压暗
//       · 返回的是 0~1 的"亮度梯度"，后面照样走 Ramp
// ---------------------------------------------------------------------------
half NPRFaceGradient(float2 uv, Light light)
{
    half3 rightWS   = normalize(_FaceRight.xyz);
    half3 forwardWS = normalize(_FaceForward.xyz);

    // 光在脸的水平方向上的分量（决定左光/右光）
    half faceNL = dot(light.direction, rightWS);

    // 背光压暗：光越偏向脑后，FL 越接近 0
    half FL = smoothstep(0.0, 0.2, max(0.0, dot(light.direction, forwardWS)));

    // 左右镜像
    float2 faceUV = float2(step(faceNL, 0.0) * uv.x + step(0.0, faceNL) * (1.0 - uv.x), uv.y);

    half4 sdf = SAMPLE_TEXTURE2D(_FaceLightMap, sampler_FaceLightMap, faceUV);
    half sdfValue = (sdf.r + sdf.g) * 0.5 + _FaceSDFOffset;

    // 用角度的平方当查询值（比一次方更接近美术画图时的手感）
    half a = abs(faceNL);
    a *= a;

    half soft = max(_FaceSDFSoftness, 1.0e-4);
    half l = smoothstep(a - soft, a + soft, sdfValue) * FL;

    // 投影阴影直接把整脸压到暗部色阶
    return saturate(l * saturate(light.shadowAttenuation));
}

// ---------------------------------------------------------------------------
//  5. 头发光带：N·V 而不是 N·H
//     N·H 会随光源滑动成"点状"高光；N·V 只跟视线有关，
//     得到沿轮廓的一圈亮边 —— 动漫头发那条光带。
// ---------------------------------------------------------------------------
half NPRHairBand(Light light, half3 normalWS, half3 viewDirWS)
{
    half NdotV = saturate(dot(normalWS, viewDirWS));
    half NdotL = saturate(dot(normalWS, light.direction));

    half band = pow(saturate(NdotV + _HairHighlightBias), max(_HairHighlightPower, 1.0));
    band *= NdotL;                                          // 背光不出光带
    band *= saturate(light.shadowAttenuation);              // 阴影里不亮

    return saturate(band) * _HairHighlightScale;
}

// ---------------------------------------------------------------------------
//  6. 卡通高光：Blinn-Phong + 阈值 -> "一块"而不是"一片"
// ---------------------------------------------------------------------------
half NPRSpecularMask(Light light, half3 normalWS, half3 viewDirWS, half smoothness, half NdotL)
{
    half3 halfDir = SafeNormalize(light.direction + viewDirWS);
    half  NdotH   = saturate(dot(normalWS, halfDir));

    // smoothness 0.5 时等于 _ToonSpecPower；越大越锐
    half power = max(_ToonSpecPower * exp2((saturate(smoothness) - 0.5) * 4.0), 1.0);
    half spec  = pow(NdotH, power);

    half soft = max(_ToonSpecSmoothness, 1.0e-4);
    half mask = smoothstep(_ToonSpecThreshold - soft, _ToonSpecThreshold + soft, spec);

    mask *= smoothstep(0.0, 0.05, NdotL);                   // 背光不出高光
    mask *= lerp(0.35, 1.0, saturate(light.shadowAttenuation)); // 阴影里保留一点

    return mask;
}

// ---------------------------------------------------------------------------
//  7. MatCap：视空间法线直接当 UV
//     相机怎么转，反光都"贴"在物体上跟着走，不需要反射向量。
// ---------------------------------------------------------------------------
half3 NPRMatCap(half3 normalWS, half3 viewDirWS)
{
    half3 normalVS = TransformWorldToViewDir(normalWS);

    half2 uv = normalVS.xy * 0.5 + 0.5;
    uv.y = 1.0 - uv.y;   // 视图空间 Y 向上、贴图 V 向下，需要翻一次
                         // 如果你的 MatCap 图上下颠倒，把这一行注释掉即可
    uv = clamp(uv, 0.001, 0.999);

    return SAMPLE_TEXTURE2D(_MatCap, sampler_MatCap, uv).rgb * _MatCapIntensity;
}

// ---------------------------------------------------------------------------
//  8. 边缘光：菲涅尔 + 阈值，得到一条清晰的亮边
// ---------------------------------------------------------------------------
half3 NPRRim(half3 normalWS, half3 viewDirWS, half shadowAtten)
{
    half NdotV = saturate(dot(normalWS, viewDirWS));

    // _RimPower 越大边缘越窄
    half fresnel = pow(1.0 - NdotV, max(_RimPower, 1.0e-4));

    half soft = max(_RimSmoothness, 1.0e-4);
    half rim = smoothstep(_RimThreshold - soft, _RimThreshold + soft, fresnel);

    // 阴影侧边缘光弱一点，避免暗部糊成一片亮边
    rim *= lerp(0.35, 1.0, saturate(shadowAtten));

    return _RimColor.rgb * (rim * _RimIntensity);
}

// ---------------------------------------------------------------------------
//  9. 内轮廓：屏幕空间深度边缘检测
//     原理：如果相邻像素比当前像素"更近"，说明当前像素处在一个被遮挡的边界上，
//           这个边界就是内轮廓（袖子压身体、下巴压脖子那种线）。
//     对比原 NPR 的做法：
//       原版要一个 SSDepthOffsetPassFeature 把物体画成纯色+深度存到 _DepthMaskColor；
//       这里直接读 URP 的 _CameraDepthTexture，不需要写 RendererFeature，
//       代价是必须在 URP Asset 里打开 Depth Texture（可见"使用说明"）。
//
//     注意：这里不用 positionCS.z / positionCS.w 取自身深度 ——
//     像素阶段的 SV_POSITION.w 已经是 1/w，除出来不是线性深度。
//     改用世界坐标转观察空间取 -z，语义明确，不依赖平台约定。
// ---------------------------------------------------------------------------
half NPRInnerEdge(float2 screenUV, half selfEyeDepth)
{
#if defined(_INNER_EDGE_ON)
    // _ScreenParams.zw = (1 + 1/W, 1 + 1/H)，所以 zw-1 = 一个像素的 UV 大小
    float2 texel = float2(_ScreenParams.z - 1.0, _ScreenParams.w - 1.0) * max(_InnerEdgeWidth, 0.0);

    float d1 = SampleSceneDepth(screenUV + float2( texel.x, 0.0));
    float d2 = SampleSceneDepth(screenUV + float2(-texel.x, 0.0));
    float d3 = SampleSceneDepth(screenUV + float2(0.0,  texel.y));
    float d4 = SampleSceneDepth(screenUV + float2(0.0, -texel.y));

    float dMin = min(min(d1, d2), min(d3, d4));

    // 没有深度纹理时（没开 Depth Texture）采到的是 0，直接跳过，避免整片变黑
    if (dMin < 1.0e-6)
        return 0.0;

    float eyeMin = LinearEyeDepth(dMin, _ZBufferParams);

    // 用自身距离归一化 -> 远近的线宽手感一致
    float diff = (selfEyeDepth - eyeMin) / max(selfEyeDepth, 1.0e-3);

    half thr = max(_InnerEdgeThreshold, 1.0e-4);
    return smoothstep(thr, thr * 2.0, diff);
#else
    return 0.0;
#endif
}

// ---------------------------------------------------------------------------
//  10. 主入口：替换 URP 的 UniversalFragmentBlinnPhong
//      结构与 URP 原函数保持一致（附加光 / 顶点光 / GI / 雾 / 调试），
//      只把主光的漫反射和高光换成卡通算法。
// ---------------------------------------------------------------------------
half4 UniversalFragmentNPRToon(InputData inputData, SurfaceData surfaceData,
                               half3 geometricNormalWS, float2 uv)
{
#if defined(DEBUG_DISPLAY)
    half4 debugColor;
    if (CanDebugOverrideOutputColor(inputData, surfaceData, debugColor))
    {
        return debugColor;
    }
#endif

    uint  meshRenderingLayers = GetMeshRenderingLayer();
    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);

    // ---- 脸部：用"整脸共享"的阴影采样点，避免低模脸出现自阴影脏块 ----
#if defined(_ISFACE_ON) && defined(_FACEPOINT_ON) && defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    inputData.shadowCoord = TransformWorldToShadowCoord(_FaceShadowPosWS.xyz);
#endif

    Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, aoFactor);

    half3 albedo = surfaceData.albedo;
    half3 normalWS = inputData.normalWS;
    half3 viewDirWS = SafeNormalize(inputData.viewDirectionWS);

    // 两套法线：
    //   shadingNormal 算明暗阶梯（皮肤建议用顶点法线，否则法线贴图会把交界线打碎）
    //   normalWS      算高光 / MatCap / 边缘光（保留细节）
    half3 shadingNormal = normalize(lerp(normalWS, geometricNormalWS, saturate(_ToonNormalWeight)));

    half3 mainDiffuse  = half3(0.0, 0.0, 0.0);
    half3 mainSpecular = half3(0.0, 0.0, 0.0);
    half3 hairBand     = half3(0.0, 0.0, 0.0);

    bool mainLightVisible = true;
#ifdef _LIGHT_LAYERS
    mainLightVisible = IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers);
#endif

    if (mainLightVisible)
    {
#if defined(_ISFACE_ON)
        // 脸部：SDF 给出梯度 -> Ramp
        half faceGradient = NPRFaceGradient(uv, mainLight);
        mainDiffuse = albedo * NPRSampleRamp(faceGradient) * mainLight.color;
#else
        half gradient = NPRGradient(mainLight, shadingNormal);
        half stepped  = NPRQuantize(gradient, _RampSteps, _RampSmoothness);
        mainDiffuse   = albedo * NPRSampleRamp(stepped) * mainLight.color;

    #if defined(_ISHAIR_ON)
        hairBand = NPRHairBand(mainLight, normalWS, viewDirWS) * mainLight.color;
    #elif defined(_TOONSPEC_ON)
        half mask = NPRSpecularMask(mainLight, normalWS, viewDirWS,
                                    surfaceData.smoothness, dot(normalWS, mainLight.direction));
        half3 specColor = lerp(_ToonSpecColor.rgb, albedo, saturate(surfaceData.metallic));
        mainSpecular = specColor * (mask * _ToonSpecIntensity) * mainLight.color;
    #endif
#endif
    }

    // ---- 附加光源：也走 Ramp，保证多灯下风格统一 ----
    half3 additional = half3(0.0, 0.0, 0.0);

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
            half g = NPRGradient(light, shadingNormal);
            additional += albedo * NPRSampleRamp(NPRQuantize(g, _RampSteps, _RampSmoothness)) * light.color;
        }
    }
    #endif

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
        #ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
        #endif
        {
            half g = NPRGradient(light, shadingNormal);
            additional += albedo * NPRSampleRamp(NPRQuantize(g, _RampSteps, _RampSmoothness)) * light.color;
        }
    LIGHT_LOOP_END
#endif

#if defined(_ADDITIONAL_LIGHTS_VERTEX)
    additional += inputData.vertexLighting * albedo;
#endif

    // ---- 环境光：只给一个整体底色，不追求物理正确 ----
    half3 ambient = inputData.bakedGI * albedo * _AmbientStrength * aoFactor.indirectAmbientOcclusion;

    // ---- MatCap 与 PBR 高光的权重分配 ----
    half3 matCap = half3(0.0, 0.0, 0.0);
    // 只有开了 MatCap 才让权重生效，否则 _MatCapWeight 会把直射光整段乘没
    half directWeight = 1.0;
#if defined(_MATCAP_ON)
    matCap = NPRMatCap(normalWS, viewDirWS) * saturate(_MatCapWeight);
    directWeight = 1.0 - saturate(_MatCapWeight);
#endif

    // ---- 边缘光 ----
    half3 rim = half3(0.0, 0.0, 0.0);
#if defined(_RIM_ON)
    rim = NPRRim(normalWS, viewDirWS, mainLight.shadowAttenuation);
#endif

    // ---- 合成：光源颜色只在各自的 diffuse/spec 里乘过一次 ----
    half3 color = (mainDiffuse + mainSpecular + hairBand) * directWeight
                + matCap
                + additional
                + ambient
                + rim
                + surfaceData.emission;   // 自发光不乘光色，没有主光时也应该亮

    // ---- 内轮廓 ----
#if defined(_INNER_EDGE_ON)
    float3 positionVS = TransformWorldToView(inputData.positionWS);
    half selfEyeDepth = max(-positionVS.z, 1.0e-4);
    half edge = NPRInnerEdge(inputData.normalizedScreenSpaceUV, selfEyeDepth);
    color = lerp(color, _InnerEdgeColor.rgb, saturate(edge * _InnerEdgeIntensity));
#endif

    return half4(color, surfaceData.alpha);
}

#endif // NPR_TOON_LIGHTING_INCLUDED
