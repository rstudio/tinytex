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

# patch tlmgr.pl to avoid the warning 'Use of uninitialized value in bitwise or
# (|) at...\TinyTeX\texmf-dist\scripts\texlive\tlmgr.pl line 1510'
# http://www.tug.org/svn/texlive/trunk/Master/texmf-dist/scripts/texlive/tlmgr.pl?r1=56562&r2=56561&pathrev=56562
f = file.path(Sys.getenv('APPDATA'), 'TinyTeX/texmf-dist/scripts/texlive/tlmgr.pl')
x = readLines(f)
i = grep('^\\s*\\$ret \\|= TeXLive::TLWinGoo::broadcast_env\\();', x)
if (length(i)) x = x[-i] else stop('No need to patch tlmgr.pl on Windows any more.')
writeLines(x, f)

setwd(owd)

sys.source('tools/clean-tlpdb.R')
