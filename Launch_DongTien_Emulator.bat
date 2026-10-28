@echo off
title Dong Tien - Android 14 Emulator Launcher
set SDK_ROOT=C:\Users\coihu12\Android\Sdk
set ADB=%SDK_ROOT%\platform-tools\adb.exe
set EMULATOR=%SDK_ROOT%\emulator\emulator.exe
set AEHD_DIR=%SDK_ROOT%\extras\google\Android_Emulator_Hypervisor_Driver

REM Prioritize lean split-per-ABI release APK (x86_64 for PC emulator)
set APK_PATH=c:\Users\coihu12\Documents\App\build\app\outputs\flutter-apk\app-x86_64-release.apk
if not exist "%APK_PATH%" (
    set APK_PATH=c:\Users\coihu12\Documents\App\build\app\outputs\flutter-apk\app-release.apk
)
if not exist "%APK_PATH%" (
    set APK_PATH=c:\Users\coihu12\Documents\App\build\app\outputs\flutter-apk\app-debug.apk
)

echo ============================================================================
echo   DONG TIEN (vn.dongtien) - ANDROID 14 (PIXEL 6) EMULATOR LAUNCHER
echo ============================================================================

REM 1. Check if Android Emulator Hypervisor Driver (aehd) is installed and running
"%SDK_ROOT%\emulator\emulator-check.exe" accel >nul 2>&1
if ERRORLEVEL 1 (
    echo [1/4] Installing Android Emulator Hypervisor Driver ^(requires Admin once^)...
    powershell -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/c cd /d \"%AEHD_DIR%\" && RUNDLL32.EXE SETUPAPI.DLL,InstallHinfSection DefaultInstall 132 .\aehd.Inf && sc start aehd' -Verb RunAs -Wait"
)

echo [2/4] Starting Android 14 Virtual Device ^(DongTien_Pixel_API34^)...
start "" "%EMULATOR%" -avd DongTien_Pixel_API34 -gpu host -no-metrics

echo [3/4] Waiting for Android 14 to finish booting...
"%ADB%" wait-for-device
:wait_boot
for /f "delims=" %%i in ('"%ADB%" shell getprop sys.boot_completed 2^>nul') do set BOOTED=%%i
if not "%BOOTED%"=="1" (
    timeout /t 2 /nobreak >nul
    goto wait_boot
)

echo [4/4] Installing %APK_PATH% and launching Dong Tien...
"%ADB%" install -r "%APK_PATH%"
"%ADB%" shell monkey -p vn.dongtien -c android.intent.category.LAUNCHER 1

echo.
echo ============================================================================
echo   SUCCESS! Dong Tien is now running on your Android 14 Emulator!
echo ============================================================================
pause
