#' Install/Uninstall TinyTeX
#'
#' The function \code{install_tinytex()} downloads and installs TinyTeX, a
#' custom LaTeX distribution based on TeX Live. The function
#' \code{uninstall_tinytex()} removes TinyTeX; \code{reinstall_tinytex()}
#' reinstalls TinyTeX as well as previously installed LaTeX packages by default;
#' \code{tinytex_root()} returns the root directory of TinyTeX if found.
#' @param force Whether to force to install or uninstall TinyTeX. For
#'   \code{install_tinytex()}, \code{force = FALSE} will stop this function from
#'   installing TinyTeX if another LaTeX distribution is detected, or the
#'   directory specified via the \code{dir} argument exists.
#' @param dir The directory to install (should not exist unless \code{force =
#'   TRUE}) or uninstall TinyTeX.
#' @param version The version of TinyTeX, e.g., \code{"2020.09"} (see all
#'   available versions at \url{https://github.com/rstudio/tinytex-releases}, or
#'   via \code{xfun::github_releases('rstudio/tinytex-releases')}). By default,
#'   it installs the latest daily build of TinyTeX. If \code{version =
#'   'latest'}, it installs the latest monthly Github release of TinyTeX.
#' @param bundle The bundle name of TinyTeX (which determines the collection of
#'   LaTeX packages to install). See
#'   \url{https://github.com/rstudio/tinytex-releases#releases} for all possible
#'   bundles and their meanings.
#' @param repository The CTAN repository to set. By default, it is the
#'   repository automatically chosen by \code{https://mirror.ctan.org} (which is
#'   usually the fastest one to your location). You can find available
#'   repositories at \code{https://ctan.org/mirrors}), e.g.,
#'   \code{'http://mirrors.tuna.tsinghua.edu.cn/CTAN/'}, or
#'   \code{'https://mirror.las.iastate.edu/tex-archive/'}. In theory, this
#'   argument should end with the path \file{/systems/texlive/tlnet}, and if it
#'   does not, the path will be automatically appended. You can get a full list
#'   of CTAN mirrors via \code{tinytex:::ctan_mirrors()}.
#' @param extra_packages A character vector of extra LaTeX packages to be
#'   installed. By default, a vector of all currently installed LaTeX packages
#'   if an existing installation of TinyTeX is found. If you want a fresh
#'   installation, you may use \code{extra_packages = NULL}.
#' @param add_path Whether to run the command \command{tlmgr path add} to add
#'   the bin path of TeX Live to the system environment variable \var{PATH}.
#' @references See the TinyTeX documentation (\url{https://yihui.org/tinytex/})
#'   for the default installation directories on different platforms.
#' @note If you really want to disable the installation, you may set the
#'   environment variable \var{TINYTEX_PREVENT_INSTALL} to \code{true}. Then
#'   \code{install_tinytex()} will fail immediately. This can be useful to
#'   sysadmins who want to prevent the accidental installation of TinyTeX.
#'
#'   Installing TinyTeX requires perl (on Linux, perl-base is insufficient).
#' @export
install_tinytex = function(
  force = FALSE, dir = 'auto', version = 'daily', bundle = 'TinyTeX-1', repository = 'auto',
  extra_packages = if (is_tinytex()) tl_pkgs(), add_path = TRUE
) {
  if (tolower(Sys.getenv('TINYTEX_PREVENT_INSTALL')) == 'true') stop(
    "The environment variable 'TINYTEX_PREVENT_INSTALL' was set to 'true', so ",
    "the installation is aborted."
  )
  if (!is.logical(force)) stop('The argument "force" must take a logical value.')
  continue_inst = function() {
    tolower(substr(readline('Continue the installation anyway? (Y/N) '), 1, 1)) == 'y'
  }
  # if tlmgr is detected in the system, ask in interactive mode whether to
  # continue the installation, and stop in non-interactive() mode
  p = which_bin(c('tlmgr', 'pdftex', 'xetex', 'luatex'))
  p = p[p != '']
  if (!force && length(p)) {
    message("Found '", p[1], "', which indicates a LaTeX distribution may have existed in the system.")
    if (interactive()) {
      if (!continue_inst()) return(invisible(''))
    } else stop(
      'If you want to force installing TinyTeX anyway, use tinytex::install_tinytex(force = TRUE).'
    )
  }
  force(extra_packages)  # evaluate it before TinyTeX is removed or reinstalled next
  check_dir = function(dir) {
    if (dir_exists(dir) && !force) stop(
      'The directory "', dir, '" exists. Please either delete it, ',
      'or use tinytex::install_tinytex(force = TRUE).'
    )
  }
  if (missing(dir)) dir = ''
  user_dir = ''
  if (dir != '') {
    dir = gsub('[/\\]+$', '', dir)  # remove trailing slashes
    check_dir(dir)
    dir = xfun::normalize_path(dir)
    if (is_windows() && !valid_path(dir)) {
      warning(
        "The directory path '", dir, "' contains spaces or non-ASCII characters, ",
        "and TinyTeX may not work. Please use a path with pure ASCII characters and no spaces.",
        immediate. = TRUE
      )
      if (!force && !(interactive() && continue_inst())) return(invisible(dir))
    }
    unlink(dir, recursive = TRUE)
    user_dir = dir
  }

  repository = normalize_repo(repository)
  not_ctan = repository != 'ctan'
  https = grepl('^https://', repository)

  if (!grepl('TinyTeX', bundle)) message(
    "The bundle name '", bundle, "' has been automatically corrected to '",
    bundle <- gsub('tinytex', 'TinyTeX', bundle, ignore.case = TRUE), "'."
  )

  owd = setwd(tempdir()); on.exit(setwd(owd), add = TRUE)

  if ((texinput <- Sys.getenv('TEXINPUT')) != '') message(
    'Your environment variable TEXINPUT is "', texinput,
    '". Normally you should not set this variable, because it may lead to issues like ',
    'https://github.com/rstudio/tinytex/issues/92.'
  )

  switch(
    os,
    'unix' = {
      check_local_bin()
      if (os_index != 3 && !any(dir_exists(c('~/bin', '~/.local/bin')))) on.exit(message(
        'You may have to restart your system after installing TinyTeX to make sure ',
        '~/bin appears in your PATH variable (https://github.com/rstudio/tinytex/issues/16).'
      ), add = TRUE)
    },
    'windows' = {},
    stop('Sorry, but tinytex::install_tinytex() does not support this platform: ', os)
  )

  src_install = getOption('tinytex.source.install', need_source_install())
  # if needs to install from source, set `extra_packages` according to `bundle`
  if (src_install && missing(extra_packages)) {
    extra_packages = switch(
      bundle,
      'TinyTeX-2' = 'scheme-full',
      'TinyTeX' = read_lines('https://tinytex.yihui.org/pkgs-custom.txt'),
      'TinyTeX-0' = {
        warning("bundle = 'TinyTeX-0' is not supported for your system"); NULL
      }
    )
  }
  install = function(...) {
    if (src_install) {
      install_tinytex_source(repository, ...)
    } else {
      install_prebuilt(bundle, ..., repo = repository)
    }
  }
  if (version == 'daily') {
    version = ''
    # test if https://yihui.org or github.com is accessible because the daily
    # version is downloaded from there
    determine_version = function() {
      if (xfun::url_accessible('https://yihui.org')) return('')
      if (xfun::url_accessible('https://github.com')) return('daily-github')
      warning(
        "The daily version of TinyTeX does not appear to be accessible. ",
        "Switching to version = 'latest' instead. If you are sure to install ",
        "the daily version, call tinytex::install_tinytex(version = 'daily') ",
        "(which may fail)."
      )
      'latest'
    }
    if (missing(version) && !src_install) version = determine_version()
  }
  user_dir = install(user_dir, version, add_path, extra_packages)

  opts = options(tinytex.tlmgr.path = find_tlmgr(user_dir))
  on.exit(options(opts), add = TRUE)

  if (not_ctan) {
    # install tlgpg for Windows and macOS users if an HTTPS repo is preferred
    if (os_index %in% c(1, 3) && https) {
      tlmgr(c('--repository', 'http://www.preining.info/tlgpg/', 'install', 'tlgpg'))
    }
    tlmgr_repo(repository)
    if (tlmgr(c('update', '--list')) != 0) {
      warning('The repository ', repository, ' does not seem to be accessible. Reverting to the default CTAN mirror.')
      tlmgr(c('option', 'repository', 'ctan'))
    }
  }

  invisible(user_dir)
}

