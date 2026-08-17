#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# StudyLine Git Sparse-Checkout Helper Script (Cone Mode)
# Usage: ./sparse_clone.sh <repo_url> <target_dir> <domain_path>
# Example: ./sparse_clone.sh https://github.com/studyline/universe.git my-study domains/philosophy
# ==============================================================================

REPO_URL="${1:-https://github.com/studyline/universe.git}"
TARGET_DIR="${2:-knowledge-checkout}"
DOMAIN_PATH="${3:-domains/philosophy}"

echo "🚀 [StudyLine] Initializing partial clone (blobless) for: ${DOMAIN_PATH}"

# Step 1: Blobless clone (only fetches commit history and trees, no blobs)
git clone --filter=blob:none --no-checkout "${REPO_URL}" "${TARGET_DIR}"
cd "${TARGET_DIR}"

# Step 2: Initialize sparse-checkout in cone mode (O(1) pattern matching)
git sparse-checkout init --cone

# Step 3: Set sparse target paths (schemas, tools, and requested domain)
git sparse-checkout set schemas tools "${DOMAIN_PATH}"

# Step 4: Checkout HEAD
git checkout main

echo "✅ [StudyLine] Successfully checked out ${DOMAIN_PATH} (Zero clutter, lightweight)!"
echo "📁 Total size on disk: $(du -sh . | cut -f1)"
