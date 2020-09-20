where /q powershell || echo powershell not found && exit /b

rem switch to a temp directory, whichever works
cd /d "%TMP%"
cd /d "%TEMP%"

rem in case there is a leftover TinyTeX* dir, delete it
for /d %%G in ("TinyTeX*") do rd /s /q "%%~G"

if not defined TINYTEX_INSTALLER set TINYTEX_INSTALLER=TinyTeX-1

if not defined TINYTEX_VERSION (
  set TINYTEX_URL=https://yihui.org/tinytex/%TINYTEX_INSTALLER%
) else (
  set TINYTEX_URL=https://github.com/yihui/tinytex-releases/releases/download/v%TINYTEX_VERSION%/%TINYTEX_INSTALLER%-v%TINYTEX_VERSION%
)

rem download the zip package and unzip it
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest $($Env:TINYTEX_URL).zip -OutFile install.zip"
powershell -Command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::ExtractToDirectory('install.zip', '.'); }"
del install.zip

rd /s /q "%APPDATA%\TinyTeX"
move /y TinyTeX "%APPDATA%"

pause
