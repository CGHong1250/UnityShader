#ifndef UNIVERSAL_LIT_INPUT_INCLUDED
#define UNIVERSAL_LIT_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"

#if defined(_DETAIL_MULX2) || defined(_DETAIL_SCALED)
#define _DETAIL
#endif

// NOTE: Do not ifdef the properties here as SRP batcher can not handle different layouts.
CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
half4 _BaseColor;
half4 _SpecColor;
half4 _EmissionColor;
half _Cutoff;
half _Smoothness;
half _Metallic;
half _BumpScale;
half _Parallax;
half _OcclusionStrength;
half _Surface;

// 色相饱和度亮度参数
half _HueShift;
half _Saturation;
half _Brightness;

//顶点混合R
float4 _LayerMapR_ST;
float4 _LayerColorR;
half4 _SpecColorLayerR;
half _HueShiftLayerR;
half _SaturationLayerR;
half _BrightnessLayerR;
half _SmoothnessLayerR;
half _MetallicLayerR;
half _BumpScaleLayerR;
half _OcclusionStrengthLayerR;

//顶点混合G
float4 _LayerMapG_ST;
float4 _LayerColorG;
half4 _SpecColorLayerG;
half _HueShiftLayerG;
half _SaturationLayerG;
half _BrightnessLayerG;
half _SmoothnessLayerG;
half _MetallicLayerG;
half _BumpScaleLayerG;
half _OcclusionStrengthLayerG;

//顶点混合G
float4 _LayerMapB_ST;
float4 _LayerColorB;
half4 _SpecColorLayerB;
half _HueShiftLayerB;
half _SaturationLayerB;
half _BrightnessLayerB;
half _SmoothnessLayerB;
half _MetallicLayerB;
half _BumpScaleLayerB;
half _OcclusionStrengthLayerB;

//顶点混合A
float4 _LayerMapA_ST;
float4 _LayerColorA;
half4 _SpecColorLayerA;
half _HueShiftLayerA;
half _SaturationLayerA;
half _BrightnessLayerA;
half _SmoothnessLayerA;
half _MetallicLayerA;
half _BumpScaleLayerA;
half _OcclusionStrengthLayerA;

// 卡通描边变量
half4 _OutlineColor;
half _OutlineWidth;
CBUFFER_END

// NOTE: Do not ifdef the properties for dots instancing, but ifdef the actual usage.
// Otherwise you might break CPU-side as property constant-buffer offsets change per variant.
// NOTE: Dots instancing is orthogonal to the constant buffer above.
#ifdef UNITY_DOTS_INSTANCING_ENABLED

UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
    UNITY_DOTS_INSTANCED_PROP(float4, _BaseColor)
    UNITY_DOTS_INSTANCED_PROP(float4, _SpecColor)
    UNITY_DOTS_INSTANCED_PROP(float4, _EmissionColor)
    UNITY_DOTS_INSTANCED_PROP(float , _Cutoff)
    UNITY_DOTS_INSTANCED_PROP(float , _Smoothness)
    UNITY_DOTS_INSTANCED_PROP(float , _Metallic)
    UNITY_DOTS_INSTANCED_PROP(float , _BumpScale)
    UNITY_DOTS_INSTANCED_PROP(float , _Parallax)
    UNITY_DOTS_INSTANCED_PROP(float , _OcclusionStrength)
    UNITY_DOTS_INSTANCED_PROP(float , _Surface)
    // 添加自定义变量的DOTS实例化
    UNITY_DOTS_INSTANCED_PROP(float , _HueShift)
    UNITY_DOTS_INSTANCED_PROP(float , _Saturation)
    UNITY_DOTS_INSTANCED_PROP(float , _Brightness)
    UNITY_DOTS_INSTANCED_PROP(float4, _OutlineColor)
    UNITY_DOTS_INSTANCED_PROP(float , _OutlineWidth)
    //顶点混合R
    UNITY_DOTS_INSTANCED_PROP(float4, _LayerColorR)
    UNITY_DOTS_INSTANCED_PROP(float4, _SpecColorLayerR)
    UNITY_DOTS_INSTANCED_PROP(float , _HueShiftLayerR)
    UNITY_DOTS_INSTANCED_PROP(float , _SaturationLayerR)
    UNITY_DOTS_INSTANCED_PROP(float , _BrightnessLayerR)
    UNITY_DOTS_INSTANCED_PROP(float , _SmoothnessLayerR)
    UNITY_DOTS_INSTANCED_PROP(float , _MetallicLayerR)
    UNITY_DOTS_INSTANCED_PROP(float , _BumpScaleLayerR)
    UNITY_DOTS_INSTANCED_PROP(float , _OcclusionStrengthLayerR)
    //顶点混合G
    UNITY_DOTS_INSTANCED_PROP(float4, _LayerColorG)
    UNITY_DOTS_INSTANCED_PROP(float4, _SpecColorLayerG)
    UNITY_DOTS_INSTANCED_PROP(float , _HueShiftLayerG)
    UNITY_DOTS_INSTANCED_PROP(float , _SaturationLayerG)
    UNITY_DOTS_INSTANCED_PROP(float , _BrightnessLayerG)
    UNITY_DOTS_INSTANCED_PROP(float , _SmoothnessLayerG)
    UNITY_DOTS_INSTANCED_PROP(float , _MetallicLayerG)
    UNITY_DOTS_INSTANCED_PROP(float , _BumpScaleLayerG)
    UNITY_DOTS_INSTANCED_PROP(float , _OcclusionStrengthLayerG)
    //顶点混合B
    UNITY_DOTS_INSTANCED_PROP(float4, _LayerColorB)
    UNITY_DOTS_INSTANCED_PROP(float4, _SpecColorLayerB)
    UNITY_DOTS_INSTANCED_PROP(float , _HueShiftLayerB)
    UNITY_DOTS_INSTANCED_PROP(float , _SaturationLayerB)
    UNITY_DOTS_INSTANCED_PROP(float , _BrightnessLayerB)
    UNITY_DOTS_INSTANCED_PROP(float , _SmoothnessLayerB)
    UNITY_DOTS_INSTANCED_PROP(float , _MetallicLayerB)
    UNITY_DOTS_INSTANCED_PROP(float , _BumpScaleLayerB)
    UNITY_DOTS_INSTANCED_PROP(float , _OcclusionStrengthLayerB)
    //顶点混合A
    UNITY_DOTS_INSTANCED_PROP(float4, _LayerColorA)
    UNITY_DOTS_INSTANCED_PROP(float4, _SpecColorLayerA)
    UNITY_DOTS_INSTANCED_PROP(float , _HueShiftLayerA)
    UNITY_DOTS_INSTANCED_PROP(float , _SaturationLayerA)
    UNITY_DOTS_INSTANCED_PROP(float , _BrightnessLayerA)
    UNITY_DOTS_INSTANCED_PROP(float , _SmoothnessLayerA)
    UNITY_DOTS_INSTANCED_PROP(float , _MetallicLayerA)
    UNITY_DOTS_INSTANCED_PROP(float , _BumpScaleLayerA)
    UNITY_DOTS_INSTANCED_PROP(float , _OcclusionStrengthLayerA)
UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)

// Here, we want to avoid overriding a property like e.g. _BaseColor with something like this:
// #define _BaseColor UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _BaseColor0)
//
// It would be simpler, but it can cause the compiler to regenerate the property loading code for each use of _BaseColor.
//
// To avoid this, the property loads are cached in some static values at the beginning of the shader.
// The properties such as _BaseColor are then overridden so that it expand directly to the static value like this:
// #define _BaseColor unity_DOTS_Sampled_BaseColor
//
// This simple fix happened to improve GPU performances by ~10% on Meta Quest 2 with URP on some scenes.
static float4 unity_DOTS_Sampled_BaseColor;
static float4 unity_DOTS_Sampled_SpecColor;
static float4 unity_DOTS_Sampled_EmissionColor;
static float  unity_DOTS_Sampled_Cutoff;
static float  unity_DOTS_Sampled_Smoothness;
static float  unity_DOTS_Sampled_Metallic;
static float  unity_DOTS_Sampled_BumpScale;
static float  unity_DOTS_Sampled_Parallax;
static float  unity_DOTS_Sampled_OcclusionStrength;
static float  unity_DOTS_Sampled_Surface;
// 添加自定义变量的DOTS实例化
static float  unity_DOTS_Sampled_HueShift;
static float  unity_DOTS_Sampled_Saturation;
static float  unity_DOTS_Sampled_Brightness;
static float4 unity_DOTS_Sampled_OutlineColor;
static float  unity_DOTS_Sampled_OutlineWidth;
//顶点混合R
static float4 unity_DOTS_Sampled_LayerColorR;
static float4 unity_DOTS_Sampled_SpecColorLayerR;
static float  unity_DOTS_Sampled_SmoothnessLayerR;
static float  unity_DOTS_Sampled_MetallicLayerR;
static float  unity_DOTS_Sampled_BumpScaleLayerR;
static float  unity_DOTS_Sampled_OcclusionStrengthLayerR;
static float  unity_DOTS_Sampled_HueShiftLayerR;
static float  unity_DOTS_Sampled_SaturationLayerR;
static float  unity_DOTS_Sampled_BrightnessLayerR;
//顶点混合G
static float4 unity_DOTS_Sampled_LayerColorG;
static float4 unity_DOTS_Sampled_SpecColorLayerG;
static float  unity_DOTS_Sampled_SmoothnessLayerG;
static float  unity_DOTS_Sampled_MetallicLayerG;
static float  unity_DOTS_Sampled_BumpScaleLayerG;
static float  unity_DOTS_Sampled_OcclusionStrengthLayerG;
static float  unity_DOTS_Sampled_HueShiftLayerG;
static float  unity_DOTS_Sampled_SaturationLayerG;
static float  unity_DOTS_Sampled_BrightnessLayerG;
//顶点混合B
static float4 unity_DOTS_Sampled_LayerColorB;
static float4 unity_DOTS_Sampled_SpecColorLayerB;
static float  unity_DOTS_Sampled_SmoothnessLayerB;
static float  unity_DOTS_Sampled_MetallicLayerB;
static float  unity_DOTS_Sampled_BumpScaleLayerB;
static float  unity_DOTS_Sampled_OcclusionStrengthLayerB;
static float  unity_DOTS_Sampled_HueShiftLayerB;
static float  unity_DOTS_Sampled_SaturationLayerB;
static float  unity_DOTS_Sampled_BrightnessLayerB;
//顶点混合A
static float4 unity_DOTS_Sampled_LayerColorA;
static float4 unity_DOTS_Sampled_SpecColorLayerA;
static float  unity_DOTS_Sampled_SmoothnessLayerA;
static float  unity_DOTS_Sampled_MetallicLayerA;
static float  unity_DOTS_Sampled_BumpScaleLayerA;
static float  unity_DOTS_Sampled_OcclusionStrengthLayerA;
static float  unity_DOTS_Sampled_HueShiftLayerA;
static float  unity_DOTS_Sampled_SaturationLayerA;
static float  unity_DOTS_Sampled_BrightnessLayerA;

