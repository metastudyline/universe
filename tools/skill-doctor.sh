#!/usr/bin/env bash

# Antigravity Skill Doctor CLI Wrapper
# Usage: ./tools/skill-doctor.sh [--check | --json]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_SCRIPT="${SCRIPT_DIR}/skill-doctor.js"

if command -v node >/dev/null 2>&1; then
    node "${NODE_SCRIPT}" "$@"
else
    echo "ERROR: Node.js runtime not found on PATH. Please install Node.js." >&2
    exit 1
fi
