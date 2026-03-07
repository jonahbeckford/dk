@ECHO OFF

REM Change drive and directory
CD /d C:\src\NotInriaCaml_Std\w64devkit\5.4.1\src
IF ERRORLEVEL 1 (
    ECHO Failed to change directory
    EXIT /B 1
)

REM Run the command passed as arguments to this script
%*
IF ERRORLEVEL 1 (
    ECHO Command failed: %*
    EXIT /B 1
)
EXIT /B 0
