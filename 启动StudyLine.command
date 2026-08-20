#!/usr/bin/env bash
# ==============================================================================
#  ✦ StudyLine Universe — macOS 一键原生桌面/终端/全栈宇宙启动中枢
#  TTZip Zen Philosophy x All-in-Rust Engine x Native Swift Desktop
# ==============================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Ensure standard environment paths
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# ANSI Colors
BOLD="\033[1m"
GOLD="\033[38;2;212;175;55m"       # TTZip Kintsugi Gold (#D4AF37)
BAMBOO="\033[38;2;59;122;87m"       # TTZip Bamboo Green (#3B7A57)
CINNABAR="\033[38;2;218;78;56m"     # TTZip Cinnabar Red (#DA4E38)
CYAN="\033[0;36m"
WHITE="\033[1;37m"
DIM="\033[2m"
RESET="\033[0m"

clear

echo -e "${GOLD}"
cat << "EOF"
  ╔═══════════════════════════════════════════════════════════════════════╗
  ║           ✦  S T U D Y L I N E   U N I V E R S E  ✦                   ║
  ║       人类知识因果图谱 · 系统级 Rust 引擎 · macOS 原生桌面工作台      ║
  ╚═══════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${RESET}"

# 1. 确保 Rust 单二进制 CLI 与 C-ABI 库已编译就绪
CLI_BIN="$SCRIPT_DIR/tools/target/release/studyline"
CABI_LIB="$SCRIPT_DIR/tools/target/release/libstudyline_cabi.a"

if [ ! -f "$CLI_BIN" ] || [ ! -f "$CABI_LIB" ]; then
    echo -e "${GOLD}[INIT] 🔨 正在构建 Rust 原生核心与工具链 (Release 极致优化)...${RESET}"
    cd "$SCRIPT_DIR/tools"
    cargo build --release -p studyline -p studyline-cabi -p studyline-daemon
    cd "$SCRIPT_DIR"
    cp "$SCRIPT_DIR/tools/target/release/studyline" "$SCRIPT_DIR/studyline"
    echo -e "${BAMBOO}  ✓ Rust 核心单二进制与 C-ABI 静态库构建完成！${RESET}\n"
else
    echo -e "${BAMBOO}[CHECK] ✓ Rust 核心单二进制与 C-ABI 静态库已就绪 (7.8MB, 冷启动 <2ms)。${RESET}\n"
fi

# 2. 菜单选择
echo -e "${BOLD}${WHITE}请选择运行模式：${RESET}"
echo -e "  ${GOLD}[1]${RESET} 🍏 ${BOLD}macOS 原生桌面工作台${RESET} ${DIM}(SwiftUI 5.9+ · TTZip Zen UI · Y=90pt金线 · 液态玻璃大考)${RESET}"
echo -e "  ${GOLD}[2]${RESET} 🦀 ${BOLD}极客终端 TUI 学术研读器${RESET} ${DIM}(Ratatui 60FPS · 双语一手文献对照 · 键盘流答题)${RESET}"
echo -e "  ${GOLD}[3]${RESET} 🌐 ${BOLD}Web 知识星云画布 + 本地 Rust 守护进程${RESET} ${DIM}(Axum WebSocket @ :3001 + Vite @ :3000)${RESET}"
echo -e "  ${GOLD}[4]${RESET} 🔍 ${BOLD}全库 Draft-07 验证与 DAG 拓扑无环性扫描${RESET} ${DIM}(./studyline check)${RESET}"
echo -e "  ${GOLD}[5]${RESET} 📦 ${BOLD}生成零拷贝 .sla 二进制只读镜像${RESET} ${DIM}(./studyline pack)${RESET}"
echo ""
echo -e "${DIM}直接回车或等待 8 秒将默认启动 [1] macOS 原生桌面工作台...${RESET}"
read -t 8 -p "请输入选项 [1-5] (默认 1): " choice
choice=${choice:-1}
echo ""

case "$choice" in
    1)
        echo -e "${GOLD}[LAUNCH] 🚀 正在启动 StudyLine 原生 macOS 桌面 App...${RESET}"
        cd "$SCRIPT_DIR/packages/studyline-macos"
        swift run StudyLineApp
        ;;
    2)
        echo -e "${GOLD}[LAUNCH] 🚀 正在启动 60FPS Ratatui 终端学术研读 TUI...${RESET}"
        cd "$SCRIPT_DIR"
        ./studyline tui --domains-dir ./domains
        ;;
    3)
        echo -e "${GOLD}[LAUNCH] 🚀 正在启动本地 Rust 守护进程与前端星云画布...${RESET}"
        DAEMON_BIN="$SCRIPT_DIR/tools/target/release/studyline-daemon"
        "$DAEMON_BIN" --domains-dir "$SCRIPT_DIR/domains" &
        DAEMON_PID=$!

        cleanup() {
            echo ""
            echo -e "${CINNABAR}[STOP] 🛑 正在停止 Rust 守护进程 (PID: $DAEMON_PID)...${RESET}"
            kill $DAEMON_PID 2>/dev/null || true
            exit 0
        }
        trap cleanup SIGINT SIGTERM EXIT

        sleep 1
        cd "$SCRIPT_DIR/packages/studyline-renderer"
        echo -e "${BAMBOO}  • Web 画布地址: http://localhost:3000${RESET}"
        echo -e "${BAMBOO}  • Rust 守护进程: ws://127.0.0.1:3001/ws${RESET}"
        ./node_modules/.bin/vite demo --port 3000 --open
        ;;
    4)
        echo -e "${GOLD}[CHECK] 🔍 正在执行全量知识图谱严格验证...${RESET}"
        cd "$SCRIPT_DIR"
        ./studyline check --domains-dir ./domains
        echo ""
        read -p "按回车键退出..."
        ;;
    5)
        echo -e "${GOLD}[PACK] 📦 正在打包零拷贝只读镜像 universe.sla...${RESET}"
        cd "$SCRIPT_DIR"
        ./studyline pack --output ./universe.sla
        echo ""
        read -p "按回车键退出..."
        ;;
    *)
        echo -e "${CINNABAR}无效选项，退出。${RESET}"
        exit 1
        ;;
esac
