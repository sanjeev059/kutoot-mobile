@echo off
echo === Fixing Flutter / Pub Cache ===
set FLUTTER=C:\flutter\flutter\bin\flutter.bat
cd /d "%~dp0"

REM Use shorter pub cache path (avoids Windows path length issues)
if not exist C:\pub-cache mkdir C:\pub-cache
set PUB_CACHE=C:\pub-cache

echo.
echo 1. Deleting .dart_tool (forces fresh package resolution)...
if exist .dart_tool rmdir /s /q .dart_tool

echo.
echo 2. Deleting pubspec.lock (optional - gets fresh versions)...
REM if exist pubspec.lock del pubspec.lock

echo.
echo 3. Getting dependencies (downloads to pub cache)...
%FLUTTER% pub get

echo.
echo 4. Cleaning build...
%FLUTTER% clean

echo.
echo 5. Getting dependencies again...
%FLUTTER% pub get

echo.
echo Done. Try: %FLUTTER% run -d chrome --dart-define=KUTOOT_API_URL=http://localhost:8000/api/v1
pause
