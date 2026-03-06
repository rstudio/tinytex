# Optimized TinyTeX-2 build: reuse the daily release when the TeX Live year
# matches, otherwise fall back to a full scheme-full install.
#
# Required environment variables:
#   TEXLIVE_YEAR  - TeX Live year from the validate-ctan job
#   CTAN_REPO     - CTAN repository URL

$ErrorActionPreference = 'Stop'

$releaseBodyLines = (gh release view daily -R rstudio/tinytex-releases --json body -q '.body' 2>&1) -split '\r?\n'
$releaseYearMatch = $releaseBodyLines | Select-String 'TeX Live (\d{4})' | Select-Object -First 1
$releaseYear = if ($releaseYearMatch) { $releaseYearMatch.Matches.Groups[1].Value } else { '' }

if ($releaseYear -ne '' -and $releaseYear -eq $env:TEXLIVE_YEAR) {
  $env:TINYTEX_INSTALLER = 'TinyTeX-2'
  cmd /c "$PSScriptRoot\install-bin-windows.bat"
  tlmgr option repository $env:CTAN_REPO

  # Capture installed packages before update so we can detect any removed from remote
  $pkgsBefore = @(tlmgr info --list --only-installed --data name)

  tlmgr update --self --all
  tlmgr install scheme-full

  # Remove packages that are no longer present in the remote repo
  $pkgsAfter = @(tlmgr info --list --only-installed --data name)
  $removed = (Compare-Object -ReferenceObject $pkgsBefore -DifferenceObject $pkgsAfter |
    Where-Object { $_.SideIndicator -eq '<=' }).InputObject
  if ($removed) {
    tlmgr remove $removed
  }

  Rscript "$PSScriptRoot\clean-tlpdb.R"
} else {
  Rscript "$PSScriptRoot\build-scheme-full.R"
}
