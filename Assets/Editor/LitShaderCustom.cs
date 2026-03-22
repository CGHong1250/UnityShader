using System;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;
using UnityEditor.Rendering.Universal;

namespace UnityEditor.Rendering.Universal.ShaderGUI
{
    internal class LitShaderCustom : BaseShaderGUI
    {
        private MaterialProperty workflowModeProp;
        private MaterialProperty metallicProp;
        private MaterialProperty specColorProp;
        private MaterialProperty smoothnessProp;
        private MaterialProperty smoothnessTextureChannelProp;
        private MaterialProperty bumpScaleProp;
        private MaterialProperty bumpMapProp;
        private MaterialProperty occlusionStrengthProp;
        private MaterialProperty emissionMapProp;
        private MaterialProperty emissionColorProp;
        private MaterialProperty highlightsProp;
        private MaterialProperty reflectionsProp;
        private MaterialProperty parallaxMapProp;
        private MaterialProperty parallaxScaleProp;
        
        // PBRMap属性
        private MaterialProperty pbrMapProp;
        
        // 颜色调整属性
        private MaterialProperty colorMaskMapProp;
        private MaterialProperty hueShiftProp;
        private MaterialProperty saturationProp;
        private MaterialProperty brightnessProp;
        
        // 描边属性
        private MaterialProperty outlineColorProp;
        private MaterialProperty outlineWidthProp;
        private MaterialProperty enableOutlineProp;
        
        // 顶点混合属性
        private MaterialProperty enableLayerBlendProp;
        private MaterialProperty enableLayerBlendLayer02Prop;
        private MaterialProperty enableLayerBlendLayer03Prop;
        private MaterialProperty enableLayerBlendLayer04Prop;
        
        // 图层R属性
        private MaterialProperty layerMapRProp;
        private MaterialProperty layerColorRProp;
        private MaterialProperty hueShiftLayerRProp;
        private MaterialProperty saturationLayerRProp;
        private MaterialProperty brightnessLayerRProp;
        private MaterialProperty bumpMapLayerRProp;
        private MaterialProperty bumpScaleLayerRProp;
        private MaterialProperty pbrMapLayerRProp;
        private MaterialProperty smoothnessLayerRProp;
        private MaterialProperty metallicLayerRProp;
        private MaterialProperty specColorLayerRProp;
        private MaterialProperty occlusionStrengthLayerRProp;
        
        // 图层G属性
        private MaterialProperty layerMapGProp;
        private MaterialProperty layerColorGProp;
        private MaterialProperty hueShiftLayerGProp;
        private MaterialProperty saturationLayerGProp;
        private MaterialProperty brightnessLayerGProp;
        private MaterialProperty bumpMapLayerGProp;
        private MaterialProperty bumpScaleLayerGProp;
        private MaterialProperty pbrMapLayerGProp;
        private MaterialProperty smoothnessLayerGProp;
        private MaterialProperty metallicLayerGProp;
        private MaterialProperty specColorLayerGProp;
        private MaterialProperty occlusionStrengthLayerGProp;
        
        // 图层B属性
        private MaterialProperty layerMapBProp;
        private MaterialProperty layerColorBProp;
        private MaterialProperty hueShiftLayerBProp;
        private MaterialProperty saturationLayerBProp;
        private MaterialProperty brightnessLayerBProp;
        private MaterialProperty bumpMapLayerBProp;
        private MaterialProperty bumpScaleLayerBProp;
        private MaterialProperty pbrMapLayerBProp;
        private MaterialProperty smoothnessLayerBProp;
        private MaterialProperty metallicLayerBProp;
        private MaterialProperty specColorLayerBProp;
        private MaterialProperty occlusionStrengthLayerBProp;
        
        // 图层A属性
        private MaterialProperty layerMapAProp;
        private MaterialProperty layerColorAProp;
        private MaterialProperty hueShiftLayerAProp;
        private MaterialProperty saturationLayerAProp;
        private MaterialProperty brightnessLayerAProp;
        private MaterialProperty bumpMapLayerAProp;
        private MaterialProperty bumpScaleLayerAProp;
        private MaterialProperty pbrMapLayerAProp;
        private MaterialProperty smoothnessLayerAProp;
        private MaterialProperty metallicLayerAProp;
        private MaterialProperty specColorLayerAProp;
        private MaterialProperty occlusionStrengthLayerAProp;
        
        // 折叠状态
        private bool layerRExpanded = false;
        private bool layerGExpanded = false;
        private bool layerBExpanded = false;
        private bool layerAExpanded = false;
        
        // 样式
        private static class Styles
        {
            public static GUIContent workflowModeText = new GUIContent("Workflow Mode",
                "Select a workflow that fits your textures. Choose between Metallic or Specular.");
            
            public static GUIContent metallicText = new GUIContent("Metallic",
                "Metallic value");
            
            public static GUIContent specularText = new GUIContent("Specular",
                "Specular color");
            
