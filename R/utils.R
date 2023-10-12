# for xfun::session_info('tinytex')
xfun_session_info = function() {
  try_null = function(...) tryCatch(..., error = function(e) NULL)
  version_info = function(cmd) try_null(system2(cmd, '--version', stdout = TRUE))
  tweak_path()
  pdftex_info = version_info('pdflatex')[1]

  info = if (is.null(pdftex_info)) {
    version_info('tectonic')[1]  # try tectonic engine?
  } else if (grepl('TeX Live', pdftex_info, fixed = TRUE)) {
    # we get more information on tlmgr in that case
    try_null(tlmgr_version('string'))
  } else {
    # for other distributions, e.g., MiKTeX-pdfTeX 4.8 (MiKTeX 21.8)
    xfun::grep_sub('^.*\\((.*)\\)$', '\\1', pdftex_info)
  }
  if (!length(info)) return(invisible(NULL))

  paste(c('LaTeX version used: ', paste0('  ', info)), collapse = '\n')
}

read_lines = function(...) readLines(..., warn = FALSE)
