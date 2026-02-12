# 渲染架构方案

## 1. 坐标系统
- **世界坐标 (World Space)**: 逻辑坐标系，范围 0,0 到 3000,1800。所有 `Node.x/y` 均存储此坐标。
- **屏幕坐标 (Screen Space)**: `InteractiveViewer` 通过矩阵变换将世界坐标映射到屏幕。
- **渲染层级**:
  1. `BackgroundLayer`: `DetectiveWallBackground` 使用图片纹理铺底。
  2. `EdgeLayer`: `CustomPainter` 绘制连线，支持绳子纹理 `ImageShader`。
  3. `NodeLayer`: `Stack` + `Positioned` 渲染卡片与交互控件。

## 2. 性能优化 (目标 60fps)
- **InteractiveViewer**: 使用 `constrained: false` 避免布局约束计算开销。
- **CustomPainter**: 目前 `EdgesPainter.shouldRepaint` 始终返回 true，保证连线实时跟随。
- **图片资源**: 背景与贴图使用 `Image.asset` 与 `FilterQuality.high`。

## 3. 视觉分层
- **阴影**: 统一光照方向（如左上角光源），通过 `BoxShadow` 实现高度感。
- **材质**: 卡片底图使用素材 PNG，连线支持绳子纹理。
