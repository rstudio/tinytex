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
    unlink(c('install-unx.sh', 'install-tl.zip', 'pkgs-custom.txt', 'texlive.profile'))
    setwd(owd)
    p = Sys.which('tlmgr')
    if (os == 'windows') message(
      'Restart your R session and check if tinytex:::is_tinytex() is TRUE.'
    ) else if (!is_tinytex()) warning(
      'TinyTeX was not successfully installed or configured.',
      if (p != '') c('tlmgr was found at ', p, '.')
    )
  }, add = TRUE)
  switch(
    os,
    'unix' = {
      download.file(
        'https://github.com/yihui/tinytex/raw/master/tools/install-unx.sh',
        'install-unx.sh'
      )
      system2('sh', 'install-unx.sh')
    },
    'windows' = {
      appdata = win_app_dir()
      unlink('install-tl-*', recursive = TRUE)
      download.file(
        'http://mirror.ctan.org/systems/texlive/tlnet/install-tl.zip',
        'install-tl.zip', mode = 'wb'
      )
      download.file(
        'https://github.com/yihui/tinytex/raw/master/tools/pkgs-custom.txt',
        'pkgs-custom.txt'
      )
      download.file(
        'https://github.com/yihui/tinytex/raw/master/tools/texlive.profile',
        'texlive.profile'
      )
      x = readLines('texlive.profile')
      writeLines(gsub('./', './TinyTeX/', x, fixed = TRUE), 'texlive.profile')
      unzip('install-tl.zip')
      in_dir(list.files('.', '^install-tl-.*'), {
        message('Starting to install TinyTeX to ', appdata, '. It will take a few minutes.')
        (if (interactive()) function(msg) utils::winDialog('ok', msg) else message)(paste0(
          'Next you may see two error dialog boxs about the missing luatex.dll, ',
          'and an error message like "Use of uninitialized value in bitwise or (|)..." in the end. ',
          'These messages can be ignored. When installation is complete, ',
          'please restart ', if (Sys.getenv('RSTUDIO') != '') 'RStudio' else 'R', '.'
        ))
        shell('echo | install-tl-windows.bat -profile=../texlive.profile', invisible = FALSE)
        system2(
          'TinyTeX\\bin\\win32\\tlmgr',
          c('install', 'latex-bin', 'xetex', readLines('../pkgs-custom.txt'))
        )
        file.remove('TinyTeX/install-tl.log')
        unlink(file.path(appdata, 'TinyTeX'), recursive = TRUE)
        file.copy('TinyTeX', appdata, recursive = TRUE)
      })
      unlink('install-tl-*', recursive = TRUE)
      system2(file.path(appdata, 'TinyTeX', 'bin', 'win32', 'tlmgr'), 'path add')
    },
    stop('This platform is not supported.')
  )
}

#' @rdname install_tinytex
#' @export
uninstall_tinytex = function() {
  target = switch(
    os,
    'windows' = file.path(win_app_dir(), 'TinyTeX'),
    'unix' = if (Sys.info()[['sysname']] == 'Darwin') '~/Library/TinyTeX' else '~/.TinyTeX',
    stop('This platform is not supported.')
  )
  tlmgr_path('remove')
  unlink(target, recursive = TRUE)
}

win_app_dir = function() {
  d = Sys.getenv('APPDATA')
  if (d == '') stop('Environment variable "APPDATA" not set.')
  d
}

is_tinytex = function(path = Sys.which('tlmgr')) {
  if (path == '') return(FALSE)
  if (os == 'unix') path = Sys.readlink(path)
  grepl('tinytex', path, ignore.case = TRUE)
}

in_dir = function(dir, expr) {
  owd = setwd(dir); on.exit(setwd(owd), add = TRUE)
  expr
}
