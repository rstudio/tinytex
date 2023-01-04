if (!requireNamespace('tinytex', quietly = TRUE)) utils::install.packages('tinytex')
# clean texlive.tlpdb.* files
tinytex:::delete_tlpdb_files()
# clean log files
unlink(list.files(
  tinytex::tinytex_root(FALSE), '[.]log$', full.names = TRUE, recursive = TRUE
))
