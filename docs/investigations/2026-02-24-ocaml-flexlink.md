# Investigation notes

Repeat failure with:

```sh
C:/src/ocaml-5.4.1 $ make --trace AWK="C:/opt/w64devkit/bin/awk.exe"
C:/src/ocaml-5.4.1 $ winepath .
```

```text
...
Building flexlink.exe with TOOLCHAIN=mingw for OCaml 5.4.1
rm -f flexlink.exe
../runtime/ocamlrun.exe ../ocamlopt.exe -nostdlib -I ../stdlib -o flexlink.exe -cclib "-link version_res.o" version.ml Compat.ml coff.ml cmdline.ml create_dll.ml reloc.ml
** Error: Sys_error("../stdlib\\libasmrun.a: Invalid argument")
File "caml_startup", line 1:
Error: Error during linking (exit code 2)
make[3]: *** [Makefile:183: flexlink.exe] Error 2
make[3]: Leaving directory 'C:/src/ocaml-5.4.1/flexdll'
make[2]: *** [Makefile:884: flexlink.opt.exe] Error 2
make[2]: Leaving directory 'C:/src/ocaml-5.4.1'
make[1]: *** [Makefile:775: opt.opt] Error 2
make[1]: Leaving directory 'C:/src/ocaml-5.4.1'
make: *** [Makefile:853: world.opt] Error 2
```

Adding `--trace`:

```text
Makefile:883: update target 'flexlink.opt.exe' due to: target does not exist
rm -f flexdll/flexlink.exe
make -C flexdll MSVCC_ROOT= MSVC_DETECT=0 OCAML_CONFIG_FILE=../Makefile.config CHAINS=mingw64 ROOTDIR=.. \
  OCAMLOPT='../runtime/ocamlrun.exe ../ocamlopt.exe -nostdlib -I ../stdlib' flexlink.exe
make[3]: Entering directory 'C:/src/ocaml-5.4.1/flexdll'
```

Execute directly the submake with `--trace`:

```sh
C:/src/ocaml-5.4.1 $ make --trace -C flexdll MSVCC_ROOT= MSVC_DETECT=0 OCAML_CONFIG_FILE=../Makefile.config CHAINS=mingw64 ROOTDIR=.. OCAMLOPT='../runtime/ocamlrun.exe ../ocamlopt.exe -nostdlib -I ../stdlib' flexlink.exe
```

That gives a different error:

```text
Makefile:181: update target 'flexlink.exe' due to: target does not exist
echo Building flexlink.exe with TOOLCHAIN=mingw for OCaml 5.4.1
Building flexlink.exe with TOOLCHAIN=mingw for OCaml 5.4.1
rm -f flexlink.exe
../runtime/ocamlrun.exe ../ocamlopt.exe -nostdlib -I ../stdlib -o flexlink.exe -cclib "-link version_res.o" version.ml Compat.ml coff.ml cmdline.ml create_dll.ml reloc.ml
0760:fixme:thread:get_thread_times not implemented on this platform
0470:fixme:file:GetTempPath2W (261, 000000000211F9C0) semi-stub
Can't recognize 'flexlink -exe -chain mingw64 -stack 33554432 -link -municode   -o "flexlink.exe"  "-L../stdlib"  "C:\users\jonah\AppData\Local\Temp\camlstartup520005.o" "../stdlib\std_exit.o" "reloc.o" "create_dll.o" "cmdline.o" "coff.o" "Compat.o" "version.o" "../stdlib\stdlib.a" "-link" "version_res.o" "../stdlib\libasmrun.a"   -lws2_32 -lole32 -luuid -lversion -lshlwapi -lsynchronization   -l:libpthread.a ' as an internal or external command, or batch script.
File "caml_startup", line 1:
Error: Error during linking (exit code 1)
make: *** [Makefile:183: flexlink.exe] Error 2
make: Leaving directory 'C:/src/ocaml-5.4.1/flexdll'
```

We know "as an internal or external command, or batch script." means the Windows `cmd.exe` interpreter is trying to find the executable/batch script but can't.

So it seems like `flexlink -exe -chain ...` is being interpreted as a single Windows command, and can't find it.

A: The primary question is how does our initial attempt pass the location of flexlink so the above immediate error does not occur?

B: The secondary possibly irrelevant question is why is the flexlink command not being split?

Digging into `A` by adding `env > flexlink-env.txt` to `Makefile:883` (before `rm -f $(FLEXDLL_SOURCE_DIR)/flexlink.exe`) shows:

