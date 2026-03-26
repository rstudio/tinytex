where /q powershell || echo PowerShell not found && exit /b

cd /d "%TEMP%"

powershell -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest 'https://tinytex.yihui.org/install-windows.ps1' -OutFile 'install-windows.ps1'"
powershell -ExecutionPolicy Bypass -File "%TEMP%\install-windows.ps1"
del "%TEMP%\install-windows.ps1"
