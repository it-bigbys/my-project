@echo off
REM Script to run Flutter with a fixed port for consistent OAuth setup

echo.
echo ====================================
echo TeamCollab - Google Drive OAuth Setup
echo ====================================
echo.
echo This script runs Flutter on port 5000 for consistent OAuth configuration.
echo.
echo Before running this, ensure you have added these redirect URIs to Google Cloud Console:
echo   - http://localhost:5000/
echo   - http://127.0.0.1:5000/
echo.
echo See GOOGLE_DRIVE_OAUTH_SETUP.md for detailed instructions.
echo.
pause

echo Starting Flutter on http://localhost:5000...
cd "%~dp0"

REM Run Flutter on fixed port 5000
flutter run -d chrome --web-port=5000

pause