# TinyTeX has to be installed from source for OSes that are not Linux or
# non-x86_64 Linux machines
need_source_install = function() {
  os_index == 0 || (os_index == 2 && !identical(Sys.info()[['machine']], 'x86_64'))
}

# append /systems/texlive/tlnet to the repo url if necessary
normalize_repo = function(url) {
  # don't normalize the url if users passes I(url) or 'ctan' or NULL
  if (is.null(url) || url == 'ctan' || inherits(url, 'AsIs')) return(url)
  if (url == 'auto') return(auto_repo())
  if (url == 'illinois') return('https://ctan.math.illinois.edu/systems/texlive/tlnet')
  url = sub('/+$', '', url)
  if (!grepl('/tlnet$', url)) {
    url2 = paste0(url, '/systems/texlive/tlnet')
    # return the amended url if it works
    if (xfun::url_accessible(url2)) return(url2)
  }
  url
}

# get the automatic CTAN mirror returned from mirror.ctan.org
auto_repo = function() {
  # curlGetHeaders() may time out, hence tryCatch() here
  x = tryCatch(
    curlGetHeaders('https://mirror.ctan.org/systems/texlive/tlnet'),
    error = function(e) character()
  )
  x = xfun::grep_sub('^location: (https://[^[:space:]]+)\\s*$', '\\1', x, ignore.case = TRUE)
  x = tail(x, 1)
  if (length(x) == 1) x else 'ctan'
}