            public static GUIContent smoothnessText = new GUIContent("Smoothness",
                "Smoothness value");
            
            public static GUIContent smoothnessChannelText = new GUIContent("Source",
                "Smoothness texture and channel");
            
            public static GUIContent highlightsText = new GUIContent("Specular Highlights",
                "Enable specular highlights");
            
            public static GUIContent reflectionsText = new GUIContent("Environment Reflections",
                "Enable environment reflections");
            
            public static GUIContent pbrMapText = new GUIContent("PBR Map", 
                "RGBA packed map: R:Metallic, G:Smoothness, B:Occlusion");
            
            public static GUIContent colorMaskText = new GUIContent("Color Mask",
                "White: Use HSB adjustment, Black: Disable adjustment (default: White)");
            
            public static GUIContent hueShiftText = new GUIContent("Hue Shift",
                "Shift the hue of the base color (0-1 range, full hue cycle)");
            
            public static GUIContent saturationText = new GUIContent("Saturation",
                "Adjust the saturation of the base color (0-2 range, 1 = normal)");
            
            public static GUIContent brightnessText = new GUIContent("Brightness",
                "Adjust the brightness of the base color (0-2 range, 1 = normal)");
            
            // 描边样式
            public static GUIContent outlineToggleText = new GUIContent("Enable Outline",
                "Enable cartoon-style outline rendering");
            
            public static GUIContent outlineColorText = new GUIContent("Outline Color",
                "Color of the outline");
            
            public static GUIContent outlineWidthText = new GUIContent("Outline Width",
                "Width of the outline (0.0 - 10)");
            
            // 顶点混合样式
            public static GUIContent layerBlendToggleText = new GUIContent("Enable Vertex Color Layer Blend",
                "Enable blending of multiple material layers using vertex color channels");
            
            public static GUIContent layerBlendInfoText = new GUIContent("Vertex Color Channel Usage:",
                "R: Blend Layer 01\nG: Blend Layer 02\nB: Blend Layer 03\nA: Blend Layer 04");
            
            // 图层样式
            public static GUIContent layerMapText = new GUIContent("Layer Map", "Texture for this layer");
            public static GUIContent layerColorText = new GUIContent("Layer Color", "Color tint for this layer");
            public static GUIContent hueShiftLayerText = new GUIContent("Hue Shift", "Hue shift for this layer");
            public static GUIContent saturationLayerText = new GUIContent("Saturation", "Saturation for this layer");
            public static GUIContent brightnessLayerText = new GUIContent("Brightness", "Brightness for this layer");
            public static GUIContent bumpMapLayerText = new GUIContent("Normal Map", "Normal map for this layer");
            public static GUIContent bumpScaleLayerText = new GUIContent("Normal Scale", "Normal map strength for this layer");
            public static GUIContent pbrMapLayerText = new GUIContent("PBR Map", "PBR map (R:Metallic, G:Smoothness, B:Occlusion) for this layer");
            public static GUIContent smoothnessLayerText = new GUIContent("Smoothness", "Smoothness for this layer");
            public static GUIContent metallicLayerText = new GUIContent("Metallic", "Metallic for this layer");
            public static GUIContent specColorLayerText = new GUIContent("Specular Color", "Specular color for this layer");
            public static GUIContent occlusionStrengthLayerText = new GUIContent("Occlusion Strength", "Occlusion strength for this layer");
            
            public static readonly string[] metallicSmoothnessChannelNames = { "Metallic Alpha", "Albedo Alpha" };
            public static readonly string[] specularSmoothnessChannelNames = { "Specular Alpha", "Albedo Alpha" };
        }
        
        // 工作流模式
        public enum WorkflowMode
        {
            Specular = 0,
            Metallic = 1
        }
        
