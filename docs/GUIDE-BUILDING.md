# Guide to building packages (everybody)

## Repeatable Builds

Most `dk0` commands will *download and extract* from binary caches and *build* software if the caches do not have what you requested.

While you are developing your own software, it is very common for your development machine to be your build machine.
Your development machine is often very different from the package author's machine. Even so, you want your build on your
development machine to be functionally identical to a build on the package author's machine. We call that **repeatable builds**.

In other words, we want to avoid:

> SOMEONE: The software is broken.
>
> DEVELOPER: But it built on my machine!

To get repeatable builds, two things have to happen (we'll define new terms shortly):

| What                           | Who is Responsible              |
| ------------------------------ | ------------------------------- |
| **hermetic** build environment | Your responsibility             |
| **deterministic** package      | Package author's responsibility |

Hermetic: If you run your builds so that software installed or running outside of the build cannot influence the build itself, we have a **hermetic build environment**.

Deterministic: The package does not rely on the date, a random number generator, or download assets from the Internet which change over time.

## Hermetic Build Environments

Let's talk about how you can get a hermetic build environment!

You can one or both of the following tactics:

- UNAWARE: Run your builds in a way that your build is unaware of what is on your machine.
- BLANK SLATE: Run your builds on a machine that has nothing installed.

If you can't do those tactics, you can get close to hermetic with the following tactic:

- AVOIDANCE: Avoid installing and running problematic software on your build machine

Each tactic is implemented differently based on the build machine's operating system.

### TO ORGANIZE

- Running your builds in a Docker container
- Running your builds in a virtual machine (VMware, etc.)
- Running your builds in a newly provisioned cloud machine (EC2, etc.)
- Linux cgroups sandboxing
- Windows Sandbox

### AVOIDANCE

If you create or open a project in an IDE, the IDE and its plugins and its extensions can modify project files **in the background**. Your IDE can be a source of non-hermetic builds.

#### FINDING background programs on Windows that create extra files

Symptom:

```text
Could not verify `CommonsBase_LLVM.Toolchain.MinGW@21.1.8+bn-20250101000000.rev-20251216 -s Release.Windows_x86_64` because the ${SLOT.Release.Windows_x86_64} directory has extra files not declared in `outputs.assets`: `["python/lib/python3.12/__pycache__/copyreg.cpython-312.pyc","python/lib/python3.12/__pycache__/enum.cpython-312.pyc","python/lib/python3.12/__pycache__/functools.cpython-312.pyc","python/lib/python3.12/__pycache__/keyword.cpython-312.pyc","python/lib/python3.12/__pycache__/operator.cpython-312.pyc","python/lib/python3.12/__pycache__/reprlib.cpython-312.pyc","python/lib/python3.12/__pycache__/types.cpython-312.pyc","python/lib/python3.12/collections/__pycache__/__init__.cpython-312.pyc","python/lib/python3.12/encodings/__pycache__/__init__.cpython-312.pyc","python/lib/python3.12/encodings/__pycache__/aliases.cpython-312.pyc","python/lib/python3.12/encodings/__pycache__/cp1252.cpython-312.pyc","python/lib/python3.12/encodings/__pycache__/utf_8.cpython-312.pyc","python/lib/python3.12/json/__pycache__/__init__.cpython-312.pyc","python/lib/python3.12/json/__pycache__/decoder.cpython-312.pyc","python/lib/python3.12/json/__pycache__/encoder.cpython-312.pyc","python/lib/python3.12/json/__pycache__/scanner.cpython-312.pyc","python/lib/python3.12/re/__pycache__/__init__.cpython-312.pyc","python/lib/python3.12/re/__pycache__/_casefix.cpython-312.pyc","python/lib/python3.12/re/__pycache__/_compiler.cpython-312.pyc","python/lib/python3.12/re/__pycache__/_constants.cpython-312.pyc","python/lib/python3.12/re/__pycache__/_parser.cpython-312.pyc"]`.
```

You will:

1. Download, install and run **Process Monitor** from [Microsoft Learn - Sysinternals](https://learn.microsoft.com/en-us/sysinternals/downloads/procmon).
2. Set Filters:

   - Go to `Filter > Filter...` (or press Ctrl+L).
   - In the "Process Monitor Filter" dialog box, click the **Reset** button if it is enabled to clear any previous filters.
   - Configure the two filters:
     - For the file/path:
       - Set the dropdowns to Path contains and type the specific filename or directory path you want to monitor (e.g., `C:\Users\YourUser\Desktop\testfile.txt` or `C:\Temp\`).
       - Ensure the last dropdown is set to `Include`.
       - Click Add.
     - For the operation:
       - Change the fields to Operation is `CreateFile` (this captures when a file is opened for creation).
       - Ensure the last dropdown is set to `Include`.
       - Click Add.
   - Optional: Check the option `Drop Filtered Events` to prevent capturing irrelevant data, but only if the build takes a long time and the events overwhelms your Windows machine.
   - Click Apply and OK.

3. Capture the Event:

   - Prepare the scenario that leads to the file creation (e.g., get the creating application ready).
   - Start capturing events by pressing Ctrl+E or clicking the magnifying glass icon.
   - Immediately perform the action that creates the file.
   - As soon as the file is created, stop the capture by pressing Ctrl+E again.
   - Analyze the Results:
   - Scroll through the captured events in the main window.
   - Look for an event with the Operation of CreateFile or WriteFile that matches the file path you specified.
   - The Process Name column will show the name of the executable (e.g., notepad.exe) responsible for creating the file.
   - The PID column shows the process ID, and the Details column offers additional information.

4. Save the Log (Optional):

   - Go to File > Save.
   - Select "Events displayed using current filter" and choose "Native Process Monitor Format (.PML)" to save the log file for later analysis.

In the example the above guidance did not show the process. So a second method was used:

1. Run **Process Monitor**
2. Set Filters:

   - One filter (`Operation` `is` `Process Create`) so you can see what and when programs are being launched.

#### AVOID Visual Studio Code - Python - ms-python.python

The **Python extension for Visual Studio Code**:

```text
Name: Python
Id: ms-python.python
Description: Python language support with extension access points for IntelliSense (Pylance), Debugging (Python Debugger), linting, formatting, refactoring, unit tests, and more.
Version: 2026.2.0
Publisher: Microsoft
VS Marketplace Link: https://marketplace.visualstudio.com/items?itemName=ms-python.python
```

When running a `dk0` command inside a folder where VS Code is running, and the `dk0` package creates or downloads a `python.exe`, you get the following:

```text
Could not verify `CommonsBase_LLVM.Toolchain.MinGW@21.1.8+bn-20250101000000.rev-20251216 -s Release.Windows_x86_64` because the ${SLOT.Release.Windows_x86_64} directory has extra files not declared in `outputs.assets`: `["python/lib/python3.12/__pycache__/copyreg.cpython-312.pyc","python/lib/python3.12/__pycache__/enum.cpython-312.pyc","python/lib/python3.12/__pycache__/functools.cpython-312.pyc","python/lib/python3.12/__pycache__/keyword.cpython-312.pyc","python/lib/python3.12/__pycache__/operator.cpython-312.pyc","python/lib/python3.12/__pycache__/reprlib.cpython-312.pyc","python/lib/python3.12/__pycache__/types.cpython-312.pyc","python/lib/python3.12/collections/__pycache__/__init__.cpython-312.pyc","python/lib/python3.12/encodings/__pycache__/__init__.cpython-312.pyc","python/lib/python3.12/encodings/__pycache__/aliases.cpython-312.pyc","python/lib/python3.12/encodings/__pycache__/cp1252.cpython-312.pyc","python/lib/python3.12/encodings/__pycache__/utf_8.cpython-312.pyc","python/lib/python3.12/json/__pycache__/__init__.cpython-312.pyc","python/lib/python3.12/json/__pycache__/decoder.cpython-312.pyc","python/lib/python3.12/json/__pycache__/encoder.cpython-312.pyc","python/lib/python3.12/json/__pycache__/scanner.cpython-312.pyc","python/lib/python3.12/re/__pycache__/__init__.cpython-312.pyc","python/lib/python3.12/re/__pycache__/_casefix.cpython-312.pyc","python/lib/python3.12/re/__pycache__/_compiler.cpython-312.pyc","python/lib/python3.12/re/__pycache__/_constants.cpython-312.pyc","python/lib/python3.12/re/__pycache__/_parser.cpython-312.pyc"]`.
```

You can either:

1. Ask the package author to add a `__pycache__` removal step:

   ```json
    "function": {
        "commands": [
          [ 
            // the existing package build steps, if any
          ],

          // Remove files from __pycache__ folders in the output.
          // - ex. python/lib/python3.12/__pycache__/enum.cpython-312.pyc
          // - mitigates Visual Studio Code extension `ms-python.python` for Python that compiles
          //   Python files in any Python environment it detects in the
          //   output folder
          [
              "$(get-object CommonsBase_Std.Fd@10.3.0 -s Release.execution_abi -m ./fd.exe -e '*' -f fd.exe)",
              "--glob", "--type", "d",
              "-X",
              "$(get-object CommonsBase_Std.Coreutils@0.2.2 -s Release.execution_abi -m ./coreutils.exe -e '*' -f coreutils.exe)",
              "rm", "-rf", "{}", ";", "--",
              "__pycache__",
              "${SLOT.request}"
          ]
        ]
    },
   ```

2. Close Visual Studio Code before running the `dk0` command that triggers the "extra files" error.
3. Disable the `ms-python.python` extension in your Workspace. You will not be able to develop Python in your project.
4. Uninstall the `ms-python.python` extension (not recommended!). You will not be able to develop Python in any of your VS Code projects.

---

The resolution was due to the [procmon analysis](#finding-background-programs-on-windows-that-create-extra-files):

```text
Operation: Process Create

    Process
    Command Line:
    c:\Users\UUU\.vscode\extensions\ms-python.python-2026.2.0-win32-x64\python-env-tools\bin\pet.exe server

    Stack
    Frame | Location                    | Path
    [4]   | ZwCreateUserProcess + 0x14  |
    [8]   | pet.exe + X                 | c:\Users\UUU\.vscode\extensions\ms-python.python-2026.2.0-win32-x64\python-env-tools\bin\pet.exe

    Event
    Command Line:
    "Y:\XXXX\t\p\476\l5ph\o\Release.Windows_x86_64\python\lib\python3.12\venv\scripts\nt\python.exe" -c "import json, sys; print('093385e9-59f7-4a16-a604-14bf206256fe');print(json.dumps({'version': '.'.join(str(n) for n in sys.version_info), 'sys_prefix': sys.prefix, 'executable': sys.executable, 'is64_bit': sys.maxsize > 2**32}))"

Operation: Process Create

    Process
    Command Line:
    c:\Users\UUU\.vscode\extensions\ms-python.python-2026.2.0-win32-x64\python-env-tools\bin\pet.exe server

    Stack
    Frame | Location                    | Path
    [4]   | ZwCreateUserProcess + 0x14  |
    [8]   | pet.exe + X                 | c:\Users\UUU\.vscode\extensions\ms-python.python-2026.2.0-win32-x64\python-env-tools\bin\pet.exe

    Event
    Command Line:
    "Y:\XXXX\t\p\476\l5ph\o\Release.Windows_x86_64\python\bin\python.exe" -c "import json, sys; print('093385e9-59f7-4a16-a604-14bf206256fe');print(json.dumps({'version': '.'.join(str(n) for n in sys.version_info), 'sys_prefix': sys.prefix, 'executable': sys.executable, 'is64_bit': sys.maxsize > 2**32}))"
```

The obvious mitigations did not work:

1. Disable all the `ms-python.python` extension settings, change the `**/*.py` `python.testing.autoTestDiscoverOnSavePattern` setting, and then `Developer: Reload Window` and `Developer: Restart Extensions`
2. Exclude the `dk0` work directories (`t/p/<PID>`) from VS Code with `.vscode/settings.json`:

   ```json
   "files.exclude": {
        "**/.git": true,
        // ...
        "**/t/p": true
   },
   ```

So we conclude that `ms-python.python` precompiles all `.py` in any Python environment it discovered in the workspace.
