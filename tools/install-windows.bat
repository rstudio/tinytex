where /q powershell || echo powershell not found && exit /b

rem switch to a temp directory, whichever works
cd /d "%TMP%"
cd /d "%TEMP%"

rem in case there is a leftover install-tl-* dir, delete it
for /d %%G in ("install-tl-*") do rd /s /q "%%~G"

rem download install-tl.zip and unzip it
powershell -Command "Invoke-WebRequest http://mirror.ctan.org/systems/texlive/tlnet/install-tl.zip -OutFile install-tl.zip"
powershell -Command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::ExtractToDirectory('install-tl.zip', '.'); }"
del install-tl.zip

rem download texlive.profile and modify it (set texdir to ./TinyTeX)
powershell -Command "Invoke-WebRequest https://github.com/yihui/tinytex/raw/master/tools/texlive.profile -OutFile texlive.profile"
powershell -Command "(gc texlive.profile) -replace './', './TinyTex/' | Out-File -encoding ASCII texlive.profile"

rem download the custom package list
powershell -Command "Invoke-WebRequest https://github.com/yihui/tinytex/raw/master/tools/pkgs-custom.txt -OutFile pkgs-custom.txt"

rem an automated installation of TeXLive (infrastructure only)
cd install-tl-*
@echo | install-tl-windows.bat -profile=../texlive.profile

del TinyTeX\install-tl.log ..\texlive.profile

rem TeXLive installed to ./TinyTeX; move it to APPDATA
rd /s /q "%APPDATA%\TinyTeX"
rd /s /q "%APPDATA%\TinyTeX"
move /y TinyTeX "%APPDATA%"

rem clean up the install-tl-* directory
cd ..
for /d %%G in ("install-tl-*") do rd /s /q "%%~G"

rem install all custom packages
@echo off
setlocal enabledelayedexpansion
set "pkgs="
for /F %%a in (pkgs-custom.txt) do set "pkgs=!pkgs! %%a"
@echo on

del pkgs-custom.txt

"%APPDATA%\TinyTeX\bin\win32\tlmgr" path add && "%APPDATA%\TinyTeX\bin\win32\tlmgr" install latex-bin xetex %pkgs%

rem TODO: the above line will make this batch file exit prematurely, but I don't know why
pause
