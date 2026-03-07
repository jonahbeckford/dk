-- USAGE 1 of 2: CommonsBase_Std.Extract.F_Untar@0.1.0
-- (Free rule) Untars a tar, tar.gz, tar.xz or tar.bz2 file.
-- Configurations: One of the following sets of options must be provided:
--  tarfile= modver= paths[]=
-- Options:
--  tarfile=$PWD/target/nothing.tar.gz
--    The tar, tar.gz, tar.xz or tar.bz2 file to extract.
--  modver=OurTest_Std.Extract@0.1.0
--    The MODULE@VERSION of the form object that will contain the extracted files.
--    The slot for the form object will be `Release.Agnostic`.
--  paths[]=README.md
--    All of the extracted paths.
--    A future version may extract only the specified paths,
--    but for now we extract all files and expect you to declare them all.
-- Examples:
--   tar cvf target/nothing.tar README.md
--
--   dk0 --trial post-object CommonsBase_Std.Extract.F_Untar@0.1.0 \
--     -f target/untar modver=OurTest_Std.Extract@0.1.0 \
--     tarfile=$PWD/target/nothing.tar 'paths[]=README.md'
--
--   {or local dev}
--
--   _build/default/ext/MlFront/src/DkZero_Exec/Shell.exe \
--     -isystem ./ext/dk/etc/dk/i -I ext/dk/etc/dk/v \
--     --trust-local-package CommonsBase_Std \
--     --trial post-object CommonsBase_Std.Extract.F_Untar@0.1.0 \
--     -f target/untar modver=OurTest_Std.Extract@0.1.0 \
--     tarfile=$PWD/target/nothing.tar 'paths[]=README.md'
--
-- USAGE 2 of 2: CommonsBase_Std.Extract.F_TarToZip@0.1.0
-- (Free rule) Extracts a tar, tar.gz, tar.xz or tar.bz2 file and then re-compresses it
-- to a .zip file which has first-class support in the dk build system.
-- Configurations: One of the following sets of options must be provided:
--  tarfile= modver=
-- Options:
--  tarfile=$PWD/target/nothing.tar.gz
--    The tar, tar.gz, tar.xz or tar.bz2 file to extract.
--  modver=OurTest_Std.Extract@0.1.0
--    The MODULE@VERSION of the form object that will contain the "output.zip" file.
--    The slot for the form object will be `Release.Agnostic`.
-- Examples:
--   tar cvf target/nothing.tar README.md
--
--   dk0 --trial post-object CommonsBase_Std.Extract.F_TarToZip@0.1.0 \
--     -f target/t2.zip \
--     tarfile=$PWD/target/nothing.tar modver=OurTest_Std.T2Zip@0.1.0
--
--   dk0 --trial get-object OurTest_Std.T2Zip@0.1.0 -s Release.Agnostic \
--     -m ./output.zip -d target/unt2zip
--
--   ls target/unt2zip
--   > README.md
--
-- DESIGN QUESTIONS
--
-- Q1: Platforms?
-- A1: On macOS the /usr/bin/tar system binary is used.
-- On Linux the toybox tar command is fetched from an asset and used.
-- On Windows the 7z.exe from S7z command is fetched from an asset and used.
-- Also, for F_TarToZip: (macOS) /usr/bin/zip. (Others) the S7z object.
--
-- Q2: There is no way to filter which files I want.
-- A2: <FUTURE> This rule will be renamed to CommonsBase_Std.Extract0, and the new CommonsBase_Std.Extract
-- will run CommonsBase_Std.Fd on the extracted files to filter them. The split is because
-- CommonsBase_Std.Fd requires CommonsBase_Std.Extract0.

local M = {
  id = "CommonsBase_Std.Extract@0.1.0"
}

-- lua-ml does not support local functions.
-- And if the variable was "local" it would be nil inside the rules/uirules function bodies.
-- So a should-be-unique global is used instead.
CommonsBase_Std__Extract__0_1_0 = {}

rules = build.newrules(M)

