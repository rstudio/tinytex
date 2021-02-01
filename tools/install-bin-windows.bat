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

rem download the zip package - method 1
echo Download zip file... Method 1
powershell -Command "& { try {Add-Type -A 'System.Net.Http'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $response = (New-Object System.Net.Http.HttpClient).GetAsync($Env:TINYTEX_URL); $response.Wait(); $outputFileStream = [System.IO.FileStream]::new('install.zip', [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write); $response.Result.Content.CopyToAsync($outputFileStream).Wait(); $outputFileStream.Close()} catch {throw $_}}"
if not errorlevel 1 goto unzip

rem Try another method if the first one failed
echo Download zip file... Method 2
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile($Env:TINYTEX_URL, 'install.zip')"
if not errorlevel 1 goto unzip

rem Try last method
echo Download zip file... Method 3
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest $Env:TINYTEX_URL -OutFile install.zip"
if errorlevel 1 exit /b %ERRORLEVEL%

:unzip
rem unzip the downloaded file
echo unzip TinyTeX
powershell -Command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::ExtractToDirectory('install.zip', '.'); }"
del install.zip

echo Move to APPDATA folder
rd /s /q "%APPDATA%\TinyTeX"
rd /s /q "%APPDATA%\TinyTeX"
move /y TinyTeX "%APPDATA%"

echo add tlmgr to PATH
call "%APPDATA%\TinyTeX\bin\win32\tlmgr" path add

exit /b %ERRORLEVEL%
