# SelfArchive (自我档案)

基于 Flutter 的高质感自我探索应用原型，以“侦探墙”为核心交互，聚合主题与线索卡片，支持离线本地保存。
你可以在self-archive.vercel.app上进行尝试。

## 主要功能
- 侦探墙画布的平移/缩放与相机状态持久化
- 图腾卡 / 主题卡 / 线索卡创建、拖拽与缩放
- 主题与标签驱动的自动连线
- 卡片编辑与样式工具栏（字体/字号/粗斜体/下划线/高亮）
- 卡片内图片插入（桌面 FilePicker、移动端 ImagePicker）
- 归档盒：归档、恢复、永久删除
- 主题风格包切换
- 画板导出为 PNG（桌面保存至下载目录、移动端保存到相册）

## 目录结构
- `lib/core`: 相机、主题包、命令体系、通用工具
- `lib/scene`: 场景模型与命令 (Node/Edge/BoardState)
- `lib/storage`: 本地存储服务（SharedPreferences）
- `lib/ui/board`: 侦探墙主界面、导出与交互层
- `lib/ui/create`: 新建卡片类型选择
- `lib/ui/editor`: 卡片详情编辑
- `lib/ui/style`: 卡片样式库
- `lib/ui/theme`: 主题选择
- `lib/ui/archive`: 归档盒
- `lib/ui/widgets`: 通用组件
- `assets/images`: 纹理与素材
- `docs`: 产品与设计说明文档

## 数据说明
- 本地离线存储，无账号体系
- Nodes/Edges 以 JSON 形式保存在 SharedPreferences
