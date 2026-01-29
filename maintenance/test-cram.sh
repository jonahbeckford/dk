#!/bin/sh

# Windows:
#   winget install dk
#   dk Ml.Use -- .\maintenance\test-cram.sh

set -euf

usage() {
    printf 'usage: maintenance/test-cram.sh [-w] [-a]\n'
    printf '  -w: watch mode\n'
    printf '  -a: auto promote\n'
    printf '  -S: no sandbox mode\n'
    printf '  -c: use dksdk-coder binary\n'
    printf '  -h: this help\n'
    exit 2
}
watch=0
autopromote=0
sandbox=1
use_coder=0
while getopts 'waShc' c
do
    case $c in
        w) watch=1 ;;
        a) autopromote=1 ;;
        S) sandbox=0 ;;
        c) use_coder=1 ;;
        h|?) usage
    esac
done
shift $((OPTIND-1))

extra=
if [ $watch -eq 1 ]; then extra="-w $extra"; fi
if [ $autopromote -eq 1 ]; then extra="--auto-promote $extra"; fi
if [ $sandbox -eq 0 ]; then extra="--sandbox=none $extra"; fi

cd "$(dirname "$0")/.."

opam show dune || opam install dune

# Clone dk source. First step in README.md.
rm -rf dksrc/
git clone --branch V2_5 https://github.com/diskuv/dk.git dksrc

# Make dk0 available in PATH
if [ $use_coder -eq 1 ]; then
    if [ -x ../dksdk-coder/_build/default/ext/MlFront/src/MlFront_Exec/Shell.exe ]; then
        echo "Using local build of dk0 from dksdk-coder" >&2
        install -d t/dk0exe
        rm -f t/dk0exe/dk0
        ln -s "$PWD/../dksdk-coder/_build/default/ext/MlFront/src/MlFront_Exec/Shell.exe" t/dk0exe/dk0
        export PATH="$PWD/t/dk0exe:$PATH"
    else
        echo "ERROR: Local build of dk0 requested but not found" >&2
        exit 1
    fi
else
    export PATH="$PWD/dksrc:$PATH"
fi

# Symlink etc/dk/v
rm -f tests/cram/etc
ln -s "$PWD/etc" tests/cram/etc

# Run cram tests using dune
#   shellcheck disable=SC2086
opam exec -- dune test --root tests/cram $extra
