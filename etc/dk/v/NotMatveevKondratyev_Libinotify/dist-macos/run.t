```cram
Distribution for NotMatveevKondratyev_Libinotify

--- Guidelines 2026.03.05 ---
1. Running one rule in a script module will bring in the entire script module.
.  But it is best to run every rule for lightweight testing during distribution.
2. Use ${CONFIG} for files in the cram test directory. Set by `dk0 test`.
3. Use ${RUNTIME}/<unique path> for -f and -d options since outputs are relative to the
.  current dir like `dk0 post-object` and `dk0 run`. Set unique to the cram
.  test by `dk0 test`. The `<unique path>` is to avoid race conditions on Windows where
.  Windows Defender (etc.) may not make a file visible or rewritable immediately after creation.

--- Objects and Assets ---

  $ get-object NotMatveevKondratyev_Libinotify.Kqueue@0.20240724.0 -s Release.Darwin_arm64 -f ${RUNTIME}/Darwin_arm64-Kqueue-0.20240724.0.zip
  $ get-object NotMatveevKondratyev_Libinotify.Kqueue@0.20240724.0 -s Release.Darwin_x86_64 -f ${RUNTIME}/Darwin_x86_64-Kqueue-0.20240724.0.zip

```
