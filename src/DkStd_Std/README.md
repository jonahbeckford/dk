# DkStd_Std

The `Dk` library can be upgraded independent of the version of DkCoder
because it is a source code compile, and because `./dk` has a TTL-cache
based upgrade mechanism.

That also means that the `Dk` library must run in old versions of DkCoder.
That old version is DkCoder 2.2, and is hardcoded into
[cmake/scripts/dkcoder/project/init.cmake:dkcoder_project_init](../../cmake/scripts/dkcoder/project/init.cmake#dkcoder_project_init)

The unresolved difficulty is that `dk.sqlite3` metadata is not yet
backwards-compatible. Backwards-compatibility is required.