# retrieve all CTAN (https) mirrors
ctan_mirrors = function() {
  html = xfun::file_string('https://ctan.org/mirrors/')
  r = function(i) sprintf('^(.*>)?\\s*([^<]+)</h%d>\\s*(.*)$', i)
  res = unlist(lapply(unlist(strsplit(html, '<h2[^>]*>')), function(x) {
    x = unlist(strsplit(x, '<h3[^>]*>'))
    if (length(x) < 2 || !grepl('</h2>', x[1])) return()
    r2 = r(2)
    continent = gsub(r2, '\\2', x[1])
    x[1] = gsub(r2, '\\3', x[1])
    x = x[!grepl('^\\s*$', x)]
    r3 = r(3)
    if (!grepl(r3, x[1])) return()
    country = gsub(r3, '\\2', x)
    x = gsub(r3, '\\3', x)
    r4 = r(4)
    x = lapply(x, function(z) {
      z = unlist(strsplit(z, '<h4[^>]*>'))
      m = regexec('<a href="(https://[^"]+)"[^>]*>https</a>', z)
      link = unlist(lapply(regmatches(z, m), `[`, 2))
      names(link) = gsub(r4, '\\2', z)
      link[!is.na(link)]
    })
    structure(list(structure(x, names = country)), names = continent)
  }))
  nm = lapply(strsplit(names(res), '.', fixed = TRUE), function(x) {
    x3 = paste(x[-(1:2)], collapse = '.')
    r5 = '.*\\(|\\).*'
    x3 = if (grepl(r5, x3)) gsub(r5, '', x3) else ''
    c(x[1], x[2], x3)
  })
  nm = do.call(rbind, nm)
  res = cbind(nm, unname(res))
  colnames(res) = c('Continent', 'Country/Region', 'City', 'URL')
  as.data.frame(res)
}

# use %APPDATA%/TinyTeX if it exists or doesn't contain spaces or non-ASCII
# chars, otherwise use %ProgramData%, because TeX Live doesn't work when the
# installation path contains non-ASCII chars
win_app_dir = function(s) {
  d = Sys.getenv('TINYTEX_DIR')
  if (d != '') return(file.path(d, s))
  d = Sys.getenv('APPDATA')
  if (d != '') {
    d2 = file.path(d, s)
    if (dir_exists(d2)) {
      if (getOption('tinytex.warn.appdata', TRUE) && !xfun::is_ascii(d2)) warning(
        "You are recommended to move TinyTeX to another location via\n\n",
        "  tinytex::copy_tinytex(to = Sys.getenv('ProgramData'), move = TRUE)\n\n",
        "otherwise TinyTeX will not work because its current installation path '",
        normalizePath(d2), "' contains non-ASCII characters.", call. = FALSE
      )
      return(d2)
    }
    if (valid_path(d)) return(d2)
  }
  d = Sys.getenv('ProgramData')
  if (d == '') stop("The environment variable 'ProgramData' is not set.")
  file.path(d, s)
}