void SetupDOTSLitMaterialPropertyCaches()
{
    unity_DOTS_Sampled_BaseColor            = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _BaseColor);
    unity_DOTS_Sampled_SpecColor            = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _SpecColor);
    unity_DOTS_Sampled_EmissionColor        = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _EmissionColor);
    unity_DOTS_Sampled_Cutoff               = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _Cutoff);
    unity_DOTS_Sampled_Smoothness           = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _Smoothness);
    unity_DOTS_Sampled_Metallic             = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _Metallic);
    unity_DOTS_Sampled_BumpScale            = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _BumpScale);
    unity_DOTS_Sampled_Parallax             = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _Parallax);
    unity_DOTS_Sampled_OcclusionStrength    = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _OcclusionStrength);
    unity_DOTS_Sampled_Surface              = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _Surface);
    // 颜色调整属性
    unity_DOTS_Sampled_HueShift             = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _HueShift);
    unity_DOTS_Sampled_Saturation           = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _Saturation);
    unity_DOTS_Sampled_Brightness           = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _Brightness);

    // 描边属性
    unity_DOTS_Sampled_OutlineColor         = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _OutlineColor);
    unity_DOTS_Sampled_OutlineWidth         = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _OutlineWidth);
    
    // 顶点混合R层属性
    unity_DOTS_Sampled_LayerColorR          = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _LayerColorR);
    unity_DOTS_Sampled_SpecColorLayerR      = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _SpecColorLayerR);
    unity_DOTS_Sampled_SmoothnessLayerR     = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _SmoothnessLayerR);
    unity_DOTS_Sampled_MetallicLayerR       = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _MetallicLayerR);
    unity_DOTS_Sampled_BumpScaleLayerR      = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _BumpScaleLayerR);
    unity_DOTS_Sampled_OcclusionStrengthLayerR = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _OcclusionStrengthLayerR);
    unity_DOTS_Sampled_HueShiftLayerR       = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _HueShiftLayerR);
    unity_DOTS_Sampled_SaturationLayerR     = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _SaturationLayerR);
    unity_DOTS_Sampled_BrightnessLayerR     = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _BrightnessLayerR);
    
    // 顶点混合G层属性
    unity_DOTS_Sampled_LayerColorG          = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _LayerColorG);
    unity_DOTS_Sampled_SpecColorLayerG      = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _SpecColorLayerG);
    unity_DOTS_Sampled_SmoothnessLayerG     = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _SmoothnessLayerG);
    unity_DOTS_Sampled_MetallicLayerG       = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _MetallicLayerG);
    unity_DOTS_Sampled_BumpScaleLayerG      = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _BumpScaleLayerG);
    unity_DOTS_Sampled_OcclusionStrengthLayerG = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _OcclusionStrengthLayerG);
    unity_DOTS_Sampled_HueShiftLayerG       = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _HueShiftLayerG);
    unity_DOTS_Sampled_SaturationLayerG     = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _SaturationLayerG);
    unity_DOTS_Sampled_BrightnessLayerG     = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _BrightnessLayerG);
    
    // 顶点混合B层属性
    unity_DOTS_Sampled_LayerColorB          = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _LayerColorB);
    unity_DOTS_Sampled_SpecColorLayerB      = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _SpecColorLayerB);
    unity_DOTS_Sampled_SmoothnessLayerB     = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _SmoothnessLayerB);
    unity_DOTS_Sampled_MetallicLayerB       = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _MetallicLayerB);
    unity_DOTS_Sampled_BumpScaleLayerB      = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _BumpScaleLayerB);
    unity_DOTS_Sampled_OcclusionStrengthLayerB = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _OcclusionStrengthLayerB);
    unity_DOTS_Sampled_HueShiftLayerB       = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _HueShiftLayerB);
    unity_DOTS_Sampled_SaturationLayerB     = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _SaturationLayerB);
    unity_DOTS_Sampled_BrightnessLayerB     = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _BrightnessLayerB);
    
    // 顶点混合A层属性
    unity_DOTS_Sampled_LayerColorA          = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _LayerColorA);
    unity_DOTS_Sampled_SpecColorLayerA      = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _SpecColorLayerA);
    unity_DOTS_Sampled_SmoothnessLayerA     = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _SmoothnessLayerA);
    unity_DOTS_Sampled_MetallicLayerA       = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _MetallicLayerA);
    unity_DOTS_Sampled_BumpScaleLayerA      = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _BumpScaleLayerA);
    unity_DOTS_Sampled_OcclusionStrengthLayerA = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _OcclusionStrengthLayerA);
    unity_DOTS_Sampled_HueShiftLayerA       = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _HueShiftLayerA);
    unity_DOTS_Sampled_SaturationLayerA     = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _SaturationLayerA);
    unity_DOTS_Sampled_BrightnessLayerA     = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _BrightnessLayerA);
}

