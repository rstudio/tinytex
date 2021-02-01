where /q powershell || echo powershell not found && exit /b

rem switch to a temp directory, whichever works
cd /d "%TMP%"
cd /d "%TEMP%"

rem in case there is a leftover TinyTeX* dir, delete it
for /d %%G in ("TinyTeX*") do rd /s /q "%%~G"

if not defined TINYTEX_INSTALLER set TINYTEX_INSTALLER=TinyTeX-1

if not defined TINYTEX_VERSION (
  set TINYTEX_URL=https://yihui.org/tinytex/%TINYTEX_INSTALLER%.zip
) else (
  set TINYTEX_URL=https://github.com/yihui/tinytex-releases/releases/download/v%TINYTEX_VERSION%/%TINYTEX_INSTALLER%-v%TINYTEX_VERSION%.zip
)

rem download the zip package - retry 5 times if issues
set /a retry=0
:download
if %retry% leq 5 (
  powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest $Env:TINYTEX_URL -OutFile install.zip"
  if errorlevel 1 (
    echo Retrying download... attempt %retry%
    set /a retry+=1
    goto download
  )
  echo Download succeeded
) else (
  echo TinyTeX zip installer not downloaded
  goto :exit
)

rem unzip it
powershell -Command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::ExtractToDirectory('install.zip', '.'); }"
del install.zip

rd /s /q "%APPDATA%\TinyTeX"
rd /s /q "%APPDATA%\TinyTeX"
move /y TinyTeX "%APPDATA%"

call "%APPDATA%\TinyTeX\bin\win32\tlmgr" path add

pause

:exit
exit /b %ERRORLEVEL%
