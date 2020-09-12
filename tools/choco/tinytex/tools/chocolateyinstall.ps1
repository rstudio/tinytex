$ErrorActionPreference = 'Stop'; # stop on all errors
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'https://yihui.org/tinytex/TinyTeX.zip'
$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  url           = $url
  checksum      = '2c51fa0d402dac3c78bf45d1adebadb21758403eef927b61f0a72c9cb00296d0'
  checksumType  = 'sha256'
}

Install-ChocolateyZipPackage @packageArgs

# Adds to Path
$statementsToRun = "/C `"$toolsDir\TinyTeX\bin\win32\tlmgr.bat path add`""
Start-ChocolateyProcessAsAdmin $statementsToRun "cmd.exe"

$files = get-childitem $installDir -include *.exe -recurse
foreach ($file in $files) {
    New-Item "$file.ignore" -type file -force | Out-Null #We are directly adding it to path so no need to generate shims
}