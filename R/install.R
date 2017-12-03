#' Install/Uninstall TinyTeX
#'
#' The function \code{install_tinytex()} downloads the installation script from
#' \url{https://github.com/yihui/tinytex} according to the platform (Unix or
#' Windows), and executes it to install TinyTeX (a custom LaTeX distribution
#' based on TeX Live). The function \code{uninstall_tinytex()} removes TinyTeX.
#' @references TinyTeX homepage: \url{https://yihui.name/tinytex/}.
#' @export
install_tinytex = function() {
  if (tlmgr_available() && !is_tinytex()) warning(
    'It seems TeX Live has been installed. You may need to uninstall it.'
  )
  owd = setwd(tempdir())
  on.exit({
    unlink(c('install-unx.bat', 'install-windows.bat'))
    setwd(owd)
    p = Sys.which('tlmgr')
    if (!is_tinytex()) warning(
      'TinyTeX was not successfully installed or configured.',
      if (p != '') c('tlmgr was found at ', p, '.')
    )
  }, add = TRUE)
  switch(
    .Platform$OS.type,
    'unix' = {
      download.file(
        'https://github.com/yihui/tinytex/raw/master/tools/install-unx.sh',
        'install-unx.sh'
      )
      system2('sh', 'install-unx.sh')
    },
    'windows' = {
      download.file(
        'https://github.com/yihui/tinytex/raw/master/tools/install-windows.bat',
        'install-windows.bat'
      )
      system2('install-windows.bat', invisible = FALSE)
    },
    stop('This platform is not supported.')
  )
}

#' @rdname install_tinytex
#' @export
uninstall_tinytex = function() {
  target = switch(
    .Platform$OS.type,
    'windows' = file.path(
      Sys.getenv('APPDATA', stop('Environment variable "APPDATA" not set.')), 'TinyTeX'
    ),
    'unix' = if (Sys.info()[['sysname']] == 'Darwin') '~/Library/TinyTeX' else '~/.TinyTeX',
    stop('This platform is not supported.')
  )
  tlmgr_path('remove')
  unlink(target, recursive = TRUE)
}

is_tinytex = function(path = Sys.which('tlmgr')) {
  grepl('tinytex', path, ignore.case = TRUE)
}
