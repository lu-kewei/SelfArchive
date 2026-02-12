# UI 结构图

```mermaid
graph TD
    App(SelfArchiveApp) --> BoardScreen
    
    subgraph Board Scene
        BoardScreen --> Scaffold
        Scaffold --> InteractiveViewer(相机/视口)
        InteractiveViewer --> BoardCanvas(AnimatedContainer 3000x1800)
        BoardCanvas --> Stack

        Stack --> BackgroundLayer(DetectiveWallBackground)
        Stack --> EdgeLayer(EdgesLayer/CustomPaint)
        Stack --> TapLayer(空白点击取消选中)
        Stack --> DragLine(拖拽图钉连线)
        Stack --> NodeLayer(DraggableNode/Positioned)

        NodeLayer --> CardWidget
        CardWidget --> PinHandle(顶部图钉)
        CardWidget --> ScaleHandles(缩放手柄)
        CardWidget --> DeleteButton(右上角)
        CardWidget --> Content(InlineTextEditor/文本)

        Scaffold --> FloatingActions(Reset/Camera/Archive/Theme/Add)
        BoardScreen --> Sheets(ThemePicker/CreateType/StyleGallery/ArchiveBox)
    end
```

## 组件层级说明
1. **BoardScreen**: 顶层页面，负责相机状态、节点选择与弹层（底部弹窗）。
2. **InteractiveViewer**: 提供画布平移/缩放与世界坐标映射。
3. **EdgesLayer**: 通过 `CustomPaint` 绘制连线与绳子纹理。
4. **DraggableNode**: 处理拖拽、缩放与卡片选择状态。
5. **CardWidget**: 渲染卡片样式、内容编辑、缩放手柄与删除按钮。
