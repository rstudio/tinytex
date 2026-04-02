$ErrorActionPreference = 'Stop'

if ($env:TINYTEX_PREVENT_INSTALL -eq 'true') {
  throw "The environment variable 'TINYTEX_PREVENT_INSTALL' was set to 'true', so the installation is aborted."
}

# parse --no-path argument
$AddPath = -not ($args -contains '--no-path')

# switch to a temp directory
cd $env:TEMP
[Environment]::CurrentDirectory = $PWD.Path

# in case there is a leftover TinyTeX* dir, delete it
rd TinyTeX* -r -fo -ErrorAction SilentlyContinue

if (-not $env:TINYTEX_INSTALLER) { $env:TINYTEX_INSTALLER = 'TinyTeX-1' }

# install to TINYTEX_DIR, which is APPDATA by default if it doesn't contain spaces or
# non-ASCII chars, otherwise use ProgramData
if (-not $env:TINYTEX_DIR) {
  $env:TINYTEX_DIR = if ($env:APPDATA -match '^[!-~]+$') { $env:APPDATA } else { $env:ProgramData }
}

# TINYTEX_TEXDIR allows callers (e.g. the R package) to specify the full installation
# path directly; fall back to the traditional TINYTEX_DIR\TinyTeX default
$TargetDir = if ($env:TINYTEX_TEXDIR) { $env:TINYTEX_TEXDIR } else { "$($env:TINYTEX_DIR)\TinyTeX" }

# new naming scheme: TinyTeX-{N}-windows.exe for daily and versions after v2026.03.02
$UseNewNames = $true
if ($env:TINYTEX_VERSION) {
  $UseNewNames = [string]::CompareOrdinal($env:TINYTEX_VERSION, '2026.03.02') -gt 0
}

if ($UseNewNames) {
  $TinyTeXFilename = "$($env:TINYTEX_INSTALLER)-windows"
  $BundleExt = 'exe'
} else {
  $TinyTeXFilename = $env:TINYTEX_INSTALLER
  $BundleExt = if ($env:TINYTEX_INSTALLER -eq 'TinyTeX-2') { 'exe' } else { 'zip' }
}

if (-not $env:TINYTEX_VERSION) {
  $TinyTeXURL = "https://github.com/rstudio/tinytex-releases/releases/download/daily/$TinyTeXFilename.$BundleExt"
} else {
  $TinyTeXURL = "https://github.com/rstudio/tinytex-releases/releases/download/v$($env:TINYTEX_VERSION)/$TinyTeXFilename-v$($env:TINYTEX_VERSION).$BundleExt"
}

$DownloadedFile = "$TinyTeXFilename.$BundleExt"

# download the bundle
Write-Host "Download $BundleExt file..."
Invoke-WebRequest $TinyTeXURL -OutFile $DownloadedFile

# unzip the downloaded file
Write-Host 'Unbundle TinyTeX'
if ($BundleExt -eq 'exe') {
  & ".\$DownloadedFile" -y
  if ($LASTEXITCODE -ne 0) { throw "Failed to extract $DownloadedFile" }
} else {
  Add-Type -A 'System.IO.Compression.FileSystem'
  [IO.Compression.ZipFile]::ExtractToDirectory($DownloadedFile, '.')
}

# save the downloaded file to the output dir (for build-tinytex-2.ps1)
if ($args[0] -and $args[0] -ne '--no-path') {
  move $DownloadedFile "$($args[0])\$DownloadedFile"
} else {
  del $DownloadedFile -Force -ErrorAction SilentlyContinue
}

# in case it was installed to APPDATA previously
rd $env:APPDATA\TinyTeX -r -fo -ErrorAction SilentlyContinue

# remove any existing installation at the target directory
rd $TargetDir -r -fo -ErrorAction SilentlyContinue

# the bundle always extracts to a 'TinyTeX' directory in the current dir (TEMP);
# move it to the parent of TargetDir, then rename if a custom leaf name was requested
$TargetParent = Split-Path $TargetDir -Parent
$TargetLeaf = Split-Path $TargetDir -Leaf
if (-not (Test-Path $TargetParent)) { mkdir $TargetParent -Force | Out-Null }
# remove an existing TinyTeX dir in the target parent that may conflict with the move
rd (Join-Path $TargetParent 'TinyTeX') -r -fo -ErrorAction SilentlyContinue
move TinyTeX $TargetParent
if ($TargetLeaf -ne 'TinyTeX') {
  rename-item (Join-Path $TargetParent 'TinyTeX') $TargetLeaf
}

# add tlmgr to PATH
$tlmgr = "$TargetDir\bin\windows\tlmgr.bat"
& $tlmgr postaction install script xetex
# do not wrap lines in latex log (https://github.com/rstudio/tinytex/issues/322)
& $tlmgr conf texmf max_print_line 10000
if ($AddPath) {
  Write-Host 'add tlmgr to PATH'
  & $tlmgr path add
}
