@echo off
title Build EXE Compressor
echo ========================================
echo  Building EXE Compressor
echo ========================================

:: Install dependencies
echo Installing dependencies...
pip install pyinstaller tkinterdnd2 --quiet

:: Build
echo Building...
pyinstaller ^
  --onefile ^
  --windowed ^
  --name "EXE_Compressor" ^
  --icon NONE ^
  --hidden-import tkinterdnd2 ^
  --collect-all tkinterdnd2 ^
  exe_compressor.py

echo.
if exist "dist\EXE_Compressor.exe" (
    echo ========================================
    echo  SUCCESS: dist\EXE_Compressor.exe
    echo ========================================
    explorer dist
) else (
    echo BUILD FAILED — check output above
)
pause