#undef UNITY_SETUP_DOTS_MATERIAL_PROPERTY_CACHES
#define UNITY_SETUP_DOTS_MATERIAL_PROPERTY_CACHES() SetupDOTSLitMaterialPropertyCaches()

#define _BaseColor              unity_DOTS_Sampled_BaseColor
#define _SpecColor              unity_DOTS_Sampled_SpecColor
#define _EmissionColor          unity_DOTS_Sampled_EmissionColor
#define _Cutoff                 unity_DOTS_Sampled_Cutoff
#define _Smoothness             unity_DOTS_Sampled_Smoothness
#define _Metallic               unity_DOTS_Sampled_Metallic
#define _BumpScale              unity_DOTS_Sampled_BumpScale
#define _Parallax               unity_DOTS_Sampled_Parallax
#define _OcclusionStrength      unity_DOTS_Sampled_OcclusionStrength
#define _Surface                unity_DOTS_Sampled_Surface
// 颜色调整属性重定向
#define _HueShift               unity_DOTS_Sampled_HueShift
#define _Saturation             unity_DOTS_Sampled_Saturation
#define _Brightness             unity_DOTS_Sampled_Brightness

// 描边属性重定向
#define _OutlineColor           unity_DOTS_Sampled_OutlineColor
#define _OutlineWidth           unity_DOTS_Sampled_OutlineWidth

// 顶点混合R层属性重定向
#define _LayerColorR            unity_DOTS_Sampled_LayerColorR
#define _SpecColorLayerR        unity_DOTS_Sampled_SpecColorLayerR
#define _SmoothnessLayerR       unity_DOTS_Sampled_SmoothnessLayerR
#define _MetallicLayerR         unity_DOTS_Sampled_MetallicLayerR
#define _BumpScaleLayerR        unity_DOTS_Sampled_BumpScaleLayerR
#define _OcclusionStrengthLayerR unity_DOTS_Sampled_OcclusionStrengthLayerR
#define _HueShiftLayerR         unity_DOTS_Sampled_HueShiftLayerR
#define _SaturationLayerR       unity_DOTS_Sampled_SaturationLayerR
#define _BrightnessLayerR       unity_DOTS_Sampled_BrightnessLayerR

// 顶点混合G层属性重定向
#define _LayerColorG            unity_DOTS_Sampled_LayerColorG
#define _SpecColorLayerG        unity_DOTS_Sampled_SpecColorLayerG
#define _SmoothnessLayerG       unity_DOTS_Sampled_SmoothnessLayerG
#define _MetallicLayerG         unity_DOTS_Sampled_MetallicLayerG
#define _BumpScaleLayerG        unity_DOTS_Sampled_BumpScaleLayerG
#define _OcclusionStrengthLayerG unity_DOTS_Sampled_OcclusionStrengthLayerG
#define _HueShiftLayerG         unity_DOTS_Sampled_HueShiftLayerG
#define _SaturationLayerG       unity_DOTS_Sampled_SaturationLayerG
#define _BrightnessLayerG       unity_DOTS_Sampled_BrightnessLayerG

