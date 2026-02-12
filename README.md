# SelfArchive (自我档案)

<p align="center">
  <img src="docs/self_archive_test.png" width="80%" />
</p>

基于 Flutter 的高质感自我探索应用原型，以「侦探墙」为核心交互，聚合主题与线索卡片，支持离线本地保存。

## 主要功能
- 侦探墙画布的平移/缩放与相机状态持久化
- 图腾卡 / 主题卡 / 线索卡创建、拖拽与缩放
- 主题与标签驱动的自动连线
- 卡片编辑与样式工具栏（字体/字号/粗斜体/下划线/高亮）
- 卡片内图片插入（桌面 FilePicker、移动端 ImagePicker）
- 归档盒：归档、恢复、永久删除
- 主题风格包切换
- 画板导出为 PNG（桌面保存至下载目录、移动端保存到相册）

## 技术栈
- Flutter / Dart
- Riverpod + riverpod_generator
- Freezed + json_serializable
- SharedPreferences（JSON 本地持久化）
- image_picker / file_picker / image_gallery_saver / path_provider / permission_handler

## 运行指南
1. **获取依赖**:
   ```bash
   flutter pub get
   ```

2. **代码生成（当修改 Riverpod/Freezed 相关文件时）**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

3. **运行**:
   ```bash
   flutter run
   ```

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

## 项目清理
- `build/`、`.dart_tool/`、`.idea/`、`.flutter-plugins`、`.flutter-plugins-dependencies`、`.metadata` 为生成文件/缓存，可安全删除并在需要时重新生成
