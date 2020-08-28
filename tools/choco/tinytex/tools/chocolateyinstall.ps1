$ErrorActionPreference = 'stop'; # stop on all errors
 
$toolsDirActual  = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$toolsDir = "$($env:TMP)\Texlive"
$texliveInstall = "http://mirrors.ctan.org/systems/texlive/tlnet/install-tl.zip"
$profileUrl = "https://yihui.org/gh/tinytex/tools/tinytex.profile"
$pkgcustom = "https://yihui.org/gh/tinytex/tools/pkgs-custom.txt"
$luatexmirror = "http://mirror.ctan.org/tex-archive/systems/texlive/tlnet/archive/luatex.win32.tar.xz"

Get-WebFile `
-Url $texliveInstall `
-FileName "$toolsDir\\install-tl.zip"

Get-ChocolateyUnzip `
-FileFullPath "$toolsDir\\install-tl.zip" `
-Destination "$toolsDir\\tinytex"

#Remove the zip file
Remove-Item "$toolsDir\\install-tl.zip"

#download tinytex.profile and modify it (set texdir to ./TinyTeX)
Get-WebFile `
-FileName "$toolsDir\\tinytex\\tinytex.profile" `
-Url $profileUrl

(gc "$toolsDir\\tinytex\\tinytex.profile") -replace '\./', './TinyTex/' | Out-File -encoding ASCII "$toolsDir\\tinytex\\tinytex.profile"

Add-Content -Path "$toolsDir\\tinytex\\tinytex.profile" -Value 'TEXMFCONFIG $TEXMFSYSCONFIG'
Add-Content -Path "$toolsDir\\tinytex\\tinytex.profile" -Value 'TEXMFHOME $TEXMFLOCAL'
Add-Content -Path "$toolsDir\\tinytex\\tinytex.profile" -Value 'TEXMFVAR $TEXMFSYSVAR'

#download the custom package list
Get-WebFile `
-FileName "$toolsDir\\tinytex\\pkgs-custom.txt" `
-Url $pkgcustom
foreach ($c in (gc "$toolsDir\\tinytex\\pkgs-custom.txt").split()){
    $pkgs="$pkgs $c"
}

#download luatex to prevent popups See https://github.com/chocolatey/choco/issues/386
Get-WebFile `
-FileName "$toolsDir\\luatex.win32.tar.xz" `
-Url $luatexmirror

Get-ChocolateyUnzip `
-FileFullPath "$toolsDir\\luatex.win32.tar.xz" `
-Destination "$toolsDir\\luatex"

Get-ChocolateyUnzip `
-FileFullPath "$toolsDir\\luatex\\luatex.win32.tar" `
-Destination "$toolsDir\\luatex"

$PREVPATH = $env:PATH
$env:PATH="$($toolsDir)\luatex\bin\win32;$ENV:PATH"

#an automated installation of TeXLive (infrastructure only)
Set-Location "$($toolsDir)\tinytex\install-tl-*"
cd "$($toolsDir)\tinytex"
cd "install-tl-*"

Start-Process -FilePath "$($PWD)\install-tl-windows.bat" -ArgumentList "-no-gui -profile=`"$($toolsDir)\tinytex\tinytex.profile`"" -WorkingDirectory "$($PWD)" -NoNewWindow -Wait

Move-Item "$($PWD)\TinyTex" "$($env:APPDATA)\TinyTex"
$appPath = "$($env:APPDATA)"
cd "$toolsDirActual"

#remove temp directory from path and edelete it
Remove-Item "$toolsDir\" -Recurse

$env:PATH = $PREVPATH

Start-Process -ArgumentList "path add" -FilePath "$($appPath)\TinyTex\bin\win32\tlmgr.bat" -NoNewWindow -Wait
Start-Process -ArgumentList "install latex-bin xetex $($pkgs)" -FilePath "$($appPath)\TinyTex\bin\win32\tlmgr.bat" -NoNewWindow -Wait