function rules.F_Untar(command, request)
  if command == "declareoutput" then
    local modver = assert(request.user.modver, "please provide `modver=MODULE@VERSION`")
    return {
      declareoutput = {
        return_form = {
          id = modver,
          slot = "Release.Agnostic"
        }
      }
    }
  elseif command == "submit" then
    local paths = assert(request.user.paths, "please provide `'paths[]=PATH1' 'paths[]=PATH2' ...`")
    assert(type(paths) == "table", "paths must be a table. please provide `'paths[]=PATH1' 'paths[]=PATH2' ...`")
    local p = {
      paths = paths
    }
    CommonsBase_Std__Extract__0_1_0.common_params(request, p)
    if request.execution.OSFamily == "macos" then
      return CommonsBase_Std__Extract__0_1_0.untar_macos(p)
    elseif request.execution.OSFamily == "linux" then
      return CommonsBase_Std__Extract__0_1_0.untar_linux(p)
    elseif request.execution.OSFamily == "windows" then
      if p.gzip or p.xz or p.bz2 then
        return CommonsBase_Std__Extract__0_1_0.untarsomez_win32(p)
      else
        return CommonsBase_Std__Extract__0_1_0.untar_win32(p)
      end
    else
      error("unsupported OSFamily: " .. request.execution.OSFamily)
    end
  end
end

function rules.F_TarToZip(command, request)
  if command == "declareoutput" then
    local modver = assert(request.user.modver, "please provide `modver=MODULE@VERSION`")
    return {
      declareoutput = {
        return_form = {
          id = modver,
          slot = "Release.Agnostic"
        }
      }
    }
  elseif command == "submit" then
    local p = {}
    CommonsBase_Std__Extract__0_1_0.common_params(request, p)
    if request.execution.OSFamily == "macos" then
      return CommonsBase_Std__Extract__0_1_0.tartozip_macos(p)
    elseif request.execution.OSFamily == "linux" then
      return CommonsBase_Std__Extract__0_1_0.tartozip_linux(p)
    elseif request.execution.OSFamily == "windows" then
      if p.gzip or p.xz or p.bz2 then
        return CommonsBase_Std__Extract__0_1_0.tartozip_somez_win32(p)
      else
        return CommonsBase_Std__Extract__0_1_0.tartozip_win32(p)
      end
    else
      error("unsupported OSFamily: " .. request.execution.OSFamily)
    end
  end
end

function CommonsBase_Std__Extract__0_1_0.common_params(request, p)
  local tarfile = assert(request.user.tarfile, "please provide `'tarfile=SOURCE'`")
  local gzip = string.find(tarfile, "%.tar%.gz$") ~= nil
  local xz = string.find(tarfile, "%.tar%.xz$") ~= nil
  local bz2 = string.find(tarfile, "%.tar%.bz2$") ~= nil
  local toyboxexe = string.format(
    "$(get-object CommonsBase_Std.Toybox@0.8.9 -s Release.%s -m ./toybox -f toybox.exe -e '*')",
    request.execution.ABIv3)
  local sevenzzexe = string.format(
    "$(get-object CommonsBase_Std.S7z@25.1.0 -s Release.%s -m ./7zz.exe -f 7zz.exe -e '*')",
    request.execution.ABIv3)
  local sevenzexe_win32 = string.format(
    "$(get-object CommonsBase_Std.S7z.Windows7zExe@25.1.0 -s Release.%s -d :)/7z.exe",
    request.execution.ABIv3)
  local coreutilsexe = string.format(
    "$(get-object CommonsBase_Std.Coreutils@0.2.2 -s Release.%s -m ./coreutils.exe -f coreutils.exe -e '*')",
    request.execution.ABIv3)

  -- /a/b/c.tar.gz -> ("z", /a/b/c.tar)
  -- /a/b/c.tar.xz -> ("J", /a/b/c.tar)
  -- /a/b/c.tar.bz2 -> ("j", /a/b/c.tar)
  local tarcompressflag = ""
  local file_tar = ""
  if gzip then
    tarcompressflag = "z"
    file_tar = string.sub(tarfile, 1, -4) -- remove .gz
  elseif xz then
    tarcompressflag = "J"
    file_tar = string.sub(tarfile, 1, -4) -- remove .xz
  elseif bz2 then
    tarcompressflag = "j"
    file_tar = string.sub(tarfile, 1, -5) -- remove .bz2
  else
    file_tar = tarfile
  end

  -- /a/b/c.tar -> c.tar
  local baseidx = assert(string.find(file_tar, "[^/][^/]*$"), "`" .. tarfile .. "` tarball must have a basename")
  local file_tar_basename = string.sub(file_tar, baseidx)

  p.outputid = request.submit.outputid
  p.outputmodule = request.submit.outputmodule
  p.outputversion = request.submit.outputversion

  p.tarfile = tarfile
  p.file_tar = file_tar
  p.file_tar_basename = file_tar_basename
  p.abi = request.execution.ABIv3
  p.tarcompressflag = tarcompressflag
  p.gzip = gzip
  p.xz = xz
  p.bz2 = bz2
  p.toyboxexe = toyboxexe
  p.sevenzzexe = sevenzzexe
  p.sevenzexe_win32 = sevenzexe_win32
  p.coreutilsexe = coreutilsexe
