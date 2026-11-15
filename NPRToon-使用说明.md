# NPRToon 使用说明

> 目标工程：`D:\Project\Unity\UnityShader`（Unity 2022.3.62f3 / URP 14.0.12）
> 新增着色器：`Hong/NPRToon`

---

## 1. 新增了哪些文件

| 文件 | 作用 |
|---|---|
| `Assets/Shaders/NPRToon.shader` | 主着色器。Pass 骨架继承 `LitToon.shader`，主光照换成卡通算法 |
| `Assets/Shaders/NPRToonInput.hlsl` | 材质数据层：`UnityPerMaterial` CBUFFER、贴图声明、`InitializeSimpleLitSurfaceData` |
| `Assets/Shaders/ShaderLibrary/NPRToonLighting.hlsl` | 算法层：阶梯量化 / Ramp 采样 / 脸部 SDF / 头发光带 / 高光 / MatCap / 边缘光 / 内轮廓 |
| `Assets/Scripts/NPRFaceShadowDriver.cs` | 脸部参数驱动：每帧写 `_FaceShadowPosWS` / `_FaceRight` / `_FaceForward`，自动开关 `_FACEPOINT_ON` |

**原有文件一行都没动**：`LitToon.shader`、`LitToonInput.hlsl`、`Cartoon.shader`、`ToonLighting.hlsl`、
`CartonnInput.hlsl` 全部保持原样。新着色器是独立的新 Shader 名，老材质不受影响。

---

## 2. 和 LitToon.shader 的关系

**继承的部分（保证行为一致）**

- Pass 列表与顺序：Outline(SRPDefaultUnlit) → ForwardLit → ShadowCaster → GBuffer → DepthOnly → DepthNormals → Meta → Universal2D
- 渲染状态变量（`_Cull` / `_SrcBlend` / `_ZWrite` / `_RECEIVE_SHADOWS_OFF` …）与混合模式预设
- LWGUI 面板写法（`[Main]` / `[Sub]` / `[SubToggle]` / `[Tex]` / `[Enum]`）
- `InitializeSimpleLitSurfaceData` 等函数名 —— 因为 ShadowCaster / GBuffer / DepthNormals / Meta
  这几个 Pass 直接复用 URP 的 `SimpleLit*Pass.hlsl`，它们依赖这些函数名

**替换的部分**

| 位置 | LitToon | NPRToon |
|---|---|---|
| 片元光照 | `UniversalFragmentBlinnPhong(...)` | `UniversalFragmentNPRToon(...)` |
| 描边宽度 | 观察空间偏移（近粗远细） | NDC 恒定宽度（远近一致，`_OutlineWidth` 单位改为"屏幕高度百分比"） |
| 明暗 | Blinn-Phong 连续 | Ramp 查表（可 1~6 档） |

---

## 3. 和原 `URP_NPR.shader` 的对照

| 原 NPR 的做法 | 本实现 | 说明 |
|---|---|---|
| Ramp 采样 `uv=(0.5, N·L×shadow)` | ✅ 保留 | 阴影并进采样坐标，一次采样出色阶 |
| 脸部 SDF（镜像 UV + `|L·Right|²` 比较） | ✅ 保留 | 额外暴露 `_FaceSDFSoftness` / `_FaceSDFOffset` |
| 整脸共享阴影坐标 `_FaceShadowPosWS` | ✅ 保留 | C# 驱动，见第 5 节 |
| 头发 `pow(N·V)` 光带 | ✅ 保留 | 参数化 Power/Bias/Scale |
| MatCap（视空间法线当 UV） | ✅ 保留 | 加了 `_MatCapWeight` 在 MatCap 与物理高光之间分配权重 |
| 内轮廓 | 🔄 **重写** | 原版要 `SSDepthOffsetPassFeature` 生成 `_DepthMaskColor`；这里直接读 URP 的 `_CameraDepthTexture` 做深度边缘检测，**不需要写 RendererFeature** |
| 描边 | 🔄 **改进** | 改成恒定屏幕宽度 |
| 光源颜色乘 3 次 | ❌ **修掉** | 现在只在 diffuse / spec 里各乘一次 |
| 自发光乘主光颜色 | ❌ **修掉** | 现在自发光独立，夜里也会亮 |
| 环境镜面项算了却丢弃 | ❌ **删掉** | 不再保留死代码 |
| `_FaceLightSDF_Offset` 声明没使用 | ❌ **接上** | 现在真的生效 |
| 屏幕空间刘海投影（SSHS） | ⚠️ **未实现** | 依赖原工程的 `SSHSRenderPassFeature`，本工程没有。要补的话见第 7 节 |
| 金属 GGX / 环境反射 | ⚠️ **未实现** | 本工程有 `ShaderLibrary/BRDF.hlsl`，可按第 7 节接回来 |

---

## 4. 快速上手

1. 新建材质 → Shader 选 `Hong/NPRToon`
2. 先只开 **Base**：贴 `_BaseMap`，确认模型正常显示
3. 打开 **Toon Ramp**：
   - 想快速看效果：不用贴图，直接调 `Shadow Color` / `Light Color`，`Ramp Steps = 1`（两分）或 `2`（三分）
   - 想用美术画的色阶：勾 `Use Ramp Map`，贴一张**竖直渐变条**（横轴不用管，代码固定取 x=0.5）
4. 模型是角色的脸 → 打开 **Face SDF**，并挂 `NPRFaceShadowDriver`
5. 头发 → 打开 **Hair Highlight**，`Power` 8~24、`Scale` 0.4~1.0 之间试
6. 需要硬边高光 → 打开 **Toon Specular**（与头发互斥，同时开会走头发分支）
7. 需要金属感 → 打开 **MatCap**，`MatCap Weight` 拉到 1
8. 需要描边 → 打开 **Outline**，`Width` 从 1 开始试（1 ≈ 屏幕高度的 1%）

