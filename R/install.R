#' Install/Uninstall TinyTeX
#'
#' The function \code{install_tinytex()} downloads the installation script from
#' \url{https://github.com/yihui/tinytex} according to the platform (Unix or
#' Windows), and executes it to install TinyTeX (a custom LaTeX distribution
#' based on TeX Live). The function \code{uninstall_tinytex()} removes TinyTeX.
#' @param force Whether to force to install (override) or uninstall TinyTeX.
#' @param dir The directory to install or uninstall TinyTeX (should not exist
#'   unless \code{force = TRUE}).
#' @param repository The CTAN repository to be used. By default, a fast mirror
#'   is automatically chosen. You can manually set one if the automatic mirror
#'   is not really fast enough, e.g., if you are in China, you may consider
#'   \code{'http://mirrors.tuna.tsinghua.edu.cn/CTAN/systems/texlive/tlnet'}.
#' @param extra_packages A character vector of extra LaTeX packages to be
#'   installed.
#' @references See the TinyTeX documentation (\url{https://yihui.name/tinytex/})
#'   for the default installation directories on different platforms.
#' @export
install_tinytex = function(
  force = FALSE, dir = 'auto', repository = 'ctan', extra_packages = NULL
) {
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
  tweak_path()
  if (!force) {
    msg = if (tlmgr_available()) {
      system2('tlmgr', '--version')
      c(
        'Detected an existing tlmgr at ', Sys.which('tlmgr'), '. ',
        'It seems TeX Live has been installed (check tinytex:::texlive_root()). '
      )
    } else if (Sys.which('pdftex') != '') {
      system2('pdftex', '--version')
      c(
        'Detected an existing LaTeX distribution (e.g., pdftex is at ',
        Sys.which('pdftex'), '). '
      )
    }
    if (length(msg)) stop(
      msg, 'You have to uninstall it, or use install_tinytex(force = TRUE) ',
      'if you are sure TinyTeX can override it (e.g., you are a PATH expert or ',
      'installed TinyTeX previously).',
      call. = FALSE
    )
  }
  owd = setwd(tempdir())
  on.exit({
    unlink(c('install-unx.sh', 'install-tl.zip', 'pkgs-custom.txt', 'texlive.profile'))
    setwd(owd)
    p = Sys.which('tlmgr')
    if (os == 'windows') message(
      'Restart your R session and check if tinytex:::is_tinytex() is TRUE.'
    ) else if (!is_tinytex()) warning(
      'TinyTeX was not successfully installed or configured.',
      if (p != '') c(' tlmgr was found at ', p) else {
        c('Your PATH variable is ', Sys.getenv('PATH'))
      }, '. See https://yihui.name/tinytex/faq/ for more information.'
    )
  }, add = TRUE)

  add_texmf = function(bin) {
    system2(bin, c('conf', 'auxtrees', 'add', r_texmf_path()))
  }
  https = grepl('^https://', repository)

  switch(
    os,
    'unix' = {
      macos = Sys.info()[['sysname']] == 'Darwin'
      downloader = if (macos) 'curl' else 'wget'
      if (Sys.which(downloader) == '') stop(sprintf(
        "'%s' is not found but required to install TinyTeX", downloader
      ), call. = FALSE)
      if (!macos && !dir_exists('~/bin')) on.exit(message(
        'You may have to restart your system after installing TinyTeX to make sure ',
        '~/bin appears in your PATH variable (https://github.com/yihui/tinytex/issues/16).'
      ), add = TRUE)
      download.file(
        'https://github.com/yihui/tinytex/raw/master/tools/install-unx.sh',
        'install-unx.sh'
      )
      res = system2('sh', c(
        'install-unx.sh', if (repository != 'ctan') c(
          '--no-admin', '--path', shQuote(repository), if (macos && https) 'tlgpg'
        )
      ))
      if (res != 0) {
        if (macos && file.access('/usr/local/bin', 2) != 0) message(
          'The directory /usr/local/bin is not writable; ',
          'see https://github.com/yihui/tinytex/issues/24 for more info.'
        )
        stop('Failed to install TinyTeX', call. = FALSE)
      }
      target = normalizePath(
        if (macos) '~/Library/TinyTeX' else '~/.TinyTeX'
      )
      if (!dir_exists(target)) stop('Failed to install TinyTeX.')
      if (!user_dir %in% c('', target)) {
        dir.create(dirname(user_dir), showWarnings = FALSE, recursive = TRUE)
        dir_rename(target, user_dir)
        target = user_dir
      }
      bin = file.path(list.files(file.path(target, 'bin'), full.names = TRUE), 'tlmgr')
      system2(bin, c('path', 'add'))
      if (length(extra_packages)) system2(bin, c('install', extra_packages))
      add_texmf(bin)
      message('TinyTeX installed to ', target)
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
        patch_TLUtils.pm()  # TODO: remove this temporary hack after the TL installer is fixed
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
        tlmgr = function(...) system2(bin_tlmgr, ...)
        if (repository != 'ctan') {
          tlmgr(c('option', 'repository', shQuote(repository)))
          if (https) tlmgr(c('--repository', 'http://www.preining.info/tlgpg/', 'install', 'tlgpg'))
          if (tlmgr(c('update', '--list')) != 0) {
            warning('The repository ', repository, ' does not seem to be accessible. Reverting to the default CTAN mirror.')
            tlmgr(c('option', 'repository', 'ctan'))
          }
        }
        tlmgr(c('install', 'latex-bin', 'xetex', pkgs_custom, extra_packages))
        tlmgr(c('path', 'add'))
        add_texmf(bin_tlmgr)
      })
      message('TinyTeX installed to ', target)
    },
    stop('This platform is not supported.')
  )
}

