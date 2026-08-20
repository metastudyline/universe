#!/usr/bin/env bash
# ==============================================================================
# Installs StudyLine Local Git Hooks to enforce local-first CI/CD
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "Configuring local git hooks path..."
cd "${ROOT_DIR}"
git config core.hooksPath .githooks
chmod +x "${ROOT_DIR}/.githooks/pre-commit" || true
chmod +x "${ROOT_DIR}/tools/scripts/local_ci.sh" || true

echo "✓ Local Git hooks installed successfully. All commits will be verified locally in <1 second!"
