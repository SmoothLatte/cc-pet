#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

step() {
    echo
    echo "==> $1"
}

step "公开发布检查"
bash Scripts/verify-public.sh

step "Python 语法检查"
python3 -m py_compile Scripts/generate_lottie.py Scripts/generate_icon.py

step "Lottie 资源生成"
python3 Scripts/generate_lottie.py > /dev/null
for resource in awake sleeping thinking working celebrating error knocking; do
    test -s "CCPet/Resources/pet_${resource}.json"
done

step "Swift 编译"
swift build

step "Swift 测试"
swift test

step "动画说明检查"
for state in "休眠" "空闲" "思考中" "执行中" "完成" "出错" "等待确认"; do
    rg -q "$state" CCPet/UI/AboutView.swift
done

echo
echo "✅ verify 全绿"
