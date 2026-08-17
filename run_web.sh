#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "======================================================"
echo "  ✦ StudyLine Universe & Rust Daemon 一键启动管线     "
echo "======================================================"

# 1. 编译并后台启动 Rust studyline-daemon
echo "[1/2] 🦀 编译并启动本地 Rust 桥接守护进程 (port 3001)..."
cd "$DIR/tools"
cargo build --release -p studyline-daemon
"$DIR/tools/target/release/studyline-daemon" --domains-dir "$DIR/domains" &
DAEMON_PID=$!

cleanup() {
    echo ""
    echo "[INFO] 🛑 正在停止 Rust 守护进程 (PID: $DAEMON_PID)..."
    kill $DAEMON_PID 2>/dev/null || true
    exit 0
}
trap cleanup SIGINT SIGTERM EXIT

sleep 1

# 2. 启动前端 Vite Dev Server
echo "[2/2] 🌐 启动前端宇宙画布 (http://localhost:3000)..."
cd "$DIR/packages/studyline-renderer"
npx vite demo --port 3000 --open
