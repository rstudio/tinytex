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
  target = texlive_root()
  tlmgr_path('remove')
  unlink(target, recursive = TRUE)
}

win_app_dir = function() {
  d = Sys.getenv('APPDATA')
  if (d == '') stop('Environment variable "APPDATA" not set.')
  d
}

texlive_root = function() {
  path = Sys.which('tlmgr')
  if (path == '') return(path)
  root_dir = function(path, ...) {
    dir = normalizePath(file.path(dirname(path), ...), mustWork = TRUE)
    if (!'bin' %in% list.files(dir)) stop(
      dir, ' does not seem to be the root directory of TeXLive (no "bin/" dir under it)'
    )
    dir
  }
  if (os == 'windows') return(root_dir(path, '..', '..'))
  if (Sys.readlink(path) == '') stop(
    'Cannot figure out the root directory of TeX Live from ', path,
    ' (not a symlink on ', os, ')'
  )
  path = symlink_root(path)
  root_dir(normalizePath(path), '..', '..', '..')
}

# trace a symlink to its final destination
symlink_root = function(path) {
  path = normalizePath(path, mustWork = TRUE)
  path2 = Sys.readlink(path)
  if (path2 == '') return(path)  # no longer a symlink; must be resolved now
  # path2 may still be a _relative_ symlink
  in_dir(dirname(path), symlink_root(path2))
}

is_tinytex = function() {
  tolower(basename(texlive_root())) == 'tinytex'
}

in_dir = function(dir, expr) {
  owd = setwd(dir); on.exit(setwd(owd), add = TRUE)
  expr
}
