#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

fail() {
    echo "❌ $1"
    exit 1
}

test -f LICENSE || fail "缺少 LICENSE"
test -d CCPet || fail "缺少 CCPet 源码目录"
test -d CCPetTests || fail "缺少 CCPetTests 测试目录"
test ! -e CCPet/Resources/pet_body.png || fail "仍包含外部图片资源"
test ! -e Scripts/cutout_pig.py || fail "仍包含外部图片抠图脚本"

legacy_brand="Fli""ggy"
legacy_product="Piggy""Pet"
legacy_slug="piggy""-pet"
legacy_bundle="piggy""pet"
legacy_display="猪""飞飞"

if find . -path './.build' -prune -o -path './.swiftpm' -prune -o \
    \( -name "*${legacy_product}*" -o -name "*${legacy_slug}*" \) -print \
    | rg -q .; then
    fail "文件或目录仍使用旧名称"
fi

if rg -n -i \
    -g '!.build/**' \
    -g '!.swiftpm/**' \
    -g '!dist/**' \
    -g '!Package.resolved' \
    -g '!Scripts/verify-public.sh' \
    "(alibaba-inc|/Users/beimo|trip-baymax|some-ai|${legacy_brand}|${legacy_product}|${legacy_slug}|${legacy_bundle}|${legacy_display})" .; then
    fail "发现内部信息、个人路径或旧名称引用"
fi

if rg -n -i \
    -g '!.build/**' \
    -g '!.swiftpm/**' \
    -g '!dist/**' \
    '(AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|sk-[A-Za-z0-9_-]{16,}|gh[pousr]_[A-Za-z0-9]{20,}|glpat-[A-Za-z0-9_-]{20,}|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY)' .; then
    fail "发现疑似凭据或私钥"
fi

echo "✅ 公开发布检查通过"
