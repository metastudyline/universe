#!/usr/bin/env bash
# ==============================================================================
#  ✦ StudyLine Universe — macOS 一键构建、安装与原生启动器
#  Auto-Builds: Rust Unified CLI (`studyline`) + Native macOS App (`StudyLineApp`)
# ==============================================================================

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 补充标准 PATH
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# ANSI 色彩
BOLD="\033[1m"
GOLD="\033[38;2;212;175;55m"       # TTZip Kintsugi Gold (#D4AF37)
BAMBOO="\033[38;2;59;122;87m"       # TTZip Bamboo Green (#3B7A57)
CINNABAR="\033[38;2;218;78;56m"     # TTZip Cinnabar Red (#DA4E38)
WHITE="\033[1;37m"
DIM="\033[2m"
RESET="\033[0m"

clear

echo -e "${GOLD}"
cat << "EOF"
  ╔═══════════════════════════════════════════════════════════════════════╗
  ║           ✦  S T U D Y L I N E   U N I V E R S E  ✦                   ║
  ║     人类知识因果图谱 · 全栈 Rust 原生引擎 · macOS 原生桌面工作台      ║
  ╚═══════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${RESET}"

# 1. 自动构建与安装底层 Rust 原生工具链 (CLI & C-ABI 静态库)
CLI_BIN="$SCRIPT_DIR/studyline"
RUST_TARGET_CLI="$SCRIPT_DIR/tools/target/release/studyline"
RUST_CABI_LIB="$SCRIPT_DIR/tools/target/release/libstudyline_cabi.a"

if [ ! -f "$CLI_BIN" ] || [ ! -f "$RUST_CABI_LIB" ] || [ "$1" == "--rebuild" ]; then
    echo -e "${GOLD}[1/3] 🦀 正在构建 Rust 核心引擎与 C-ABI (Release 极致优化)...${RESET}"
    cd "$SCRIPT_DIR/tools"
    cargo build --release -p studyline -p studyline-cabi -p studyline-daemon
    cd "$SCRIPT_DIR"
    cp "$RUST_TARGET_CLI" "$CLI_BIN"
    chmod +x "$CLI_BIN"
    echo -e "${BAMBOO}  ✓ Rust 底层 CLI 安装完成: ${CLI_BIN} (7.8MB)${RESET}\n"
else
    echo -e "${BAMBOO}[1/3] ✓ Rust 底层 CLI 与 C-ABI 静态库已就绪。${RESET}"
fi

# 2. 自动构建与安装 macOS 原生桌面应用程序 (StudyLineApp)
APP_BIN="$SCRIPT_DIR/packages/studyline-macos/.build/release/StudyLineApp"

if [ ! -f "$APP_BIN" ] || [ "$1" == "--rebuild" ]; then
    echo -e "${GOLD}[2/3] 🍏 正在构建与安装 macOS 原生桌面工作台 (Release 编译)...${RESET}"
    cd "$SCRIPT_DIR/packages/studyline-macos"
    # 防跨路径缓存污染清理
    rm -rf .build/arm64-apple-macosx/debug/ModuleCache 2>/dev/null || true
    swift build -c release || (rm -rf .build && swift build -c release)
    cd "$SCRIPT_DIR"
    echo -e "${BAMBOO}  ✓ macOS 原生桌面 App 安装完成: ${APP_BIN}${RESET}\n"
else
    echo -e "${BAMBOO}[2/3] ✓ macOS 原生桌面 App 已就绪。${RESET}"
fi

# 3. 运行模式选择与自动拉起
echo -e "\n${BOLD}${WHITE}请选择运行模式：${RESET}"
echo -e "  ${GOLD}[1]${RESET} 🍏 ${BOLD}启动 macOS 原生桌面工作台${RESET} ${DIM}(SwiftUI · TTZip Zen UI · Y=90pt金线 · 640x520pt 液态玻璃大考)${RESET}"
echo -e "  ${GOLD}[2]${RESET} 🦀 ${BOLD}启动 60FPS 终端 TUI 学术研读器${RESET} ${DIM}(Ratatui 终端三栏 · 双语一手原典 · 键盘流答题)${RESET}"
echo -e "  ${GOLD}[3]${RESET} 🌐 ${BOLD}启动 Web 星云画布 + 本地 Rust 守护进程${RESET} ${DIM}(Axum WebSocket @ :3001 + Vite @ :3000)${RESET}"
echo -e "  ${GOLD}[4]${RESET} 🔍 ${BOLD}执行全库 Draft-07 严格体检与 DAG 拓扑无环性扫描${RESET} ${DIM}(./studyline check)${RESET}"
echo -e "  ${GOLD}[5]${RESET} 📦 ${BOLD}重新打包零拷贝 .sla 二进制只读镜像${RESET} ${DIM}(./studyline pack)${RESET}"
echo -e "  ${GOLD}[6]${RESET} 🔨 ${BOLD}全量强制重新编译 (Rebuild All)${RESET}"
echo ""
echo -e "${DIM}直接按回车或等待 6 秒将默认启动 [1] macOS 原生桌面工作台...${RESET}"
read -t 6 -p "请输入选项 [1-6] (默认 1): " choice || choice=1
choice=${choice:-1}
echo ""

case "$choice" in
    1)
        echo -e "${GOLD}[LAUNCH] 🚀 正在启动 StudyLine 原生桌面工作台...${RESET}"
        "$APP_BIN"
        ;;
    2)
        echo -e "${GOLD}[LAUNCH] 🚀 正在启动 60FPS Ratatui 终端学术研读 TUI...${RESET}"
        "$CLI_BIN" tui --domains-dir "$SCRIPT_DIR/domains"
        ;;
    3)
        echo -e "${GOLD}[LAUNCH] 🚀 正在拉起本地 Rust 桥接守护进程与 Web 星云画布...${RESET}"
        DAEMON_BIN="$SCRIPT_DIR/tools/target/release/studyline-daemon"
        "$DAEMON_BIN" --domains-dir "$SCRIPT_DIR/domains" &
        DAEMON_PID=$!

        cleanup() {
            echo ""
            echo -e "${CINNABAR}[STOP] 🛑 正在安全停止 Rust 守护进程 (PID: $DAEMON_PID)...${RESET}"
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
        echo -e "${GOLD}[CHECK] 🔍 正在执行全量知识图谱严格体检...${RESET}"
        "$CLI_BIN" check --domains-dir "$SCRIPT_DIR/domains"
        echo ""
        read -p "体检完成，按回车键退出..."
        ;;
    5)
        echo -e "${GOLD}[PACK] 📦 正在打包零拷贝只读镜像 universe.sla...${RESET}"
        "$CLI_BIN" pack --output "$SCRIPT_DIR/universe.sla"
        echo ""
        read -p "打包完成，按回车键退出..."
        ;;
    6)
        echo -e "${GOLD}[REBUILD] 🔨 正在全量清理并重新构建...${RESET}"
        exec "$0" --rebuild
        ;;
    *)
        echo -e "${CINNABAR}无效选项，退出。${RESET}"
        exit 1
        ;;
esac