        // 收集属性
        public override void FindProperties(MaterialProperty[] properties)
        {
            base.FindProperties(properties);
            
            // 查找所有需要的属性
            workflowModeProp = FindProperty("_WorkflowMode", properties, false);
            metallicProp = FindProperty("_Metallic", properties, false);
            specColorProp = FindProperty("_SpecColor", properties, false);
            smoothnessProp = FindProperty("_Smoothness", properties, false);
            smoothnessTextureChannelProp = FindProperty("_SmoothnessTextureChannel", properties, false);
            bumpScaleProp = FindProperty("_BumpScale", properties, false);
            bumpMapProp = FindProperty("_BumpMap", properties, false);
            occlusionStrengthProp = FindProperty("_OcclusionStrength", properties, false);
            emissionMapProp = FindProperty("_EmissionMap", properties, false);
            emissionColorProp = FindProperty("_EmissionColor", properties, false);
            highlightsProp = FindProperty("_SpecularHighlights", properties, false);
            reflectionsProp = FindProperty("_EnvironmentReflections", properties, false);
            parallaxMapProp = FindProperty("_ParallaxMap", properties, false);
            parallaxScaleProp = FindProperty("_Parallax", properties, false);
            
            // PBRMap属性
            pbrMapProp = FindProperty("_PBRMap", properties, false);
            
            // 颜色调整属性
            colorMaskMapProp = FindProperty("_ColorMaskMap", properties, false);
            hueShiftProp = FindProperty("_HueShift", properties, false);
            saturationProp = FindProperty("_Saturation", properties, false);
            brightnessProp = FindProperty("_Brightness", properties, false);
            
            // 描边属性
            outlineColorProp = FindProperty("_OutlineColor", properties, false);
            outlineWidthProp = FindProperty("_OutlineWidth", properties, false);
            enableOutlineProp = FindProperty("_EnableOutline", properties, false);
            
            // 顶点混合属性
            enableLayerBlendProp = FindProperty("_EnableLayerBlend", properties, false);
            enableLayerBlendLayer02Prop = FindProperty("_EnableLayerBlendLayer02", properties, false);
            enableLayerBlendLayer03Prop = FindProperty("_EnableLayerBlendLayer03", properties, false);
            enableLayerBlendLayer04Prop = FindProperty("_EnableLayerBlendLayer04", properties, false);
            
            // 图层R属性
            layerMapRProp = FindProperty("_LayerMapR", properties, false);
            layerColorRProp = FindProperty("_LayerColorR", properties, false);
            hueShiftLayerRProp = FindProperty("_HueShiftLayerR", properties, false);
            saturationLayerRProp = FindProperty("_SaturationLayerR", properties, false);
            brightnessLayerRProp = FindProperty("_BrightnessLayerR", properties, false);
            bumpMapLayerRProp = FindProperty("_BumpMapLayerR", properties, false);
            bumpScaleLayerRProp = FindProperty("_BumpScaleLayerR", properties, false);
            pbrMapLayerRProp = FindProperty("_PBRMaLayerR", properties, false);
            smoothnessLayerRProp = FindProperty("_SmoothnessLayerR", properties, false);
            metallicLayerRProp = FindProperty("_MetallicLayerR", properties, false);
            specColorLayerRProp = FindProperty("_SpecColorLayerR", properties, false);
            occlusionStrengthLayerRProp = FindProperty("_OcclusionStrengthLayerR", properties, false);
            
            // 图层G属性
            layerMapGProp = FindProperty("_LayerMapG", properties, false);
            layerColorGProp = FindProperty("_LayerColorG", properties, false);
            hueShiftLayerGProp = FindProperty("_HueShiftLayerG", properties, false);
            saturationLayerGProp = FindProperty("_SaturationLayerG", properties, false);
            brightnessLayerGProp = FindProperty("_BrightnessLayerG", properties, false);
            bumpMapLayerGProp = FindProperty("_BumpMapLayerG", properties, false);
            bumpScaleLayerGProp = FindProperty("_BumpScaleLayerG", properties, false);
            pbrMapLayerGProp = FindProperty("_PBRMaLayerG", properties, false);
            smoothnessLayerGProp = FindProperty("_SmoothnessLayerG", properties, false);
            metallicLayerGProp = FindProperty("_MetallicLayerG", properties, false);
            specColorLayerGProp = FindProperty("_SpecColorLayerG", properties, false);
            occlusionStrengthLayerGProp = FindProperty("_OcclusionStrengthLayerG", properties, false);
            
            // 图层B属性
            layerMapBProp = FindProperty("_LayerMapB", properties, false);
            layerColorBProp = FindProperty("_LayerColorB", properties, false);
            hueShiftLayerBProp = FindProperty("_HueShiftLayerB", properties, false);
            saturationLayerBProp = FindProperty("_SaturationLayerB", properties, false);
            brightnessLayerBProp = FindProperty("_BrightnessLayerB", properties, false);
            bumpMapLayerBProp = FindProperty("_BumpMapLayerB", properties, false);
            bumpScaleLayerBProp = FindProperty("_BumpScaleLayerB", properties, false);
            pbrMapLayerBProp = FindProperty("_PBRMaLayerB", properties, false);
            smoothnessLayerBProp = FindProperty("_SmoothnessLayerB", properties, false);
            metallicLayerBProp = FindProperty("_MetallicLayerB", properties, false);
            specColorLayerBProp = FindProperty("_SpecColorLayerB", properties, false);
            occlusionStrengthLayerBProp = FindProperty("_OcclusionStrengthLayerB", properties, false);
            
            // 图层A属性
            layerMapAProp = FindProperty("_LayerMapA", properties, false);
            layerColorAProp = FindProperty("_LayerColorA", properties, false);
            hueShiftLayerAProp = FindProperty("_HueShiftLayerA", properties, false);
            saturationLayerAProp = FindProperty("_SaturationLayerA", properties, false);
            brightnessLayerAProp = FindProperty("_BrightnessLayerA", properties, false);
            bumpMapLayerAProp = FindProperty("_BumpMapLayerA", properties, false);
            bumpScaleLayerAProp = FindProperty("_BumpScaleLayerA", properties, false);
            pbrMapLayerAProp = FindProperty("_PBRMaLayerA", properties, false);
            smoothnessLayerAProp = FindProperty("_SmoothnessLayerA", properties, false);
            metallicLayerAProp = FindProperty("_MetallicLayerA", properties, false);
            specColorLayerAProp = FindProperty("_SpecColorLayerA", properties, false);
            occlusionStrengthLayerAProp = FindProperty("_OcclusionStrengthLayerA", properties, false);
        }
        
