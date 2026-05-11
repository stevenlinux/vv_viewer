#!/bin/bash
# Git Hooks 安装脚本
# 运行方式: bash scripts/install_hooks.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

echo "安装 Git hooks 到: $HOOKS_DIR"

# 创建 hooks 目录（如果不存在）
mkdir -p "$HOOKS_DIR"

# 安装 pre-commit hook
if [ -f "$PROJECT_ROOT/.git/hooks/pre-commit" ]; then
    echo "pre-commit hook 已存在，跳过"
else
    cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash
# Pre-commit hook for vv_viewer
# Runs flutter analyze before commit

set -e

echo "Running pre-commit checks..."

# Check if flutter is available
if ! command -v flutter &> /dev/null; then
    echo "Flutter not found, skipping analyze"
    exit 0
fi

# Run flutter analyze
echo "Running flutter analyze..."
flutter analyze --no-fatal-infos --no-fatal-warnings

echo "Pre-commit checks passed!"
EOF
    chmod +x "$HOOKS_DIR/pre-commit"
    echo "已安装 pre-commit hook"
fi

# 安装 commit-msg hook (可选 - 规范 commit message)
if [ -f "$PROJECT_ROOT/.git/hooks/commit-msg" ]; then
    echo "commit-msg hook 已存在，跳过"
else
    cat > "$HOOKS_DIR/commit-msg" << 'EOF'
#!/bin/bash
# Commit message hook
# 检查 commit message 格式

COMMIT_MSG="$1"
ALLOWED_TYPES="feat|fix|docs|style|refactor|test|chore"

if ! grep -qE "^[a-z]+(\([a-z]+\))?: .+" "$COMMIT_MSG"; then
    echo "Invalid commit message format."
    echo "Expected: <type>(<scope>): <subject>"
    echo "Allowed types: $ALLOWED_TYPES"
    exit 1
fi

echo "Commit message format OK"
EOF
    chmod +x "$HOOKS_DIR/commit-msg"
    echo "已安装 commit-msg hook"
fi

echo "Git hooks 安装完成！"
echo ""
echo "已安装的 hooks:"
ls -la "$HOOKS_DIR"/*.sh "$HOOKS_DIR"/pre-commit "$HOOKS_DIR"/commit-msg 2>/dev/null || echo "  (none additional)"
