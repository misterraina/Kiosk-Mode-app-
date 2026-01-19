@echo off
echo Finding your local IP address...
echo.
ipconfig | findstr /i "IPv4"
echo.
echo Copy the IPv4 Address shown above and update lib/config/api_config.dart
pause
