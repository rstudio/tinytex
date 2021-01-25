tinytex::tlmgr_install(c('latex-bin', 'xetex', readLines('tools/pkgs-custom.txt')))
sys.source('tools/clean-tlpdb.R')
