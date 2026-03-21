@echo off
echo === Kutoot - Build APK ===
echo.
echo Building release APK...
echo Default API: https://dev.kutoot.com/api/v1
echo.
echo For LOCAL backend on physical phone, use:
echo   build_apk_local.bat
echo   (Uses your PC IP - phone must be on same WiFi)
echo.
cd /d "%~dp0"
C:\flutter\flutter\bin\flutter.bat build apk
if %ERRORLEVEL% EQU 0 (
  echo.
  echo === BUILD SUCCESS ===
  echo APK location: build\app\outputs\flutter-apk\app-release.apk
  echo.
  echo Copy to your phone via USB or share, then install.
) else (
  echo.
  echo Build failed. Check errors above.
)
pause