// 顶点混合B层属性重定向
#define _LayerColorB            unity_DOTS_Sampled_LayerColorB
#define _SpecColorLayerB        unity_DOTS_Sampled_SpecColorLayerB
#define _SmoothnessLayerB       unity_DOTS_Sampled_SmoothnessLayerB
#define _MetallicLayerB         unity_DOTS_Sampled_MetallicLayerB
#define _BumpScaleLayerB        unity_DOTS_Sampled_BumpScaleLayerB
#define _OcclusionStrengthLayerB unity_DOTS_Sampled_OcclusionStrengthLayerB
#define _HueShiftLayerB         unity_DOTS_Sampled_HueShiftLayerB
#define _SaturationLayerB       unity_DOTS_Sampled_SaturationLayerB
#define _BrightnessLayerB       unity_DOTS_Sampled_BrightnessLayerB

// 顶点混合A层属性重定向
#define _LayerColorA            unity_DOTS_Sampled_LayerColorA
#define _SpecColorLayerA        unity_DOTS_Sampled_SpecColorLayerA
#define _SmoothnessLayerA       unity_DOTS_Sampled_SmoothnessLayerA
#define _MetallicLayerA         unity_DOTS_Sampled_MetallicLayerA
#define _BumpScaleLayerA        unity_DOTS_Sampled_BumpScaleLayerA
#define _OcclusionStrengthLayerA unity_DOTS_Sampled_OcclusionStrengthLayerA
#define _HueShiftLayerA         unity_DOTS_Sampled_HueShiftLayerA
#define _SaturationLayerA       unity_DOTS_Sampled_SaturationLayerA
#define _BrightnessLayerA       unity_DOTS_Sampled_BrightnessLayerA

#endif

TEXTURE2D(_PBRMap);       
SAMPLER(sampler_PBRMap);
TEXTURE2D(_ParallaxMap);        
SAMPLER(sampler_ParallaxMap);
TEXTURE2D(_ColorMaskMap);      
SAMPLER(sampler_ColorMaskMap);
//顶点混合
// 图层纹理定义 - 使用条件编译防止重复定义
#ifdef _ENABLE_LAYER_BLEDN
    TEXTURE2D(_LayerMapR);      
    SAMPLER(sampler_LayerMapR);
    TEXTURE2D(_BumpMapLayerR);      
    SAMPLER(sampler_BumpMapLayerR);
    TEXTURE2D(_PBRMaLayerR);      
    SAMPLER(sampler_PBRMaLayerR);
    
    #ifdef _ENABLE_LAYER_BLEDN_LAYER02
        TEXTURE2D(_LayerMapG);      
        SAMPLER(sampler_LayerMapG);
        TEXTURE2D(_BumpMapLayerG);      
        SAMPLER(sampler_BumpMapLayerG);
        TEXTURE2D(_PBRMaLayerG);      
        SAMPLER(sampler_PBRMaLayerG);
    #endif
    
    #ifdef _ENABLE_LAYER_BLEDN_LAYER03
        TEXTURE2D(_LayerMapB);      
        SAMPLER(sampler_LayerMapB);
        TEXTURE2D(_BumpMapLayerB);      
        SAMPLER(sampler_BumpMapLayerB);
        TEXTURE2D(_PBRMaLayerB);      
        SAMPLER(sampler_PBRMaLayerB);
    #endif
    
    #ifdef _ENABLE_LAYER_BLEDN_LAYER04
        TEXTURE2D(_LayerMapA);      
        SAMPLER(sampler_LayerMapA);
        TEXTURE2D(_BumpMapLayerA);      
        SAMPLER(sampler_BumpMapLayerA);
        TEXTURE2D(_PBRMaLayerA);      
        SAMPLER(sampler_PBRMaLayerA);
    #endif
#endif



half4 SampleMetallicSpecGloss()
{
    half4 specGloss;

    #if _SPECULAR_SETUP
        specGloss.rgb = _SpecColor.rgb;
    #else
        specGloss.rgb = _Metallic.rrr;
    #endif

    return specGloss;
}

half3 SamplePBRMap(float2 uv)
{
    #ifdef _PBRMAP
        half3 pbr = SAMPLE_TEXTURE2D(_PBRMap, sampler_PBRMap, uv);
        half occ = LerpWhiteTo(pbr.b, _OcclusionStrength);
        // r: Metallic, g: Smoothness, b: Occlusion
        return half3(pbr.r * _Metallic, pbr.g * _Smoothness, occ);
    #else
        // 当没有PBRMap时，使用独立的属性
        return half3(_Metallic, _Smoothness, 1.0);
    #endif
}

