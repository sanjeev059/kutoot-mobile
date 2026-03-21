@echo off
echo === Kutoot Mobile - Chrome + Local API ===
echo Using backend at http://localhost:8000/api/v1
echo.
echo Make sure Docker backend is running: docker compose up -d
echo.
cd /d "%~dp0"
C:\flutter\flutter\bin\flutter.bat run -d chrome --dart-define=KUTOOT_API_URL=http://localhost:8000/api/v1
pause
