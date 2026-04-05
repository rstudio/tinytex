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

# in case there is a leftover TinyTeX* dir, delete it
rd TinyTeX* -r -fo -ErrorAction SilentlyContinue

if (-not $env:TINYTEX_INSTALLER) { $env:TINYTEX_INSTALLER = 'TinyTeX-1' }

# install to TINYTEX_DIR, which is APPDATA by default if it doesn't contain spaces or
# non-ASCII chars, otherwise use ProgramData
if (-not $env:TINYTEX_DIR) {
  $env:TINYTEX_DIR = if ($env:APPDATA -match '^[!-~]+$') { $env:APPDATA } else { $env:ProgramData }
}

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
Invoke-DownloadWithRetry $TinyTeXURL $DownloadedFile

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
if ($args[0]) {
  move $DownloadedFile "$($args[0])\$DownloadedFile"
} else {
  del $DownloadedFile -Force -ErrorAction SilentlyContinue
}

# in case it was installed to APPDATA previously
rd $env:APPDATA\TinyTeX -r -fo -ErrorAction SilentlyContinue

rd $env:TINYTEX_DIR\TinyTeX -r -fo -ErrorAction SilentlyContinue
rd $env:TINYTEX_DIR\TinyTeX -r -fo -ErrorAction SilentlyContinue
move TinyTeX $env:TINYTEX_DIR

# add tlmgr to PATH
Write-Host 'add tlmgr to PATH'
$tlmgr = "$env:TINYTEX_DIR\TinyTeX\bin\windows\tlmgr.bat"
& $tlmgr path add
& $tlmgr postaction install script xetex
