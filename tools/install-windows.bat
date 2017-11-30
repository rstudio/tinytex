rem switch to a temp directory, whichever works
cd /d "%TMP%"
cd /d "%TEMP%"
cd /d "%TMPDIR%"

for /d %%G in ("install-tl-*") do rd /s /q "%%~G"
powershell -Command "Invoke-WebRequest http://mirror.ctan.org/systems/texlive/tlnet/install-tl.zip -OutFile install-tl.zip"
powershell -Command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::ExtractToDirectory('install-tl.zip', '.'); }"
del install-tl.zip
powershell -Command "Invoke-WebRequest https://github.com/yihui/tinytex/raw/master/tools/texlive.profile -OutFile texlive.profile"
powershell -Command "(gc texlive.profile) -replace './', './TinyTex/' | Out-File -encoding ASCII texlive.profile"
powershell -Command "Invoke-WebRequest https://github.com/yihui/tinytex/raw/master/tools/pkgs-custom.txt -OutFile pkgs-custom.txt"

cd install-tl-*
@echo | install-tl-windows.bat -profile=../texlive.profile

del TinyTeX\install-tl.log ..\texlive.profile

rd /s /q "%APPDATA%\TinyTeX"
rd /s /q "%APPDATA%\TinyTeX"
move /y TinyTeX "%APPDATA%"

cd ..
for /d %%G in ("install-tl-*") do rd /s /q "%%~G"

@echo off
setlocal enabledelayedexpansion
set "pkgs="
for /F %%a in (pkgs-custom.txt) do set "pkgs=!pkgs! %%a"
@echo on

del pkgs-custom.txt

"%APPDATA%\TinyTeX\bin\win32\tlmgr" path add && "%APPDATA%\TinyTeX\bin\win32\tlmgr" install latex-bin xetex %pkgs%

pause
