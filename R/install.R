#' Install/Uninstall TinyTeX
#'
#' The function \code{install_tinytex()} downloads and installs TinyTeX, a
#' custom LaTeX distribution based on TeX Live. The function
#' \code{uninstall_tinytex()} removes TinyTeX; \code{reinstall_tinytex()}
#' reinstalls TinyTeX as well as previously installed LaTeX packages by default;
#' \code{tinytex_root()} returns the root directory of TinyTeX if found.
#' @param force Whether to force to install (override) or uninstall TinyTeX.
#' @param dir The directory to install or uninstall TinyTeX (should not exist
#'   unless \code{force = TRUE}).
#' @param version The version of TinyTeX, e.g., \code{"2020.09"} (see all
#'   available versions at \url{https://github.com/yihui/tinytex-releases}). By
#'   default, it installs the latest daily build of TinyTeX.
#' @param repository The CTAN repository to set. You can find available
#'   repositories at \code{https://ctan.org/mirrors}), e.g.,
#'   \code{'http://mirrors.tuna.tsinghua.edu.cn/CTAN/'}, or
#'   \code{'https://mirror.las.iastate.edu/tex-archive/'}. In theory, this
#'   argument should end with the path \file{/systems/texlive/tlnet}, and if it
#'   does not, the path will be automatically appended.
#' @param extra_packages A character vector of extra LaTeX packages to be
#'   installed. By default, a vector of all currently installed LaTeX packages
#'   if an existing installation of TinyTeX is found. If you want a fresh
#'   installation, you may use \code{extra_packages = NULL}.
#' @param add_path Whether to run the command \command{tlmgr path add} to add
#'   the bin path of TeX Live to the system environment variable \var{PATH}.
#' @references See the TinyTeX documentation (\url{https://yihui.org/tinytex/})
#'   for the default installation directories on different platforms.
#' @export
install_tinytex = function(
  force = FALSE, dir = 'auto', version = '', repository = 'ctan',
  extra_packages = if (is_tinytex()) tl_pkgs(), add_path = TRUE
) {
  if (!is.logical(force)) stop('The argument "force" must take a logical value.')
  check_dir = function(dir) {
    if (dir_exists(dir) && !force) stop(
      'The directory "', dir, '" exists. Please either delete it, ',
      'or use install_tinytex(force = TRUE).'
    )
  }
  if (missing(dir)) dir = ''
  user_dir = ''
  if (dir != '') {
    dir = gsub('[/\\]+$', '', dir)  # remove trailing slashes
    check_dir(dir)
    unlink(dir, recursive = TRUE)
    user_dir = normalizePath(dir, mustWork = FALSE)
  }
  tweak_path()
  msg = if (tlmgr_available()) {
    if (!is_tinytex()) {
      system2('tlmgr', '--version')
      c(
        'Detected an existing tlmgr at ', Sys.which('tlmgr'), '. ',
        'It seems TeX Live has been installed (check tinytex::tinytex_root()). '
      )
    }
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

  https = grepl('^https://', repository)
  repository = sub('/+$', '', repository)
  if ((not_ctan <- repository != 'ctan') && !grepl('/tlnet$', repository)) {
    repository = paste0(repository, '/systems/texlive/tlnet')
  }

  owd = setwd(tempdir()); on.exit(setwd(owd), add = TRUE)

  if ((texinput <- Sys.getenv('TEXINPUT')) != '') message(
    'Your environment variable TEXINPUT is "', texinput,
    '". Normally you should not set this variable, because it may lead to issues like ',
    'https://github.com/yihui/tinytex/issues/92.'
  )

  switch(
    os,
    'unix' = {
      check_local_bin()
      if (os_index != 2 && dir_exists('~/bin')) on.exit(message(
        'You may have to restart your system after installing TinyTeX to make sure ',
        '~/bin appears in your PATH variable (https://github.com/yihui/tinytex/issues/16).'
      ), add = TRUE)
    },
    'windows' = {},
    stop('Sorry, but tinytex::install_tinytex() does not support this platform: ', os)
  )

  install = function(...) {
    if (os_index == 0) {
      install_tinytex_source(repository, ...)
    } else {
      install_prebuilt('TinyTeX-1', ...)
    }
  }
  force(extra_packages)  # evaluate it before installing another version of TinyTeX
  user_dir = install(user_dir, version, add_path, extra_packages)

  opts = options(tinytex.tlmgr.path = find_tlmgr(user_dir))
  on.exit(options(opts), add = TRUE)

  if (not_ctan) {
    # install tlgpg for Windows and macOS users if an HTTPS repo is preferred
    if (os_index %in% c(1, 3) && https) {
      tlmgr(c('--repository', 'http://www.preining.info/tlgpg/', 'install', 'tlgpg'))
    }
    tlmgr(c('option', 'repository', shQuote(repository)))
    if (tlmgr(c('update', '--list')) != 0) {
      warning('The repository ', repository, ' does not seem to be accessible. Reverting to the default CTAN mirror.')
      tlmgr(c('option', 'repository', 'ctan'))
    }
  }

  invisible(user_dir)
}

win_app_dir = function(..., error = TRUE) {
  d = Sys.getenv('APPDATA')
  if (d == '') {
    if (error) stop('Environment variable "APPDATA" not set.')
    return(d)
  }
  file.path(d, ...)
}

# check if /usr/local/bin on macOS is writable
check_local_bin = function() {
  if (os_index != 3 || is_writable('/usr/local/bin')) return()
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

install_tinytex_source = function(repo = '', dir, version, add_path, extra_packages) {
  if (version != '') stop(
    'tinytex::install_tinytex() does not support installing a specific version of ',
    'TinyTeX for your platform. Please use the argument version = "".'
  )
  if (repo != 'ctan') {
    Sys.setenv(CTAN_REPO = repo)
    on.exit(Sys.unsetenv('CTAN_REPO'), add = TRUE)
  }
  download_file('https://yihui.org/gh/tinytex/tools/install-unx.sh')
  res = system2('sh', c(
    'install-unx.sh', if (repo != 'ctan') c('--no-admin', '--path', shQuote(repo))
  ))
  if (res != 0) stop('Failed to install TinyTeX', call. = FALSE)
  target = normalizePath(default_inst())
  if (!dir_exists(target)) stop('Failed to install TinyTeX.')
  if (!dir %in% c('', target)) {
    dir.create(dirname(dir), showWarnings = FALSE, recursive = TRUE)
    dir_rename(target, dir)
    target = dir
  }
  opts = options(tinytex.tlmgr.path = find_tlmgr(target))
  on.exit(options(opts), add = TRUE)
  post_install_config(add_path, extra_packages)
  unlink(c('install-unx.sh', 'install-tl.zip', 'pkgs-custom.txt', 'tinytex.profile'))
  target
}

os_index = if (is_windows()) 1 else if (is_linux()) 2 else if (is_macos()) 3 else 0

default_inst = function() switch(
  os_index, win_app_dir('TinyTeX'), '~/.TinyTeX', '~/Library/TinyTeX'
)

find_tlmgr = function(dir = default_inst()) {
  bin = file.path(list.files(file.path(dir, 'bin'), full.names = TRUE), 'tlmgr')
  if (is_windows()) bin = paste0(bin, '.bat')
  bin[file_test('-x', bin)][1]
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

# it should be TinyTeX if the root dir name is [.]TinyTeX, or a line like this
# can be found in fmtutil.cnf:
# Generated by */TinyTeX/bin/x86_64-darwin/tlmgr on Thu Sep 17 07:13:28 2020
is_tinytex = function() tryCatch({
  root = tinytex_root()
  gsub('^[.]', '', tolower(basename(root))) == 'tinytex' || any(grepl(
    '\\W[.]?TinyTeX\\W',
    readLines(file.path(root, 'texmf-dist/web2c/fmtutil.cnf'), n = 1)
  ))
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
install_prebuilt = function(
  pkg = '', dir = '', version = '', add_path = TRUE, extra_packages = NULL, hash = FALSE, cache = NA
) {
  if (os_index == 0) stop(
    'There is no prebuilt version of TinyTeX for this platform: ',
    .Platform$OS.type, '.'
  )
  dir0 = default_inst(); b = basename(dir0)
  dir1 = xfun::normalize_path(dir)  # expected installation dir
  if (dir1 == '') dir1 = dir0
  # the archive is extracted to this target dir
  target = dirname(dir1)
  dir2 = file.path(target, b)  # path to (.)TinyTeX/ after extraction

  if (xfun::file_ext(pkg) == '') {
    installer = if (pkg == '') 'TinyTeX' else pkg
    # e.g., TinyTeX-0.zip, TinyTeX-1-v2020.10.tar.gz, ...
    pkg = paste0(
      installer, if (version != '') paste0('-v', version), '.',
      c('zip', 'tar.gz', 'tgz')[os_index]
    )
    if (file.exists(pkg) && is.na(cache)) {
      # invalidate cache (if unspecified) when the installer is more than one day old
      if (as.numeric(difftime(Sys.time(), file.mtime(pkg), units = 'days')) > 1)
        cache = FALSE
    }
    if (xfun::isFALSE(cache)) file.remove(pkg)
    if (!file.exists(pkg)) download_installer(pkg, version)
  }

  # installation dir shouldn't be a file but a directory
  file.remove(exist_files(c(dir1, dir2)))
  extract = if (grepl('[.]zip$', pkg)) unzip else untar
  extract(pkg, exdir = path.expand(target))
  # TinyTeX (or .TinyTeX) is extracted to the parent dir of `dir`; may need to rename
  if (dir != '') {
    if (basename(dir1) != b) file.rename(dir2, dir1)
    opts = options(tinytex.tlmgr.path = find_tlmgr(dir1))
    on.exit(options(opts), add = TRUE)
  }
  post_install_config(add_path, extra_packages, hash)
  invisible(dir1)
}

# post-install configurations
post_install_config = function(add_path, extra_packages, hash = FALSE) {
  if (os_index == 2) {
    dir.create('~/bin', FALSE, TRUE)
    tlmgr(c('option', 'sys_bin', '~/bin'))
  }
  if (add_path) tlmgr_path()
  r_texmf()
  tlmgr_install(setdiff(extra_packages, tl_pkgs()))
  if (hash) {
    texhash(); fmtutil(stdout = FALSE); updmap(); fc_cache()
  }
}

download_installer = function(file, version) {
  url = if (version != '') sprintf(
    'https://github.com/yihui/tinytex-releases/releases/download/v%s/%s', version, file
  ) else paste0('https://yihui.org/tinytex/', file)
  download_file(url, file)
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