---

## 5. 脸部 SDF 怎么用

**驱动脚本配置**（`NPRFaceShadowDriver`）

| 字段 | 说明 |
|---|---|
| Material | 留空则自动取 Renderer 的材质 |
| Face Point | 脸中心的一个空物体（位置会写进 `_FaceShadowPosWS`） |
| Head Bone | 头骨，用来推导朝向轴 |
| Auto Set Face Right | `_FaceRight = -headBone.forward`（模型默认面朝 -Z 时正确） |
| Auto Set Face Forward | `_FaceForward = headBone.up` |
| Use Shared Shadow Point | 勾上后自动开关材质关键字 `_FACEPOINT_ON` |

**如果脸部阴影方向整个是反的**，按顺序排查：

1. 先交换 `Negate Head Forward For Right` 的勾选状态
2. 还不对就把 `Use Head Up For Forward` 取消（改用 `headBone.forward`）
3. 仍不对，就在材质面板手动填 `_FaceRight` / `_FaceForward`，把脚本两个 auto 选项都关掉
   —— 这两个向量本质就是"脸的右方向"和"脸的上方向"，在世界空间里直接指对就行

**SDF 贴图约定**：R 通道为主 SDF、G 通道为次 SDF（代码取 `(r+g)*0.5`）。
只画了一张就放 R 通道，G 留黑会整体偏暗 → 那就把 `_FaceSDFOffset` 调到 `-0.5` 附近补偿。

---

## 6. 三个必须知道的限制

1. **内轮廓需要 Depth Texture**
   URP Asset（`UniversalRenderPipelineAsset`）里必须勾上 **Depth Texture**。
   没勾时 `_CameraDepthTexture` 采到 0，代码已做保护会直接返回 0（不会花屏），但也不会有线。

2. **MatCap 的 Y 方向**
   代码里有一行 `uv.y = 1.0 - uv.y;`。如果你的 MatCap 图上下颠倒，把那行注释掉即可
   （文件：`NPRToonLighting.hlsl` 的 `NPRMatCap`）。

3. **Deferred 走的是 SimpleLit 的 GBuffer**
   `UniversalGBuffer` Pass 复用了 URP 的 `SimpleLitGBufferPass.hlsl`，所以**在 Deferred 渲染路径下
   角色会按普通 SimpleLit 出图**，NPR 效果只在 Forward 生效。要用 NPR 就把渲染路径设为 Forward
   （或 Forward+）。

---

## 7. 想继续加功能时的接入点

**A. 屏幕空间刘海投影（SSHS）**

原实现依赖 `SSHSRenderPassFeature` 把头发渲染成 `_HairSoildColor`（R=遮罩，G=深度）。补法：

1. 抄原工程的 `SSHSRenderPassFeature` + 对应 shader（把头发画成纯色+深度）
2. 在 `NPRToonLighting.hlsl` 里新增一个 `NPRHairShadow(...)` 函数，逻辑就是原版那 6 行：
   光照方向投到屏幕 → 按 `1/w` 抵消距离 → `step(depth, hairDepth+0.02)` 深度测试 →
   乘 `1-smoothstep(0.6,0.8,uv.y)` 限制造用范围
3. 在 `UniversalFragmentNPRToon` 里把结果乘进脸部的 ramp 梯度

**B. 环境反射 / 金属 GGX**

本工程 `Assets/Shaders/ShaderLibrary/BRDF.hlsl` 里已有 `DirectBRDFSpecular` / `EnvironmentBRDF`，
`Lighting.hlsl` 里有 `InitializeBRDFData`。在 `NPRToonLighting.hlsl` 里加：

```hlsl
BRDFData brdfData;
InitializeBRDFData(albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.alpha, brdfData);
half3 spec = DirectBRDFSpecular(brdfData, N, L, V);
```

再乘 `_ToonSpecIntensity`，就能得到"卡通色阶 + 物理高光"的混合。

---

## 8. 调参速查

| 想要的效果 | 参数 |
|---|---|
| 阴影交界线位置 | `Shadow Offset`（+ 往暗部推） |
| 色阶硬/软 | `Ramp Smoothness`（0 = 硬边） |
| 色阶档数 | `Ramp Steps`（1=两分，2=三分，3=四分） |
| 阴影偏冷/偏暖 | `Ramp Shadow Color` 或 `Ramp Map` + `Ramp Tint` |
| 皮肤明暗更干净 | `Use Vertex Normal For Steps` 调大（1 = 完全用顶点法线） |
| 环境光太亮冲淡阴影 | `Ambient Strength` 调小（0.3~0.5） |
| 头发光带位置 | `Hair Highlight Bias` |
| 头发光带粗细 | `Hair Highlight Power`（越大越窄） |
| 高光硬边 | `Toon Spec Threshold` 调高 + `Spec Edge Softness` 调小 |
| 描边粗细 | `Outline Width`（1 = 屏幕高度 1%） |
| 内轮廓深浅 | `Inner Edge Intensity` / `Depth Threshold` |
| 内轮廓线宽 | `Sample Width (px)` |

---

## 9. 打开 Unity 后先看什么

1. Console 有没有 **Shader error**。最可能出问题的是两个外部 include：
   - `SimpleLitGBufferPass.hlsl`（GBuffer Pass）
   - `DeclareDepthTexture.hlsl`（内轮廓）
   这两个如果报错，把对应 Pass 或那段 `#if defined(_INNER_EDGE_ON)` 注释掉即可，主光照不受影响。
2. 材质面板能不能正常展开（LWGUI 属性写错会整块报错）。
3. 先只开 Base 看模型是否正常，再逐组打开开关 —— 这样出问题时能立刻定位是哪一组。