        // 绘制表面选项
        public override void DrawSurfaceOptions(Material material)
        {
            EditorGUIUtility.labelWidth = 0f;
            
            // 绘制工作流模式
            if (workflowModeProp != null)
            {
                string[] workflowModeNames = Enum.GetNames(typeof(WorkflowMode));
                DoPopup(Styles.workflowModeText, workflowModeProp, workflowModeNames);
            }
            
            base.DrawSurfaceOptions(material);
        }
        
        // 绘制表面输入
        public override void DrawSurfaceInputs(Material material)
        {
            base.DrawSurfaceInputs(material);
            
            // 绘制颜色调整区域
            DrawColorAdjustmentArea();
            
            // 绘制PBRMap区域
            DrawPBRMapArea();
            
            // 绘制金属/高光区域
            DrawMetallicSpecularArea(material);
            
            // 绘制法线贴图
            if (bumpMapProp != null)
            {
                DrawNormalArea(materialEditor, bumpMapProp, bumpMapProp.textureValue != null ? bumpScaleProp : null);
            }
            
            // 绘制高度图
            if (parallaxMapProp != null)
            {
                materialEditor.TexturePropertySingleLine(
                    new GUIContent("Height Map", "Defines a Height Map that will drive a parallax effect"),
                    parallaxMapProp,
                    parallaxMapProp.textureValue != null ? parallaxScaleProp : null);
            }
            
            // 绘制描边区域
            DrawOutlineArea();
            
            // 绘制顶点混合区域
            DrawVertexBlendArea(material);
            
            // 绘制自发光属性
            DrawEmissionProperties(material, true);

            DrawTileOffset(materialEditor, baseMapProp);
        }
        
        // 绘制颜色调整区域
        private void DrawColorAdjustmentArea()
        {
            EditorGUILayout.Space();
            EditorGUILayout.LabelField("Color Adjustment", EditorStyles.boldLabel);
            EditorGUI.indentLevel++;
            
            // 绘制颜色遮罩贴图
            if (colorMaskMapProp != null)
            {
                materialEditor.TexturePropertySingleLine(Styles.colorMaskText, colorMaskMapProp);
            }
            
            // 显示调整参数
            EditorGUI.indentLevel++;
            
            if (hueShiftProp != null)
            {
                materialEditor.ShaderProperty(hueShiftProp, Styles.hueShiftText);
            }
            
            if (saturationProp != null)
            {
                materialEditor.ShaderProperty(saturationProp, Styles.saturationText);
            }
            
            if (brightnessProp != null)
            {
                materialEditor.ShaderProperty(brightnessProp, Styles.brightnessText);
            }
            
            EditorGUI.indentLevel--;
            
            // 显示提示信息
            EditorGUILayout.HelpBox(
                "色彩调整逻辑：" +
                "1. 如果提供了颜色蒙版纹理：\n" +
                "   - 白色像素：完全调整\n" +
                "   - 黑色像素：无需调整\n" +
                "   - 灰色像素：部分调整\n" +
                "2. 如果没有颜色掩码纹理：\n" +
                "   - 已进行全局调整(掩码值 = 1)\n" +
                "\n" +
                "默认设置:色调偏移(0),饱和度(1),亮度(1)= 不变",
                MessageType.Info);
            
            EditorGUI.indentLevel--;
        }
        
        // 绘制PBRMap区域
        private void DrawPBRMapArea()
        {
            if (pbrMapProp == null) return;
            
            EditorGUILayout.Space();
            EditorGUILayout.LabelField("PBR Map", EditorStyles.boldLabel);
            EditorGUI.indentLevel++;
            
            // 绘制PBRMap纹理
            materialEditor.TexturePropertySingleLine(Styles.pbrMapText, pbrMapProp);
            
            // 显示通道信息提示
            if (pbrMapProp.textureValue != null)
            {
                EditorGUILayout.HelpBox(
                    "PBR Map Channels:\n" +
                    "R: Metallic (multiplied by Metallic slider)\n" +
                    "G: Smoothness (multiplied by Smoothness slider)\n" +
                    "B: Occlusion (multiplied by Occlusion Strength)\n" +
                    "\n" +
                    "When PBR Map is assigned:\n" +
                    "- Overrides individual Metallic, Smoothness, and Occlusion values\n" +
                    "- Each channel is multiplied by its corresponding slider value", 
                    MessageType.Info);
            }
            
            EditorGUI.indentLevel--;
        }
        