end

function CommonsBase_Std__Extract__0_1_0.untar_macos(p)
  return {
    submit = {
      values = {
        schema_version = { major = 1, minor = 0 },
        forms = {
          {
            id = p.outputid,
            function_ = {
              execution = { { name = "OSFamily", value = "macos" } },
              commands = {
                { -- macOS system tar
                  "/usr/bin/tar",
                  "-x" .. p.tarcompressflag .. "f",
                  p.tarfile,
                  "-C",
                  "${SLOT.Release.Agnostic}" }
              }
            },
            outputs = {
              assets = {
                {
                  slots = { "Release.Agnostic" },
                  paths = p.paths
                }
              }
            }
          }
        }
      }
    }
  }
end

function CommonsBase_Std__Extract__0_1_0.tartozip_macos(p)
  return {
    submit = {
      values = {
        schema_version = { major = 1, minor = 0 },
        forms = {
          {
            id = p.outputid,
            function_ = {
              execution = { { name = "OSFamily", value = "macos" } },
              commands = {
                { -- macOS system tar
                  "/usr/bin/tar",
                  "-x" .. p.tarcompressflag .. "f",
                  p.tarfile
                },
                {
                  -- [p.sevenzzee] is 7zz
                  p.sevenzzexe,
                  "a",
                  "${SLOT.Release.Agnostic}/output.zip"
                }
              }
            },
            outputs = {
              assets = {
                {
                  slots = { "Release.Agnostic" },
                  paths = { "output.zip" }
                }
              }
            }
          }
        }
      }
    }
  }
end

function CommonsBase_Std__Extract__0_1_0.untar_linux(p)
  return {
    submit = {
      values = {
        schema_version = { major = 1, minor = 0 },
        forms = {
          {
            id = p.outputid,
            function_ = {
              execution = { { name = "OSFamily", value = "linux" } },
              commands = {
                {
                  p.toyboxexe,
                  "tar",
                  "-x" .. p.tarcompressflag .. "f",
                  p.tarfile,
                  "-C",
                  "${SLOT.Release.Agnostic}"
                } }
            },
            outputs = {
              assets = {
                {
                  slots = { "Release.Agnostic" },
                  paths = p.paths
                }
              }
            }
          }
        }
      }
    }
  }
end

function CommonsBase_Std__Extract__0_1_0.tartozip_linux(p)
  return {
    submit = {
      values = {
        schema_version = { major = 1, minor = 0 },
        forms = {
          {
            id = p.outputid,
            function_ = {
              execution = { { name = "OSFamily", value = "linux" } },
              commands = {
                {
                  p.toyboxexe,
                  "tar",
                  "-x" .. p.tarcompressflag .. "f",
                  p.tarfile
                },
                {
                  -- [p.sevenzzee] is 7zz
                  p.sevenzzexe,
                  "a",
                  "${SLOT.Release.Agnostic}/output.zip"
                }
              }
            },
            outputs = {
              assets = {
                {
                  slots = { "Release.Agnostic" },
                  paths = { "output.zip" }
                }
              }
            }
          }
        }
      }
    }
  }
end

