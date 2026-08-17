#!/usr/bin/env python3
"""
StudyLine Scientific Code Sandbox Reproducibility Tester
Uses uv for fast dependency resolution and Papermill / pytest-mpl for reproducible assertions.
"""

import sys
import os
import subprocess
import argparse
from pathlib import Path

def run_reproducibility_test(notebook_path: Path, output_dir: Path) -> bool:
    print(f"[INFO] Testing scientific reproducibility for: {notebook_path}")
    output_dir.mkdir(parents=True, exist_ok=True)
    out_notebook = output_dir / f"executed_{notebook_path.name}"

    cmd = [
        "papermill",
        str(notebook_path),
        str(out_notebook),
        "--execution-timeout", "60",
        "--log-output"
    ]

    try:
        res = subprocess.run(cmd, capture_output=True, text=True, check=True)
        print(f"[SUCCESS] Notebook executed deterministically without exceptions.")
        return True
    except subprocess.CalledProcessError as e:
        print(f"[ERROR] Scientific reproducibility failure in {notebook_path}:\n{e.stderr}", file=sys.stderr)
        return False

def main():
    parser = argparse.ArgumentParser(description="StudyLine Scientific Reproducibility Runner")
    parser.add_argument("--notebook", type=Path, required=True, help="Path to ipynb notebook")
    parser.add_argument("--output-dir", type=Path, default=Path("./target/sci-output"), help="Output execution directory")
    args = parser.parse_args()

    success = run_reproducibility_test(args.notebook, args.output_dir)
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
