# 大型项目开发实践

## 一、开发流程

```
需求提出
    ↓
[Brainstorming] ← 需求澄清、方案选择
    ↓
[Writing Plans] ← 多步骤任务规划
    ↓
用户确认
    ↓
[Executing Plans] ← 带检查点的执行
    ↓
[Verification] ← 每步验证后再下一步
    ↓
[Requesting Code Review] ← 完成前审查
    ↓
合并/发布
```

## 二、核心Skill速查

| Skill | 用途 | 何时使用 |
|-------|------|----------|
| `superpowers:brainstorming` | 头脑风暴 | 任何新功能开始前 |
| `superpowers:writing-plans` | 写实施计划 | 多步骤任务 |
| `superpowers:executing-plans` | 执行计划 | 用户确认计划后 |
| `superpowers:test-driven-development` | TDD | 写代码前先写测试 |
| `superpowers:systematic-debugging` | 系统化调试 | 遇到bug时 |
| `superpowers:requesting-code-review` | 代码审查 | 合并前 |
| `security-review` | 安全审查 | 涉及安全时 |
| `shell-scripting` | 脚本开发 | 需要自动化时 |
| `flutter-development` | Flutter开发 | 移动端开发时 |

## 三、内置命令

| 命令 | 说明 |
|------|------|
| `/help` | 显示帮助信息 |
| `/clear` | 清除当前对话 |
| `/review` | 审查PR |
| `/init` | 为项目生成CLAUDE.md |
| `/fast` | 快速模式 |
| `/budget` | 设置会话预算 |

## 四、关键原则

1. **先分析再动手** - 不要直接写代码，先理解需求
2. **先头脑风暴** - 用 brainstorming skill 澄清需求
3. **小步快跑** - 大任务拆成小步骤，每步验证
4. **自动化验证** - 边开发边测试，不要最后才测
5. **记录上下文** - 用CLAUDE.md和memory保存状态

## 五、本项目常用命令

### Flutter项目 (vv_viewer/)
```bash
cd vv_viewer
flutter pub get              # 安装依赖
flutter run                  # 运行
flutter test                 # 运行测试
flutter analyze              # 代码检查
flutter test --no-test-assets # 测试(无assets)
```

### Android项目 (remote-desktop-clients/)
```bash
cd remote-desktop-clients
./download-prebuilt-dependencies.sh              # 下载预编译库
./bVNC/prepare_project.sh --skip-build libs nopath  # 准备项目
./gradlew aSPICE-app:assembleDebug               # 构建
```

## 六、开发检查清单

### 开始新功能
- [ ] 用 brainstorming 分析需求
- [ ] 确认方案后才动手

### 调试问题
- [ ] 用 systematic-debugging 定位根因
- [ ] 不要猜测，用工具验证

### 代码完成
- [ ] 运行 `flutter analyze`
- [ ] 运行 `flutter test`
- [ ] 用 requesting-code-review 审查
- [ ] 检查 CLAUDE.md 是否需要更新

## 七、文档索引

| 文档 | 用途 |
|------|------|
| `CLAUDE.md` | 项目整体指导 |
| `vv_viewer/docs/INTEGRATION.md` | Flutter+aSPICE集成 |
| `vv_viewer/docs/EMBEDDED_SPICE.md` | 内嵌SPICE开发 |
| `vv_viewer/docs/ARCHITECTURE.md` | 架构详解 |
| `vv_viewer/docs/SETUP.md` | 环境搭建 |
| `vv_viewer/docs/VV_FILE_FORMAT.md` | .vv文件格式 |
