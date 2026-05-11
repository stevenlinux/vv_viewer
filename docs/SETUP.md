# 开发环境搭建指南

## 目录

- [系统要求](#系统要求)
- [Flutter 项目环境](#flutter-项目环境)
- [Android 项目环境](#android-项目环境)
- [验证安装](#验证安装)
- [IDE 配置](#ide-配置)

## 系统要求

### 最低配置

- **操作系统**: macOS 10.15+, Windows 10+, 或 Linux (Ubuntu 18.04+)
- **内存**: 8GB RAM (推荐 16GB)
- **磁盘空间**: 20GB 可用空间
- **CPU**: Intel i5 或同等性能

### 推荐配置

- **操作系统**: macOS 12+ (开发 iOS/macOS 应用推荐)
- **内存**: 16GB+ RAM
- **磁盘空间**: 50GB+ SSD
- **CPU**: Intel i7 / M1/M2 或更好

## Flutter 项目环境

### 1. 安装 Flutter

#### macOS

```bash
# 使用 Homebrew 安装 (推荐)
brew install --cask flutter

# 或手动安装
# 下载 Flutter SDK: https://docs.flutter.dev/get-started/install
```

#### Linux

```bash
# 下载 Flutter SDK
cd ~/development
tar xf ~/Downloads/flutter_linux_*.tar.xz

# 添加到 PATH
export PATH="$PATH:$HOME/development/flutter/bin"
```

#### Windows

```powershell
# 使用 Chocolatey
choco install flutter

# 或手动下载解压
```

### 2. 验证 Flutter 安装

```bash
# 运行 flutter doctor
flutter doctor

# 检查所有依赖
flutter doctor -v
```

### 3. 配置 Flutter 项目

```bash
# 进入项目目录
cd /Users/steve/ClaudeProjects/vv_viewer

# 安装依赖
flutter pub get

# 检查可用设备
flutter devices

# 运行项目
flutter run
```

### 4. Flutter  IDE 配置

#### VS Code

1. 安装 Flutter 扩展
2. 安装 Dart 扩展
3. 打开项目文件夹
4. 按 F5 运行调试

#### Android Studio / IntelliJ

1. 安装 Flutter 插件
2. 安装 Dart 插件
3. 打开项目 (`File` -> `Open` -> 选择 `vv_viewer` 目录
4. 点击运行按钮

## Android 项目环境

### 1. 安装 JDK

aSPICE 项目需要 JDK 11 或更高版本。

#### macOS

```bash
# 使用 Homebrew
brew install openjdk@11

# 配置 JAVA_HOME
export JAVA_HOME=$(/usr/libexec/java_home -v 11)
export PATH=$JAVA_HOME/bin:$PATH
```

#### Linux (Ubuntu)

```bash
sudo apt update
sudo apt install openjdk-11-jdk

# 配置环境变量
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH
```

#### Windows

下载并安装 [Adoptium JDK 11](https://adoptium.net/)

### 2. 安装 Android Studio

下载地址: https://developer.android.com/studio

安装后需要配置:

1. 启动 Android Studio
2. 安装 Android SDK (API 28, 29, 30)
3. 安装 Android SDK Command-line Tools
4. 安装 CMake (用于 NDK 编译)
5. 安装 NDK (如需编译原生代码)

### 3. 配置 Android SDK

```bash
# 设置环境变量 (macOS/Linux)
export ANDROID_SDK=$HOME/Library/Android/sdk
export ANDROID_HOME=$ANDROID_SDK
export PATH=$PATH:$ANDROID_SDK/platform-tools
export PATH=$PATH:$ANDROID_SDK/cmdline-tools/latest/bin
```

### 4. 接受 Android 许可证

```bash
# 接受所有许可证
sdkmanager --licenses

# 多次输入 y 确认
```

### 5. 配置 aSPICE 项目

```bash
# 进入项目目录
cd /Users/steve/ClaudeProjects/remote-desktop-clients

# 下载预编译依赖 (推荐，避免漫长的原生编译)
./download-prebuilt-dependencies.sh

# 准备项目
./bVNC/prepare_project.sh --skip-build libs nopath
```

### 6. 使用 Android Studio 打开项目

1. 启动 Android Studio
2. 选择 `Open an Existing Project`
3. 选择 `/Users/steve/ClaudeProjects/remote-desktop-clients`
4. 等待 Gradle 同步完成 (首次可能需要 5-10 分钟)
5. 安装提示缺失的 SDK 版本

## 验证安装

### 验证 Flutter

```bash
cd /Users/steve/ClaudeProjects/vv_viewer
flutter doctor
flutter analyze
flutter test
```

### 验证 Android 项目

```bash
cd /Users/steve/ClaudeProjects/remote-desktop-clients

# 检查 Gradle
./gradlew tasks

# 编译 Debug 版本 (aSPICE)
./gradlew aSPICE-app:assembleDebug
```

## IDE 配置

### 推荐工具

#### VS Code 扩展 (Flutter)

- Flutter
- Dart
- Flutter Widget Snippets
- Awesome Flutter Snippets
- Pubspec Assist
- Error Lens

#### Android Studio 插件 (Android)

- IdeaVim (如果你喜欢 Vim)
- Key Promoter X
- Rainbow Brackets
- CodeGlance
- SonarLint

### 代码风格配置

#### Flutter 格式化配置 (`analysis_options.yaml)

项目已包含 `analysis_options.yaml`，定义了 lint 规则。

#### Java 代码风格

Android 项目使用标准 Java 代码风格。

### Git 配置

```bash
# 设置用户信息
git config --global user.name "Your Name"
git config --global user.email "you@example.com"

# 配置编辑器
git config --global core.editor "code --wait"

# 配置默认分支
git config --global init.defaultBranch main
```

## 常见问题

### Q: `flutter doctor` 报错怎么办？

A: 按提示安装缺失的依赖。常见问题：

- Android toolchain - 按提示安装 Android Studio 和命令行工具
- VS Code - 安装 Flutter 扩展
- Connected device - 启动模拟器或连接真机

### Q: Gradle 同步失败？

A: 尝试：

1. 检查网络连接
2. 检查 `local.properties` 文件中的 SDK 路径
3. 运行 `./gradlew clean`
4. 删除 `File` -> `Invalidate Caches / Restart`

### Q: 如何启动模拟器？

A: 在 Android Studio 中：
1. 打开 Device Manager
2. 创建新设备 (推荐 Pixel 5 API 30)
3. 启动模拟器

或使用命令行：
```bash
# 列出可用模拟器
emulator -list-avds

# 启动模拟器
emulator -avd <device_name>
```

### Q: 如何连接真机调试？

A:
1. 在手机上启用「开发者选项」
2. 启用「USB 调试」
3. 用 USB 连接手机
4. 运行 `adb devices` 确认
5. 在 Android Studio 中选择设备

### Q: NDK 相关错误？

A: 使用预编译库跳过原生编译：
```bash
./download-prebuilt-dependencies.sh
```

## 下一步

- 阅读 [ARCHITECTURE.md](./ARCHITECTURE.md) 了解项目架构
- 阅读 [MODIFICATION_GUIDE.md](./MODIFICATION_GUIDE.md) 开始魔改
