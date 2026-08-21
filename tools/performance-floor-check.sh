#!/usr/bin/env bash
# ✦ StudyLine & NoteBoot Deterministic Performance Floor Gate
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}======================================================================${NC}"
echo -e "${CYAN}  ✦ STAGE 5: Deterministic Performance Floor Hard Gatekeeper          ${NC}"
echo -e "${CYAN}======================================================================${NC}"

# Threshold Definitions (Process End-to-End Hard Gates)
DAG_BUILD_THRESHOLD_MS=50.0
NOTEBOOT_INDEX_THRESHOLD_MS=60.0
SQL_QUERY_THRESHOLD_MS=40.0

echo -e "  • Threshold: Global DAG Building (CLI)   < ${DAG_BUILD_THRESHOLD_MS} ms"
echo -e "  • Threshold: NoteBoot Vault Sync (CLI)   < ${NOTEBOOT_INDEX_THRESHOLD_MS} ms"
echo -e "  • Threshold: Bento SQLite Point Query    < ${SQL_QUERY_THRESHOLD_MS} ms"
echo ""

# Setup clean benchmark sandbox vault
BENCH_VAULT="/tmp/noteboot_bench_vault_$$"
rm -rf "$BENCH_VAULT"
mkdir -p "$BENCH_VAULT/01-Inbox" "$BENCH_VAULT/02-Concepts" "$BENCH_VAULT/03-Projects"
"$ROOT_DIR/noteboot" init "$BENCH_VAULT" > /dev/null 2>&1

# Seed 20 structured benchmark markdown documents
for i in {1..20}; do
    cat <<EOF > "$BENCH_VAULT/02-Concepts/doc_$i.md"
---
title: 性能基准测试笔记 $i
status: active
priority: P1
tags: [rust, performance, benchmark]
---

# 性能基准测试节点 $i

这是由自动化性能门禁生成的标准测试节点，包含指向 [[02-Concepts/doc_1.md#^anchor-1]] 的双向引用。

^anchor-$i
EOF
done

# 1. Measure NoteBoot Vault Sync Latency
START_TIME=$(python3 -c 'import time; print(int(time.time_ns()))')
"$ROOT_DIR/noteboot" sync "$BENCH_VAULT" > /dev/null 2>&1
END_TIME=$(python3 -c 'import time; print(int(time.time_ns()))')
DURATION_MS=$(python3 -c "print(round(($END_TIME - $START_TIME) / 1000000.0, 2))")

echo -n "  [1/3] Benchmarking NoteBoot Vault Sync (20 docs)... "
if (( $(python3 -c "print(1 if $DURATION_MS <= $NOTEBOOT_INDEX_THRESHOLD_MS else 0)") )); then
    echo -e "${GREEN}PASSED (${DURATION_MS} ms)${NC}"
else
    echo -e "${RED}FAILED: ${DURATION_MS} ms exceeded ${NOTEBOOT_INDEX_THRESHOLD_MS} ms${NC}"
    rm -rf "$BENCH_VAULT"
    exit 1
fi

# 2. Measure SQLite Point Query Latency
START_TIME_Q=$(python3 -c 'import time; print(int(time.time_ns()))')
"$ROOT_DIR/noteboot" query "SELECT vault, path, title, status FROM v_tasks LIMIT 5" "$BENCH_VAULT" > /dev/null 2>&1
END_TIME_Q=$(python3 -c 'import time; print(int(time.time_ns()))')
DURATION_Q_MS=$(python3 -c "print(round(($END_TIME_Q - $START_TIME_Q) / 1000000.0, 2))")

echo -n "  [2/3] Benchmarking Bento SQLite View Point Query... "
if (( $(python3 -c "print(1 if $DURATION_Q_MS <= $SQL_QUERY_THRESHOLD_MS else 0)") )); then
    echo -e "${GREEN}PASSED (${DURATION_Q_MS} ms)${NC}"
else
    echo -e "${RED}FAILED: ${DURATION_Q_MS} ms exceeded ${SQL_QUERY_THRESHOLD_MS} ms${NC}"
    rm -rf "$BENCH_VAULT"
    exit 1
fi

rm -rf "$BENCH_VAULT"

# 3. Measure StudyLine DAG Check Latency
START_TIME_D=$(python3 -c 'import time; print(int(time.time_ns()))')
target/release/studyline-compiler check --schemas-dir "$ROOT_DIR/schemas" --domains-dir "$ROOT_DIR/domains" --strict > /dev/null 2>&1 || true
END_TIME_D=$(python3 -c 'import time; print(int(time.time_ns()))')
DURATION_DAG_MS=$(python3 -c "print(round(($END_TIME_D - $START_TIME_D) / 1000000.0, 2))")

echo -n "  [3/3] Benchmarking StudyLine DAG & Schema Verification... "
if (( $(python3 -c "print(1 if $DURATION_DAG_MS <= $DAG_BUILD_THRESHOLD_MS else 0)") )); then
    echo -e "${GREEN}PASSED (${DURATION_DAG_MS} ms)${NC}"
else
    echo -e "${RED}FAILED: ${DURATION_DAG_MS} ms exceeded ${DAG_BUILD_THRESHOLD_MS} ms${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✓ STAGE 5 PASSED: All operations strictly adhere to Performance Floor.${NC}"
