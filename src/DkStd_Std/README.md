# DkStd_Std

The `Dk` library can be upgraded independent of the version of DkCoder
because it is a source code compile, and because `./dk` has a TTL-cache
based upgrade mechanism.

That also means that the `Dk` library must run in old versions of DkCoder.
<!-- SYNC: src/DkStd_Std/README.md, .vscode/settings.json, cmake/scripts/dkcoder/project/init.cmake -->
That old version is DkCoder 2.2, and `DkRun_V2_2` is hardcoded into
[cmake/scripts/dkcoder/project/init.cmake:dkcoder_project_init](../../cmake/scripts/dkcoder/project/init.cmake#dkcoder_project_init)
and (less important) in [.vscode/settings.json](../../.vscode/settings.json).

The unresolved difficulty is that `dk.sqlite3` metadata is not yet
backwards-compatible. Backwards-compatibility is required.
