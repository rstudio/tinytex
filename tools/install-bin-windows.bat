where /q powershell || echo PowerShell not found && exit /b

cd /d "%TEMP%"

powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest 'https://tinytex.yihui.org/install-bin-windows.ps1' -OutFile 'install-bin-windows.ps1'"
powershell -ExecutionPolicy Bypass -File "install-bin-windows.ps1" %*
del "install-bin-windows.ps1"
