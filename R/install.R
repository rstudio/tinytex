#' Install/Uninstall TinyTeX
#'
#' The function \code{install_tinytex()} downloads the installation script from
#' \url{https://github.com/yihui/tinytex} according to the platform (Unix or
#' Windows), and executes it to install TinyTeX (a custom LaTeX distribution
#' based on TeX Live). The function \code{uninstall_tinytex()} removes TinyTeX;
#' \code{reinstall_tinytex()} reinstalls TinyTeX as well as previously installed
#' LaTeX packages by default; \code{tinytex_root()} returns the root directory
#' of TinyTeX if found.
#' @param force Whether to force to install (override) or uninstall TinyTeX.
#' @param dir The directory to install or uninstall TinyTeX (should not exist
#'   unless \code{force = TRUE}).
#' @param repository The CTAN repository to be used. By default, a random fast
#'   mirror is automatically chosen (via \code{http://mirror.ctan.org}). You can
#'   manually set one if the automatic mirror is not really fast enough, e.g.,
#'   if you are in China, you may consider
#'   \code{'http://mirrors.tuna.tsinghua.edu.cn/CTAN/'}, or if you are in the
#'   midwest in the US, you may use
#'   \code{'https://mirror.las.iastate.edu/tex-archive/'}. You can find the full
#'   list of mirrors at \url{https://ctan.org/mirrors}. This argument should end
#'   with the path \file{/systems/texlive/tlnet}, and if it is not, the path
#'   will be automatically appended.
#' @param extra_packages A character vector of extra LaTeX packages to be
#'   installed.
#' @param add_path Whether to run the command \command{tlmgr path add} to add
#'   the bin path of TeX Live to the system environment variable \var{PATH}.
#' @references See the TinyTeX documentation (\url{https://yihui.org/tinytex/})
#'   for the default installation directories on different platforms.
#' @export
install_tinytex = function(
  force = FALSE, dir = 'auto', repository = 'ctan', extra_packages = NULL,
  add_path = TRUE
) {
  if (!is.logical(force)) stop('The argument "force" must take a logical value.')
  check_dir = function(dir) {
    if (dir_exists(dir) && !force) stop(
      'The directory "', dir, '" exists. Please either delete it, ',
      'or use install_tinytex(force = TRUE).'
    )
  }
  user_dir = ''
  if (!(dir %in% c('', 'auto'))) {
    dir = gsub('[/\\]+$', '', dir)  # remove trailing slashes
    check_dir(dir)
    unlink(dir, recursive = TRUE)
    user_dir = normalizePath(dir, mustWork = FALSE)
  }
  tweak_path()
  msg = if (tlmgr_available()) {
    system2('tlmgr', '--version')
    c(
      'Detected an existing tlmgr at ', Sys.which('tlmgr'), '. ',
      'It seems TeX Live has been installed (check tinytex::tinytex_root()). '
    )
  } else if (Sys.which('pdftex') != '') {
    system2('pdftex', '--version')
    c(
      'Detected an existing LaTeX distribution (e.g., pdftex is at ',
      Sys.which('pdftex'), '). '
    )
  }
  if (length(msg)) warning(
    msg, 'You are recommended to uninstall it, although TinyTeX should work well alongside ',
    'another LaTeX distribution if a LaTeX document is compiled through tinytex::latexmk().',
    call. = FALSE
  )
  owd = setwd(tempdir())
  on.exit({
    unlink(c('install-unx.sh', 'install-tl.zip', 'pkgs-custom.txt', 'tinytex.profile'))
    setwd(owd)
    p = Sys.which('tlmgr')
    if (os == 'windows') message(
      'Please quit and reopen your R session and IDE (if you are using one, such ',
      'as RStudio or Emacs) and check if tinytex:::is_tinytex() is TRUE.'
    ) else if (!is_tinytex()) warning(
      'TinyTeX was not successfully installed or configured.',
      if (p != '') c(' tlmgr was found at ', p) else {
        c('Your PATH variable is ', Sys.getenv('PATH'))
      }, '. See https://yihui.org/tinytex/faq/ for more information.'
    )
  }, add = TRUE)

  add_texmf = function(bin) {
    system2(bin, c('conf', 'auxtrees', 'add', r_texmf_path()))
  }
  https = grepl('^https://', repository)
  repository = sub('/+$', '', repository)
  if ((not_ctan <- repository != 'ctan') && !grepl('/tlnet$', repository)) {
    repository = paste0(repository, '/systems/texlive/tlnet')
  }

  if ((texinput <- Sys.getenv('TEXINPUT')) != '') message(
    'Your environment variable TEXINPUT is "', texinput,
    '". Normally you should not set this variable, because it may lead to issues like ',
    'https://github.com/yihui/tinytex/issues/92.'
  )

  switch(
    os,
    'unix' = {
      macos = Sys.info()[['sysname']] == 'Darwin'
      downloader = if (macos) 'curl' else 'wget'
      if (Sys.which(downloader) == '') stop(sprintf(
        "'%s' is not found but required to install TinyTeX", downloader
      ), call. = FALSE)
      if (macos && file.access('/usr/local/bin', 2) != 0) {
        chown_cmd = 'chown -R `whoami`:admin /usr/local/bin'
        message(
          'The directory /usr/local/bin is not writable. I recommend that you ',
          'make it writable. See https://github.com/yihui/tinytex/issues/24 for more info.'
        )
        if (system(sprintf(
          "/usr/bin/osascript -e 'do shell script \"%s\" with administrator privileges'", chown_cmd
        )) != 0) warning(
          "Please run this command in your Terminal (password required):\n  sudo ",
          chown_cmd, call. = FALSE
        )
      }
      if (!macos && dir_exists('~/bin')) on.exit(message(
        'You may have to restart your system after installing TinyTeX to make sure ',
        '~/bin appears in your PATH variable (https://github.com/yihui/tinytex/issues/16).'
      ), add = TRUE)
      if (not_ctan) {
        Sys.setenv(CTAN_REPO = repository)
        on.exit(Sys.unsetenv('CTAN_REPO'), add = TRUE)
      }
      download_file('https://yihui.org/gh/tinytex/tools/install-unx.sh')
      res = system2('sh', c(
        'install-unx.sh', if (not_ctan) c(
          '--no-admin', '--path', shQuote(repository), if (macos && https) 'tlgpg'
        )
      ))
      if (res != 0) stop('Failed to install TinyTeX', call. = FALSE)
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
      if (add_path) system2(bin, c('path', 'add'))
      if (length(extra_packages)) system2(bin, c('install', extra_packages))
      add_texmf(bin)
      message('TinyTeX installed to ', target)
    },
    'windows' = {
      target = if (user_dir == '') win_app_dir('TinyTeX') else user_dir
      unlink('install-tl-*', recursive = TRUE)
      download_file(paste0(
        if (repository == 'ctan') 'http://mirror.ctan.org/systems/texlive/tlnet' else repository,
        '/install-tl.zip'
      ), mode = 'wb')
      download_file('https://sites.northwestern.edu/mthomas/files/2020/04/pkgs-custom.txt')
      pkgs_custom = readLines('pkgs-custom.txt')
      download_file('https://sites.northwestern.edu/mthomas/files/2020/04/tinytex.profile.txt')
      x = c(
        readLines('tinytex.profile.txt'), 'TEXMFCONFIG $TEXMFSYSCONFIG',
        'TEXMFHOME $TEXMFLOCAL', 'TEXMFVAR $TEXMFSYSVAR'
      )
      writeLines(gsub('./', './TinyTeX/', x, fixed = TRUE), 'tinytex.profile')
      unzip('install-tl.zip')
      in_dir(list.files('.', '^install-tl-.*'), {
        message('Starting to install TinyTeX to ', target, '. It will take a few minutes.')
        (if (interactive()) function(msg) utils::winDialog('ok', msg) else message)(paste0(
          'Next you may see two error dialog boxes about the missing luatex.dll, ',
          'and an error message like "Use of uninitialized value in bitwise or (|)..." in the end. ',
          'These messages can be ignored.'
        ))
        bat = readLines('install-tl-windows.bat')
        # never PAUSE (no way to interact with the Windows shell from R)
        writeLines(
          grep('^pause\\s*$', bat, ignore.case = TRUE, invert = TRUE, value = TRUE),
          'install-tl-windows.bat'
        )
        shell('install-tl-windows.bat -no-gui -profile=../tinytex.profile', invisible = FALSE)
        file.remove('TinyTeX/install-tl.log')
        # target shouldn't be a file but a directory
        if (file_test('-f', target)) file.remove(target)
        dir.create(target, showWarnings = FALSE, recursive = TRUE)
        file.copy(list.files('TinyTeX', full.names = TRUE), target, recursive = TRUE)
      })
      unlink('install-tl-*', recursive = TRUE)
      in_dir(target, {
        bin_tlmgr = file.path('bin', 'win32', 'tlmgr')
        tlmgr = function(...) system2(bin_tlmgr, ...)
        if (not_ctan) {
          tlmgr(c('option', 'repository', shQuote(repository)))
          if (https) tlmgr(c('--repository', 'http://www.preining.info/tlgpg/', 'install', 'tlgpg'))
          if (tlmgr(c('update', '--list')) != 0) {
            warning('The repository ', repository, ' does not seem to be accessible. Reverting to the default CTAN mirror.')
            tlmgr(c('option', 'repository', 'ctan'))
          }
        }
        tlmgr(c('install', 'latex-bin', 'xetex', pkgs_custom, extra_packages))
        if (add_path) tlmgr(c('path', 'add'))
        add_texmf(bin_tlmgr)
      })
    },
    stop('This platform is not supported.')
  )
}