```text
PATH=C:/src/ocaml-5.4.1/opt/bin;C:/src/ocaml-5.4.1/byte/bin;C:/src/ocaml-5.4.1/opt/bin;C:/src/ocaml-5.4.1/byte/bin;C:/src/ocaml-5.4.1/opt/bin;C:/src/ocaml-5.4.1/byte/bin;C:/opt/w64devkit/bin;C:/windows/system32;C:/windows;C:/windows/system32/wbem;C:/windows/system32/WindowsPowershell/v1.0;C:/src/NotInriaCaml_Std/Toolchain__LLVM/5.4.1/bin;C:/opt/make/bin;C:/opt/awk/bin;C:/opt/llvm-mingw/bin;C:/opt/coreutils
```

where:

```sh
C:/src/ocaml-5.4.1 $ ls opt/bin
C:/src/ocaml-5.4.1 $ ls byte/bin
flexlink.exe
```

So we just need to add `byte/bin` to that PATH.

Okay, start again by adding `byte/bin` back at the step "Execute directly the submake with `--trace`":

```sh
C:/src/ocaml-5.4.1 $ env "PATH=$PWD/byte/bin;$PATH" make --trace -C flexdll MSVCC_ROOT= MSVC_DETECT=0 OCAML_CONFIG_FILE=../Makefile.config CHAINS=mingw64 ROOTDIR=.. OCAMLOPT='../runtime/ocamlrun.exe ../ocamlopt.exe -nostdlib -I ../stdlib' flexlink.exe
...
Makefile:181: update target 'flexlink.exe' due to: target does not exist
echo Building flexlink.exe with TOOLCHAIN=mingw for OCaml 5.4.1
Building flexlink.exe with TOOLCHAIN=mingw for OCaml 5.4.1
rm -f flexlink.exe
../runtime/ocamlrun.exe ../ocamlopt.exe -nostdlib -I ../stdlib -o flexlink.exe -cclib "-link version_res.o" version.ml Compat.ml coff.ml cmdline.ml create_dll.ml reloc.ml
** Error: Sys_error("../stdlib\\libasmrun.a: Invalid argument")
File "caml_startup", line 1:
Error: Error during linking (exit code 2)
make: *** [Makefile:183: flexlink.exe] Error 2
make: Leaving directory 'C:/src/ocaml-5.4.1/flexdll'
```

We now recreated the original error, but are executing much closer to the root cause:

```makefile
# file: flexdll/Makefile
# line: 180-183
flexlink.exe: $(OBJS) $(RES)
  @echo Building flexlink.exe with TOOLCHAIN=$(TOOLCHAIN) for OCaml $(OCAML_VERSION)
  rm -f $@
  $(RES_PREFIX) $(OCAMLOPT) -o $@ $(LINKFLAGS) $(OBJS)
```

Changing the last line to include `-verbose`:

```makefile
  $(RES_PREFIX) $(OCAMLOPT) -verbose -o $@ $(LINKFLAGS) $(OBJS)
```

and rerunning gives:

```sh
C:/src/ocaml-5.4.1 $ env "PATH=$PWD/byte/bin;$PATH" make --trace -C flexdll MSVCC_ROOT= MSVC_DETECT=0 OCAML_CONFIG_FILE=../Makefile.config CHAINS=mingw64 ROOTDIR=.. OCAMLOPT='../runtime/ocamlrun.exe ../ocamlopt.exe -nostdlib -I ../stdlib' flexlink.exe
...
../runtime/ocamlrun.exe ../ocamlopt.exe -nostdlib -I ../stdlib -verbose -o flexlink.exe -cclib "-link version_res.o" version.ml Compat.ml coff.ml cmdline.ml create_dll.ml reloc.ml
+ gcc -c  -o "version.o" "C:\users\jonah\AppData\Local\Temp\camlasmd4c867.s"
+ gcc -c  -o "Compat.o" "C:\users\jonah\AppData\Local\Temp\camlasm1508e2.s"
+ gcc -c  -o "coff.o" "C:\users\jonah\AppData\Local\Temp\camlasme47e57.s"
+ gcc -c  -o "cmdline.o" "C:\users\jonah\AppData\Local\Temp\camlasm9321f9.s"
+ gcc -c  -o "create_dll.o" "C:\users\jonah\AppData\Local\Temp\camlasme41a33.s"
+ gcc -c  -o "reloc.o" "C:\users\jonah\AppData\Local\Temp\camlasm883712.s"
+ gcc -c  -o "C:\users\jonah\AppData\Local\Temp\camlstartup6488e5.o" "C:\users\jonah\AppData\Local\Temp\camlstartupe72e75.s"
+ flexlink -exe -chain mingw64 -stack 33554432 -link -municode   -o "flexlink.exe"  "-L../stdlib"  "C:\users\jonah\AppData\Local\Temp\camlstartup6488e5.o" "../stdlib\std_exit.o" "reloc.o" "create_dll.o" "cmdline.o" "coff.o" "Compat.o" "version.o" "../stdlib\stdlib.a" "-link" "version_res.o" "../stdlib\libasmrun.a"   -lws2_32 -lole32 -luuid -lversion -lshlwapi -lsynchronization   -l:libpthread.a
** Error: Sys_error("../stdlib\\libasmrun.a: Invalid argument")
File "caml_startup", line 1:
Error: Error during linking (exit code 2)
make: *** [Makefile:183: flexlink.exe] Error 2
make: Leaving directory 'C:/src/ocaml-5.4.1/flexdll'
```

