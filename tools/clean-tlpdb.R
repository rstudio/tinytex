if (!requireNamespace('tinytex', quietly = TRUE)) utils::install.packages('tinytex')
# clean texlive.tlpdb.* files
tinytex:::delete_tlpdb_files()

local({
  files = list.files(tinytex::tinytex_root(FALSE), full.names = TRUE, recursive = TRUE)

  # clean log files
  unlink(grep('[.]log$', files, value = TRUE))

  # compress executables using upx
  if (Sys.which('upx') != '') {
    if (xfun::is_windows()) {
      files = grep('[.](dll|exe)$', files, value = TRUE)
    } else {
      files = files[file_test('-x', files)]
      files = files[sapply(sprintf('file --mime-encoding %s | grep -q binary', shQuote(files)), system) == 0]
    }
    for (f in shQuote(files)) system2('upx', c('-qq', f))
  }
})