void ApplyPerPixelDisplacement(half3 viewDirTS, inout float2 uv)
{
#if defined(_PARALLAXMAP)
    uv += ParallaxMapping(TEXTURE2D_ARGS(_ParallaxMap, sampler_ParallaxMap), viewDirTS, _Parallax, uv);
#endif
}

// RGB到HSV转换
half3 RGBToHSV(half3 rgb)
{
    half4 K = half4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    half4 p = lerp(half4(rgb.bg, K.wz), half4(rgb.gb, K.xy), step(rgb.b, rgb.g));
    half4 q = lerp(half4(p.xyw, rgb.r), half4(rgb.r, p.yzx), step(p.x, rgb.r));

    half d = q.x - min(q.w, q.y);
    half e = 1.0e-10;
    return half3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// HSV到RGB转换
half3 HSVToRGB(half3 hsv)
{
    half4 K = half4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    half3 p = abs(frac(hsv.xxx + K.xyz) * 6.0 - K.www);
    return hsv.z * lerp(K.xxx, saturate(p - K.xxx), hsv.y);
}

// 调整色相
half3 AdjustHue(half3 color, half hueShift)
{
    half3 hsv = RGBToHSV(color);
    hsv.x = frac(hsv.x + hueShift);
    return HSVToRGB(hsv);
}

// 调整饱和度
half3 AdjustSaturation(half3 color, half saturation)
{
    half luminance = dot(color, half3(0.299, 0.587, 0.114));
    return lerp(half3(luminance, luminance, luminance), color, saturation);
}

// 调整亮度
half3 AdjustBrightness(half3 color, half brightness)
{
    return color * brightness;
}


// 应用所有颜色调整
half3 ApplyColorAdjustments(half3 color, float2 uv)
{
#ifdef _COLOR_ADJUST
    // 采样Mask贴图（默认使用R通道）
    half mask = 1.0;
    #if _COLORMASKMAP
        mask = SAMPLE_TEXTURE2D(_ColorMaskMap, sampler_ColorMaskMap, uv).r;
    #endif

        half3 adjustedColor = color;
        
        // 调整色相
            adjustedColor = AdjustHue(adjustedColor, _HueShift);
        // 调整饱和度
            adjustedColor = AdjustSaturation(adjustedColor, _Saturation);
        // 调整亮度
            adjustedColor = AdjustBrightness(adjustedColor, _Brightness);
        
        // 根据mask值混合原始颜色和调整后的颜色
        color = lerp(color, adjustedColor, mask);
#endif
    return color;
}

// 应用所有颜色调整（四个参数版本）
half3 ApplyColorAdjustments(half3 color, half hueShift, half saturation, half brightness)
{
    half3 adjustedColor = color;
    
    // 调整色相
    adjustedColor = AdjustHue(adjustedColor, hueShift);
    // 调整饱和度
    adjustedColor = AdjustSaturation(adjustedColor, saturation);
    // 调整亮度
    adjustedColor = AdjustBrightness(adjustedColor, brightness);
    
    return adjustedColor;
}

// 顶点混合层采样
struct LayerData
{
    half3 albedo;
    half3 specular;
    half3 normalTS;
    half metallic;
    half smoothness;
    half bumpScale;
    half occlusion;
};
// 采样单个图层数据
LayerData SampleLayerData(float2 uv, float4 layerColor, half hueShift, half saturation, half brightness,
                         half metallic, half smoothness, half occlusionStrength, half bumpScale,
                         TEXTURE2D_PARAM(layerMap, sampler_layerMap), 
                         TEXTURE2D_PARAM(pbrMapLayer, sampler_pbrMapLayer),
                         TEXTURE2D_PARAM(bumpMapLayer, sampler_bumpMapLayer),
                         bool hasLayerMap, bool hasPBRMap, bool hasBumpMap)
{
    LayerData layer;
    
    // 采样漫反射纹理
    if (hasLayerMap)
    {
        half4 layerTex = SAMPLE_TEXTURE2D(layerMap, sampler_layerMap, uv);
        layer.albedo = layerTex.rgb * layerColor.rgb;
    }
    else
    {
        layer.albedo = layerColor.rgb;
    }
    
    // 应用颜色调整
    layer.albedo = ApplyColorAdjustments(layer.albedo, hueShift, saturation, brightness);
    
    // 采样PBR属性
    if (hasPBRMap)
    {
        half4 pbr = SAMPLE_TEXTURE2D(pbrMapLayer, sampler_pbrMapLayer, uv);
        layer.metallic = pbr.r * metallic;
        layer.smoothness = pbr.g * smoothness;
        layer.occlusion = LerpWhiteTo(pbr.b, occlusionStrength);
    }
    else
    {
        layer.metallic = metallic;
        layer.smoothness = smoothness;
        layer.occlusion = 1.0;
    }
    
    // 采样法线
    if (hasBumpMap)
    {
        layer.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(bumpMapLayer, sampler_bumpMapLayer), bumpScale);
    }
    else
    {
        layer.normalTS = half3(0, 0, 1);
    }
    
    layer.bumpScale = bumpScale;
    
#if _SPECULAR_SETUP
    // 高光工作流 - 这里需要根据您的实现来设置specular
    layer.specular = _SpecColor.rgb;
#else
    // 金属度工作流
    layer.specular = half3(0.0, 0.0, 0.0);
#endif
    
    return layer;
}

