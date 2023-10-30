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

# read a file without warning, and discard lines with invalid characters to
# avoid warnings in the grep() family (invalid lines in log files should be safe
# to discard in this package, although it isn't so in general)
read_lines = function(...) {
  x = readLines(..., warn = FALSE)
  x[!validEnc(x)] = ''
  x
}

# for some reason, some TeX Live utilities refuse to work if they are called by
# their short paths (#427), in which case we switch to shell()
if (xfun::is_windows()) system2 = function(command, args, ...) {
  if (length(list(...)) > 0 || !is_short(command)) {
    base::system2(command, args, ...)
  } else shell(paste(c(command, args), collapse = ' '))
}

# test if a path would be shortened on Windows
is_short = function(x) {
  x = Sys.which(x)
  (x != '') && (normalizePath(x) != shortPathName(x))
}
