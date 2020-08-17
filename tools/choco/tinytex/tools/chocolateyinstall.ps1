$ErrorActionPreference = 'Stop'; # stop on all errors
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

$texliveInstall="http://mirrors.ctan.org/systems/texlive/tlnet/install-tl.zip"
$profileUrl = "https://yihui.org/gh/tinytex/tools/tinytex.profile"
$pkgcustom = "https://yihui.org/gh/tinytex/tools/pkgs-custom.txt"

$installTLFileLoc = Get-ChocolateyWebFile `
  -PackageName "texlive" `
  -FileFullPath "$toolsDir\install-tl.zip" `
  -Url $texliveInstall `
  -Checksum "1a7601c1a33276731a56aba24e55b775eb2a6e417f24dd106f8ead5ad432b10b0bd80947ddbe85840e761887b7c10b84f5218d61b3640900998734b71b6c4b61" `
  -ChecksumType sha512

Get-ChocolateyUnzip `
  -FileFullPath $installTLFileLoc `
  -Destination "$toolsDir\install-tl" `
  -PackageName "texlive" `

#Remove the zip file
Remove-Item $installTLFileLoc

#download tinytex.profile and modify it (set texdir to ./TinyTeX)
Get-ChocolateyWebFile `
  -PackageName "texlive" `
  -FileFullPath "$toolsDir\tinytex.profile" `
  -Url $profileUrl `
(gc "$toolsDir\tinytex.profile") -replace '\./', './TinyTex/' | Out-File -encoding ASCII tinytex.profile

#I don't the the powershell command for this
cmd.exe /C echo TEXMFCONFIG $TEXMFSYSCONFIG>> tinytex.profile
cmd.exe /C TEXMFHOME $TEXMFLOCAL>> tinytex.profile
cmd.exe /C TEXMFVAR $TEXMFSYSVAR>> tinytex.profile

#download the custom package list
Get-ChocolateyWebFile `
  -PackageName "texlive" `
  -FileFullPath "$toolsDir\pkgs-custom.txt" `
  -Url $pkgcustom `

#an automated installation of TeXLive (infrastructure only)
Set-Location install-tl-*
Write-Verbose -Message ./install-tl-windows.bat -no-gui -profile=../tinytex.profile -q

