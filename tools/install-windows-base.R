# run install-windows.bat without installing any LaTeX packages, so we get a
# minimal TeX Live installation (which only contains tlmgr)
owd = setwd('tools')
f = 'install-windows.bat'
x = readLines(f)
i = x == r"(call "%APPDATA%\TinyTeX\bin\win32\tlmgr" install %pkgs%)"
if (sum(i) != 1)
  stop('The script ', f, ' should contain a line to install extra LaTeX packages.')
x = x[!i]
x = x[x != 'pause']  # do not pause
writeLines(x, f)
shell('install-windows.bat')
setwd(owd)

sys.source('tools/clean-tlpdb.R')
