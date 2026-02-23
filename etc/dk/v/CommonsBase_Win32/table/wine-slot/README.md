# Wine runtime library slots

## CommonsBase_Win32.Wine@11.2.0

### Problem

`Release.Darwin_arm64` does not work with Windows ARM64/ARM64EC ... it compiles
but does not run ... and unfortunately I (jonahbeckford@) am too novice to figure
out how to get it working.

### Mitigation (deprecated)

For now `Release.Darwin_arm64` is hardcoded in Wine.values.jsonc to use Rosetta2
emulation (which is not always present).

Alternatively we could have redefined `Release.Darwin_arm64` to resolve to
`Release.Darwin_x86_64` by changing the lookup in this directory. We tried that
but got the following errors:

1. (Benefit - more hermetic builds) Local machine packages (ex. Homebrew) won't link
   because `arch -x86_64 ld` will fail to find the right architecture.
2. We get NULL pointer failures of downstream packages like OCaml bytecode interpreter
   (perhaps because wrong macOS System packages linked into Wine, and boundary
   between Windows code and Linux code is messing the ntdll return codes?).
