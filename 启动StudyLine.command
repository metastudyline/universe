#!/usr/bin/env bash
# ==============================================================================
#  ✦ StudyLine Universe — macOS 一键原生双击启动器 (Rust Daemon + Web Canvas)
# ==============================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Ensure standard environment paths (Homebrew, fnm, nvm, cargo)
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# Colors
BOLD="\033[1m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
RED="\033[0;31m"
RESET="\033[0m"

echo -e "${BOLD}${CYAN}"
echo "  ╔═══════════════════════════════════════════════════════════════════╗"
echo "  ║            ✦ StudyLine Universe 全栈知识宇宙启动器                ║"
echo "  ║        High-Performance Rust Daemon + 60FPS Cosmic Canvas         ║"
echo "  ╚═══════════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

# 1. 检查 Rust 编译产物
DAEMON_BIN="$SCRIPT_DIR/tools/target/release/studyline-daemon"
if [ ! -f "$DAEMON_BIN" ]; then
    echo -e "${YELLOW}[1/3] 🔨 首次运行，正在编译 Rust 高性能图引擎与守护进程...${RESET}"
    cd "$SCRIPT_DIR/tools"
    cargo build --release -p studyline-daemon
    cd "$SCRIPT_DIR"
    echo -e "${GREEN}  ✓ Rust 核心守护进程编译完成！${RESET}\n"
else
    echo -e "${GREEN}[1/3] ✓ Rust 核心守护进程已就绪。${RESET}"
fi

# 2. 后台拉起 Rust studyline-daemon
echo -e "${BLUE}[2/3] 🦀 正在启动本地 Rust 桥接守护进程 (WebSocket /ws @ :3001)...${RESET}"
DOMAINS_DIR="$SCRIPT_DIR/domains"
if [ ! -d "$DOMAINS_DIR" ]; then
    DOMAINS_DIR="$SCRIPT_DIR/../domain-philosophy"
fi

"$DAEMON_BIN" --domains-dir "$DOMAINS_DIR" &
DAEMON_PID=$!

cleanup() {
    echo ""
    echo -e "${YELLOW}[INFO] 🛑 正在退出并释放 Rust 守护进程 (PID: $DAEMON_PID)...${RESET}"
    kill $DAEMON_PID 2>/dev/null || true
    exit 0
}
trap cleanup SIGINT SIGTERM EXIT

sleep 1

# 3. 检查前端依赖并启动 Web 服务
echo -e "${BLUE}[3/3] 🌐 正在启动前端星云画布 (http://localhost:3000)...${RESET}"
cd "$SCRIPT_DIR/packages/studyline-renderer"

if [ ! -d "node_modules" ] || [ ! -f "node_modules/.bin/vite" ]; then
    echo -e "${YELLOW}[INFO] 📦 正在自愈安装前端依赖 (npm install)...${RESET}"
    npm install
fi

echo -e "${GREEN}======================================================================${RESET}"
echo -e "${BOLD}  🚀 StudyLine Universe 已成功启动！${RESET}"
echo -e "  • 网页画布地址: ${CYAN}http://localhost:3000${RESET}"
echo -e "  • Rust 桥接端口: ${CYAN}ws://127.0.0.1:3001/ws${RESET}"
echo -e "  • 本地文件监听: ${CYAN}${DOMAINS_DIR}${RESET} (50ms 防抖实时热重载)"
echo -e "  💡 提示: 按下 ${BOLD}Ctrl + C${RESET} 即可安全停止所有服务。"
echo -e "${GREEN}======================================================================${RESET}\n"

# 优先使用本地 vite 二进制启动，若失败则回退到 npm run dev
if [ -f "./node_modules/.bin/vite" ]; then
    ./node_modules/.bin/vite demo --port 3000 --open
elif command -v npm &> /dev/null; then
    npm run dev
else
    # 终极无依赖 Fallback (Python3 原生静态服务)
    echo -e "${YELLOW}[FALLBACK] 正在使用 Python3 静态服务器拉起...${RESET}"
    open "http://localhost:3000/demo/index.html"
    python3 -m http.server 3000
fi
