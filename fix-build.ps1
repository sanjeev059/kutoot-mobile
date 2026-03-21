# Fix Flutter Android build - run this script, then: flutter run -d emulator-5554

Write-Host "Cleaning Flutter project..." -ForegroundColor Cyan
flutter clean

Write-Host "`nDeleting project build caches..." -ForegroundColor Cyan
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$PSScriptRoot\build"
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$PSScriptRoot\android\.gradle"
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$PSScriptRoot\android\build"
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$PSScriptRoot\android\app\build"

Write-Host "Deleting corrupted Kotlin cache in Flutter SDK..." -ForegroundColor Cyan
$flutterGradleBuild = "C:\flutter\flutter\packages\flutter_tools\gradle\build"
if (Test-Path $flutterGradleBuild) {
    Remove-Item -Recurse -Force $flutterGradleBuild
    Write-Host "  Deleted: $flutterGradleBuild" -ForegroundColor Green
} else {
    Write-Host "  Path not found (may use different Flutter install)" -ForegroundColor Yellow
}

Write-Host "`nClearing Gradle daemon..." -ForegroundColor Cyan
cd $PSScriptRoot\android
.\gradlew.bat --stop 2>$null

Write-Host "`nRunning flutter pub get..." -ForegroundColor Cyan
cd $PSScriptRoot
flutter pub get

Write-Host "`nDone! Now run: flutter run -d emulator-5554" -ForegroundColor Green
