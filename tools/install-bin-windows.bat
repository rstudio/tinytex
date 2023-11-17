where /q powershell || echo powershell not found && exit /b

rem switch to a temp directory, whichever works
cd /d "%TMP%"
cd /d "%TEMP%"

rem in case there is a leftover TinyTeX* dir, delete it
for /d %%G in ("TinyTeX*") do rd /s /q "%%~G"

if not defined TINYTEX_INSTALLER set TINYTEX_INSTALLER=TinyTeX-1

rem install to TINYTEX_DIR, which is APPDATA by default if it doesn't contain spaces or non-ASCII chars, otherwise use ProgramData
if not defined TINYTEX_DIR (
  set TINYTEX_DIR=%APPDATA%
  powershell -Command "if ($Env:APPDATA -match '^[!-~]+$') {exit 0} else {exit 1}" || set TINYTEX_DIR=%ProgramData%
)
set BUNDLE_EXT=zip
if "%TINYTEX_INSTALLER%" == "TinyTeX-2" set BUNDLE_EXT=exe

if not defined TINYTEX_VERSION (
  set TINYTEX_URL=https://github.com/rstudio/tinytex-releases/releases/download/daily/%TINYTEX_INSTALLER%.%BUNDLE_EXT%
) else (
  set TINYTEX_URL=https://github.com/rstudio/tinytex-releases/releases/download/v%TINYTEX_VERSION%/%TINYTEX_INSTALLER%-v%TINYTEX_VERSION%.%BUNDLE_EXT%
)

set DOWNLOADED_FILE=install.%BUNDLE_EXT%

rem download the zip package - method 1
echo Download %BUNDLE_EXT% file... Method 1
powershell -Command "& { try {Add-Type -A 'System.Net.Http'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $response = (New-Object System.Net.Http.HttpClient).GetAsync($Env:TINYTEX_URL); $response.Wait(); $outputFileStream = [System.IO.FileStream]::new($Env:DOWNLOADED_FILE, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write); $response.Result.Content.CopyToAsync($outputFileStream).Wait(); $outputFileStream.Close()} catch {throw $_}}"
if not errorlevel 1 goto unzip

rem Try another method if the first one failed
echo Download %BUNDLE_EXT% file... Method 2
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile($Env:TINYTEX_URL, $Env:DOWNLOADED_FILE)"
if not errorlevel 1 goto unzip

rem Try last method
echo Download bundle file... Method 3
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest $Env:TINYTEX_URL -OutFile $Env:DOWNLOADED_FILE"
if errorlevel 1 exit /b %ERRORLEVEL%

:unzip
rem unzip the downloaded file
echo Unbundle TinyTeX
if %BUNDLE_EXT% == exe (
  CALL %DOWNLOADED_FILE% -y
) ELSE (
  powershell -Command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::ExtractToDirectory($Env:DOWNLOADED_FILE, '.'); }"
)
del %DOWNLOADED_FILE%

rem in case it was installed to APPDATA previously
rd /s /q "%APPDATA%\TinyTeX"

rd /s /q "%TINYTEX_DIR%\TinyTeX"
rd /s /q "%TINYTEX_DIR%\TinyTeX"
move /y TinyTeX "%TINYTEX_DIR%"

echo add tlmgr to PATH
cd /d "%TINYTEX_DIR%\TinyTeX\bin\win*"
call tlmgr path add
if /i not "%CI%"=="true" call tlmgr option repository ctan
call tlmgr postaction install script xetex

exit /b %ERRORLEVEL%
