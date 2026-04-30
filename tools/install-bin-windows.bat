where /q powershell || echo PowerShell not found && exit /b

cd /d "%TEMP%"

curl.exe -fsSLO 'https://tinytex.yihui.org/install-bin-windows.ps1'
powershell -ExecutionPolicy Bypass -File "install-bin-windows.ps1" %*
del "install-bin-windows.ps1"
