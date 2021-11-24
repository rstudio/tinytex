xfun_session_info = function() {
  tryCatch(
    tlmgr_version(short = TRUE),
    error = function(e) NULL
  )
}