#' @rdname install_tinytex
#' @export
uninstall_tinytex = function(force = FALSE, dir = tinytex_root()) {
  tweak_path()
  if (dir == '') stop('TinyTeX does not seem to be installed.')
  if (!is_tinytex() && !force) stop(
    'Detected TeX Live at "', dir, '", but it appears to be TeX Live instead of TinyTeX. ',
    'To uninstall TeX Live, use the argument force = TRUE.'
  )
  r_texmf('remove')
  tlmgr_path('remove')
  delete_texmf_user()
  unlink(dir, recursive = TRUE)
}

# delete user's texmf tree; don't delete ~/.TinyTeX if TinyTeX itself is
# installed there
delete_texmf_user = function() {
  r = dir.exists(d <- path.expand('~/.TinyTeX'))
  if (!r) return(FALSE)
  d1 = xfun::normalize_path(tinytex_root(error = FALSE))
  if (d1 == '') return()  # not TinyTeX
  d2 = xfun::normalize_path(d)
  if (substr(d1, 1, nchar(d2)) == d2) return(FALSE)
  unlink(d, recursive = TRUE)
  r
}

#' @param packages Whether to reinstall all currently installed packages.
#' @param ... Other arguments to be passed to \code{install_tinytex()} (note
#'   that the \code{extra_packages} argument will be set to \code{tl_pkgs()} if
#'   \code{packages = TRUE}).
#' @rdname install_tinytex
#' @export
reinstall_tinytex = function(packages = TRUE, dir = tinytex_root(), ...) {
  pkgs = if (packages) tl_pkgs()
  if (length(pkgs)) message(
    'If reinstallation fails, try install_tinytex() again. Then ',
    'install the following packages:\n\ntinytex::tlmgr_install(c(',
    paste('"', pkgs, '"', sep = '', collapse = ', '), '))\n'
  )
  # in theory, users should not touch the texmf-local dir; if they did, I'll try
  # to preserve it during reinstall: https://github.com/yihui/tinytex/issues/117
  if (length(list.files(texmf <- file.path(dir, 'texmf-local'), recursive = TRUE)) > 0) {
    dir.create(texmf_tmp <- tempfile(), recursive = TRUE)
    message(
      'The directory ', texmf, ' is not empty. It will be backed up to ',
      texmf_tmp, ' and restored later.\n'
    )
    file.copy(texmf, texmf_tmp, recursive = TRUE)
    on.exit(
      file.copy(file.path(texmf_tmp, basename(texmf)), dirname(texmf), recursive = TRUE),
      add = TRUE
    )
  }
  uninstall_tinytex()
  install_tinytex(extra_packages = pkgs, dir = dir, ...)
}

