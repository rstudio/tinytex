where /q powershell || echo powershell not found && exit /b

rem switch to a temp directory, whichever works
cd /d "%TMP%"
cd /d "%TEMP%"

rem in case there is a leftover TinyTeX* dir, delete it
for /d %%G in ("TinyTeX*") do rd /s /q "%%~G"

rem download the zip package and unzip it
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest https://yihui.org/tinytex/TinyTeX-1.zip -OutFile install.zip"
powershell -Command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::ExtractToDirectory('install.zip', '.'); }"
del install.zip

rd /s /q "%APPDATA%\TinyTeX"
move /y TinyTeX "%APPDATA%"

pause
