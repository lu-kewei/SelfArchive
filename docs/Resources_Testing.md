# 资源资产规范

## 目录结构
```
assets/
  images/
    bg_artistic.png
    bg_felt.png
    bg_fresh.png
    frame_fern.png
    frame_lilyofthevalley.png
    frame_sakura.png
    frame_tropical.png
    framed_sheet.png
    hanging_tag.png
    hemp_rope.png
    red_rope.png
    stickynote_blue.png
    stickynote_green.png
    stickynote_pink.png
    stickynote_yellow.png
    taped_note.png
    target_frame.png
```

## 命名规范
- 蛇形命名: `category_name_variant.png`
- 尺寸: 
  - 图钉: 64px (1x), 128px (2x), 192px (3x)
  - 纹理: 512px 或 1024px 可平铺
  - 图标: SVG 优先

---

# 测试清单 (当前实现)

## 核心交互
- [ ] **画布漫游**: 双指/鼠标拖拽能否平滑移动画布？缩放是否限制在 0.1-2.5 范围？
- [ ] **卡片拖拽**: 拖拽卡片时位置与连线是否同步更新？
- [ ] **创建流程**: FAB -> 类型选择 -> 样式选择 -> 卡片生成并进入编辑。
- [ ] **缩放模式**: 选中线索卡后缩放手柄可用，拖拽缩放是否顺滑。
- [ ] **删除确认**: 点击卡片右上角删除按钮是否弹出确认对话框。

## 数据持久化
- [ ] **冷启动**: 杀掉 App 再打开，卡片位置是否保留？
- [ ] **初始化**: 首次打开是否自动生成了图腾 + 11张主题卡？
## 标签与编辑
- [ ] **内联编辑**: 双击卡片进入编辑后，内容与标签是否自动保存。
- [ ] **标签关联**: 标签内容更新后，连线是否符合预期规则。

## 边界情况
- [ ] **无标签**: 创建无标签线索卡，应无连线，但不报错。
- [ ] **无效标签**: 输入不存在的主题标签，应忽略或建立到默认位置（需定义规则，当前忽略）。
- [ ] **大量数据**: 快速添加 20 张卡片，FPS 是否稳定？
