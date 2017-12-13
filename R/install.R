#' Install/Uninstall TinyTeX
#'
#' The function \code{install_tinytex()} downloads the installation script from
#' \url{https://github.com/yihui/tinytex} according to the platform (Unix or
#' Windows), and executes it to install TinyTeX (a custom LaTeX distribution
#' based on TeX Live). The function \code{uninstall_tinytex()} removes TinyTeX.
#' @param force Whether to force to install (override) or uninstall TinyTeX.
#' @param dir The directory to install or uninstall TinyTeX (should not exist
#'   unless \code{force = TRUE}).
#' @references See the TinyTeX documentation (\url{https://yihui.name/tinytex/})
#'   for the default installation directories on different platforms.
#' @export
install_tinytex = function(force = FALSE, dir) {
  if (!is.logical(force)) stop('The argument "force" must take a logical value.')
  check_dir = function(dir) {
    if (dir_exists(dir) && !force) stop(
      'The directory "', dir, '" exists. Please either delete it, ',
      'or use install_tinytex(force = TRUE).'
    )
  }
  user_dir = ''
  if (!missing(dir)) {
    dir = gsub('[/\\]+$', '', dir)  # remove trailing slashes
    check_dir(dir)
    unlink(dir, recursive = TRUE)
    user_dir = normalizePath(dir, mustWork = FALSE)
  }
  if (tlmgr_available() && !force) stop(
    'It seems TeX Live has been installed (check tinytex:::texlive_root()). ',
    'You may need to uninstall it.', call. = FALSE
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
      target = normalizePath(
        if (Sys.info()[['sysname']] == 'Darwin') '~/Library/TinyTeX' else '~/.TinyTeX'
      )
      if (!dir_exists(target)) stop('Failed to install TinyTeX.')
      if (!user_dir %in% c('', target)) {
        dir.create(dirname(user_dir), showWarnings = FALSE, recursive = TRUE)
        file.rename(target, user_dir)
        bin = file.path(list.files(file.path(user_dir, 'bin'), full.names = TRUE), 'tlmgr')
        system2(bin, c('path', 'add'))
      }
    },
    'windows' = {
      target = if (user_dir == '') win_app_dir('TinyTeX') else user_dir
      unlink('install-tl-*', recursive = TRUE)
      download.file(
        'http://mirror.ctan.org/systems/texlive/tlnet/install-tl.zip',
        'install-tl.zip', mode = 'wb'
      )
      download.file(
        'https://github.com/yihui/tinytex/raw/master/tools/pkgs-custom.txt',
        'pkgs-custom.txt'
      )
      pkgs_custom = readLines('pkgs-custom.txt')
      download.file(
        'https://github.com/yihui/tinytex/raw/master/tools/texlive.profile',
        'texlive.profile'
      )
      x = readLines('texlive.profile')
      writeLines(gsub('./', './TinyTeX/', x, fixed = TRUE), 'texlive.profile')
      unzip('install-tl.zip')
      in_dir(list.files('.', '^install-tl-.*'), {
        message('Starting to install TinyTeX to ', target, '. It will take a few minutes.')
        (if (interactive()) function(msg) utils::winDialog('ok', msg) else message)(paste0(
          'Next you may see two error dialog boxs about the missing luatex.dll, ',
          'and an error message like "Use of uninitialized value in bitwise or (|)..." in the end. ',
          'These messages can be ignored. When installation is complete, ',
          'please restart ', if (Sys.getenv('RSTUDIO') != '') 'RStudio' else 'R', '.'
        ))
        bat = readLines('install-tl-windows.bat')
        # never PAUSE (no way to interact with the Windows shell from R)
        writeLines(
          grep('^pause\\s*$', bat, ignore.case = TRUE, invert = TRUE, value = TRUE),
          'install-tl-windows.bat'
        )
        shell('install-tl-windows.bat -profile=../texlive.profile', invisible = FALSE)
        file.remove('TinyTeX/install-tl.log')
        dir.create(target, showWarnings = FALSE, recursive = TRUE)
        file.copy(list.files('TinyTeX', full.names = TRUE), target, recursive = TRUE)
      })
      unlink('install-tl-*', recursive = TRUE)
      in_dir(target, {
        bin_tlmgr = file.path('bin', 'win32', 'tlmgr')
        system2(bin_tlmgr, c('install', 'latex-bin', 'xetex', pkgs_custom))
        system2(bin_tlmgr, c('path', 'add'))
      })
    },
    stop('This platform is not supported.')
  )
}

#' @rdname install_tinytex
#' @export
uninstall_tinytex = function(force = FALSE, dir = texlive_root()) {
  if (dir == '') stop('TinyTeX does not seem to be installed.')
  if (!is_tinytex() && !force) stop(
    'Detected TeX Live at "', dir, '", but it appears to be TeX Live instead of TinyTeX. ',
    'To uninstall TeX Live, use the argument force = TRUE.'
  )
  tlmgr_path('remove')
  unlink(dir, recursive = TRUE)
}

win_app_dir = function(...) {
  d = Sys.getenv('APPDATA')
  if (d == '') stop('Environment variable "APPDATA" not set.')
  file.path(d, ...)
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

dir_exists = function(path) file_test('-d', path)
