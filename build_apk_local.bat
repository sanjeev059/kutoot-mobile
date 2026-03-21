@echo off
echo === Kutoot - Build APK (Local Backend) ===
echo.
echo Enter your PC's IP address (e.g. 192.168.1.5)
echo Find it: ipconfig ^| findstr "IPv4"
echo.
set /p PC_IP=Your PC IP: 
if "%PC_IP%"=="" (
  echo No IP entered. Using 192.168.1.1 as default.
  set PC_IP=192.168.1.1
)
echo.
echo Building APK with API: http://%PC_IP%:8000/api/v1
echo Make sure: 1) Docker backend is running  2) Phone on same WiFi
echo.
cd /d "%~dp0"
C:\flutter\flutter\bin\flutter.bat build apk --dart-define=KUTOOT_API_URL=http://%PC_IP%:8000/api/v1
if %ERRORLEVEL% EQU 0 (
  echo.
  echo === BUILD SUCCESS ===
  echo APK: build\app\outputs\flutter-apk\app-release.apk
) else (
  echo Build failed.
)
pause
