$ErrorActionPreference = 'Stop'

function Invoke-DownloadWithRetry {
  param([string]$Uri, [string]$OutFile, [int]$MaxRetries = 10, [int]$RetryDelay = 30)
  for ($i = 1; $i -le ($MaxRetries + 1); $i++) {
    try {
      Invoke-WebRequest $Uri -OutFile $OutFile
      return
    } catch {
      if ($i -gt $MaxRetries) { throw }
      Write-Host "Download failed (attempt $i of $($MaxRetries + 1)), retrying in $RetryDelay seconds..."
      Start-Sleep -Seconds $RetryDelay
    }
  }
}

# switch to a temp directory
cd $env:TEMP
[Environment]::CurrentDirectory = $PWD.Path

# in case there is a leftover install-tl-* dir, delete it
rd install-tl-* -r -fo -ErrorAction SilentlyContinue

$TLREPO = if ($env:CTAN_REPO) { $env:CTAN_REPO } else { 'https://tlnet.yihui.org' }
$TLURL = "$TLREPO/install-tl.zip"

# download install-tl.zip and unzip it
Invoke-DownloadWithRetry $TLURL install-tl.zip
Add-Type -A 'System.IO.Compression.FileSystem'
[IO.Compression.ZipFile]::ExtractToDirectory('install-tl.zip', '.')
del install-tl.zip

# download tinytex.profile and modify it (set texdir to ./TinyTeX)
Invoke-DownloadWithRetry 'https://tinytex.yihui.org/tinytex.profile' tinytex.profile
Add-Content tinytex.profile 'TEXMFCONFIG $TEXMFSYSCONFIG'
Add-Content tinytex.profile 'TEXMFVAR $TEXMFSYSVAR'

# download the custom package list
Invoke-DownloadWithRetry 'https://tinytex.yihui.org/pkgs-custom.txt' pkgs-custom.txt

# an automated installation of TeX Live (infrastructure only)
cd install-tl-*
(Get-Content install-tl-windows.bat) -notmatch '^\s*pause\s*$' | Set-Content install-tl-windows.bat
mkdir TinyTeX
cd TinyTeX
$env:TEXLIVE_INSTALL_ENV_NOCHECK=true
$env:TEXLIVE_INSTALL_NO_WELCOME=true
& ..\install-tl-windows.bat -no-gui -profile=..\..\tinytex.profile -repository $TLREPO

# a token to differentiate TinyTeX with other TeX Live distros
ni .tinytex | Out-Null

del install-tl.log, install-tl, install-tl-windows.bat -ErrorAction SilentlyContinue
cd ..

# TeX Live installed to ./TinyTeX; move it to APPDATA
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