patch_TLUtils.pm = function() {
  if (!file.exists(f <- 'tlpkg/TeXLive/TLUtils.pm')) return()
  x = readLines(f)
  if (!all(x[2368 + 0:1] == c(
    '    $s += setup_unix_one(\'lz4\',  "$bindir/lz4/lz4.$platform", "--version");',
    '    $ok = ($s == 4);  # failure return unless all are present.'
  ))) return()
  x[2368 + 0:2] = c(
    '    $ok = ($s == 3);  # failure return unless all are present.',
    '    # also try to set up lz4, but don\'t fail/warn',
    '    setup_unix_one(\'lz4\',  "$bindir/lz4/lz4.$platform", "--version", 1);'
  )
  writeLines(x, f)
}

#' @rdname install_tinytex
#' @export
uninstall_tinytex = function(force = FALSE, dir = texlive_root()) {
  tweak_path()
  if (dir == '') stop('TinyTeX does not seem to be installed.')
  if (!is_tinytex() && !force) stop(
    'Detected TeX Live at "', dir, '", but it appears to be TeX Live instead of TinyTeX. ',
    'To uninstall TeX Live, use the argument force = TRUE.'
  )
  r_texmf('remove')
  tlmgr_path('remove')
  unlink(dir, recursive = TRUE)
}

#' @param packages Whether to reinstall all currently installed packages.
#' @param ... Other arguments to be passed to \code{install_tinytex()} (note
#'   that the \code{extra_packages} argument will be set to \code{tl_pkgs()} if
#'   \code{packages = TRUE}).
#' @rdname install_tinytex
#' @export
reinstall_tinytex = function(packages = TRUE, dir = texlive_root(), ...) {
  pkgs = if (packages) tl_pkgs()
  uninstall_tinytex()
  install_tinytex(extra_packages = pkgs, dir = dir, ...)
}

win_app_dir = function(...) {
  d = Sys.getenv('APPDATA')
  if (d == '') stop('Environment variable "APPDATA" not set.')
  file.path(d, ...)
}

texlive_root = function() {
  tweak_path()
  path = Sys.which('tlmgr')
  if (path == '') return('')
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
  gsub('^[.]', '', tolower(basename(texlive_root()))) == 'tinytex'
}

in_dir = function(dir, expr) {
  owd = setwd(dir); on.exit(setwd(owd), add = TRUE)
  expr
}

dir_exists = function(path) file_test('-d', path)

dir_rename = function(from, to) {
  # cannot rename '/foo' to '/bar' because of 'Invalid cross-device link'
  suppressWarnings(file.rename(from, to)) || dir_copy(from, to)
}

dir_copy = function(from, to) {
  dir.create(to, showWarnings = FALSE, recursive = TRUE)
  all(file.copy(list.files(from, full.names = TRUE), to, recursive = TRUE)) &&
    unlink(from, recursive = TRUE) == 0
}

# LaTeX packages that I use
install_yihui_pkgs = function() {
  pkgs = readLines('https://github.com/yihui/tinytex/raw/master/tools/pkgs-yihui.txt')
  tlmgr_install(pkgs)
}
