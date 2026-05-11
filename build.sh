#!/bin/bash
# VV Viewer 构建脚本
# 用于在网络环境不好时使用 wget 下载 Gradle 后手动构建

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

echo "=== VV Viewer 构建脚本 ==="
echo "项目目录: $PROJECT_DIR"

# 检查 Gradle
echo ""
echo "检查 Gradle..."
if command -v ./android/gradlew &> /dev/null; then
    echo "使用项目自带的 Gradle Wrapper"
elif command -v gradle &> /dev/null; then
    echo "使用系统 Gradle"
else
    echo "错误: 未找到 Gradle"
    exit 1
fi

# 检查 Flutter
echo ""
echo "检查 Flutter..."
if ! command -v flutter &> /dev/null; then
    echo "错误: 未找到 Flutter"
    exit 1
fi

# 清理
echo ""
echo "清理项目..."
flutter clean

# 获取依赖
echo ""
echo "获取依赖..."
flutter pub get

# 构建
echo ""
echo "构建 APK..."
flutter build apk --debug

echo ""
echo "=== 构建完成 ==="
echo "APK 文件位于: build/app/outputs/flutter-apk/app-debug.apk"