        // 绘制描边区域
        private void DrawOutlineArea()
        {
            if (enableOutlineProp == null) return;
            
            EditorGUILayout.Space();
            EditorGUILayout.LabelField("Outline", EditorStyles.boldLabel);
            EditorGUI.indentLevel++;
            
            // 绘制描边启用开关
            bool enableOutline = enableOutlineProp.floatValue > 0.5f;
            EditorGUI.BeginChangeCheck();
            enableOutline = EditorGUILayout.Toggle(Styles.outlineToggleText, enableOutline);
            if (EditorGUI.EndChangeCheck())
            {
                enableOutlineProp.floatValue = enableOutline ? 1.0f : 0.0f;
            }
            
            // 如果启用了描边，显示其他属性
            if (enableOutline)
            {
                EditorGUI.indentLevel++;
                
                if (outlineColorProp != null)
                {
                    materialEditor.ShaderProperty(outlineColorProp, Styles.outlineColorText);
                }
                
                if (outlineWidthProp != null)
                {
                    materialEditor.ShaderProperty(outlineWidthProp, Styles.outlineWidthText);
                    EditorGUILayout.HelpBox(
                        "轮廓宽度受以下因素影响：模型比例\n" +
                        "1. 与摄像机的距离\n" +
                        "2. 屏幕分辨率\n" +
                        "3. 屏幕分辨率\n" +
                        "将数值调整至 0.0 至 10 之间可获得最佳效果",
                        MessageType.Info);
                }
                
                EditorGUI.indentLevel--;
            }
            
            EditorGUI.indentLevel--;
        }
        
        // 绘制顶点混合区域
        private void DrawVertexBlendArea(Material material)
        {
            if (enableLayerBlendProp == null) return;
            
            EditorGUILayout.Space();
            EditorGUILayout.LabelField("Vertex Color Layer Blend", EditorStyles.boldLabel);
            EditorGUI.indentLevel++;
            
            // 绘制总开关
            bool enableLayerBlend = enableLayerBlendProp.floatValue > 0.5f;
            EditorGUI.BeginChangeCheck();
            enableLayerBlend = EditorGUILayout.Toggle(Styles.layerBlendToggleText, enableLayerBlend);
            if (EditorGUI.EndChangeCheck())
            {
                enableLayerBlendProp.floatValue = enableLayerBlend ? 1.0f : 0.0f;
            }
            
            // 显示使用说明
            if (enableLayerBlend)
            {
                EditorGUILayout.HelpBox(Styles.layerBlendInfoText.tooltip, MessageType.Info);
            }
            
            // 如果启用了顶点混合，显示各图层
            if (enableLayerBlend)
            {
                // 图层R（总开关控制）
                DrawLayerProperties("Layer 01 (Vertex Color R)", true, 
                    layerMapRProp, layerColorRProp, hueShiftLayerRProp, saturationLayerRProp, brightnessLayerRProp,
                    bumpMapLayerRProp, bumpScaleLayerRProp, pbrMapLayerRProp, smoothnessLayerRProp, 
                    metallicLayerRProp, specColorLayerRProp, occlusionStrengthLayerRProp, ref layerRExpanded);
                
                // 图层G（需要额外开关）
                if (enableLayerBlendLayer02Prop != null)
                {
                    bool enableLayer02 = enableLayerBlendLayer02Prop.floatValue > 0.5f;
                    EditorGUI.BeginChangeCheck();
                    enableLayer02 = EditorGUILayout.Toggle("Enable Layer 02 (Vertex Color G)", enableLayer02);
                    if (EditorGUI.EndChangeCheck())
                    {
                        enableLayerBlendLayer02Prop.floatValue = enableLayer02 ? 1.0f : 0.0f;
                    }
                    
                    if (enableLayer02)
                    {
                        DrawLayerProperties("Layer 02 (Vertex Color G)", false,
                            layerMapGProp, layerColorGProp, hueShiftLayerGProp, saturationLayerGProp, brightnessLayerGProp,
                            bumpMapLayerGProp, bumpScaleLayerGProp, pbrMapLayerGProp, smoothnessLayerGProp,
                            metallicLayerGProp, specColorLayerGProp, occlusionStrengthLayerGProp, ref layerGExpanded);
                    }
                }
                
                // 图层B（需要额外开关）
                if (enableLayerBlendLayer03Prop != null)
                {
                    bool enableLayer03 = enableLayerBlendLayer03Prop.floatValue > 0.5f;
                    EditorGUI.BeginChangeCheck();
                    enableLayer03 = EditorGUILayout.Toggle("Enable Layer 03 (Vertex Color B)", enableLayer03);
                    if (EditorGUI.EndChangeCheck())
                    {
                        enableLayerBlendLayer03Prop.floatValue = enableLayer03 ? 1.0f : 0.0f;
                    }
                    
                    if (enableLayer03)
                    {
                        DrawLayerProperties("Layer 03 (Vertex Color B)", false,
                            layerMapBProp, layerColorBProp, hueShiftLayerBProp, saturationLayerBProp, brightnessLayerBProp,
                            bumpMapLayerBProp, bumpScaleLayerBProp, pbrMapLayerBProp, smoothnessLayerBProp,
                            metallicLayerBProp, specColorLayerBProp, occlusionStrengthLayerBProp, ref layerBExpanded);
                    }
                }
                
                // 图层A（需要额外开关）
                if (enableLayerBlendLayer04Prop != null)
                {
                    bool enableLayer04 = enableLayerBlendLayer04Prop.floatValue > 0.5f;
                    EditorGUI.BeginChangeCheck();
                    enableLayer04 = EditorGUILayout.Toggle("Enable Layer 04 (Vertex Color A)", enableLayer04);
                    if (EditorGUI.EndChangeCheck())
                    {
                        enableLayerBlendLayer04Prop.floatValue = enableLayer04 ? 1.0f : 0.0f;
                    }
                    
                    if (enableLayer04)
                    {
                        DrawLayerProperties("Layer 04 (Vertex Color A)", false,
                            layerMapAProp, layerColorAProp, hueShiftLayerAProp, saturationLayerAProp, brightnessLayerAProp,
                            bumpMapLayerAProp, bumpScaleLayerAProp, pbrMapLayerAProp, smoothnessLayerAProp,
                            metallicLayerAProp, specColorLayerAProp, occlusionStrengthLayerAProp, ref layerAExpanded);
                    }
                }
            }
            
            EditorGUI.indentLevel--;
        }
        
