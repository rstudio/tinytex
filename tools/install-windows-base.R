# run install-windows.ps1 without installing any LaTeX packages, so we get a
# minimal TeX Live installation (which only contains tlmgr)
owd = setwd('tools')
f = 'install-windows.ps1'
x = readLines(f)
i = x == r"(& .\tlmgr.bat install @pkgs)"
if (sum(i) != 1)
  stop('The script ', f, ' should contain a line to install extra LaTeX packages.')
x = x[!i]
x = x[!grepl("^Read-Host", x)]  # do not pause
writeLines(x, f)
shell('powershell -ExecutionPolicy Bypass -File install-windows.ps1')
setwd(owd)

sys.source('tools/clean-tlpdb.R')
