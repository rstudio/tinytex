$ErrorActionPreference = 'Stop'

# switch to a temp directory
cd $env:TEMP

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

# download the bundle - method 1
Write-Host "Download $BundleExt file... Method 1"
$downloaded = $false
try {
  Add-Type -A 'System.Net.Http'
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $response = (New-Object System.Net.Http.HttpClient).GetAsync($TinyTeXURL)
  $response.Wait()
  $outputFileStream = [System.IO.FileStream]::new($DownloadedFile, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
  $response.Result.Content.CopyToAsync($outputFileStream).Wait()
  $outputFileStream.Close()
  $downloaded = $true
} catch {}

if (-not $downloaded) {
  # Try another method if the first one failed
  Write-Host "Download $BundleExt file... Method 2"
  try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    (New-Object System.Net.WebClient).DownloadFile($TinyTeXURL, $DownloadedFile)
    $downloaded = $true
  } catch {}
}

if (-not $downloaded) {
  # Try last method
  Write-Host "Download bundle file... Method 3"
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Invoke-WebRequest $TinyTeXURL -OutFile $DownloadedFile
}

# unzip the downloaded file
Write-Host 'Unbundle TinyTeX'
if ($BundleExt -eq 'exe') {
  & ".\$DownloadedFile" -y
  if ($LASTEXITCODE -ne 0) { throw "Failed to extract $DownloadedFile" }
} else {
  Add-Type -A 'System.IO.Compression.FileSystem'
  [IO.Compression.ZipFile]::ExtractToDirectory($DownloadedFile, '.')
}

if ($args[0]) {
  move $DownloadedFile "$($args[0])\$DownloadedFile"
} else {
  del $DownloadedFile
}

# in case it was installed to APPDATA previously
rd $env:APPDATA\TinyTeX -r -fo -ErrorAction SilentlyContinue

rd $env:TINYTEX_DIR\TinyTeX -r -fo -ErrorAction SilentlyContinue
rd $env:TINYTEX_DIR\TinyTeX -r -fo -ErrorAction SilentlyContinue
move TinyTeX $env:TINYTEX_DIR

# add tlmgr to PATH
Write-Host 'add tlmgr to PATH'
$tlmgr = (ls "$env:TINYTEX_DIR\TinyTeX\bin\win*\tlmgr.bat").FullName
& $tlmgr path add
if ($env:CI -ne 'true') { & $tlmgr option repository ctan }
& $tlmgr postaction install script xetex
if ($LASTEXITCODE -ne 0) { throw "tlmgr postaction failed" }
