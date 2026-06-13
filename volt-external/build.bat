@echo off
REM Build Volt External with the MSVC toolchain.
REM Run from a "x64 Native Tools Command Prompt for VS".
REM
REM   cd volt-external
REM   build.bat
REM
REM Output: build\Volt.exe

setlocal
where cl >nul 2>nul
if errorlevel 1 (
    echo [Volt] MSVC compiler 'cl' not found.
    echo        Open "x64 Native Tools Command Prompt for VS" and re-run.
    exit /b 1
)

if not exist build mkdir build

cl /std:c++17 /EHsc /O2 /W4 /utf-8 /nologo ^
   /Fe:build\Volt.exe /Fo:build\ ^
   src\main.cpp src\App.cpp src\Store.cpp src\UI.cpp src\Renderer.cpp src\Bridge.cpp ^
   /link /SUBSYSTEM:WINDOWS d2d1.lib dwrite.lib user32.lib gdi32.lib ole32.lib

if errorlevel 1 (
    echo [Volt] Build failed.
    exit /b 1
)
echo [Volt] Built build\Volt.exe
endlocal