        // 绘制单个图层的属性
        private void DrawLayerProperties(string title, bool isLayerR, 
            MaterialProperty layerMap, MaterialProperty layerColor, 
            MaterialProperty hueShift, MaterialProperty saturation, MaterialProperty brightness,
            MaterialProperty bumpMap, MaterialProperty bumpScale,
            MaterialProperty pbrMap, MaterialProperty smoothness,
            MaterialProperty metallic, MaterialProperty specColor, MaterialProperty occlusionStrength,
            ref bool expanded)
        {
            EditorGUILayout.Space();
            
            // 使用折叠区域
            expanded = EditorGUILayout.Foldout(expanded, title, true);
            if (expanded)
            {
                EditorGUI.indentLevel++;
                
                // 绘制贴图和颜色
                materialEditor.TexturePropertySingleLine(Styles.layerMapText, layerMap, layerColor);
                
                // 绘制颜色调整
                EditorGUILayout.LabelField("Color Adjustment", EditorStyles.miniBoldLabel);
                EditorGUI.indentLevel++;
                if (hueShift != null) materialEditor.ShaderProperty(hueShift, Styles.hueShiftLayerText);
                if (saturation != null) materialEditor.ShaderProperty(saturation, Styles.saturationLayerText);
                if (brightness != null) materialEditor.ShaderProperty(brightness, Styles.brightnessLayerText);
                EditorGUI.indentLevel--;
                
                // 绘制法线贴图
                EditorGUILayout.Space();
                if (bumpMap != null)
                {
                    materialEditor.TexturePropertySingleLine(Styles.bumpMapLayerText, bumpMap, 
                        bumpMap.textureValue != null ? bumpScale : null);
                }
                
                // 绘制PBR属性
                EditorGUILayout.Space();
                EditorGUILayout.LabelField("PBR Properties", EditorStyles.miniBoldLabel);
                EditorGUI.indentLevel++;
                
                // 绘制PBR贴图
                if (pbrMap != null)
                {
                    materialEditor.TexturePropertySingleLine(Styles.pbrMapLayerText, pbrMap);
                }
                
                // 如果是金属工作流，绘制金属度
                if (metallic != null)
                {
                    materialEditor.ShaderProperty(metallic, Styles.metallicLayerText);
                }
                
                // 如果是高光工作流，绘制高光颜色
                if (specColor != null)
                {
                    materialEditor.ShaderProperty(specColor, Styles.specColorLayerText);
                }
                
                // 绘制光滑度
                if (smoothness != null)
                {
                    materialEditor.ShaderProperty(smoothness, Styles.smoothnessLayerText);
                }
                
                // 绘制遮挡强度
                if (occlusionStrength != null)
                {
                    materialEditor.ShaderProperty(occlusionStrength, Styles.occlusionStrengthLayerText);
                }
                
                EditorGUI.indentLevel--;
                
                EditorGUI.indentLevel--;
            }
        }
        