The intermediate files like `C:\users\jonah\AppData\Local\Temp\camlasmd4c867.s` have disappeared so changed the last line to include `-S`:

```makefile
  $(RES_PREFIX) $(OCAMLOPT) -verbose -S -o $@ $(LINKFLAGS) $(OBJS)
```

with the relevant output:

```sh
+ gcc -c  -o "version.o" "version.s"
+ gcc -c  -o "Compat.o" "Compat.s"
+ gcc -c  -o "coff.o" "coff.s"
+ gcc -c  -o "cmdline.o" "cmdline.s"
+ gcc -c  -o "create_dll.o" "create_dll.s"
+ gcc -c  -o "reloc.o" "reloc.s"
+ gcc -c  -o "C:\users\jonah\AppData\Local\Temp\camlstartupc67866.o" "C:\users\jonah\AppData\Local\Temp\camlstartupe65504.s"
+ flexlink -exe -chain mingw64 -stack 33554432 -link -municode   -o "flexlink.exe"  "-L../stdlib"  "C:\users\jonah\AppData\Local\Temp\camlstartupc67866.o" "../stdlib\std_exit.o" "reloc.o" "create_dll.o" "cmdline.o" "coff.o" "Compat.o" "version.o" "../stdlib\stdlib.a" "-link" "version_res.o" "../stdlib\libasmrun.a"   -lws2_32 -lole32 -luuid -lversion -lshlwapi -lsynchronization   -l:libpthread.a
** Error: Sys_error("../stdlib\\libasmrun.a: Invalid argument")
```

Per <https://discuss.ocaml.org/t/keeping-all-assembly-files/7641> we also need `-dstartup`:

```makefile
  $(RES_PREFIX) $(OCAMLOPT) -verbose -S -dstartup -o $@ $(LINKFLAGS) $(OBJS)
```

which has the relevant output:

```sh
+ gcc -c  -o "version.o" "version.s"
+ gcc -c  -o "Compat.o" "Compat.s"
+ gcc -c  -o "coff.o" "coff.s"
+ gcc -c  -o "cmdline.o" "cmdline.s"
+ gcc -c  -o "create_dll.o" "create_dll.s"
+ gcc -c  -o "reloc.o" "reloc.s"
+ gcc -c  -o "C:\users\jonah\AppData\Local\Temp\camlstartupee9ec1.o" "flexlink.exe.startup.s"
+ flexlink -exe -chain mingw64 -stack 33554432 -link -municode   -o "flexlink.exe"  "-L../stdlib"  "C:\users\jonah\AppData\Local\Temp\camlstartupee9ec1.o" "../stdlib\std_exit.o" "reloc.o" "create_dll.o" "cmdline.o" "coff.o" "Compat.o" "version.o" "../stdlib\stdlib.a" "-link" "version_res.o" "../stdlib\libasmrun.a"   -lws2_32 -lole32 -luuid -lversion -lshlwapi -lsynchronization   -l:libpthread.a
** Error: Sys_error("../stdlib\\libasmrun.a: Invalid argument")
```

Recreating the original error is now focused on the startup object file and `flexlink` itself, tweaked to use the path to `flexlink.exe`:

```sh
$ gcc -c  -o "C:\users\jonah\AppData\Local\Temp\camlstartupee9ec1.o" "flexdll/flexlink.exe.startup.s"
<no output>
$ (cd flexdll && PATH="$PWD/../byte/bin;$PATH" flexlink -exe -chain mingw64 -stack 33554432 -link -municode   -o "flexlink.exe"  "-L../stdlib"  "C:\users\jonah\AppData\Local\Temp\camlstartupee9ec1.o" "../stdlib\std_exit.o" "reloc.o" "create_dll.o" "cmdline.o" "coff.o" "Compat.o" "version.o" "../stdlib\stdlib.a" "-link" "version_res.o" "../stdlib\libasmrun.a"   -lws2_32 -lole32 -luuid -lversion -lshlwapi -lsynchronization   -l:libpthread.a)
** Error: Sys_error("../stdlib\\libasmrun.a: Invalid argument")
```

---

H1 - Our first hypothesis is that the backslash or forward slash is causing a problem with `cmd.exe`.

We try again with backslashes for the failing argument. That is, `"..\stdlib\libasmrun.a"`:

