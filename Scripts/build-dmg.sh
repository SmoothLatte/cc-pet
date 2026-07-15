#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DIST_DIR="$PROJECT_DIR/dist"
APP_NAME="cc-pet"
DMG_NAME="$APP_NAME.dmg"
VOLUME_NAME="cc-pet"
APP_PATH="$DIST_DIR/$APP_NAME.app"

cd "$PROJECT_DIR"

# 构建
echo "🔨 构建项目..."
swift build -c release 2>&1 | tail -3

echo "📦 打包 .app..."
bash Scripts/build-app.sh

if [ ! -d "$APP_PATH" ]; then
    echo "❌ $APP_PATH 不存在"
    exit 1
fi

# 清理旧 DMG
rm -f "$DIST_DIR/$DMG_NAME"

# 创建临时目录
TMP_DMG_DIR=$(mktemp -d)
mkdir -p "$TMP_DMG_DIR/.background"

# 拷贝 app 和 Applications 链接
cp -R "$APP_PATH" "$TMP_DMG_DIR/"
ln -s /Applications "$TMP_DMG_DIR/Applications"

# 创建 DMG
echo "💿 生成 DMG..."
hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$TMP_DMG_DIR" \
    -ov \
    -format UDZO \
    "$DIST_DIR/$DMG_NAME"

# 清理
rm -rf "$TMP_DMG_DIR"

echo ""
echo "✅ DMG 已生成: $DIST_DIR/$DMG_NAME"
echo "   大小: $(du -h "$DIST_DIR/$DMG_NAME" | cut -f1)"
echo ""
echo "   使用方式: 打开 DMG → 拖拽 cc-pet.app 到 Applications"
