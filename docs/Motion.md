# 当前动效实现

## 1. 连线曲线与绳子纹理
- **贝塞尔曲线**: 使用二阶贝塞尔曲线 (`quadraticBezierTo`) 绘制连线。
- **控制点**: 以 `(start + end) / 2 + (0, slack)` 构建下垂感，`slack = distance * 0.1`。
- **纹理**: 通过 `ImageShader` 将绳子纹理平铺在连线上。

## 2. 卡片入场缩放
- **动画控制**: `AnimationController` + `Curves.easeOutBack`。
- **表现**: 卡片创建时执行 `ScaleTransition` 的轻微弹性放大回弹。

## 3. 图钉拖拽连线
- **拖拽预览线**: 拖拽图钉时绘制单独的二阶贝塞尔线段，用于预览连接。
