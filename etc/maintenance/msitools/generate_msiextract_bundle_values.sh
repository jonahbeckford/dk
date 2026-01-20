#!/bin/sh
set -euf

# Regenerates:
#   ext/dk/etc/dk/v/CommonsBase_Std/Msitools.Msiextract.Bundle.values.jsonc
#
# Usage:
#   ext/dk/etc/maintenance/msitools/generate_msiextract_bundle_values.sh 0.106.0
#
# Optional env vars:
#   DK_GHCR_AUTHORIZATION='Bearer QQ=='
#   DK_GHCR_CURL=/usr/bin/curl

version=${1:-}
if [ -z "$version" ]; then
  echo "usage: $0 <VERSION>" >&2
  exit 64
fi

cd "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"/../../..

python3 etc/maintenance/msitools/generate_msiextract_bundle_values.py \
  --version "$version" \
  --out etc/dk/v/CommonsBase_Std/Msitools.Msiextract.Bundle.values.jsonc
