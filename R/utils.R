# for xfun::session_info('tinytex')
xfun_session_info = function() {
  pdftex_info = tryCatch(system2('pdflatex', "--version", stdout = TRUE)[1], error = function(e) NULL)
  info = if (grepl("TeX Live", pdftex_info, fixed = TRUE)) {
    tryCatch(tlmgr_version(raw = FALSE), error = function(e) NULL)
  } else {
    # e.g MiKTeX-pdfTeX 4.8 (MiKTeX 21.8) return MiKTeX 21.8
    xfun::grep_sub("^.*\\((.*)\\)$", "\\1", pdftex_info)
  }

  if (length(info)) {
    return(paste(c("LaTeX version used: ", paste0("  ", info)), collapse = "\n"))
  }
  invisible(NULL)
}