        // 绘制金属/高光区域
        private void DrawMetallicSpecularArea(Material material)
        {
            if (workflowModeProp == null) return;
            
            var workflowMode = (WorkflowMode)workflowModeProp.floatValue;
            
            EditorGUI.indentLevel += 2;
            
            if (workflowMode == WorkflowMode.Metallic)
            {
                // 金属工作流
                if (metallicProp != null)
                {
                    materialEditor.ShaderProperty(metallicProp, Styles.metallicText);
                }
            }
            else
            {
                // 高光工作流
                if (specColorProp != null)
                {
                    materialEditor.ShaderProperty(specColorProp, Styles.specularText);
                }
            }
            
            // 绘制平滑度
            if (smoothnessProp != null)
            {
                materialEditor.ShaderProperty(smoothnessProp, Styles.smoothnessText);
                
                // 绘制平滑度来源通道
                if (smoothnessTextureChannelProp != null)
                {
                    EditorGUI.indentLevel++;
                    
                    bool opaque = IsOpaque(material);
                    EditorGUI.showMixedValue = smoothnessTextureChannelProp.hasMixedValue;
                    
                    if (opaque)
                    {
                        MaterialEditor.BeginProperty(smoothnessTextureChannelProp);
                        EditorGUI.BeginChangeCheck();
                        var smoothnessSource = (int)smoothnessTextureChannelProp.floatValue;
                        
                        string[] channelNames = workflowMode == WorkflowMode.Metallic ? 
                            Styles.metallicSmoothnessChannelNames : 
                            Styles.specularSmoothnessChannelNames;
                        
                        smoothnessSource = EditorGUILayout.Popup(Styles.smoothnessChannelText, 
                            smoothnessSource, channelNames);
                        if (EditorGUI.EndChangeCheck())
                            smoothnessTextureChannelProp.floatValue = smoothnessSource;
                        MaterialEditor.EndProperty();
                    }
                    else
                    {
                        EditorGUI.BeginDisabledGroup(true);
                        EditorGUILayout.Popup(Styles.smoothnessChannelText, 0, 
                            workflowMode == WorkflowMode.Metallic ? 
                            Styles.metallicSmoothnessChannelNames : 
                            Styles.specularSmoothnessChannelNames);
                        EditorGUI.EndDisabledGroup();
                    }
                    
                    EditorGUI.showMixedValue = false;
                    EditorGUI.indentLevel--;
                }
            }
            
            EditorGUI.indentLevel -= 2;
        }
        
        // 检查是否不透明
        private bool IsOpaque(Material material)
        {
            if (material.HasProperty("_Surface"))
                return ((SurfaceType)material.GetFloat("_Surface") == SurfaceType.Opaque);
            return true;
        }
        
        // 绘制高级选项
        public override void DrawAdvancedOptions(Material material)
        {
            base.DrawAdvancedOptions(material);
            
            if (highlightsProp != null)
            {
                materialEditor.ShaderProperty(highlightsProp, Styles.highlightsText);
            }
            
            if (reflectionsProp != null)
            {
                materialEditor.ShaderProperty(reflectionsProp, Styles.reflectionsText);
            }
        }
        
        // 设置材质关键字
        public override void ValidateMaterial(Material material)
        {
            base.ValidateMaterial(material);
            
            // 设置自定义关键字
            SetCustomMaterialKeywords(material);
        }

