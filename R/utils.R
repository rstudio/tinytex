xfun_session_info = function() {
  paste('TinyTeX used:', is_tinytex(),
        tryCatch(paste(
          "\nTeX Live Version (tlmgr --version):\n",
          paste(tlmgr("--version", stdout = TRUE, .quiet = TRUE), collapse = "\n ")
        ),
        error = function(e) NULL)
  )
}