```sh
$ (cd flexdll && PATH="$PWD/../byte/bin;$PATH" flexlink -exe -chain mingw64 -stack 33554432 -link -municode   -o "flexlink.exe"  "-L../stdlib"  "C:\users\jonah\AppData\Local\Temp\camlstartupee9ec1.o" "../stdlib\std_exit.o" "reloc.o" "create_dll.o" "cmdline.o" "coff.o" "Compat.o" "version.o" "../stdlib\stdlib.a" "-link" "version_res.o" "..\stdlib\libasmrun.a"   -lws2_32 -lole32 -luuid -lversion -lshlwapi -lsynchronization   -l:libpthread.a)
** Error: Sys_error("..\\stdlib\\libasmrun.a: Invalid argument")
```

Since that didn't work, we try again with forward slashes for the failing argument. That is, `"../stdlib/libasmrun.a"`:

```sh
$ (cd flexdll && PATH="$PWD/../byte/bin;$PATH" flexlink -exe -chain mingw64 -stack 33554432 -link -municode   -o "flexlink.exe"  "-L../stdlib"  "C:\users\jonah\AppData\Local\Temp\camlstartupee9ec1.o" "../stdlib\std_exit.o" "reloc.o" "create_dll.o" "cmdline.o" "coff.o" "Compat.o" "version.o" "../stdlib\stdlib.a" "-link" "version_res.o" "../stdlib/libasmrun.a"   -lws2_32 -lole32 -luuid -lversion -lshlwapi -lsynchronization   -l:libpthread.a)
** Error: Sys_error("../stdlib/libasmrun.a: Invalid argument")
```

So `H1` is not a correct hypothesis.

---

It is pretty annoying that `OCAMLRUNPARAM=b` does not produce a stacktrace:

```sh
(cd flexdll && PATH="$PWD/../byte/bin;$PATH" OCAMLRUNPARAM=b flexlink -exe -chain mingw64 -stack 33554432 -link -municode   -o "flexlink.exe"  "-L../stdlib"  "C:\users\jonah\AppData\Local\Temp\camlstartupee9ec1.o" "../stdlib\std_exit.o" "reloc.o" "create_dll.o" "cmdline.o" "coff.o" "Compat.o" "version.o" "../stdlib\stdlib.a" "-link" "version_res.o" "../stdlib\libasmrun.a"   -lws2_32 -lole32 -luuid -lversion -lshlwapi -lsynchronization   -l:libpthread.a)
```

So we'll try to create a bytecode ocamldebug.exe.

```sh
make --trace AWK="C:/opt/w64devkit/bin/awk.exe" debugger/ocamldebug.exe
```

gives:

```text
 OCAMLC otherlibs/dynlink/dynlink_cmo_format.cmi
Makefile:2545: update target 'otherlibs/dynlink/dynlink_cmo_format.cmi' due to: target does not exist
./boot/ocamlrun.exe ./ocamlc.exe -nostdlib -I ./stdlib -g -strict-sequence -principal -absname -w +a-4-9-40-41-42-44-45-48 -warn-error +a -bin-annot -strict-formats -I otherlibs/dynlink -I utils -I parsing -I typing -I bytecomp -I file_formats -I lambda -I middle_end -I middle_end/closure -I middle_end/flambda -I middle_end/flambda/base_types -I asmcomp -I driver -I toplevel -I tools -I runtime -I otherlibs/dynlink -I otherlibs/str -I otherlibs/systhreads -I otherlibs/unix -I otherlibs/runtime_events -I otherlibs/unix -I otherlibs/dynlink -I otherlibs/dynlink/byte -c otherlibs/dynlink/dynlink_cmo_format.mli
File "C:\src\ocaml-5.4.1\otherlibs\dynlink\dynlink_cmo_format.mli", line 1:
Error: I/O error: otherlibs/dynlink/dynlink_cmo_format.mli: No such file or directory
make: *** [Makefile:2545: otherlibs/dynlink/dynlink_cmo_format.cmi] Error 2
```

So the problem seems to be not seeing files from the filesystem. It may be a `cygpath` issue or maybe Wine's lack of `inotify` on macOS has a problem (not likely since an earlier Linux recreation had the same problem).

Perhaps `OCAMLRUNPARAM=b` can show what is happening:

```sh
env OCAMLRUNPARAM=b ./boot/ocamlrun.exe ./ocamlc.exe -nostdlib -I ./stdlib -g -strict-sequence -principal -absname -w +a-4-9-40-41-42-44-45-48 -warn-error +a -bin-annot -strict-formats -I otherlibs/dynlink -I utils -I parsing -I typing -I bytecomp -I file_formats -I lambda -I middle_end -I middle_end/closure -I middle_end/flambda -I middle_end/flambda/base_types -I asmcomp -I driver -I toplevel -I tools -I runtime -I otherlibs/dynlink -I otherlibs/str -I otherlibs/systhreads -I otherlibs/unix -I otherlibs/runtime_events -I otherlibs/unix -I otherlibs/dynlink -I otherlibs/dynlink/byte -c otherlibs/dynlink/dynlink_cmo_format.mli
```