// 混合图层
LayerData BlendLayers(LayerData baseLayer, LayerData blendLayer, float blendFactor)
{
    LayerData result;
    
    // 线性混合
    result.albedo = lerp(baseLayer.albedo, blendLayer.albedo, blendFactor);
    result.metallic = lerp(baseLayer.metallic, blendLayer.metallic, blendFactor);
    result.smoothness = lerp(baseLayer.smoothness, blendLayer.smoothness, blendFactor);
    result.occlusion = lerp(baseLayer.occlusion, blendLayer.occlusion, blendFactor);
    result.specular = lerp(baseLayer.specular, blendLayer.specular, blendFactor);
    
    // 法线混合
    if (blendFactor > 0)
    {
        // 使用Reoriented Normal Mapping (RNM) 混合法线
        result.normalTS = blendLayer.normalTS;
        result.bumpScale = lerp(baseLayer.bumpScale, blendLayer.bumpScale, blendFactor);
    }
    else
    {
        result.normalTS = baseLayer.normalTS;
        result.bumpScale = baseLayer.bumpScale;
    }
    
    return result;
}

inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
{
    // 采样基础纹理
    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);
    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;
    
    // 应用颜色调整，传入uv用于采样Mask
    outSurfaceData.albedo = ApplyColorAdjustments(outSurfaceData.albedo, uv);


    //切换金属高光工作流，采样PBR纹理
    half4 specGloss = SampleMetallicSpecGloss();
    half3 pbrMap = SamplePBRMap(uv);

#if _SPECULAR_SETUP
    // 高光工作流
    outSurfaceData.metallic = 0.0;
    outSurfaceData.specular = specGloss.rgb;
#else
    // 金属度工作流
    outSurfaceData.metallic = pbrMap.r;
    outSurfaceData.specular = half3(0.0, 0.0, 0.0);
#endif

    outSurfaceData.smoothness = pbrMap.g;
    outSurfaceData.occlusion = pbrMap.b;
    // 采样基础法线
    outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);


    outSurfaceData.albedo = AlphaModulate(outSurfaceData.albedo, outSurfaceData.alpha);

    //采样自发光纹理
#if _EMISSION
    outSurfaceData.emission = SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));
#else
    outSurfaceData.emission = half3(0.0, 0.0, 0.0);
#endif
    
    // 移除ClearCoat相关代码
    outSurfaceData.clearCoatMask = half(0.0);
    outSurfaceData.clearCoatSmoothness = half(0.0);
}

inline void InitializeStandardLitSurfaceData(float2 uv, float4 vertexColor, out SurfaceData outSurfaceData)
{
    // 采样基础纹理
    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);
    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;
    
    // 应用颜色调整，传入uv用于采样Mask
    outSurfaceData.albedo = ApplyColorAdjustments(outSurfaceData.albedo, uv);


    //切换金属高光工作流，采样PBR纹理
    half4 specGloss = SampleMetallicSpecGloss();
    half3 pbrMap = SamplePBRMap(uv);

#if _SPECULAR_SETUP
    // 高光工作流
    outSurfaceData.metallic = 0.0;
    outSurfaceData.specular = specGloss.rgb;
#else
    // 金属度工作流
    outSurfaceData.metallic = pbrMap.r;
    outSurfaceData.specular = half3(0.0, 0.0, 0.0);
