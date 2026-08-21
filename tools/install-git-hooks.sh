#!/usr/bin/env bash
# ✦ Install Local-First Git Hooks for PR/Commit Gatekeeping
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}======================================================================${NC}"
echo -e "${CYAN}  ✦ Installing Local-First Git Hook Gatekeepers                       ${NC}"
echo -e "${CYAN}======================================================================${NC}"

chmod +x "$ROOT_DIR/.githooks/pre-commit" "$ROOT_DIR/.githooks/pre-push" "$ROOT_DIR/tools/ci-gatekeeper.sh" "$ROOT_DIR/tools/performance-floor-check.sh"
git config core.hooksPath .githooks

echo -e "${GREEN}✔ Successfully configured Git hooks path to .githooks/${NC}"
echo -e "  • ${BOLD}pre-commit${NC}: 运行快速门禁 (Stage 1~3, <2s)"
echo -e "  • ${BOLD}pre-push${NC}:   运行全量 5 阶工业级门禁 (Lint, Schema, DAG, Tests, Performance)"
echo ""
echo -e "${GREEN}✓ 100% 本地离线、零云端配额消耗、亚秒级质量拦截已就绪！${NC}"
