# patches

## gawk-mingw-llvm-5.3.1

MinGW LLVM uses `_popen` and `_pclose` (where `popen` and `pclose` may be macros).

But GAWK undefines `popen` and `pclose` so the patch uses `_popen` and `_pclose` directly.
