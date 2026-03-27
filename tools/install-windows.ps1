$ErrorActionPreference = 'Stop'

# switch to a temp directory
cd $env:TEMP
[Environment]::CurrentDirectory = $PWD.Path

# in case there is a leftover install-tl-* dir, delete it
rd install-tl-* -r -fo -ErrorAction SilentlyContinue

$TLREPO = if ($env:CTAN_REPO) { $env:CTAN_REPO } else { 'https://tlnet.yihui.org' }
$TLURL = "$TLREPO/install-tl.zip"

# download install-tl.zip and unzip it
Invoke-WebRequest $TLURL -OutFile install-tl.zip
Add-Type -A 'System.IO.Compression.FileSystem'
[IO.Compression.ZipFile]::ExtractToDirectory('install-tl.zip', '.')
del install-tl.zip

# download tinytex.profile and modify it (set texdir to ./TinyTeX)
Invoke-WebRequest 'https://tinytex.yihui.org/tinytex.profile' -OutFile tinytex.profile
Add-Content tinytex.profile 'TEXMFCONFIG $TEXMFSYSCONFIG'
Add-Content tinytex.profile 'TEXMFVAR $TEXMFSYSVAR'

# download the custom package list
Invoke-WebRequest 'https://tinytex.yihui.org/pkgs-custom.txt' -OutFile pkgs-custom.txt

# an automated installation of TeXLive (infrastructure only)
cd install-tl-*
(Get-Content install-tl-windows.bat) -notmatch '^\s*pause\s*$' | Set-Content install-tl-windows.bat
mkdir TinyTeX
cd TinyTeX
& ..\install-tl-windows.bat -no-gui -profile=..\..\tinytex.profile -repository $TLREPO

# a token to differentiate TinyTeX with other TeX Live distros
ni .tinytex | Out-Null
cd ..

del TinyTeX\install-tl.log, ..\tinytex.profile, install-tl, install-tl-windows.bat -ErrorAction SilentlyContinue

# TeXLive installed to ./TinyTeX; move it to APPDATA
rd $env:APPDATA\TinyTeX -r -fo -ErrorAction SilentlyContinue
rd $env:APPDATA\TinyTeX -r -fo -ErrorAction SilentlyContinue
move TinyTeX $env:APPDATA

# clean up the install-tl-* directory
cd ..
rd install-tl-* -r -fo -ErrorAction SilentlyContinue

# install all custom packages
$pkgs = gc pkgs-custom.txt
del pkgs-custom.txt

$tlmgr = "$env:APPDATA\TinyTeX\bin\windows\tlmgr.bat"
& $tlmgr conf texmf max_print_line 10000
& $tlmgr path add
& $tlmgr install @pkgs

pause