That doesn't change anything. Maybe `-verbose` will help:

```sh
./boot/ocamlrun.exe ./ocamlc.exe -verbose -nostdlib -I ./stdlib -g -strict-sequence -principal -absname -w +a-4-9-40-41-42-44-45-48 -warn-error +a -bin-annot -strict-formats -I otherlibs/dynlink -I utils -I parsing -I typing -I bytecomp -I file_formats -I lambda -I middle_end -I middle_end/closure -I middle_end/flambda -I middle_end/flambda/base_types -I asmcomp -I driver -I toplevel -I tools -I runtime -I otherlibs/dynlink -I otherlibs/str -I otherlibs/systhreads -I otherlibs/unix -I otherlibs/runtime_events -I otherlibs/unix -I otherlibs/dynlink -I otherlibs/dynlink/byte -c otherlibs/dynlink/dynlink_cmo_format.mli
```

That doesn't change anything. So we'll edit the `ocamlc` driver and add logging statements. To find the driver:

```sh
winepath driver/maindriver.ml
```

and to rebuild after editing it:

```sh
make --trace AWK="C:/opt/w64devkit/bin/awk.exe" ocamlc.exe
```

But adding logging statements with `Printf.eprintf` only revealed that `Pparse.open_and_check_magic` was failing at the `open_in_bin` function.

We've been chasing a dead-end because the w64devkit `sh` interpreter does not see the file either:

```sh
C:/src/ocaml-5.4.1 $ head otherlibs/dynlink/dynlink_cmo_format.mli
head: otherlibs/dynlink/dynlink_cmo_format.mli: No such file or directory
```

even if it can see it in the filesystem:

```sh
C:/src/ocaml-5.4.1 $ ls -l otherlibs/dynlink/dynlink_cmo_format.mli
-rw-rw----    1 root     root             0 Feb 23 16:35 otherlibs/dynlink/dynlink_cmo_format.mli
```

When we dump the Unix filesystem we see extended attributes:

```sh
$ ls -l /Volumes/xxxx/dk/t/p/99658/3lwn/s/wineprefixes/NotInriaCaml_Std.Toolchain.LLVM_MinGW.Release.Darwin_arm64.Windows_x86_64@5.4.1/drive_c/src/ocaml-5.4.1/otherlibs/dynlink/
total 280
drwxr-xr-x  5 jonah  staff    160 Feb 17 02:04 byte
-rw-r--r--  1 jonah  staff   1421 Feb 17 02:04 dune
-rw-r--r--@ 1 jonah  staff      0 Feb 23 16:35 dynlink_cmo_format.mli?
-rw-r--r--@ 1 jonah  staff      0 Feb 23 16:35 dynlink_cmxs_format.mli?
-rw-r--r--  1 jonah  staff   1856 Feb 24 12:15 dynlink_common.cmi
-rw-r--r--  1 jonah  staff  11233 Feb 24 12:15 dynlink_common.cmti
...
-rw-r--r--  1 jonah  staff   2461 Feb 17 02:04 dynlink_platform_intf.ml
-rw-r--r--@ 1 jonah  staff      0 Feb 23 16:35 dynlink_platform_intf.mli?
-rw-r--r--  1 jonah  staff   1911 Feb 24 12:15 dynlink_types.cmi
-rw-r--r--  1 jonah  staff  10792 Feb 24 12:15 dynlink_types.cmti
```

which we expand with:

```sh
$ /bin/ls -aleO@ /Volumes/xxxx/dk/t/p/99658/3lwn/s/wineprefixes/NotInriaCaml_Std.Toolchain.LLVM_MinGW.Release.Darwin_arm64.Windows_x86_64@5.4.1/drive_c/src/ocaml-5.4.1/otherlibs/dynlink/
total 288
drwxr-xr-x  27 jonah  staff  -   864 Feb 24 13:12 .
drwxr-xr-x   9 jonah  staff  -   288 Feb 17 02:04 ..
drwxr-xr-x   5 jonah  staff  -   160 Feb 17 02:04 byte
-rw-r--r--   1 jonah  staff  -  1421 Feb 17 02:04 dune
-rw-r--r--   1 jonah  staff  -  3697 Feb 24 13:12 dynlink_cmo_format.mli
  (I skipped ahead to use `config.status` so I already fixed this file)
-rw-r--r--@  1 jonah  staff  -     0 Feb 23 16:35 dynlink_cmxs_format.mli?
        user.WINEREPARSE          160 
-rw-r--r--   1 jonah  staff  -  1856 Feb 24 12:15 dynlink_common.cmi
-rw-r--r--   1 jonah  staff  - 11233 Feb 24 12:15 dynlink_common.cmti
...
-rw-r--r--   1 jonah  staff  -  2461 Feb 17 02:04 dynlink_platform_intf.ml
-rw-r--r--@  1 jonah  staff  -     0 Feb 23 16:35 dynlink_platform_intf.mli?
        user.WINEREPARSE          216 
```

