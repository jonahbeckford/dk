# Wine runtime library slots

## CommonsBase_Win32.Wine@11.2.0

### Problem

`Release.Darwin_arm64` does not work with Windows ARM64/ARM64EC ... it compiles
but does not run ... and unfortunately I (jonahbeckford@) am too novice to figure
out how to get it working.

### Mitigation

Since Wine on `Release.Darwin_arm64` will be compiled with `-arch x86_64`, we
need `Release.Darwin_x86_64` C libraries at runtime.
