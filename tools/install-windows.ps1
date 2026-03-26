# switch to a temp directory
Set-Location $env:TEMP

# in case there is a leftover install-tl-* dir, delete it
Get-ChildItem -Directory -Filter "install-tl-*" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

if (-not $env:CTAN_REPO) {
  $TLREPO = 'https://tlnet.yihui.org'
} else {
  $TLREPO = $env:CTAN_REPO
}
$TLURL = "$TLREPO/install-tl.zip"

# download install-tl.zip and unzip it
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest $TLURL -OutFile install-tl.zip
Add-Type -A 'System.IO.Compression.FileSystem'
[IO.Compression.ZipFile]::ExtractToDirectory('install-tl.zip', '.')
Remove-Item install-tl.zip

# download tinytex.profile and modify it (set texdir to ./TinyTeX)
Invoke-WebRequest 'https://tinytex.yihui.org/tinytex.profile' -OutFile tinytex.profile
(Get-Content tinytex.profile) -replace '\./', './TinyTeX/' | Out-File -Encoding ASCII tinytex.profile
Add-Content -Encoding ASCII tinytex.profile 'TEXMFCONFIG $TEXMFSYSCONFIG'
Add-Content -Encoding ASCII tinytex.profile 'TEXMFVAR $TEXMFSYSVAR'

# download the custom package list
Invoke-WebRequest 'https://tinytex.yihui.org/pkgs-custom.txt' -OutFile pkgs-custom.txt

# an automated installation of TeXLive (infrastructure only)
Set-Location (Get-Item "install-tl-*" | Select-Object -First 1)
cmd /c "echo. | install-tl-windows.bat -no-gui -profile=../tinytex.profile -repository $TLREPO"
if ($LASTEXITCODE -ne 0) { throw "TeX Live installation failed with exit code $LASTEXITCODE" }

Remove-Item TinyTeX\install-tl.log -ErrorAction SilentlyContinue
Remove-Item ..\tinytex.profile -ErrorAction SilentlyContinue
Remove-Item install-tl -ErrorAction SilentlyContinue
Remove-Item install-tl-windows.bat -ErrorAction SilentlyContinue

# TeXLive installed to ./TinyTeX; move it to APPDATA
# remove twice in case the first attempt fails (e.g., directory is locked)
Remove-Item "$env:APPDATA\TinyTeX" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:APPDATA\TinyTeX" -Recurse -Force -ErrorAction SilentlyContinue
Move-Item TinyTeX "$env:APPDATA" -Force
# a token to differentiate TinyTeX with other TeX Live distros
New-Item -ItemType File "$env:APPDATA\TinyTeX\.tinytex" -Force | Out-Null

# clean up the install-tl-* directory
Set-Location $env:TEMP
Get-ChildItem -Directory -Filter "install-tl-*" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

# install all custom packages
$pkgs = Get-Content pkgs-custom.txt
Remove-Item pkgs-custom.txt

Push-Location (Get-Item "$env:APPDATA\TinyTeX\bin\win*" | Select-Object -First 1)
& .\tlmgr.bat conf texmf max_print_line 10000
& .\tlmgr.bat path add
& .\tlmgr.bat install @pkgs
if ($LASTEXITCODE -ne 0) { throw "tlmgr install failed with exit code $LASTEXITCODE" }
Pop-Location

Read-Host 'Press Enter to continue'
