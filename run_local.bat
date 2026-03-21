@echo off
echo === Kutoot Mobile - Local API Mode ===
echo Using backend at http://10.0.2.2:8000/api/v1 (Android emulator)
echo.
echo Make sure Docker backend is running: docker compose up -d
echo.
cd /d "%~dp0"
C:\flutter\flutter\bin\flutter.bat run -d emulator-5554 --dart-define=KUTOOT_API_URL=http://10.0.2.2:8000/api/v1
pause
