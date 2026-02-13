#!/usr/bin/env bash
set -euo pipefail

# 1) 安装 Flutter（Vercel 环境默认没有 Flutter，所以必须装）
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter
fi

export PATH="$PWD/flutter/bin:$PATH"

# 2) 开启 web（有些环境需要）
flutter config --enable-web

# 3) 依赖 + 代码生成（你项目用到了 build_runner）
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# 4) 构建 web
flutter build web --release