That seems to be Wine emulating a Windows reparse link (a form of symlink for Windows).
But clearly the reparse links aren't working, or maybe w64devkit (MinGW) does not work with reparse links.

I already mentioned that I skipped ahead to regenerate `dynlink_cmo_format.mli` with:

```sh
sh -x ./config.status --file otherlibs/dynlink/dynlink_cmo_format.mli:file_formats/cmo_format.mli
```

which came from <https://github.com/ocaml/ocaml/blob/02ee646ee1f40eb19f4942f50a4a607b52b3ab39/configure.ac#L978>:

```sh
m4_define([dldir], [otherlibs/dynlink])
AC_CONFIG_LINKS(
  dldir[/dynlink_cmo_format.mli:file_formats/cmo_format.mli]
  dldir[/dynlink_cmxs_format.mli:file_formats/cmxs_format.mli]
  dldir[/dynlink_platform_intf.mli:]dldir[/dynlink_platform_intf.ml]
)
```

and reading <https://www.gnu.org/software/autoconf/manual/autoconf-2.64/html_node/config_002estatus-Invocation.html#config_002estatus-Invocation>.

Now if we do:

```sh
./config.status
```

that recreates all the `user.WINEREPARSE` links which makes sense because our

```sh
./config.status --file otherlibs/dynlink/dynlink_cmo_format.mli:file_formats/cmo_format.mli
```

mimicked `AC_CONFIG_FILES` rather than `AC_CONFIG_LINKS` that is in `./configure`.

SOLUTION:

We could either patch `./configure` ... where the patch is dependent on the OCaml version 5.4.1 ...
or run `./config.status --file` which is preferred.

The list for `--file` comes from:

```sh
C:/src/ocaml-5.4.1 $ grep ac_config_links= configure
ac_config_links="$ac_config_links $dldir/dynlink_cmo_format.mli:file_formats/cmo_format.mli $dldir/dynlink_cmxs_format.mli:file_formats/cmxs_format.mli $dldir/dynlink_platform_in
tf.mli:$dldir/dynlink_platform_intf.ml"
  ac_config_links="$ac_config_links otherlibs/unix/unix.ml:otherlibs/unix/unix_${unix_or_win32}.ml"
  ac_config_links="$ac_config_links ocamltest/ocamltest_unix.ml:${ocamltest_unix_mod}"
```

where `dldir=otherlibs/dynlink` from:

```sh
# configure
dldir=otherlibs/dynlink
```

and where `unix_or_win32=win32` from both:

```sh
# configure
case $target in #(
  *-w64-mingw32*|*-pc-windows) :
    unix_or_win32="win32"
```

and

```sh
# config.status
S["unix_or_win32"]="win32"
```

We can ignore the `ocamltest_unix_mod` link because we aren't building tests when we do `./configure --disable-tests`:

```sh
if $build_ocamltest
then :
  optional_libraries="$optional_libraries testsuite/lib/testing"
  ocamltest_unix_mod="ocamltest/ocamltest_unix_${ocamltest_unix_impl}.ml"
  ac_config_links="$ac_config_links ocamltest/ocamltest_unix.ml:${ocamltest_unix_mod}"

  for ac_prog in patdiff diff
do
```

So:

```sh
C:/src/ocaml-5.4.1 $ ./config.status --file otherlibs/dynlink/dynlink_cmo_format.mli:file_formats/cmo_format.mli --file otherlibs/dynlink/dynlink_cmxs_format.mli:file_formats/cmxs_format.mli --file otherlibs/dynlink/dynlink_platform_intf.mli:otherlibs/dynlink/dynlink_platform_intf.ml --file otherlibs/unix/unix.ml:otherlibs/unix/unix_win32.ml
config.status: creating otherlibs/dynlink/dynlink_cmo_format.mli
config.status: creating otherlibs/dynlink/dynlink_cmxs_format.mli
config.status: creating otherlibs/dynlink/dynlink_platform_intf.mli
config.status: creating otherlibs/unix/unix.ml
```

---

Back to creating ocamldebug.exe:

```sh
C:/src/ocaml-5.4.1 $ make --trace AWK="C:/opt/w64devkit/bin/awk.exe" debugger/ocamldebug.exe
```

