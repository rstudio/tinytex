# for xfun::session_info('tinytex')
xfun_session_info = function() {
  pdftex_info = tryCatch(system2('pdflatex', "--version", stdout = TRUE)[1], error = function(e) NULL)
  if (is.null(pdftex_info)) return(invisible(NULL))

  info = if (grepl("TeX Live", pdftex_info, fixed = TRUE)) {
    # we get more information on tlmgr in that case
    tryCatch(tlmgr_version(raw = FALSE), error = function(e) NULL)
  } else {
    # For other distributions
    # e.g MiKTeX-pdfTeX 4.8 (MiKTeX 21.8) returns MiKTeX 21.8
    xfun::grep_sub("^.*\\((.*)\\)$", "\\1", pdftex_info)
  }

  if (!length(info)) return(invisible(NULL))

  paste(c("LaTeX version used: ", paste0("  ", info)), collapse = "\n")
}

