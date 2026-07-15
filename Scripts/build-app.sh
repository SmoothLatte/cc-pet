#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PRODUCT_NAME="CCPet"
APP_NAME="cc-pet"
BUNDLE_ID="com.ccpet.app"
BUILD_DIR="$PROJECT_DIR/.build/release"
APP_DIR="$PROJECT_DIR/dist/${APP_NAME}.app"
CONTENTS="$APP_DIR/Contents"

echo "==> 编译 Release 版本..."
cd "$PROJECT_DIR"
swift build -c release 2>&1

echo "==> 创建 .app 包结构..."
rm -rf "$APP_DIR"
mkdir -p "$CONTENTS/MacOS"
mkdir -p "$CONTENTS/Resources"

echo "==> 复制可执行文件..."
cp "$BUILD_DIR/$PRODUCT_NAME" "$CONTENTS/MacOS/$APP_NAME"

echo "==> 准备图标..."
ICON_SRC="$PROJECT_DIR/Resources/AppIcon.icns"
if [ ! -f "$ICON_SRC" ]; then
    echo "    AppIcon.icns 缺失,先运行 python3 Scripts/generate_icon.py"
    python3 "$PROJECT_DIR/Scripts/generate_icon.py"
fi
cp "$ICON_SRC" "$CONTENTS/Resources/AppIcon.icns"

echo "==> 生成 Info.plist..."
cat > "$CONTENTS/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>cc-pet</string>
    <key>CFBundleDisplayName</key>
    <string>cc-pet</string>
    <key>CFBundleIdentifier</key>
    <string>com.ccpet.app</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleExecutable</key>
    <string>cc-pet</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
</dict>
</plist>
PLIST

echo "==> 复制资源文件..."
BUNDLE_NAME="${APP_NAME}_${PRODUCT_NAME}.bundle"
if [ ! -d "$BUILD_DIR/$BUNDLE_NAME" ]; then
    echo "错误:缺少 SwiftPM 资源包 $BUILD_DIR/$BUNDLE_NAME"
    exit 1
fi
cp -R "$BUILD_DIR/$BUNDLE_NAME" "$CONTENTS/Resources/"
# SPM 生成的 Bundle.module 在 app 根目录也找,这里建软链接兜底
ln -sf "Contents/Resources/$BUNDLE_NAME" "$APP_DIR/$BUNDLE_NAME"

echo "==> 完成！"
echo "    应用路径: $APP_DIR"
echo ""
echo "    安装到 Applications:"
echo "    cp -R \"$APP_DIR\" /Applications/"
echo ""
echo "    直接运行:"
echo "    open \"$APP_DIR\""

du -sh "$APP_DIR"