        // 设置自定义材质关键字
        private void SetCustomMaterialKeywords(Material material)
        {
            // 设置PBRMap关键字
            if (pbrMapProp != null)
            {
                bool hasPBRMap = pbrMapProp.textureValue != null;

                if (hasPBRMap)
                {
                    material.EnableKeyword("_PBRMAP");
                }
                else
                {
                    material.DisableKeyword("_PBRMAP");
                }
            }

            // 设置颜色调整关键字
            // 总是启用_COLOR_ADJUST关键字，因为即使没有遮罩贴图也会应用调整
            material.EnableKeyword("_COLOR_ADJUST");

            if (colorMaskMapProp != null)
            {
                bool hasColorMask = colorMaskMapProp.textureValue != null;

                if (hasColorMask)
                {
                    material.EnableKeyword("_COLORMASKMAP");
                }
                else
                {
                    material.DisableKeyword("_COLORMASKMAP");
                }
            }

            // 设置描边关键字
            if (enableOutlineProp != null)
            {
                bool enableOutline = enableOutlineProp.floatValue > 0.5f;
                if (enableOutline)
                {
                    material.EnableKeyword("ENABLE_OUTLINE");
                }
                else
                {
                    material.DisableKeyword("ENABLE_OUTLINE");
                }
            }

            // 设置顶点混合关键字
            if (enableLayerBlendProp != null)
            {
                bool enableLayerBlend = enableLayerBlendProp.floatValue > 0.5f;
                if (enableLayerBlend)
                {
                    material.EnableKeyword("_ENABLE_LAYER_BLEDN");


                    // 设置图层G的关键字
                    if (enableLayerBlendLayer02Prop != null)
                    {
                        bool enableLayer02 = enableLayerBlendLayer02Prop.floatValue > 0.5f;
                        if (enableLayer02)
                        {
                            material.EnableKeyword("_ENABLE_LAYER_BLEDN_LAYER02");
                        }
                        else
                        {
                            material.DisableKeyword("_ENABLE_LAYER_BLEDN_LAYER02");
                        }
                    }

                    // 设置图层B的关键字
                    if (enableLayerBlendLayer03Prop != null)
                    {
                        bool enableLayer03 = enableLayerBlendLayer03Prop.floatValue > 0.5f;
                        if (enableLayer03)
                        {
                            material.EnableKeyword("_ENABLE_LAYER_BLEDN_LAYER03");
                        }
                        else
                        {
                            material.DisableKeyword("_ENABLE_LAYER_BLEDN_LAYER03");
                        }
                    }

                    // 设置图层A的关键字
                    if (enableLayerBlendLayer04Prop != null)
                    {
                        bool enableLayer04 = enableLayerBlendLayer04Prop.floatValue > 0.5f;
                        if (enableLayer04)
                        {
                            material.EnableKeyword("_ENABLE_LAYER_BLEDN_LAYER04");
                        }
                        else
                        {
                            material.DisableKeyword("_ENABLE_LAYER_BLEDN_LAYER04");
                        }
                    }
                }
                else
                {
                    material.DisableKeyword("_ENABLE_LAYER_BLEDN");
                    material.DisableKeyword("_ENABLE_LAYER_BLEDN_LAYER02");
                    material.DisableKeyword("_ENABLE_LAYER_BLEDN_LAYER03");
                    material.DisableKeyword("_ENABLE_LAYER_BLEDN_LAYER04");
                }
            }

            // 设置其他关键字
            if (highlightsProp != null)
            {
                bool highlights = highlightsProp.floatValue == 1.0f;
                CoreUtils.SetKeyword(material, "_SPECULARHIGHLIGHTS_OFF", !highlights);
            }

            if (reflectionsProp != null)
            {
                bool reflections = reflectionsProp.floatValue == 1.0f;
                CoreUtils.SetKeyword(material, "_ENVIRONMENTREFLECTIONS_OFF", !reflections);
            }

            // 设置工作流模式关键字
            if (workflowModeProp != null)
            {
                bool isSpecularWorkflow = (WorkflowMode)workflowModeProp.floatValue == WorkflowMode.Specular;
                CoreUtils.SetKeyword(material, "_SPECULAR_SETUP", isSpecularWorkflow);
            }

            // 设置平滑度通道关键字
            if (smoothnessTextureChannelProp != null && material.HasProperty("_SmoothnessTextureChannel"))
            {
                bool smoothnessChannelAlbedoAlpha = material.GetFloat("_SmoothnessTextureChannel") == 1;
                if (IsOpaque(material))
                {
                    CoreUtils.SetKeyword(material, "_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A", smoothnessChannelAlbedoAlpha);
                }
                else
                {
                    material.DisableKeyword("_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A");
                }
            }

            // 设置高度图关键字
            if (parallaxMapProp != null)
            {
                bool hasParallaxMap = parallaxMapProp.textureValue != null;
                CoreUtils.SetKeyword(material, "_PARALLAXMAP", hasParallaxMap);
            }

            // 设置法线贴图关键字
            if (bumpMapProp != null)
            {
                bool hasNormalMap = bumpMapProp.textureValue != null;
                CoreUtils.SetKeyword(material, "_NORMALMAP", hasNormalMap);
            }
        
            // 设置 Emission 关键字
            if (emissionMapProp != null && emissionColorProp != null)
            {
                bool hasEmissionMap = emissionMapProp.textureValue != null;
                bool hasEmissionColor = emissionColorProp.colorValue.maxColorComponent > 0.01f;

                if (hasEmissionMap || hasEmissionColor)
                {
                    material.EnableKeyword("_EMISSION");
                }
                else
                {
                    material.DisableKeyword("_EMISSION");
                }
                
                // 如果有 Emission 贴图，设置对应关键字
                if (hasEmissionMap)
                {
                    material.EnableKeyword("_EMISSION_MAP");
                }
                else
                {
                    material.DisableKeyword("_EMISSION_MAP");
                }
            }

        }
        
        // 绘制法线贴图区域的辅助方法
        private static void DrawNormalArea(MaterialEditor materialEditor, MaterialProperty bumpMap, MaterialProperty bumpScale = null)
        {
            if (bumpScale != null)
            {
                materialEditor.TexturePropertySingleLine(
                    new GUIContent("Normal Map", "Designates a Normal Map to create the illusion of bumps and dents on this Material's surface."),
                    bumpMap,
                    bumpMap.textureValue != null ? bumpScale : null);
            }
            else
            {
                materialEditor.TexturePropertySingleLine(
                    new GUIContent("Normal Map", "Designates a Normal Map to create the illusion of bumps and dents on this Material's surface."),
                    bumpMap);
            }
        }
    }
}