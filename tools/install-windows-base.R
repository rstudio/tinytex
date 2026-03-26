# run install-windows.ps1 without installing any LaTeX packages, so we get a
# minimal TeX Live installation (which only contains tlmgr)
owd = setwd('tools')
f = 'install-windows.ps1'
x = readLines(f)
i = x == "& $tlmgr install @pkgs"
if (sum(i) != 1)
  stop('The script ', f, ' should contain a line to install extra LaTeX packages.')
x = x[!i]
x = x[x != 'pause']  # do not pause
writeLines(x, f)
shell(paste('powershell -ExecutionPolicy Bypass -File', f))
setwd(owd)

sys.source('tools/clean-tlpdb.R')