win_app_dir = function(..., error = TRUE) {
  d = Sys.getenv('APPDATA')
  if (d == '') {
    if (error) stop('Environment variable "APPDATA" not set.')
    return(d)
  }
  file.path(d, ...)
}

#' @param error Whether to signal an error if TinyTeX is not found.
#' @rdname install_tinytex
#' @export
tinytex_root = function(error = TRUE) {
  tweak_path()
  path = Sys.which('tlmgr')
  if (path == '') return('')
  root_dir = function(path, ...) {
    dir = normalizePath(file.path(dirname(path), ...), mustWork = TRUE)
    if (!'bin' %in% list.files(dir)) if (error) stop(
      dir, ' does not seem to be the root directory of TeX Live (no "bin/" dir under it)'
    ) else return('')
    dir
  }
  if (os == 'windows') return(root_dir(path, '..', '..'))
  if (Sys.readlink(path) == '') if (error) stop(
    'Cannot figure out the root directory of TeX Live from ', path,
    ' (not a symlink on ', os, ')'
  ) else return('')
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

is_tinytex = function() tryCatch({
  gsub('^[.]', '', tolower(basename(tinytex_root()))) == 'tinytex'
}, error = function(e) FALSE)

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

download_file = function(...) {
  xfun::download_file(..., quiet = Sys.getenv('APPVEYOR') != '')
}

# LaTeX packages that I use
install_yihui_pkgs = function() {
  pkgs = readLines('https://yihui.org/gh/tinytex/tools/pkgs-yihui.txt')
  tlmgr_install(pkgs)
}

# install a prebuilt version of TinyTeX
install_prebuilt = function() {
  if (is_windows()) {
    installer = 'TinyTeX.zip'
    download_file('https://ci.appveyor.com/api/projects/yihui/tinytex/artifacts/TinyTeX.zip', installer)
    install_windows_zip(installer)
  } else if (is_linux()) {
    system('wget -qO- https://yihui.org/gh/tinytex/tools/download-travis-linux.sh | sh')
  } else {
    stop('TinyTeX was not prebuilt for this platform.')
  }
}

# if you have already downloaded the zip archive, use this function to install it
install_windows_zip = function(path = 'TinyTeX.zip') {
  unzip(path, exdir =  win_app_dir())
  tlmgr_path(); texhash(); fmtutil(); updmap(); fc_cache()
}

#' Copy TinyTeX to another location and use it in another system
#'
#' The function \code{copy_tinytex()} copies the existing TinyTeX installation
#' to another directory (e.g., a portable device like a USB stick). The function
#' \code{use_tinytex()} runs \command{tlmgr path add} to add the copy of TinyTeX
#' in an existing folder to the \code{PATH} variable of the current system, so
#' that you can use utilities such as \command{tlmgr} and \command{pdflatex},
#' etc.
#' @param from The root directory of the TinyTeX installation. For
#'   \code{copy_tinytex()}, the default value \code{tinytex_root()} should be a
#'   reasonable guess if you installed TinyTeX via \code{install_tinytex()}. For
#'   \code{use_tinytex()}, if \code{from} is not provided, a dialog for choosing
#'   the directory interactively will pop up.
#' @param to The destination directory where you want to make a copy of TinyTeX.
#'   Like \code{from} in \code{use_tinytex()}, a dialog will pop up if \code{to}
#'   is not provided in \code{copy_tinytex()}.
#' @note You can only copy TinyTeX and use it in the same system, e.g., the
#'   Windows version of TinyTeX only works on Windows.
#' @export
copy_tinytex = function(from = tinytex_root(), to = select_dir('Select Destination Directory')) {
  if (!dir_exists(from)) stop('TinyTeX does not seem to be installed.')
  if (length(to) != 1 || !dir_exists(to))
    stop("The destination directory '", to, "' does not exist.")
  file.copy(from, to, recursive = TRUE)
}

#' @rdname copy_tinytex
#' @export
use_tinytex = function(from = select_dir('Select TinyTeX Directory')) {
  if (length(from) != 1) stop('Please provide a valid path to the TinyTeX directory.')
  d = list.files(file.path(from, 'bin'), full.names = TRUE)
  d = d[dir_exists(d)]
  if (length(d) != 1) stop("The directory '", from, "' does not contain TinyTeX.")
  p = file.path(d, 'tlmgr')
  if (os == 'windows') p = paste0(p, '.bat')
  if (system2(p, c('path', 'add')) != 0) stop(
    "Failed to add '", d, "' to your system's environment variable PATH. You may ",
    "consider the fallback approach, i.e., set options(tinytex.tlmgr.path = '", p, "')."
  )
  message('Restart R and your editor and check if tinytex::tinytex_root() points to ', from)
}

select_dir = function(caption = 'Select Directory') {
  d = tryCatch(rstudioapi::selectDirectory(caption), error = function(e) {
    if (os == 'windows') utils::choose.dir(caption = caption) else {
      tcltk::tk_choose.dir(caption = caption)
    }
  })
  if (!is.null(d) && !is.na(d)) d
}
