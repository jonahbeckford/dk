#!/bin/sh
set -euf

# ------------------------------------------------------------------------------
# Script: generate_msvc_values.sh
# Purpose: Generates the MSVC.Bundle.values.jsonc file for DkSDK Coder.
# Usage:
#   ./generate_msvc_values.sh <MSVC_VERSION> <COMPONENT_ID_1> [COMPONENT_ID_2] ...
#
# Example:
#   ./generate_msvc_values.sh 14.38.17.8 \
#     Microsoft.VisualStudio.Workload.VCTools \
#     Microsoft.VisualStudio.Component.VC.14.38.17.8.x86.x64
# ------------------------------------------------------------------------------

# 1. Parse Arguments
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <MSVC_VERSION> <COMPONENT_ID_1> [COMPONENT_ID_2] ..."
    echo "Example: $0 14.38.17.8 Microsoft.VisualStudio.Workload.VCTools Microsoft.VisualStudio.Component.VC.14.38.17.8.x86.x64"
    exit 1
fi

MSVC_VERSION="$1"
shift
COMPONENTS_ARGS=""
for comp in "$@"; do
    COMPONENTS_ARGS="$COMPONENTS_ARGS --component $comp"
done

# Paths
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
VSDOWNLOAD_PY="$SCRIPT_DIR/vsdownload.py"
GENERATOR_PY="$SCRIPT_DIR/generate_msvc_config.py"
OUTPUT_FILE="$PROJECT_ROOT/etc/dk/v/CommonsBase_VisualStudio/MSVC.Bundle.values.jsonc"
TEMP_DIR="$PROJECT_ROOT/build/tmp"
MANIFEST_FILE="$TEMP_DIR/manifest.json"

# Ensure cleanup of temp if needed, but we use persistent build/tmp
# trap 'rm -rf "$TEMP_DIR"' EXIT

echo "--> Setup: Using vsdownload.py from $VSDOWNLOAD_PY"
echo "--> Generating MSVC package for version $MSVC_VERSION"
echo "    Components args: $COMPONENTS_ARGS"
echo "    Temp Dir:   $TEMP_DIR"

mkdir -p "$TEMP_DIR"

# 2. Fetch Manifest
if [ ! -f "$MANIFEST_FILE" ]; then
    echo "--> Step 1/2: Downloading manifest..."
    # We rely on vsdownload.py to fetch the manifest.
    # --save-manifest saves '<VERSION>.manifest' to the current directory.
    # We run in TEMP_DIR to capture it.
    (
        cd "$TEMP_DIR"
        python3 "$VSDOWNLOAD_PY" \
            --dest "$TEMP_DIR" \
            --save-manifest \
            --only-download \
            --accept-license \
            --ignore "Microsoft.VisualStudio.Workload.VCTools" \
            "Microsoft.VisualStudio.Workload.VCTools" || true
        
        # Rename the downloaded manifest to manifest.json
        # Find the most recent .manifest file
        LATEST_MANIFEST=$(find . -maxdepth 1 -name "*.manifest" | head -n 1)
        if [ -n "$LATEST_MANIFEST" ]; then
            mv "$LATEST_MANIFEST" manifest.json
        fi
    )
    
    # Check if manifest.json exists now
    if [ ! -f "$MANIFEST_FILE" ]; then
        echo "Error: manifest.json was not downloaded to $TEMP_DIR"
        exit 1
    fi
else
    echo "--> Step 1/2: Using existing manifest at $MANIFEST_FILE"
fi

# 3. Generate JSONC
echo "--> Step 2/2: Generating values.jsonc..."

python3 "$GENERATOR_PY" \
    --manifest "$MANIFEST_FILE" \
    --msvc-version "$MSVC_VERSION" \
    $COMPONENTS_ARGS \
    --output "$OUTPUT_FILE"

echo "Success! Generated $OUTPUT_FILE"
