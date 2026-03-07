# Optimized TinyTeX-2 build: reuse the daily release when the TeX Live year
# matches, otherwise fall back to a full scheme-full install.
#
# Required environment variables:
#   TEXLIVE_YEAR    - TeX Live year from the validate-ctan job
#   CTAN_REPO       - CTAN repository URL
#   FORCE_REBUILD   - set to 'true' to skip the fast path and do a full rebuild

$ErrorActionPreference = 'Stop'

$releaseBodyLines = (gh release view daily -R rstudio/tinytex-releases --json body -q '.body' 2>&1) -split '\r?\n'
$releaseYearMatch = $releaseBodyLines | Select-String 'TeX Live (\d{4})' | Select-Object -First 1
$releaseYear = if ($releaseYearMatch) { $releaseYearMatch.Matches.Groups[1].Value } else { '' }

if ($env:FORCE_REBUILD -ne 'true' -and $releaseYear -ne '' -and $releaseYear -eq $env:TEXLIVE_YEAR) {
  Write-Host ">> Years match (TeX Live $($env:TEXLIVE_YEAR)): reusing daily TinyTeX-2 bundle and applying incremental updates"
  $env:TINYTEX_INSTALLER = 'TinyTeX-2'
  cmd /c "$PSScriptRoot\install-bin-windows.bat"
  Rscript -e "tinytex::tlmgr(c('option', 'repository', Sys.getenv('CTAN_REPO')))"

  # Capture installed packages before update so we can detect any removed from remote
  $pkgsBefore = @(Rscript -e "cat(tinytex::tl_pkgs(), sep = '\n')")

  Rscript -e "tinytex::tlmgr_update()"

  # Remove packages that are no longer present in the remote repo
  $pkgsAfter = @(Rscript -e "cat(tinytex::tl_pkgs(), sep = '\n')")
  $removed = (Compare-Object -ReferenceObject $pkgsBefore -DifferenceObject $pkgsAfter |
    Where-Object { $_.SideIndicator -eq '<=' }).InputObject
  if ($removed) {
    Write-Host ">> Removing packages no longer in remote repo: $removed"
    $env:REMOVED_PKGS = $removed -join ' '
    Rscript -e "tinytex::tlmgr(c('remove', scan(text=Sys.getenv('REMOVED_PKGS'), what='', quiet=TRUE)))"
  }

  Rscript "$PSScriptRoot\clean-tlpdb.R"
} else {
  if ($env:FORCE_REBUILD -eq 'true') {
    Write-Host ">> Force rebuild requested: installing TinyTeX-2 from scratch"
  } else {
    Write-Host ">> Years do not match (local: $($env:TEXLIVE_YEAR), release: $(if ($releaseYear) { $releaseYear } else { 'none' })): installing TinyTeX-2 from scratch"
  }
  Rscript "$PSScriptRoot\build-scheme-full.R"
}
