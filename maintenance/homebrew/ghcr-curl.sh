#!/bin/sh
set -euf

# Wrap curl so dk0 can download GHCR bottle blobs.
# Usage:
#   DKMLSYS_CURL=$PWD/ext/dk/maintenance/homebrew/ghcr-curl.sh \
#   DK_GHCR_AUTHORIZATION='Bearer QQ==' \
#   ext/dk/dk0 ... get-asset ...

real_curl=${DK_GHCR_REAL_CURL:-/usr/bin/curl}
auth=${DK_GHCR_AUTHORIZATION:-}

if [ -z "$auth" ]; then
  exec "$real_curl" "$@"
else
  exec "$real_curl" -H "Authorization: $auth" "$@"
fi
