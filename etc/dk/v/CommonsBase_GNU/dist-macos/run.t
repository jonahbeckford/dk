```cram
Distribution for CommonsBase_GNU

--- Guidelines 2026.03.05 ---
1. Running one rule in a script module will bring in the entire script module.
.  But it is best to run every rule for lightweight testing during distribution.
2. Use ${CONFIG} for files in the cram test directory. Set by `dk0 test`.
3. Use ${RUNTIME}/<unique path> for -f and -d options since outputs are relative to the
.  current dir like `dk0 post-object` and `dk0 run`. Set unique to the cram
.  test by `dk0 test`. The `<unique path>` is to avoid race conditions on Windows where
.  Windows Defender (etc.) may not make a file visible or rewritable immediately after creation.

--- Objects and Assets ---

  $ get-object CommonsBase_GNU.Toolchain.W64dev@2.5.0 -s Release.Windows_x86 -f ${RUNTIME}/Windows_x86-Toolchain.W64dev-2.5.0.zip
  $ get-object CommonsBase_GNU.Toolchain.W64dev@2.5.0 -s Release.Windows_x86_64 -f ${RUNTIME}/Windows_x86_64-Toolchain.W64dev-2.5.0.zip

  $ get-object CommonsBase_GNU.Nettle@3.10.2 -s Release.Darwin_arm64 -f ${RUNTIME}/Darwin_arm64-Nettle-3.10.2.zip
  $ get-object CommonsBase_GNU.Nettle@3.10.2 -s Release.Darwin_x86_64 -f ${RUNTIME}/Darwin_x86_64-Nettle-3.10.2.zip

  $ get-object CommonsBase_GNU.GMP@6.3.0 -s Release.Darwin_arm64 -f ${RUNTIME}/Darwin_arm64-GMP-6.3.0.zip
  $ get-object CommonsBase_GNU.GMP@6.3.0 -s Release.Darwin_x86_64 -f ${RUNTIME}/Darwin_x86_64-GMP-6.3.0.zip

  $ get-object CommonsBase_GNU.TLS@3.8.12 -s Release.Darwin_arm64 -f ${RUNTIME}/Darwin_arm64-TLS-3.8.12.zip
  $ get-object CommonsBase_GNU.TLS@3.8.12 -s Release.Darwin_x86_64 -f ${RUNTIME}/Darwin_x86_64-TLS-3.8.12.zip

  $ get-object CommonsBase_GNU.Awk@5.3.1 -s Release.Darwin_arm64 -f ${RUNTIME}/Darwin_arm64-Awk-5.3.1.zip
  $ get-object CommonsBase_GNU.Awk@5.3.1 -s Release.Darwin_x86_64 -f ${RUNTIME}/Darwin_x86_64-Awk-5.3.1.zip

  $ get-object CommonsBase_GNU.Awk.Win32.LLVM_MinGW@5.3.1 -s Release.Darwin_x86_64.Windows_x86_64 -f ${RUNTIME}/Darwin_x86_64.Windows_x86_64-Awk.Win32.LLVM_MinGW-5.3.1.zip
  $ get-object CommonsBase_GNU.Awk.Win32.LLVM_MinGW@5.3.1 -s Release.Darwin_x86_64.Windows_x86 -f ${RUNTIME}/Darwin_x86_64.Windows_x86-Awk.Win32.LLVM_MinGW-5.3.1.zip
  $ get-object CommonsBase_GNU.Awk.Win32.LLVM_MinGW@5.3.1 -s Release.Darwin_x86_64.Windows_arm64 -f ${RUNTIME}/Darwin_x86_64.Windows_arm64-Awk.Win32.LLVM_MinGW-5.3.1.zip
  $ get-object CommonsBase_GNU.Awk.Win32.LLVM_MinGW@5.3.1 -s Release.Darwin_arm64.Windows_x86_64 -f ${RUNTIME}/Darwin_arm64.Windows_x86_64-Awk.Win32.LLVM_MinGW-5.3.1.zip
  $ get-object CommonsBase_GNU.Awk.Win32.LLVM_MinGW@5.3.1 -s Release.Darwin_arm64.Windows_x86 -f ${RUNTIME}/Darwin_arm64.Windows_x86-Awk.Win32.LLVM_MinGW-5.3.1.zip
  $ get-object CommonsBase_GNU.Awk.Win32.LLVM_MinGW@5.3.1 -s Release.Darwin_arm64.Windows_arm64 -f ${RUNTIME}/Darwin_arm64.Windows_arm64-Awk.Win32.LLVM_MinGW-5.3.1.zip

  $ get-object CommonsBase_GNU.Bison@3.8.2 -s Release.Darwin_arm64 -f ${RUNTIME}/Darwin_arm64-Bison-3.8.2.zip
  $ get-object CommonsBase_GNU.Bison@3.8.2 -s Release.Darwin_x86_64 -f ${RUNTIME}/Darwin_x86_64-Bison-3.8.2.zip

  $ get-object CommonsBase_GNU.Make@4.4.1 -s Release.Darwin_arm64 -f ${RUNTIME}/Darwin_arm64-Make-4.4.1.zip
  $ get-object CommonsBase_GNU.Make@4.4.1 -s Release.Darwin_x86_64 -f ${RUNTIME}/Darwin_x86_64-Make-4.4.1.zip

  $ get-object CommonsBase_GNU.Make.Win32.LLVM_MinGW@4.4.1 -s Release.Darwin_x86_64.Windows_x86_64 -f ${RUNTIME}/Darwin_x86_64.Windows_x86_64-Make.Win32.LLVM_MinGW-4.4.1.zip
  $ get-object CommonsBase_GNU.Make.Win32.LLVM_MinGW@4.4.1 -s Release.Darwin_x86_64.Windows_x86 -f ${RUNTIME}/Darwin_x86_64.Windows_x86-Make.Win32.LLVM_MinGW-4.4.1.zip
  $ get-object CommonsBase_GNU.Make.Win32.LLVM_MinGW@4.4.1 -s Release.Darwin_x86_64.Windows_arm64 -f ${RUNTIME}/Darwin_x86_64.Windows_arm64-Make.Win32.LLVM_MinGW-4.4.1.zip
  $ get-object CommonsBase_GNU.Make.Win32.LLVM_MinGW@4.4.1 -s Release.Darwin_arm64.Windows_x86_64 -f ${RUNTIME}/Darwin_arm64.Windows_x86_64-Make.Win32.LLVM_MinGW-4.4.1.zip
  $ get-object CommonsBase_GNU.Make.Win32.LLVM_MinGW@4.4.1 -s Release.Darwin_arm64.Windows_x86 -f ${RUNTIME}/Darwin_arm64.Windows_x86-Make.Win32.LLVM_MinGW-4.4.1.zip
  $ get-object CommonsBase_GNU.Make.Win32.LLVM_MinGW@4.4.1 -s Release.Darwin_arm64.Windows_arm64 -f ${RUNTIME}/Darwin_arm64.Windows_arm64-Make.Win32.LLVM_MinGW-4.4.1.zip

```