# test if path is pure ASCII and has no spaces
valid_path = function(x) grepl('^[!-~]+$', x)

# check if /usr/local/bin on macOS is writable
check_local_bin = function() {
  if (os_index != 3 || is_writable(p <- '/usr/local/bin')) return()
  message(
    'The directory ', p, ' is not writable. I recommend that you make it writable. ',
    'See https://github.com/rstudio/tinytex/issues/24 for more info.'
  )
  if (!dir_exists(p)) osascript(paste('mkdir -p', p))
  user = system2('whoami', stdout = TRUE)
  osascript(sprintf('chown -R %s:admin %s', user, p))
}

osascript = function(cmd) {
  if (system(sprintf(
    "/usr/bin/osascript -e 'do shell script \"%s\" with administrator privileges'", cmd
  )) != 0) warning(
    "Please run this command in your Terminal (password required):\n  sudo ",
    cmd, call. = FALSE
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
  download_file('https://tinytex.yihui.org/install-unx.sh')
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
  post_install_config(add_path, extra_packages, repo)
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
  r_texmf('remove', .quiet = TRUE)
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
  # to preserve it during reinstall: https://github.com/rstudio/tinytex/issues/117
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
  path = which_bin('tlmgr')
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

# return paths to TinyTeX's executables even if TinyTeX was not added to PATH
which_bin = function(exec) {
  tweak_path()
  Sys.which(exec)
}

# trace a symlink to its final destination
symlink_root = function(path) {
  path = normalizePath(path, mustWork = TRUE)
  path2 = Sys.readlink(path)
  if (path2 == '') return(path)  # no longer a symlink; must be resolved now
  # path2 may still be a _relative_ symlink
  in_dir(dirname(path), symlink_root(path2))
}

# a helper function to open tlmgr.pl (on *nix)
open_tlmgr = function() {
  file.edit(symlink_root(Sys.which('tlmgr')))
}

#' Check if the LaTeX installation is TinyTeX
#'
#' First find the root directory of the installation via
#' \code{\link{tinytex_root}()}. Then check if the directory name is
#' \code{"tinytex"} (case-insensitive). If not, further check if the first line
#' of the file \file{texmf-dist/web2c/fmtutil.cnf} under the directory contains
#' \code{"TinyTeX"} or \code{".TinyTeX"}. If the binary version of TinyTeX was
#' installed, \file{fmtutil.cnf} should contain a line like \samp{Generated by
#' */TinyTeX/bin/x86_64-darwin/tlmgr on Thu Sep 17 07:13:28 2020}.
#' @return A logical value indicating if the LaTeX installation is TinyTeX.
#' @export
#' @examples tinytex::is_tinytex()
is_tinytex = function() tryCatch({
  root = tinytex_root()
  root != '' && (
    grepl('^[.]?tinytex$', tolower(basename(root))) ||
      file.exists(file.path(root, '.tinytex'))
  )
}, error = function(e) FALSE)

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
  pkgs = read_lines('https://tinytex.yihui.org/pkgs-yihui.txt')
  tlmgr_install(pkgs)
}

# install a prebuilt version of TinyTeX
install_prebuilt = function(
  pkg = '', dir = '', version = '', add_path = TRUE, extra_packages = NULL,
  repo = 'ctan', hash = FALSE, cache = NA
) {
  if (need_source_install()) stop(
    'There is no prebuilt version of TinyTeX for this platform: ',
    paste(Sys.info()[c('sysname', 'machine')], collapse = ' '), '.'
  )
  dir0 = default_inst(); b = basename(dir0)
  dir1 = xfun::normalize_path(dir)  # expected installation dir
  if (dir1 == '') dir1 = dir0
  # the archive is extracted to this target dir
  target = dirname(dir1)
  dir2 = file.path(target, b)  # path to (.)TinyTeX/ after extraction

  if (xfun::file_ext(pkg) == '') {
    if (version == 'latest') {
      version = xfun::github_releases('rstudio/tinytex-releases', version)
    } else if (version == 'daily-github') {
      version = ''
    }
    version = gsub('^v', '', version)
    installer = if (pkg == '') 'TinyTeX' else pkg
    # e.g., TinyTeX-0.zip, TinyTeX-1-v2020.10.tar.gz, ...
    pkg = paste0(
      installer, if (version != '') paste0('-v', version), '.',
      c('zip', 'tar.gz', 'tgz')[os_index]
    )
    # Full scheme is bundled as a self extracting archive on Windows
    if (os_index == 1 && installer == 'TinyTeX-2') pkg = xfun::with_ext(pkg, "exe")
    if (file.exists(pkg) && is.na(cache)) {
      # invalidate cache (if unspecified) when the installer is more than one day old
      if (as.numeric(difftime(Sys.time(), file.mtime(pkg), units = 'days')) > 1)
        cache = FALSE
    }
    if (identical(cache, FALSE)) {
      file.remove(pkg); on.exit(file.remove(pkg), add = TRUE)
    }
    if (!file.exists(pkg)) download_installer(pkg, version)
  }
  pkg = path.expand(pkg)

  # installation dir shouldn't be a file but a directory
  file.remove(exist_files(c(dir1, dir2)))
  if (grepl('[.]exe$', pkg)) {
    system2(pkg, args = c('-y', paste0('-o', path.expand(target))))
  } else {
    extract = if (grepl('[.]zip$', pkg)) unzip else untar
    extract(pkg, exdir = path.expand(target))
  }
  # TinyTeX (or .TinyTeX) is extracted to the parent dir of `dir`; may need to rename
  if (dir != '') {
    if (basename(dir1) != b) file.rename(dir2, dir1)
    opts = options(tinytex.tlmgr.path = find_tlmgr(dir1))
    on.exit(options(opts), add = TRUE)
  }
  post_install_config(add_path, extra_packages, repo, hash)
  invisible(dir1)
}

# post-install configurations
post_install_config = function(add_path = TRUE, extra_packages = NULL, repo = 'ctan', hash = FALSE) {
  if (os_index == 2) {
    if (!dir_exists(bin_dir <- '~/.local/bin')) dir.create(bin_dir <- '~/bin', FALSE, TRUE)
    tlmgr(c('option', 'sys_bin', bin_dir))
  }
  # fix fonts.conf: https://github.com/rstudio/tinytex/issues/313
  tlmgr(c('postaction', 'install', 'script', 'xetex'), .quiet = TRUE)
  # do not wrap lines in latex log (#322)
  tlmgr_conf(c('texmf', 'max_print_line', '10000'), .quiet = TRUE, stdout = FALSE)

  if (add_path) tlmgr_path()
  r_texmf(.quiet = TRUE)
  # don't use the default random ctan mirror when installing on CI servers
  if (repo != 'ctan' || tolower(Sys.getenv('CI')) != 'true')
    tlmgr_repo(repo, stdout = FALSE, .quiet = TRUE)
  tlmgr_install(setdiff(extra_packages, tl_pkgs()))
  if (hash) {
    texhash(); fmtutil(stdout = FALSE); updmap(); fc_cache()
  }
}

download_installer = function(file, version) {
  v = if (version == '') 'daily' else paste0('v', version)
  u = sprintf('https://github.com/rstudio/tinytex-releases/releases/download/%s/%s', v, file)
  download_file(u, file, mode = 'wb')
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
#' @param move Whether to use the new copy and delete the original copy of
#'   TinyTeX after copying it.
#' @note You can only copy TinyTeX and use it in the same system, e.g., the
#'   Windows version of TinyTeX only works on Windows.
#' @export
copy_tinytex = function(
  from = tinytex_root(), to = select_dir('Select Destination Directory'), move = FALSE
) {
  op = options(tinytex.warn.appdata = FALSE); on.exit(options(op), add = TRUE)
  if (!dir_exists(from)) stop('TinyTeX does not seem to be installed.')
  if (length(to) != 1 || !dir_exists(to))
    stop("The destination directory '", to, "' does not exist.")
  target = file.path(to, basename(from))
  if (!move || !{tlmgr_path('remove'); res <- file.rename(from, target)}) {
    res = file.copy(from, to, recursive = TRUE)
    if (res && move) {
      tlmgr_path('remove')
      unlink(from, recursive = TRUE)
    }
  }
  if (res && move) use_tinytex(target)
  res
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
  op = options(tinytex.tlmgr.path = p); on.exit(options(op), add = TRUE)
  post_install_config(FALSE)
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
