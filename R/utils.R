# for xfun::session_info('tinytex')
xfun_session_info = function() {
  tryCatch(tlmgr_version(raw = FALSE), error = function(e) NULL)
}

