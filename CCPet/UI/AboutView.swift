import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Text("🐷")
                        .font(.system(size: 36))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("cc-pet")
                            .font(.system(size: 20, weight: .bold))
                        Text("v1.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("陪你写代码的桌面萌宠")
                        .font(.body.weight(.medium))
                    Text("监听 Claude Code 钩子事件,用动画和通知反馈会话状态。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 8) {
                    sectionHeader("动画含义")
                    stateRow(emoji: "💤", name: "休眠",
                             desc: "闭眼缓慢呼吸 · 会话结束或暂无活动")
                    stateRow(emoji: "👀", name: "空闲",
                             desc: "一开一眨眼,轻轻弹跳 · 会话开始 / 工具执行完成,等待下一步")
                    stateRow(emoji: "💭", name: "思考中",
                             desc: "头部倾斜 + 三个思考气泡由小到大升起 · 你提交了新指令,Claude 正在思考")
                    stateRow(emoji: "🛠", name: "执行中",
                             desc: "头顶锤子哐哐双击 + 撞击星花闪现 + 身体随击打震压 · 正在调用工具")
                    stateRow(emoji: "🎉", name: "完成",
                             desc: "高高跳起 + 12 颗彩色星星与五彩纸屑散开 · 任务完成(Stop 事件)")
                    stateRow(emoji: "⚠️", name: "出错",
                             desc: "X 眼睛 + 汗水滴落 · 工具调用失败")
                    stateRow(emoji: "❗️", name: "等待确认",
                             desc: "瞪大眼睛 + 感叹号闪烁 · 工具需要授权(预留)")
                }

                VStack(alignment: .leading, spacing: 6) {
                    sectionHeader("功能")
                    bullet("任务完成、出错、会话结束时系统通知")
                    bullet("多会话管理,面板中可切换查看不同项目")
                    bullet("拖拽到屏幕任意位置,下次启动恢复")
                    bullet("一键安装 Claude Code Hook,免手动配置")
                }

                VStack(alignment: .leading, spacing: 6) {
                    sectionHeader("使用")
                    step(1, "在「设置」面板点击「安装 Hook」")
                    step(2, "启动 Claude Code,宠物会随会话状态变化")
                    step(3, "单击宠物展开会话信息面板")
                }
            }
            .padding(16)
        }
        .frame(width: 400, height: 540)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.accentColor)
                .frame(width: 3, height: 10)
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
        }
    }

    private func stateRow(emoji: String, name: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(emoji)
                .font(.system(size: 16))
                .frame(width: 22, alignment: .center)
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.caption.weight(.semibold))
                Text(desc)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•").foregroundColor(.secondary)
            Text(text)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func step(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("\(n).").foregroundColor(.secondary).font(.caption.weight(.semibold))
            Text(text)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
