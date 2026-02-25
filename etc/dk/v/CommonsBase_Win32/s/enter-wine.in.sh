#!/bin/sh
set -euf
HERE=$(dirname "$0")
HERE=$(cd "$HERE" && pwd)

usage() {
    echo "Usage: enter-wine.sh [--init] WINEPREFIX <Windows command> [args...]"
    echo "  --init: initialize the Wine prefix with 'wineboot --init'"
    exit 1
}

# Parse options
_init=false
while [ "$#" -gt 0 ]; do
    case "$1" in
        --init)
            _init=true
            shift
            ;;
        *)
            break
            ;;
    esac
done
if [ "$#" -lt 1 ]; then
    usage
fi
_wineprefix="$1"
shift

# Make absolute path WINEPREFIX. Create directory if it doesn't exist.
_wineprefix=$(install -d "$_wineprefix" && cd "$_wineprefix" && pwd)
export WINEPREFIX="$_wineprefix"

# Any shared libraries that are given to ./configure must be available at runtime
# using DYLD_FALLBACK_LIBRARY_PATH:
#   GNUTLS_LIBDIR: @GNUTLS_LIBDIR@
#   INOTIFY_LIBDIR: @INOTIFY_LIBDIR@
#   KRB5_LIBDIR: @KRB5_LIBDIR@
#
# If you want X11, the path for X11 libraries needs to be here as well.
# macOS X11: Confer https://gitlab.winehq.org/wine/wine/-/wikis/MacOS-FAQ#how-to-launch-wine-from-terminal-instead-of-the-wine-application
export DYLD_FALLBACK_LIBRARY_PATH='@GNUTLS_LIBDIR@:@INOTIFY_LIBDIR@:@KRB5_LIBDIR@:/usr/lib'

# Disable the Wine Mono installer popup.
# confer https://gitlab.winehq.org/wine/wine/-/wikis/Wine-User's-Guide#winedlloverrides-dll-overrides
export WINEDLLOVERRIDES=mscoree=

# --init: Initialize the Wine prefix
if [ "$_init" = true ]; then
    exec "$HERE/wineboot" --init
fi

# otherwise: execute Wine
exec "$HERE/wine" "$@"