#endif

    outSurfaceData.smoothness = pbrMap.g;
    outSurfaceData.occlusion = pbrMap.b;
    // 采样基础法线
    outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);


    // 顶点混合，创建基础图层
    LayerData baseLayer;
    baseLayer.albedo = outSurfaceData.albedo;
    baseLayer.metallic = outSurfaceData.metallic;
    baseLayer.specular = outSurfaceData.specular;
    baseLayer.smoothness = outSurfaceData.smoothness;
    baseLayer.occlusion = outSurfaceData.occlusion;
    baseLayer.normalTS = outSurfaceData.normalTS;
    baseLayer.bumpScale = _BumpScale;

    LayerData finalLayer = baseLayer;


     // 检查是否启用顶点混合
    #ifdef _ENABLE_LAYER_BLEDN
        // R通道混合
        if (vertexColor.r > 0.001)
        {
                LayerData layerR = SampleLayerData(
                    uv, _LayerColorR, _HueShiftLayerR, _SaturationLayerR, _BrightnessLayerR,
                    _MetallicLayerR, _SmoothnessLayerR, _OcclusionStrengthLayerR, _BumpScaleLayerR,
                    TEXTURE2D_ARGS(_LayerMapR, sampler_LayerMapR),
                    TEXTURE2D_ARGS(_PBRMaLayerR, sampler_PBRMaLayerR),
                    TEXTURE2D_ARGS(_BumpMapLayerR, sampler_BumpMapLayerR),
                    true, true, true
                );
                
                // 使用顶点颜色的R通道作为混合因子
                finalLayer = BlendLayers(finalLayer, layerR, vertexColor.r);

        }

        // G通道混合
        if (vertexColor.g > 0.001)
        {
            #ifdef _ENABLE_LAYER_BLEDN_LAYER02
                LayerData layerG = SampleLayerData(
                    uv, _LayerColorG, _HueShiftLayerG, _SaturationLayerG, _BrightnessLayerG,
                    _MetallicLayerG, _SmoothnessLayerG, _OcclusionStrengthLayerG, _BumpScaleLayerG,
                    TEXTURE2D_ARGS(_LayerMapG, sampler_LayerMapG),
                    TEXTURE2D_ARGS(_PBRMaLayerG, sampler_PBRMaLayerG),
                    TEXTURE2D_ARGS(_BumpMapLayerG, sampler_BumpMapLayerG),
                    true, true, true
                );
                
                finalLayer = BlendLayers(finalLayer, layerG, vertexColor.g);
            #endif
        }
        
        // B通道混合
        if (vertexColor.b > 0.001)
        {
            #ifdef _ENABLE_LAYER_BLEDN_LAYER03
                LayerData layerB = SampleLayerData(
                    uv, _LayerColorB, _HueShiftLayerB, _SaturationLayerB, _BrightnessLayerB,
                    _MetallicLayerB, _SmoothnessLayerB, _OcclusionStrengthLayerB, _BumpScaleLayerB,
                    TEXTURE2D_ARGS(_LayerMapB, sampler_LayerMapB),
                    TEXTURE2D_ARGS(_PBRMaLayerB, sampler_PBRMaLayerB),
                    TEXTURE2D_ARGS(_BumpMapLayerB, sampler_BumpMapLayerB),
                    true, true, true
                );
                
                finalLayer = BlendLayers(finalLayer, layerB, vertexColor.b);
            #endif
        }
        
        // A通道混合
        if (vertexColor.a > 0.001)
        {
            #ifdef _ENABLE_LAYER_BLEDN_LAYER04
                LayerData layerA = SampleLayerData(
                    uv, _LayerColorA, _HueShiftLayerA, _SaturationLayerA, _BrightnessLayerA,
                    _MetallicLayerA, _SmoothnessLayerA, _OcclusionStrengthLayerA, _BumpScaleLayerA,
                    TEXTURE2D_ARGS(_LayerMapA, sampler_LayerMapA),
                    TEXTURE2D_ARGS(_PBRMaLayerA, sampler_PBRMaLayerA),
                    TEXTURE2D_ARGS(_BumpMapLayerA, sampler_BumpMapLayerA),
                    true, true, true
                );
                
                finalLayer = BlendLayers(finalLayer, layerA, vertexColor.a);
            #endif
        }
    #endif
    
    // 设置输出表面数据
    outSurfaceData.albedo = finalLayer.albedo;
    outSurfaceData.metallic = finalLayer.metallic;
    outSurfaceData.smoothness = finalLayer.smoothness;
    outSurfaceData.occlusion = finalLayer.occlusion;
    outSurfaceData.normalTS = finalLayer.normalTS;
    
    #if _SPECULAR_SETUP
        outSurfaceData.specular = finalLayer.specular;
    #else
        outSurfaceData.specular = half3(0.0, 0.0, 0.0);
    #endif

    outSurfaceData.albedo = AlphaModulate(outSurfaceData.albedo, outSurfaceData.alpha);

    //采样自发光纹理
#if _EMISSION
    outSurfaceData.emission = SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));
#else
    outSurfaceData.emission = half3(0.0, 0.0, 0.0);
#endif
    
    // 移除ClearCoat相关代码
    outSurfaceData.clearCoatMask = half(0.0);
    outSurfaceData.clearCoatSmoothness = half(0.0);
}


#endif // UNIVERSAL_INPUT_SURFACE_PBR_INCLUDED
