#!/bin/sh
set -euf

# usage: quick-ocaml-wine.sh [WINEPREFIX]
if [ "$#" -ge 1 ]; then
    cd "$1"
fi

[ -e system.reg ] || {
    echo "Error: system.reg not found. Please run this script from Wine prefix directory."
    exit 1
}

install -d drive_c/opt/ drive_c/src/

### OCAML

if [ ! -e drive_c/src/ocaml-5.4.1.tar.gz ]; then
    echo "Downloading OCaml 5.4.1 ..."
    curl -L -o drive_c/src/ocaml-5.4.1.tar.gz https://github.com/ocaml/ocaml/releases/download/5.4.1/ocaml-5.4.1.tar.gz
fi
if [ ! -e drive_c/src/flexdll-0.44.zip ]; then
    echo "Downloading flexdll 0.44 ..."
    curl -L -o drive_c/src/flexdll-0.44.zip https://github.com/ocaml/flexdll/archive/refs/tags/0.44.zip
fi

if [ ! -d drive_c/src/ocaml-5.4.1 ]; then
    echo "Extracting OCaml 5.4.1 ..."
    tar -xzf drive_c/src/ocaml-5.4.1.tar.gz -C drive_c/src/
fi

if [ ! -e drive_c/src/ocaml-5.4.1/flexdll/README.md ]; then
    echo "Extracting flexdll 0.44 ..."
    rm -rf drive_c/src/ocaml-5.4.1/flexdll
    unzip -q drive_c/src/flexdll-0.44.zip -d drive_c/src/ocaml-5.4.1
    mv drive_c/src/ocaml-5.4.1/flexdll-0.44 drive_c/src/ocaml-5.4.1/flexdll
fi

### W64DEVKIT

# https://github.com/skeeto/w64devkit/releases/download/v2.5.0/w64devkit-x64-2.5.0.7z.exe
if [ ! -e drive_c/opt/w64devkit-x64-2.5.0.7z.exe ]; then
    echo "Downloading w64devkit-x64-2.5.0.7z.exe ..."
    curl -L -o drive_c/opt/w64devkit-x64-2.5.0.7z.exe https://github.com/skeeto/w64devkit/releases/download/v2.5.0/w64devkit-x64-2.5.0.7z.exe
fi
if [ ! -d drive_c/opt/w64devkit ]; then
    echo "Extracting w64devkit-x64-2.5.0.7z.exe ..."
    7zr x -odrive_c/opt/ drive_c/opt/w64devkit-x64-2.5.0.7z.exe
fi

### BUILD

# shellcheck disable=SC2028 disable=SC2016
printf "%s\n" '
c:\opt\w64devkit\bin\sh -l
export PATH="C:/opt/w64devkit/bin:$PATH"
export WINEDEBUG=-kerberos
cd "C:/src/ocaml-5.4.1"
unset AWK # forget perm bit in NotInriaCaml_Std.Toolchain.LLVM_MinGW@5.4.1 on `get-object ... -e gawk.exe`
./configure --prefix=C:/opt/ocaml-5.4.1 --disable-ocamldoc --disable-ocamltest --disable-stdlib-manpages
make --trace AWK="C:/opt/w64devkit/bin/awk.exe" LN="cp -pf"
make --trace LN="cp -pf" install
'
