#' Install/Uninstall TinyTeX
#'
#' The function \code{install_tinytex()} downloads the installation script from
#' \url{https://github.com/yihui/tinytex} according to the platform (Unix or
#' Windows), and executes it to install TinyTeX (a custom LaTeX distribution
#' based on TeX Live). The function \code{uninstall_tinytex()} removes TinyTeX.
#' @references TinyTeX homepage: \url{https://yihui.name/tinytex/}.
#' @export
install_tinytex = function() {
  owd = setwd(tempdir()); on.exit(setwd(owd), add = TRUE)
  switch(
    .Platform$OS.type,
    'unix' = {
      download.file(
        'https://github.com/yihui/tinytex/raw/master/tools/install-unx.sh',
        'install-unx.sh'
      )
      system2('sh', 'install-unix.sh')
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
