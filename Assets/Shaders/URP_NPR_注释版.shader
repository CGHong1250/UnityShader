// ============================================================================
// URP_NPR（二次元 / Toon 卡通渲染）Shader —— 完整逐段注释版
// 原文路径：Assets/Products/NPR/URP_NPR.shader
// 用途：角色卡通渲染，包含：Ramp 明暗分层、脸部 SDF 光照、屏幕空间头发投影、
//       MatCap 卡通高光、GGX 高光、内轮廓描边、菲涅尔边缘光等。
//
// 阅读顺序建议：
//   1) Properties      —— 有哪些可调参数
//   2) HLSLINCLUDE     —— 通用工具函数
//   3) UniversalForward Pass
//        vert          —— 顶点变换
//        GGXSpecular   —— 直接光（PBR 高光 + Ramp 漫反射）
//        GGXSpecular_Env —— 间接光（环境 + 反射探针）
//        frag          —— 片元主流程（脸 / 非脸 / 头发 / 描边）
//   4) 其余 Pass       —— ShadowCaster / GBuffer / DepthOnly / DepthNormals / Meta / Universal2D
// ============================================================================

Shader "KTSAMA/NPR/Toon"
{
    Properties
    {
        // --------------------------------------------------------------------
        // 渲染状态 & 通用开关
        // --------------------------------------------------------------------
        // 剔除模式：Off=双面 / Front=剔除正面 / Back=剔除背面（默认背面剔除）
        [Enum(Off, 0, Front, 1, Back, 2)]
        _Cull("Cull Mode", Float) = 2.0

        // Alpha 测试开关（开启后低于 _Cutoff 的像素被丢弃，用于镂空/树叶等）
        [Toggle]_AlphaTest("AlphaTest",float)=0

        // 屏幕空间头发投影开关（需要配合 SSHSRenderPassFeature 使用）
        [Toggle]_Screen_Space_HairShadow("屏幕空间头发投影(需要打开SSHSRenderPassFeature)？",float)=0

        // 是否为脸部材质（脸部走独立的 SDF 光照逻辑）
        [Toggle]_IsFace("IsFace",float)=0

        // 脸部的“右方向”和“前方向”（世界空间），用于判断光从脸左/右打来
        // 这两个向量通常由外部脚本根据模型朝向写入
        _FaceRight("_FaceRight",Vector)=(0, -1,0 ,0)
        _FaceForward("_FaceForward",Vector)=(-1, 0,0,0 )

        // 是否为头发材质（头发走各向异性高光逻辑）
        [Toggle]_IsHair("IsHair",float)=0

        // --------------------------------------------------------------------
        // 内轮廓描边（需要 SSDepthOffsetPassFeature 配合）
        // --------------------------------------------------------------------
        [Toggle]_Depth_Mask_Color_Local("开启深度偏移描边（需要打开SSDepthOffsetPassFeature）？",float)=0
        [Toggle]_Inside_Edge_Albedo_Mul("内轮廓描边与基础颜色相乘？",float)=0
        [Toggle]_Inside_Edge_Screen_Aequilatus("内轮廓描边屏幕像素等宽？",float)=1
        _InsiteEdgeWidth("内轮廓描边宽度",float)=5
        _EdgeColorIntensity("内轮廓描边颜色强度",float)=2
        _DepthMaskColor1("内轮廓描边未描边区域",Color)=(0,0,0,1)
        _DepthMaskColor2("内轮廓描边描边区域",Color)=(1,1,1,1)

        // 是否接受主光阴影
        [Toggle]_GetShadow("是否接受阴影？",float)=1

        // --------------------------------------------------------------------
        // 基础贴图 & 颜色
        // --------------------------------------------------------------------
        [MainTexture]_BaseMap("BaseMap",2D)="white"{}
        [HDR]_EmissionColor("EmissionColor",Color)=(0,0,0,1)
        _EmissionMap("EmissionMap",2D)="black"{}

        // 这些是给 ShadowCaster 等复用 LitInput 用的占位参数（隐藏）
        [HideInInspector]_Metallic("_Metallic",float)=1
        [HideInInspector]_Smoothness("_Smoothness",float)=1
        [HideInInspector]_Cutoff("_Cutoff",float)=1
        [HideInInspector]_FaceShadowPosWS("_FaceShadowPosWS",Vector)=(0,0,0,0)

        // --------------------------------------------------------------------
        // MatCap 卡通高光
        // --------------------------------------------------------------------
        _MatCapIntensity("MatCapIntensity",Range(0,1))=1
        _MatCap("MatCap",2D)="black"{}

        // --------------------------------------------------------------------
        // M 贴图：多通道打包图
        //   R = 金属度 metallic
        //   G = 光滑度 smoothness
        //   B = MatCap 遮罩（=1 处显示 MatCap，=0 处走 GGX 高光）
        // --------------------------------------------------------------------
        _M("M贴图",2D)="black"{}

        // 皮肤遮罩：R 通道，=1 表示皮肤区域
        _SkinMask("皮肤遮罩",2D)="black"{}

        // --------------------------------------------------------------------
        // Ramp 明暗分层贴图（二次元核心）
        //   注意：本 shader 采样时固定 x=0.5，用 “NL*shadow” 作为 y 坐标，
        //   所以 Ramp 图的渐变方向是【竖直方向（Y 轴）】。
        //   皮肤和其他材质各用一张，可调出不同明暗色调。
        // --------------------------------------------------------------------
        _RampMap_Skin("RampMap_Skin",2D)="white"{}
        _RampMap_Other("RampMap_Other",2D)="white"{}

        // 脸部 SDF 光照图：用 SDF 记录“光线打到脸上的明暗分界线”
        _FaceLightMap("FaceLightMap",2D)="white"{}
        _FaceLightSDF_Offset("FaceLightSDF_Offset",Range(-1,1))=0

        // Ramp 暗部颜色叠加（用于把暗部染成特定颜色）
        _RampColor_Skin("RampColor_Skin",Color)=(1,1,1,1)
        _RampColor_Other("RampColor_Other",Color)=(1,1,1,1)

        [MainColor]_BaseColor("Color",Color)=(1,1,1,1)

        // --------------------------------------------------------------------
        // 法线贴图 & 环境高光
        // --------------------------------------------------------------------
        _EnvColor_Specular("EnvColor",Color)=(1,1,1,1)
        _BumpScale("Scale", Range(-2,2)) = 1.0
        _BumpMap("Normal", 2D) ="bump"{}
        _FaceLightSDF_Add("_FaceLightSDF_Add", float) =0.1

        // --------------------------------------------------------------------
        // 头发高光参数（各向异性高光，只在 _ISHAIR_ON 时生效）
        // --------------------------------------------------------------------
        _HaifHightLight_Bias("HaifHightLight_Bias", float) =0      // 高光偏移
        _HaifHightLight_Power("HaifHightLight_Power", float) =5     // 高光锐利度（幂次）
        _HaifHightLight_Scale("HaifHightLight_Scale", float) =1     // 高光强度
        _HairShadowDistace("HairShadowDistace", float) =0           // 头发投影偏移距离
        _DebugFloat("_DebugFloat", float) =1
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"               // 不透明物体
            "RenderPipeline" = "UniversalPipeline"// 使用 URP 管线
            "UniversalMaterialType" = "Lit"       // 材质类型标记（编辑器用）
            "IgnoreProjector" = "True"            // 忽略投影机
        }
        LOD 100

        // ====================================================================
        // HLSLINCLUDE：这里的代码会被本 SubShader 内所有 Pass 共享（先声明好）
        // ====================================================================
        HLSLINCLUDE
        // 引入 URP 的光照库和核心库（注意顺序：Lighting 会用到 Core）
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        // Lit 的输入定义（_BaseMap / _BaseColor / sampler 等）
        #include "LitInput.hlsl"
        // 自定义 PBR 函数（GGX 的 D/G/F、FresnelSchlickRoughness、EnvBRDFApprox 等）
        #include "Assets/Products/PBR/PBR_Func.hlsl"

        #pragma target 4.5
        #pragma prefer_hlslcc gles

        // --------------------------------------------------------------------
        // 把“裁剪空间坐标”转换成“屏幕空间 UV（0~1）”。
        // 来自 Amplify Shader Editor 的屏幕抓取坐标算法：
        //   1) 先做透视投影的 y 轴翻转（处理 DirectX / OpenGL 的上下翻转差异）
        //   2) 再用 pos.w 做透视除法，得到 0~1 的屏幕坐标
        // 实际在本 shader 里，它是对 ComputeScreenPos 的结果再处理一次，
        // 最终用于采样屏幕空间阴影 / 头发投影 / 深度遮罩等贴图。
        // --------------------------------------------------------------------
        inline float4 ASE_ComputeGrabScreenPos(float4 pos)
        {
            #if UNITY_UV_STARTS_AT_TOP
            float scale = -1.0;   // DirectX 等平台：UV 从顶部开始，需要翻转
            #else
            float scale = 1.0;    // OpenGL 等平台：不用翻转
            #endif
            float4 o = pos;
            o.y = pos.w * 0.5f;
            o.y = (pos.y - o.y) * _ProjectionParams.x * scale + o.y;
            return o;
        }
        ENDHLSL

        // ====================================================================
        // 主渲染 Pass（前向渲染，LightMode = UniversalForward）
        // ====================================================================
        Pass
        {
            Tags
            {
                "LightMode"="UniversalForward"
            }
            Cull [_Cull]   // 剔除模式由材质面板的 _Cull 控制

            HLSLPROGRAM
            // 声明顶点/片元入口函数
            #pragma vertex vert
            #pragma fragment frag

            // ---- 主光阴影关键字（三种阴影方案，URP 会按设置选一个） ----
            #pragma multi_compile  _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            // 软阴影
            #pragma multi_compile _ _SHADOWS_SOFT

            // ---- 本地材质关键字（材质面板开关） ----
            #pragma shader_feature_local _ _ALPHATEST_ON                       // Alpha 测试
            #pragma shader_feature_local _ _SCREEN_SPACE_HAIRSHADOW_ON          // 屏幕空间头发投影
            #pragma shader_feature_local_fragment _ _ISFACE_ON                  // 脸部
            #pragma shader_feature_local_fragment _ _ISHAIR_ON                  // 头发
            #pragma shader_feature_local_fragment _ _DEPTH_MASK_COLOR_LOCAL_ON  // 内轮廓描边
            #pragma shader_feature_local_fragment _GETSHADOW_ON                 // 接收阴影
            #pragma shader_feature_local_fragment _ _INSIDE_EDGE_ALBEDO_MUL_ON  // 描边颜色乘 albedo
            #pragma shader_feature_local_fragment _ _INSIDE_EDGE_SCREEN_AEQUILATUS_ON // 描边像素等宽
            // 全局关键字（由 RenderFeature 控制）
            #pragma shader_feature _ _DEPTH_MASK_COLOR
            #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION

            // ---- 附加光源 ----
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ADDITIONAL_LIGHTS

            // ---- Unity 定义关键字：雾 ----
            #pragma multi_compile_fog

            // 声明本 Pass 用到的贴图和采样器（Lighting/Core 已声明了 _BaseMap 等）
            TEXTURE2D(_FaceLightMap);       SAMPLER(sampler_FaceLightMap);
            TEXTURE2D(_RampMap_Skin);       SAMPLER(sampler_RampMap_Skin);
            TEXTURE2D(_RampMap_Other);      SAMPLER(sampler_RampMap_Other);
            TEXTURE2D(_SkinMask);           SAMPLER(sampler_SkinMask);
            TEXTURE2D(_MatCap);             SAMPLER(sampler_MatCap);
            TEXTURE2D(_M);                  SAMPLER(sampler_M);
            TEXTURE2D(_HairSoildColor);     SAMPLER(sampler_HairSoildColor);
            TEXTURE2D(_DepthMaskColor);     SAMPLER(sampler_DepthMaskColor);

            // ================================================================
            // 顶点输入结构：模型数据
            // ================================================================
            struct VertexInput
            {
                float4 positionOS : POSITION;  // 物体空间顶点坐标
                float2 uv : TEXCOORD0;         // UV 坐标
                float4 normalOS : NORMAL;      // 物体空间法线
                float4 tangentOS : TANGENT;    // 物体空间切线
                float4 color : COLOR;          // 顶点色（本 shader 其实没用到，保留）
            };

            // ================================================================
            // 顶点 -> 片元 传递结构
            // ================================================================
            struct VertexOutput
            {
                float4 positionCS : SV_POSITION;  // 裁剪空间坐标（必须）
                float2 uv : TEXCOORD0;            // UV
                float3 positionWS : TEXCOORD1;    // 世界空间顶点
                float3 normalWS : TEXCOORD2;      // 世界空间法线
                float3 tangentWS : TEXCOORD3;     // 世界空间切线
                float3 bitangentWS : TEXCOORD4;   // 世界空间副切线

                // 只有用到屏幕空间相关效果时才需要这些（节省带宽）
                #if _MAIN_LIGHT_SHADOWS_SCREEN || _SCREEN_SPACE_OCCLUSION || _SCREEN_SPACE_HAIRSHADOW_ON || _DEPTH_MASK_COLOR
                 float4 screenPos : TEXCOORD5;          // 屏幕坐标（透视未除）
                 float4 shadowCoord_Screen : TEXCOORD6; // 屏幕空间阴影坐标（透视已除）
                #endif
                float4 color : TEXCOORD7;   // 顶点色透传
                float4 posNDCw : TEXCOORD8; // NDC 坐标的 w（用于修正距离导致的投影大小变化）
            };

            // ================================================================
            // 顶点着色器：只做坐标/法线变换，不做光照
            // ================================================================
            VertexOutput vert(VertexInput i)
            {
                VertexOutput o;
                o.uv = TRANSFORM_TEX(i.uv, _BaseMap);   // 应用 _BaseMap_ST 的 Tiling/Offset

                // 物体空间 -> 世界/裁剪空间
                VertexPositionInputs positionInputs = GetVertexPositionInputs(i.positionOS);
                o.positionWS = positionInputs.positionWS;   // 世界坐标
                o.positionCS = positionInputs.positionCS;   // 裁剪坐标

                // 法线/切线/副切线：物体空间 -> 世界空间
                VertexNormalInputs normalInputs = GetVertexNormalInputs(i.normalOS.xyz, i.tangentOS);
                o.normalWS = normalInputs.normalWS;
                o.bitangentWS = normalInputs.bitangentWS;
                o.tangentWS = normalInputs.tangentWS;

                o.color = i.color;   // 透传顶点色

                // 屏幕空间相关：算屏幕坐标和 NDC.w
                #if _MAIN_LIGHT_SHADOWS_SCREEN || _SCREEN_SPACE_OCCLUSION || _SCREEN_SPACE_HAIRSHADOW_ON || _DEPTH_MASK_COLOR
                o.screenPos = ComputeScreenPos(positionInputs.positionCS);
                o.posNDCw = positionInputs.positionNDC.w;
                #endif
                return o;
            }

            // ================================================================
            // GGXSpecular：直接光着色函数
            // 作用：把【GGX PBR 高光】和【Ramp 明暗分层漫反射】合在一起
            //
            // 参数说明：
            //   albedo            反照率（基础色）
            //   shadow            阴影衰减（0~1）
            //   lightData         光源数据（方向/颜色）
            //   N                 世界空间法线
            //   V                 世界空间视角方向
            //   metallic          金属度
            //   roughness         粗糙度
            //   mask_skin         皮肤遮罩（1=皮肤）
            //   mask_hair_HightLight  头发高光遮罩（默认 1）
            // ================================================================
            float3 GGXSpecular(float3 albedo, float shadow, Light lightData, float3 N, float3 V, float metallic,
                float roughness, float mask_skin, float mask_hair_HightLight = 1)
            {
                // ---- 基本向量与点积 ----
                float3 L = normalize(lightData.direction);   // 光线方向（指向光源）
                float3 F0 = lerp(0.04, albedo, metallic);    // 菲涅尔基础反射率（非金属约0.04，金属=albedo）
                float3 H = normalize(V + L);                 // 半程向量（Blinn 高光用）
                float NV = saturate(dot(N, V));              // N·V
                float NL = saturate(dot(N, L));              // N·L（漫反射强度）

                // ---- GGX 的 D / G / F 三项 ----
                float D = D_DistributionGGX(N, H, roughness);          // 法线分布项
                float G = G_GeometrySmith_Direct_Light(N, V, L, roughness); // 几何遮蔽项
                float3 F = F_FrenelSchlick(NV, F0);                    // 菲涅尔项

                // ---- Ramp 采样坐标：x 固定 0.5，y = NL * shadow ----
                // 所以 Ramp 图的渐变方向是【竖直的（Y 轴）】，
                // 明暗分界由 y 值决定，阴影也会影响 y（阴影处直接掉到暗部）。
                float2 uv_rampNL = float2(0.5, NL * shadow);

                // 能量守恒的漫反射系数（本函数实际用 Ramp 当漫反射，这个只作参考保留）
                float3 kd = (1 - F) * (1 - metallic);

                // 采样两张 Ramp 图得到“其他材质”和“皮肤”的明暗颜色
                float3 rampMap_otherNL = SAMPLE_TEXTURE2D(_RampMap_Other, sampler_RampMap_Other, uv_rampNL);
                float3 rampMap_skinNL = SAMPLE_TEXTURE2D(_RampMap_Skin, sampler_RampMap_Skin, uv_rampNL);

                float3 final_other = 0;   // 其他材质结果
                float3 specular;          // 高光（下面两个分支共用声明）

                #ifdef _ISHAIR_ON
                // ================= 头发：各向异性高光 =================
                // 用 NV 的幂次模拟头发一绺一绺的高光（各向异性），
                // 再乘以 NL * shadow 让高光只在受光处出现。
                specular = pow(NV + _HaifHightLight_Bias, _HaifHightLight_Power)
                         * _HaifHightLight_Scale
                         * mask_hair_HightLight
                         * NL * shadow;
                specular = saturate(specular);

                // 头发最终 = Ramp 漫反射 + 各向异性高光 + 一层受光提亮
                final_other = (rampMap_otherNL + specular + mask_hair_HightLight * NL * 0.5 * max(0.2, shadow)) * albedo;
                #else
                // ================= 非头发：标准 GGX 高光 =================
                // Cook-Torrance 高光公式：D*G*F / (4 * NdotV * NdotL)
                specular = (D * G * F) / (4 * max((NV * NL), 0.000001));
                final_other = (rampMap_otherNL + specular) * albedo;
                #endif

                // ---- 其他材质：暗部染色 + 按皮肤遮罩取反 ----
                // lerp(A, B, NL)：NL 小时用 A（染了 _RampColor_Other 的颜色），
                //               NL 大时用 B（原色）。实现“暗部偏色”效果。
                final_other = lerp(final_other * _RampColor_Other, final_other, NL) * (1 - mask_skin);

                // ---- 皮肤：同理，用 _RampColor_Skin 染暗部 ----
                float3 final_skin = (rampMap_skinNL + specular) * albedo;
                final_skin = lerp(final_skin * _RampColor_Skin, final_skin, NL) * (mask_skin);

                // ---- 皮肤 + 其他材质相加，再乘光照颜色 ----
                float3 col_final = (final_other + final_skin) * lightData.color;

                return col_final;
            }

            // ================================================================
            // GGXSpecular_Env：间接光（环境光 + 反射探针）
            // 作用：计算环境漫反射（球谐 SampleSH）+ 间接高光（反射探针）。
            // 注意：函数最后【只返回了间接漫反射】，间接高光被算出来但没返回，
            //       作者可能有自己的取舍（高光主要由 MatCap / 直接光承担）。
            // ================================================================
            float3 GGXSpecular_Env(float3 albedo, float3 N, float3 V, float metallic, float roughness,
                float mask_hair_HightLight = 1)
            {
                float NV = saturate(dot(N, V));

                // 菲涅尔（粗糙度修正版）
                float3 F0 = lerp(0.04, albedo, metallic);
                float3 F = FresnelSchlickRoughness(NV, F0, roughness);
                float3 kd = (1 - F);   // 漫反射能量

                // 反射方向（当前视角在 N 上的镜面反射方向）
                float3 reflectDirWS = reflect(-V, N);

                // 环境 BRDF 数值近似（F * env_brdf.r + env_brdf.g 的权重）
                float2 env_brdf = EnvBRDFApprox(roughness, NV);

                // 按粗糙度选 mip（越粗糙 mip 越高，反射越糊）
                float mip = roughness * (1.7 - 0.7 * roughness) * UNITY_SPECCUBE_LOD_STEPS;

                // 采样反射探针立方体贴图
                float4 _CubeMapColor = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDirWS, mip);

                // 间接漫反射：球谐采样（SampleSH）+ albedo
                float3 diffuse_col_InDirect = SampleSH(N) * albedo * kd;

                // 间接高光：环境颜色 * BRDF
                #ifdef _ISHAIR_ON
                  // 头发：削弱间接高光（乘 0.2 和头发高光遮罩）
                  float3 specular_InDirect = _EnvColor_Specular * (F * env_brdf.r + env_brdf.g) * 0.2 * mask_hair_HightLight;
                #else
                  float3 specular_InDirect = _EnvColor_Specular * (F * env_brdf.r + env_brdf.g);
                #endif

                // 最终只返回间接漫反射（间接高光被丢弃）
                return diffuse_col_InDirect;
            }

            // ================================================================
            // 片元着色器：核心渲染逻辑
            // 第二个参数 face:VFACE —— 当前片元是正面(1)还是背面(-1)，
            // 可用于双面渲染时翻转法线。本 shader 声明了但未使用。
            // ================================================================
            float4 frag(VertexOutput i, float face:VFACE) : SV_Target
            {
                // ------------------------------------------------------------
                // 1) 法线贴图解码
                // ------------------------------------------------------------
                float4 normalTXS = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, i.uv);
                float4 normalPacked = normalize(float4(normalTXS.xy, 1, 0));

                // 把法线从 [0,1] 映射到 [-1,1]，并重建 z（这里用 sqrt(1-x^2-y^2) 的近似）
                float3 normalTS = 0;
                normalTS.xy = normalPacked.rg * 2.0 - 1.0;
                normalTS.z = max(1.0e-16, sqrt(1.0 - saturate(dot(normalTS.xy, normalTS.xy))));
                normalTS.xy *= _BumpScale;   // 缩放法线强度

                // 切线空间法线 -> 世界空间法线
                float3 normalWS = normalize(
                    TransformTangentToWorld(normalTS, real3x3(i.tangentWS, i.bitangentWS, i.normalWS)));

                // ------------------------------------------------------------
                // 2) 采样基础贴图 & M 贴图 & 皮肤遮罩
                // ------------------------------------------------------------
                float4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv) * _BaseColor;

                // M 贴图多通道打包：
                //   m.r = 金属度 metallic
                //   m.g = 光滑度 smoothness
                //   m.b = MatCap 遮罩（1=显示 MatCap，0=走 GGX 高光）
                float4 m = SAMPLE_TEXTURE2D(_M, sampler_M, i.uv);

                // 皮肤遮罩：r 通道 =1 表示皮肤区域
                float mask_skin = SAMPLE_TEXTURE2D(_SkinMask, sampler_SkinMask, i.uv).r;

                // ------------------------------------------------------------
                // 3) 屏幕坐标（用于屏幕空间阴影 / 头发投影 / 深度遮罩）
                // ------------------------------------------------------------
                #if _MAIN_LIGHT_SHADOWS_SCREEN || _SCREEN_SPACE_OCCLUSION || _SCREEN_SPACE_HAIRSHADOW_ON || _DEPTH_MASK_COLOR
                i.shadowCoord_Screen = ASE_ComputeGrabScreenPos(i.screenPos);
                i.shadowCoord_Screen = i.shadowCoord_Screen / i.shadowCoord_Screen.w;   // 透视除法 -> 0~1
                #endif

                // ------------------------------------------------------------
                // 4) 主光源 & 阴影
                // ------------------------------------------------------------
                Light light_main = GetMainLight();   // 获取主光源（方向/颜色）

                // 阴影坐标：
                //   脸部：用 _FaceShadowPosWS（由外部脚本提供，保证脸部阴影不受顶点插值影响）
                //   其他：用当前片元世界坐标
                #ifdef _ISFACE_ON
                float4 shadow_coord_Main = TransformWorldToShadowCoord(_FaceShadowPosWS);
                #else
                float4 shadow_coord_Main = TransformWorldToShadowCoord(i.positionWS);
                #endif

                // 阴影值
                half shadow_main = 1;   // 默认无阴影
                #ifdef _GETSHADOW_ON
                  // 屏幕空间阴影：直接采样屏幕空间阴影图
                  #if _MAIN_LIGHT_SHADOWS_SCREEN
                  shadow_main = SAMPLE_TEXTURE2D(_ScreenSpaceShadowmapTexture, sampler_ScreenSpaceShadowmapTexture, i.shadowCoord_Screen.xy);
                  #else
                  // 级联/常规阴影：用 MainLightRealtimeShadow 采样阴影图
                  shadow_main = MainLightRealtimeShadow(shadow_coord_Main);
                  shadow_main = saturate(shadow_main);
                  #endif
                #endif

                // ------------------------------------------------------------
                // 5) 脸部方向相关量（无论脸不脸都会算，脸部才用）
                // ------------------------------------------------------------
                // _FaceRight / _FaceForward 由外部脚本写入，定义脸部的“右/前”方向。
                float3 rightDirWS = _FaceRight;
                float3 lightDirWS = light_main.direction;   // 主光方向
                float3 forwardDirWS = _FaceForward;

                // FL_step：光越接近从脸部“正面”打来，值越接近 1
                // （用 smoothstep 让正面/背面的切换更柔和）
                float FL_step = smoothstep(0, 0.2, max(0, dot(lightDirWS, forwardDirWS)));

                // faceNL：光在脸部“左右”方向的投影（>0 光在右脸，<0 光在左脸）
                float faceNL = dot(lightDirWS, rightDirWS);

                // 采样脸部 SDF 光照图：
                //   光在右脸时用 (1-uv.x) 翻转采样，保证 SDF 图案始终从受光侧进入。
                //   （本质：把 SDF 的水平方向按受光左右翻转，实现“光从左/右打脸”的明暗）
                float4 faceLightmap = SAMPLE_TEXTURE2D(_FaceLightMap, sampler_FaceLightMap,
                    float2(step(faceNL, 0.0) * i.uv.x + step(0.0, faceNL) * (1 - i.uv.x), i.uv.y));

                // ------------------------------------------------------------
                // 6) 通用量：视角方向、结果累加器
                // ------------------------------------------------------------
                float3 viewDirWS = normalize(GetWorldSpaceViewDir(i.positionWS));
                float3 final_color = 0;   // 最终颜色累加器
                float3 env_col = 0;       // 环境（间接）光
                float3 specular = 0;      // 额外高光（本 shader 未填充，保留）

                // MatCap 相关：把世界法线转到观察空间 -> 映射到 [0,1] 作为 MatCap 采样 UV
                float3 normalVS = TransformWorldToViewNormal(normalWS);
                float2 uv_matCap = normalVS + 0.5;   // 法线在屏幕上的朝向决定 MatCap 采样位置
                float3 matCap = 0;

                // 菲涅尔边缘光（作者注释：此处边缘光效果不佳，考虑移除，实际由下面重算）
                float frenal = 0;

                // ============================================================
                // 7) 两个大分支：脸部 / 非脸部
                // ============================================================
                #ifdef _ISFACE_ON
                // ================= 脸部渲染 =================
                // 脸部固定一套材质参数（不走 M 贴图）
                normalTXS.a = 0;          // a 通道当高光用，脸不用
                normalTXS.b = 0.5;        // b 通道当 AO 用，脸设为 0.5（无 AO）
                m.r = 192.0 / 255;        // 金属度
                m.b = 25.0 / 255;         // MatCap 遮罩

                // 用 abs(faceNL)^2 作为 SDF 阈值的基础，实现光越正/越偏，明暗线位置不同
                float abs_value = abs(faceNL);
                abs_value = abs_value * abs_value;

                // l = 脸部明暗值：SDF 采样结果经过 smoothstep 生成柔和的明暗分界，
                //     再乘 FL_step（光从背面打来时变 0，脸全暗）
                float l = smoothstep(abs_value, abs_value + 0.2, (faceLightmap.r + faceLightmap.g) * 0.5) * FL_step;

                // 采样皮肤 Ramp 图：x=0.5（固定），y=l（明暗值）
                float2 uv_ramp = float2(0.5, l);
                float4 rampMap_skin = SAMPLE_TEXTURE2D(_RampMap_Skin, sampler_RampMap_Skin, uv_ramp);

                // 脸部基础颜色 = Ramp * albedo * 主光颜色
                float3 final = rampMap_skin * albedo * light_main.color;

                // ---- 屏幕空间头发投影（阴影） ----
                float4 ssHairShadowMap = 1;
                float ssHairShadow = 1;   // 1 = 无头发投影
                #ifdef _SCREEN_SPACE_HAIRSHADOW_ON
                // 把光方向转到观察空间，再乘 (1/NDC.w) 修正“距离越远投影越大”的问题
                float3 viewLightDir = normalize(TransformWorldToViewDir(light_main.direction)) * (1 / i.posNDCw);

                // 用固定 1920x1080 作为标准分辨率做偏移，保证不同分辨率下偏移距离一致
                float2 samplingPoint = i.shadowCoord_Screen.xy
                                     + _HairShadowDistace * viewLightDir.xy * float2(1.0 / 1920.0, 1.0 / 1080.0);

                // 采样头发实体色图：r=头发遮挡，g=头发深度
                ssHairShadowMap = SAMPLE_TEXTURE2D(_HairSoildColor, sampler_HairSoildColor, samplingPoint);
                ssHairShadow = 1 - ssHairShadowMap.r;   // r=1 处被头发挡住

                // 用深度判断投影是否在当前片元之上（step(depth, hairDepth+0.02)）
                // 再乘 (1-smoothstep(0.6,0.8,uv.y)) 让发梢区域投影渐弱
                float depth = (i.positionCS.z / i.positionCS.w) * 0.5 + 0.5;
                float hairDepth = ssHairShadowMap.g;
                ssHairShadow = lerp(1, ssHairShadow, step(depth, hairDepth + 0.02))
                             * (1 - smoothstep(0.6, 0.8, i.uv.y));
                #endif

                // 脸部最终颜色：在“染了 RampColor_Skin 的版本”和“原版”之间按
                // l * 头发投影 * 阴影 插值 —— 暗部用染色版，亮部用原版。
                final_color = lerp(final * _RampColor_Skin, final, l * ssHairShadow * shadow_main);

                #else
                // ================= 非脸部渲染 =================
                // MatCap 卡通高光：
                //   采样 MatCap 球贴图，乘阴影（max(shadow,0.5) 让暗部也保留一点），
                //   再乘 N·L（受光处才亮）和主光颜色。
                matCap = max(shadow_main, 0.5)
                       * SAMPLE_TEXTURE2D(_MatCap, sampler_MatCap, uv_matCap)
                       * _MatCapIntensity
                       * dot(normalWS, light_main.direction)
                       * light_main.color;

                #ifdef _ISHAIR_ON
                // ---- 头发 ----
                // 间接光（只对非皮肤区域）
                env_col = GGXSpecular_Env(albedo, normalWS, viewDirWS, m.r, saturate(1 - m.g), m.b) * (1 - mask_skin);
                // 直接光：各向异性高光（在 GGXSpecular 内部走 _ISHAIR_ON 分支）
                final_color = GGXSpecular(albedo, shadow_main, light_main, normalWS, viewDirWS, m.r, saturate(1 - m.g), mask_skin, m.b);
                matCap = 0;   // 头发不用 MatCap
                #else
                // ---- 普通材质 ----
                // 菲涅尔边缘光：视角越掠射（N·V 越小）越亮，乘主光颜色和阴影
                frenal = (1 - saturate(pow(dot(viewDirWS, normalWS), 6) * 70)) * light_main.color * lerp(0.3, 0.1, shadow_main);

                // 间接光 + 直接光（普通 GGX 高光）
                env_col = GGXSpecular_Env(albedo, normalWS, viewDirWS, m.r, saturate(1 - m.g), 1) * (1 - mask_skin);
                final_color = GGXSpecular(albedo, shadow_main, light_main, normalWS, viewDirWS, m.r, saturate(1 - m.g), mask_skin, 0);

                // 金属部分（m.b 小）少用 GGX、多用 MatCap；非金属反之。
                // 即：金属区域主要由 MatCap 表现，非金属区域主要由 GGX 表现。
                final_color *= (1 - m.b);
                matCap *= saturate(m.b);
                #endif
                #endif

                // ============================================================
                // 8) 合并：MatCap + 高光 + 环境光，再乘主光颜色
                // ============================================================
                final_color += matCap;
                final_color += specular + env_col;
                final_color *= light_main.color;

                // ============================================================
                // 9) 内轮廓描边（屏幕空间深度遮罩偏移）
                // ============================================================
                #ifdef _DEPTH_MASK_COLOR
                #ifdef _DEPTH_MASK_COLOR_LOCAL_ON
                float depthOffset1 = 1;
                float depthOffset2 = 1;
                float depthOffset3 = 1;
                float depthOffset4 = 1;
                float final_depthoffset = 1;
                float3 depthColor = 1;

                // 屏幕像素等宽 or 随距离缩放
                #ifdef _INSIDE_EDGE_SCREEN_AEQUILATUS_ON
                float2 f = float2(1.0 / 1920.0, 1.0 / 1080.0);
                #else
                float2 f = float2(1.0 / 1920.0, 1.0 / 1080.0) * (1 / i.posNDCw);
                #endif

                // 对深度遮罩图做四个对角方向偏移采样，
                // 检测“周围有没有被别的物体挡住”（即边缘/遮挡处）。
                depthOffset1 = SAMPLE_TEXTURE2D(_DepthMaskColor, sampler_DepthMaskColor, i.shadowCoord_Screen.xy + _InsiteEdgeWidth * float2(1, -1) * f).r;
                depthOffset2 = SAMPLE_TEXTURE2D(_DepthMaskColor, sampler_DepthMaskColor, i.shadowCoord_Screen.xy + _InsiteEdgeWidth * float2(-1, 1) * f).r;
                depthOffset3 = SAMPLE_TEXTURE2D(_DepthMaskColor, sampler_DepthMaskColor, i.shadowCoord_Screen.xy + _InsiteEdgeWidth * float2(1, 1) * f).r;
                depthOffset4 = SAMPLE_TEXTURE2D(_DepthMaskColor, sampler_DepthMaskColor, i.shadowCoord_Screen.xy + _InsiteEdgeWidth * float2(-1, -1) * f).r;

                // 四个采样里取最小，得到“边缘强度”（越大越靠近边缘）
                final_depthoffset = 1 - min(depthOffset1, min(depthOffset2, min(depthOffset3, depthOffset4)));

                // 用边缘强度在“未描边色 / 描边色”之间插值
                depthColor = lerp(_DepthMaskColor1, _DepthMaskColor2, final_depthoffset);

                // 先把被描边覆盖的部分挖掉（乘 1-边缘强度）
                final_color *= 1 - final_depthoffset;

                // 再把描边颜色叠上去（可选：乘 albedo）
                #ifdef _INSIDE_EDGE_ALBEDO_MUL_ON
                final_color += depthColor * albedo * _EdgeColorIntensity;
                #else
                final_color += depthColor * _EdgeColorIntensity;
                #endif
                #endif
                #endif

                // ============================================================
                // 10) 最终合成
                // ============================================================
                // normalTXS.b 这里被当作【AO 通道】用：+0.5 后当明暗系数。
                // （法线贴图的 b 通道在本项目里被复用成了 AO 遮罩）
                normalTXS.b += 0.5;

                // 自发光：采样 _EmissionMap，乘 _EmissionColor 和主光颜色
                float3 emission = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, i.uv) * _EmissionColor * light_main.color;

                // 最终颜色 = (光照结果 + 菲涅尔边缘光*albedo) * AO + 自发光
                return float4((final_color + (frenal * albedo)) * normalTXS.b + emission, 1);
            }
            ENDHLSL
        }

        // ====================================================================
        // ShadowCaster Pass：向阴影贴图写入深度（让本物体能投阴影）
        // ====================================================================
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On
            ZTest LEqual
            ColorMask 0   // 只写深度，不写颜色
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            // 区分平行光 / 点光源阴影（应用 Normal Bias 的公式不同）
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            #if defined(LOD_FADE_CROSSFADE)
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

            // 阴影投射用的光源几何参数，由 URP 运行时设置（ShadowUtils.SetupShadowCasterConstantBuffer）
            float3 _LightDirection;   // 平行光方向
            float3 _LightPosition;    // 点/聚光灯位置

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float2 texcoord     : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                #if defined(_ALPHATEST_ON)
                    float2 uv       : TEXCOORD0;
                #endif
                float4 positionCS   : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            // 计算带阴影偏差（Normal Bias）的裁剪坐标
            float4 GetShadowPositionHClip(Attributes input)
            {
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

                // 点光源用光源位置算方向，平行光用固定方向
                #if _CASTING_PUNCTUAL_LIGHT_SHADOW
                float3 lightDirectionWS = normalize(_LightPosition - positionWS);
                #else
                float3 lightDirectionWS = _LightDirection;
                #endif

                // ApplyShadowBias：按法线和光方向偏移，减少阴影痤疮/条纹
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

                // 处理反向 Z（把 z 夹到近裁剪面附近）
                #if UNITY_REVERSED_Z
                positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #else
                positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #endif

                return positionCS;
            }

            Varyings ShadowPassVertex(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                #if defined(_ALPHATEST_ON)
                    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                #endif

                output.positionCS = GetShadowPositionHClip(input);
                return output;
            }

            half4 ShadowPassFragment(Varyings input) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(input);

                // Alpha 测试：镂空物体只在贴图不透明处投阴影
                #if defined(_ALPHATEST_ON)
                    Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);
                #endif

                #if defined(LOD_FADE_CROSSFADE)
                    LODFadeCrossFade(input.positionCS);
                #endif

                return 0;   // 颜色被 ColorMask 0 屏蔽，只写深度
            }
            ENDHLSL
        }

        // ====================================================================
        // GBuffer Pass：延迟渲染路径（本 shader 复用 URP 内置 LitGBuffer，
        // 注意：延迟路径不支持自定义 NPR 光照，实际以 Forward 为准）
        // ====================================================================
        Pass
        {
            Name "GBuffer"
            Tags { "LightMode" = "UniversalGBuffer" }

            ZWrite[_ZWrite]
            ZTest LEqual
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 4.5
            // 延迟渲染不支持桌面 OpenGL / ES3 / WebGL2
            #pragma exclude_renderers gles3 glcore

            #pragma vertex LitGBufferPassVertex
            #pragma fragment LitGBufferPassFragment

            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local_fragment _OCCLUSIONMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED

            #pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
            #pragma shader_feature_local_fragment _SPECULAR_SETUP
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile_fragment _ _RENDER_PASS_ENABLED
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT

            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // 直接复用 URP 内置的 Lit GBuffer（标准 PBR 输出，NPR 在延迟下不生效）
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitGBufferPass.hlsl"
            ENDHLSL
        }

        // ====================================================================
        // DepthOnly Pass：只写深度（用于 _CameraDepthTexture 等）
        // ====================================================================
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }

            ZWrite On
            ColorMask R   // 只写 R 通道（深度）
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // 复用 URP 内置 DepthOnly
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        // ====================================================================
        // DepthNormals Pass：写入深度+法线纹理（_CameraNormalsTexture，供描边/SSAO 等用）
        // ====================================================================
        Pass
        {
            Name "DepthNormals"
            Tags { "LightMode" = "DepthNormals" }

            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // 复用 URP 内置 DepthNormals
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"
            ENDHLSL
        }

        // ====================================================================
        // Meta Pass：光照烘焙用（只在烘焙时渲染，非运行期）
        // ====================================================================
        Pass
        {
            Name "Meta"
            Tags { "LightMode" = "Meta" }

            Cull Off

            HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMetaLit

            #pragma shader_feature_local_fragment _SPECULAR_SETUP
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local_fragment _SPECGLOSSMAP
            #pragma shader_feature EDITOR_VISUALIZATION

            // 复用 URP 内置 Meta（烘焙输出 albedo / emission）
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitMetaPass.hlsl"
            ENDHLSL
        }

        // ====================================================================
        // Universal2D Pass：2D 渲染器支持（本 shader 是 3D，基本用不到，保留兼容）
        // ====================================================================
        Pass
        {
            Name "Universal2D"
            Tags { "LightMode" = "Universal2D" }

            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON

            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Utils/Universal2D.hlsl"
            ENDHLSL
        }
    }
}