which now works.

We use that to enter the debugger:

```sh
C:/src/ocaml-5.4.1 $ (export CAML_LD_LIBRARY_PATH="$PWD/otherlibs/unix" && cd flexdll && ../runtime/ocamlrun.exe ../debugger/ocamldebug.exe ../byte/bin/flexlink.exe -exe -chain mingw64 -stack 33554432 -link -municode   -o "flexlink.exe"  "-L../stdlib"  "C:\users\jonah\AppData\Local\Temp\camlstartupee9ec1.o" "../stdlib\std_exit.o" "reloc.o" "create_dll.o" "cmdline.o" "coff.o" "Compat.o" "version.o" "../stdlib\stdlib.a" "-link" "version_res.o" "../stdlib\libasmrun.a"   -lws2_32 -lole32 -luuid -lversion -lshlwapi -lsynchronization   -l:libpthread.a)
        OCaml Debugger version 5.4.1

(ocd) r
Loading program... C:\src\ocaml-5.4.1\flexdll\../byte/bin/flexlink.exe has no debugging info.
```

so we need debug symbols.

We'll add `-g` to:

```makefile
# file: flexdll/Makefile
# line: 180-183
flexlink.exe: $(OBJS) $(RES)
  @echo Building flexlink.exe with TOOLCHAIN=$(TOOLCHAIN) for OCaml $(OCAML_VERSION)
  rm -f $@
  $(RES_PREFIX) $(OCAMLOPT) -g -o $@ $(LINKFLAGS) $(OBJS)
```

and recompile `byte/bin/flexlink.exe`:

```sh
C:/src/ocaml-5.4.1 $ make --trace AWK="C:/opt/w64devkit/bin/awk.exe" byte/bin/flexlink.exe
```

Enter the debugger again (using `set arguments` since `ocamldebug` does not recognize arguments on the command line ... at least when using the `ocamlrun ocamldebug` form):

```sh
C:/src/ocaml-5.4.1 $ (export CAML_LD_LIBRARY_PATH="$PWD/otherlibs/unix" && cd flexdll && ../runtime/ocamlrun.exe ../debugger/ocamldebug.exe ../byte/bin/flexlink.exe)
        OCaml Debugger version 5.4.1

(ocd) set arguments -exe -chain mingw64 -stack 33554432 -link -municode   -o "flexlink.exe"  "-L../stdlib"  "C:\users\jonah\AppData\Local\Temp\camlstartupee9ec1.o" "../stdlib\std_exit.o" "reloc.o" "create_dll.o" "cmdline.o" "coff.o" "Compat.o" "version.o" "../stdlib\stdlib.a" "-link" "version_res.o" "../stdlib\libasmrun.a"   -lws2_32 -lole32 -luuid -lversion -lshlwapi -lsynchronization   -l:libpthread.a

(ocd) r
Loading program... done.
** Fatal error: Cannot find file "\"-L../stdlib\""
Time: 81331
Program exit.

(ocd) set arguments -exe -chain mingw64 -stack 33554432 -link -municode   -o flexlink.exe  -L../stdlib  C:\\users\\jonah\\AppData\\Local\\Temp\\camlstartupee9ec1.o ../stdlib\\std_exit.o reloc.o create_dll.o cmdline.o coff.o Compat.o version.o ../stdlib\\stdlib.a -link version_res.o ../stdlib\\libasmrun.a   -lws2_32 -lole32 -luuid -lversion -lshlwapi -lsynchronization   -l:libpthread.a

(ocd) r
Loading program... done.
** Error: Sys_error("../stdlib\\\\libasmrun.a: Invalid argument")
Time: 6240188
Program exit.

(ocd) goto 6240187
Can't go that far in the past !
Reload program ? (y or n) y
** Error: Sys_error("../stdlib\\\\libasmrun.a: Invalid argument")
Time: 6240187 - pc: 3:6180 - module Stdlib
579   do_at_exit ()<|a|>;

(ocd) bt
Backtrace:
#0 Stdlib stdlib.ml:579:16
#1 Reloc reloc.ml:1605:15
```

That `reloc.ml` is:

```ocaml
  try main ()
  with
    (* ... *)    
    | exn ->
        Printf.eprintf "** Error: %s\n" (Printexc.to_string exn);
        exit 2 (* line 1605 *)
```

So we'll comment out the three lines `| exn -> ... exit 2` and recompile so we can see the real exception.

```sh
C:/src/ocaml-5.4.1 $ make --trace AWK="C:/opt/w64devkit/bin/awk.exe" byte/bin/flexlink.exe
```

Since we changed earlier to having debug information, `OCAMLRUNPARAM=b` now works:

