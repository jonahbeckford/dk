#!/usr/bin/env bash
# Simple wrapper around the Python verifier
set -euo pipefail

PY=${PY:-python3}
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
"$PY" "$SCRIPT_DIR/verify_all_assets.py" "$@"