-- tar.gz, tar.xz or tar.bz2
function CommonsBase_Std__Extract__0_1_0.untarsomez_win32(p)
  return {
    submit = {
      values = {
        schema_version = { major = 1, minor = 0 },
        forms = {
          {
            id = p.outputid,
            function_ = {
              execution = { { name = "OSFamily", value = "windows" } },
              commands = {
                -- extract the .tar.gz/.tar.xz/.tar.bz2 to a .tar
                {
                  -- with [7z.exe] ...
                  p.sevenzexe_win32,
                  -- uncompress
                  "x",
                  -- to current directory
                  "-o.",
                  -- the .tar.gz
                  p.tarfile,
                  -- select the .tar extracted output
                  p.file_tar_basename
                },
                -- extract the .tar
                {
                  -- with [7z.exe] ...
                  p.sevenzexe_win32,
                  -- uncompress
                  "x",
                  -- to output directory
                  "-o${SLOT.Release.Agnostic}",
                  -- the tarball
                  p.file_tar_basename
                } }
            },
            outputs = {
              assets = {
                {
                  slots = { "Release.Agnostic" },
                  paths = p.paths
                }
              }
            }
          }
        }
      }
    }
  }
end

function CommonsBase_Std__Extract__0_1_0.tartozip_somez_win32(p)
  return {
    submit = {
      values = {
        schema_version = { major = 1, minor = 0 },
        forms = {
          {
            id = p.outputid,
            function_ = {
              execution = { { name = "OSFamily", value = "windows" } },
              commands = {
                -- extract the .tar.gz/.tar.xz/.tar.bz2 to a .tar
                {
                  -- with [7z.exe] ...
                  p.sevenzexe_win32,
                  -- uncompress
                  "x",
                  -- to current directory
                  "-o.",
                  -- the .tar.gz
                  p.tarfile,
                  -- select the .tar extracted output
                  p.file_tar_basename
                },
                -- make temp directory
                {
                  p.coreutilsexe,
                  "mkdir",
                  "${CACHE}"
                },
                -- move the .tar to a temp directory
                {
                  p.coreutilsexe,
                  "mv",
                  p.file_tar_basename,
                  "${CACHE}/" .. p.file_tar_basename
                },
                -- extract the .tar
                {
                  -- with [7z.exe] ...
                  p.sevenzexe_win32,
                  -- uncompress
                  "x",
                  -- to current directory
                  "-o.",
                  -- the tarball
                  "${CACHE}/" .. p.file_tar_basename
                },
                -- remove the .tar from the temp directory
                {
                  p.coreutilsexe,
                  "rm",
                  "${CACHE}/" .. p.file_tar_basename
                },
                -- create output.zip from the .tar
                {
                  -- with [7z.exe] ...
                  p.sevenzexe_win32,
                  "a",
                  "${SLOT.Release.Agnostic}/output.zip"
                }
              }
            },
            outputs = {
              assets = {
                {
                  slots = { "Release.Agnostic" },
                  paths = { "output.zip" }
                }
              }
            }
          }
        }
      }
    }
  }
end

function CommonsBase_Std__Extract__0_1_0.untar_win32(p)
  return {
    submit = {
      values = {
        schema_version = { major = 1, minor = 0 },
        forms = {
          {
            id = p.outputid,
            function_ = {
              execution = { { name = "OSFamily", value = "windows" } },
              commands = {
                -- with [7z.exe] ...
                p.sevenzexe_win32,
                -- uncompress
                "x",
                -- to output directory
                "-o${SLOT.Release.Agnostic}",
                -- the tarball
                p.tarfile
              }
            },
            outputs = {
              assets = {
                {
                  slots = { "Release.Agnostic" },
                  paths = p.paths
                }
              }
            }
          }
        }
      }
    }
  }
end

function CommonsBase_Std__Extract__0_1_0.tartozip_win32(p)
  return {
    submit = {
      values = {
        schema_version = { major = 1, minor = 0 },
        forms = {
          {
            id = p.outputid,
            function_ = {
              execution = { { name = "OSFamily", value = "windows" } },
              commands = {
                -- extract the .tar
                {
                  -- with [7z.exe] ...
                  p.sevenzexe_win32,
                  -- uncompress
                  "x",
                  -- to current directory
                  "-o.",
                  -- the tarball
                  p.tarfile
                },
                -- create output.zip from the .tar
                {
                  -- with [7z.exe] ...
                  p.sevenzexe_win32,
                  "a",
                  "${SLOT.Release.Agnostic}/output.zip"
                }
              }
            },
            outputs = {
              assets = {
                {
                  slots = { "Release.Agnostic" },
                  paths = { "output.zip" }
                }
              }
            }
          }
        }
      }
    }
  }
end

return M