```sh
C:/src/ocaml-5.4.1 $ (export OCAMLRUNPARAM=b CAML_LD_LIBRARY_PATH="$PWD/otherlibs/unix" && cd flexdll && ../runtime/ocamlrun.exe ../byte/bin/flexlink.exe -exe -chain mingw64 -stack 33554432 -link -municode   -o "flexlink.exe"  "-L../stdlib"  "C:\users\jonah\AppData\Local\Temp\camlstartupee9ec1.o" "../stdlib\std_exit.o" "reloc.o" "create_dll.o" "cmdline.o" "coff.o" "Compat.o" "version.o" "../stdlib\stdlib.a" "-link" "version_res.o" "../stdlib\libasmrun.a"   -lws2_32 -lole32 -luuid -lversion -lshlwapi -lsynchronization   -l:libpthread.a)
Fatal error: exception Sys_error("../stdlib\\libasmrun.a: Invalid argument")
Raised by primitive operation at Stdlib.open_in_gen in file "stdlib.ml", line 405, characters 28-54
Called from Coff.Lib.is_dll in file "coff.ml", line 1000, characters 13-33
Called from Reloc.build_dll.read_file in file "reloc.ml", line 745, characters 7-20
Called from Reloc.build_dll.(fun) in file "reloc.ml", line 751, characters 38-50
Called from Stdlib__List.map in file "list.ml", line 88, characters 15-19
Called from Stdlib__List.map in file "list.ml", line 90, characters 14-21
Called from Reloc.build_dll in file "reloc.ml", line 751, characters 14-57
Called from Reloc in file "reloc.ml", line 1589, characters 6-13
```

It seems like we ran into the same reparse problem:

```sh
C:/src/ocaml-5.4.1 $ ls -l stdlib/libasmrun.a
-rw-rw----    1 root     root             0 Feb 24 11:35 stdlib/libasmrun.a

% /bin/ls -aleO@ /Volumes/xxxx/dk/t/p/99658/3lwn/s/wineprefixes/NotInriaCaml_Std.Toolchain.LLVM_MinGW.Release.Darwin_arm64.Windows_x86_64@5.4.1/drive_c/src/ocaml-5.4.1/stdlib/lib*       
-rw-r--r--@ 1 jonah  staff  - 0 Feb 24 11:35 /Volumes/xxxx/dk/t/p/99658/3lwn/s/wineprefixes/NotInriaCaml_Std.Toolchain.LLVM_MinGW.Release.Darwin_arm64.Windows_x86_64@5.4.1/drive_c/src/ocaml-5.4.1/stdlib/libasmrun.a?
        user.WINEREPARSE        112 
-rw-r--r--@ 1 jonah  staff  - 0 Feb 24 11:35 /Volumes/xxxx/dk/t/p/99658/3lwn/s/wineprefixes/NotInriaCaml_Std.Toolchain.LLVM_MinGW.Release.Darwin_arm64.Windows_x86_64@5.4.1/drive_c/src/ocaml-5.4.1/stdlib/libcamlrun.a?
        user.WINEREPARSE        116 
```

That is because a symlink is created:

```makefile
# Makefile
stdlib/libcamlrun.$(A): runtime-all
  cd stdlib; $(LN) ../runtime/libcamlrun.$(A) .
```

The easiest solution that does not involve patching `./configure` which sets (indentation added):

```sh
case $host in #(
  *-w64-mingw32*|*-pc-windows) :

    { printf "%s\n" "$as_me:${as_lineno-$LINENO}: checking for a workable solution for ln -sf" >&5
      printf %s "checking for a workable solution for ln -sf... " >&6; }
    if MSYS=winsymlinks:nativestrict CYGWIN=winsymlinks:nativestrict ln -sf configure conftestLink 2>/dev/null
    then :
      ln='ln -sf'
    else $as_nop
      ln='cp -pf'

    fi
    { printf "%s\n" "$as_me:${as_lineno-$LINENO}: result: $ln" >&5
      printf "%s\n" "$ln" >&6; }

    ocamlsrcdir="$(LC_ALL=C.UTF-8 cygpath -w -- "$ocamlsrcdir")" ;; #(
  *) :
    ln='ln -sf' ;;
esac
```

is to run `make LN="cp -pf" ...`.

---

Verifying with:

```sh
C:/src/ocaml-5.4.1 $ rm -f stdlib/lib*.a
C:/src/ocaml-5.4.1 $ make --trace AWK="C:/opt/w64devkit/bin/awk.exe" LN="cp -pf"
```

CONCLUSION 1: We would not need to use `LN="cp -pf"` if `ln.exe` was not bundled into w64devkit at `C:/opt/w64devkit/bin/ln.exe`.

CONCLUSION 2: The AC_CONFIG_LINKS macro using `ln` is unavoidable without a patch to `./configure` or what we did here (correcting the links after the fact).
