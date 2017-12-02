#' Install TinyTeX
#'
#' Download the installation script from \url{https://github.com/yihui/tinytex}
#' according to the platform (Unix or Windows), and execute it to install
#' TinyTeX.
#' @references TinyTeX homepage: \url{https://yihui.name/tinytex/}.
#' @export
install_tinytex = function() {
  owd = setwd(tempdir()); on.exit(setwd(owd), add = TRUE)
  if (.Platform$OS.type == 'unix') {
    download.file(
      'https://github.com/yihui/tinytex/raw/master/tools/install-unx.sh',
      'install-unx.sh'
    )
    system2('sh', 'install-unix.sh')
  } else {
    download.file(
      'https://github.com/yihui/tinytex/raw/master/tools/install-windows.bat',
      'install-windows.bat'
    )
    system2('install-windows.bat', invisible = FALSE)
  }
}
