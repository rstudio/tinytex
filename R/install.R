#' Install/Uninstall TinyTeX
#'
#' The function `install_tinytex()` downloads and installs TinyTeX, a
#' custom LaTeX distribution based on TeX Live. The function
#' `uninstall_tinytex()` removes TinyTeX; `reinstall_tinytex()`
#' reinstalls TinyTeX as well as previously installed LaTeX packages by default;
#' `tinytex_root()` returns the root directory of TinyTeX if found.
#' @param force Whether to force to install or uninstall TinyTeX. For
#'   `install_tinytex()`, `force = FALSE` will stop this function from
#'   installing TinyTeX if another LaTeX distribution is detected, or the
#'   directory specified via the `dir` argument exists.
#' @param dir The directory to install (should not exist unless `force =
#'   TRUE`) or uninstall TinyTeX.
#' @param version The version of TinyTeX, e.g., `"2020.09"` (see all
#'   available versions at <https://github.com/rstudio/tinytex-releases>, or
#'   via `xfun::github_releases('rstudio/tinytex-releases')`). By default,
#'   it installs the latest daily build of TinyTeX. If `version =
#'   'latest'`, it installs the latest monthly Github release of TinyTeX.
#' @param bundle The bundle name of TinyTeX (which determines the collection of
#'   LaTeX packages to install). See
#'   <https://github.com/rstudio/tinytex-releases#releases> for all possible
#'   bundles and their meanings.
#' @param repository The CTAN repository to set. By default, it is
#'   `https://tlnet.yihui.org` (a CDN-based mirror); if this site is not
#'   accessible, use the repository automatically chosen by
#'   `https://mirror.ctan.org` (which is usually the fastest one to your
#'   location). You can find available repositories at
#'   `https://ctan.org/mirrors`), e.g.,
#'   `'http://mirrors.tuna.tsinghua.edu.cn/CTAN/'`, or
#'   `'https://mirror.las.iastate.edu/tex-archive/'`. You can get a full
#'   list of CTAN mirrors via `tinytex:::ctan_mirrors()`.
#' @param extra_packages A character vector of extra LaTeX packages to be
#'   installed. By default, a vector of all currently installed LaTeX packages
#'   if an existing installation of TinyTeX is found. If you want a fresh
#'   installation, you may use `extra_packages = NULL`.
#' @param add_path Whether to add the bin path of TeX Live to the system
#'   environment variable \var{PATH}. See [tlmgr_path()].
#' @references See the TinyTeX documentation (<https://yihui.org/tinytex/>)
#'   for the default installation directories on different platforms.
#' @note If you really want to disable the installation, you may set the
#'   environment variable \var{TINYTEX_PREVENT_INSTALL} to `true`. Then
#'   `install_tinytex()` will fail immediately. This can be useful to
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
      if (os_index != 3 && !any(dir_exists(c('~/bin', '~/.local/bin')))) on.exit(message(
        'You may have to restart your system after installing TinyTeX to make sure ',
        '~/bin appears in your PATH variable (https://github.com/rstudio/tinytex/issues/16).'
      ), add = TRUE)
    },
    'windows' = {},
    stop('Sorry, but tinytex::install_tinytex() does not support this platform: ', os)
  )

  if (version == 'latest') {
    version = xfun::github_releases('rstudio/tinytex-releases', version)
  }
  version = gsub('^v([0-9]+[.][0-9]+.*)', '\\1', version)  # pure number
  src_install = getOption('tinytex.source.install', !binary_supported(version))
  # if needs to install from source, set `extra_packages` according to `bundle`
  if (src_install && missing(extra_packages)) {
    extra_packages = switch(
      bundle,
      'TinyTeX-2' = 'scheme-full',
      'TinyTeX' = read_lines('https://tinytex.yihui.org/pkgs-custom.txt'),
      'TinyTeX-1' = read_lines('https://tinytex.yihui.org/pkgs-yihui.txt'),
      'TinyTeX-0' = {
        warning("bundle = 'TinyTeX-0' is not supported for your system"); NULL
      }
    )
  }
  install = function(...) {
    if (src_install) {
      install_tinytex_source(repository, ...)
    } else {
      install_via_script(bundle, ..., repo = repository)
    }
  }
  user_dir = install(user_dir, version, add_path, extra_packages)

  opts = options(tinytex.tlmgr.path = find_tlmgr(user_dir))
  on.exit(options(opts), add = TRUE)

  if (not_ctan) {
    # install tlgpg for Windows and macOS users if an HTTPS repo is preferred
    if (os_index %in% c(1, 3) && https) {
      tlmgr(c('--repository', 'https://www.preining.info/tlgpg/', 'install', 'tlgpg'))
    }
    tlmgr_repo(repository)
    if (tlmgr(c('update', '--list')) != 0) {
      warning('The repository ', repository, ' does not seem to be accessible. Reverting to the default CTAN mirror.')
      tlmgr(c('option', 'repository', 'ctan'))
    }
  }

  invisible(user_dir)
}

# TinyTeX has to be installed from source for OSes without a prebuilt binary.
# arm64 Linux (aarch64) gained prebuilt support after v2026.03.02.
binary_supported = function(version = '') {
  new_version = version == 'daily' || (grepl('^[0-9]+[.][0-9]+', version) && version > '2026.03.02')
  os_index != 0 && (os_index != 2 || {
    arch = Sys.info()[['machine']]
    # x86_64 is supported; arm64: supported with daily or version > '2026.03.02'
    # musl linux: only x86_64 is supported (with new naming: daily or version > '2026.03.02')
    if (is_musl()) arch == 'x86_64' && new_version
    else arch == 'x86_64' || is_arm64(arch) && new_version
  })
}

is_arm64 = function(arch = Sys.info()[['machine']]) {
  arch %in% c('aarch64', 'arm64')
}

is_musl = function() {
  xfun::is_linux() && (length(Sys.glob('/lib/libc.musl-*.so.1')) > 0 || isTRUE(suppressWarnings(
    grepl('musl', system2('ldd', '--version', stdout = TRUE, stderr = TRUE)[1], ignore.case = TRUE)
  )))
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
    # return the amended url if the file texlive.tlpdb can be found
    if (is_tlnet(url2)) return(url2)
  }
  url
}

# check if a URL points to the tlnet dir of CTAN
is_tlnet = function(x) {
  xfun::url_accessible(paste0(x, '/tlpkg/texlive.tlpdb'))
}

auto_repo = function() {
  # try the CDN-based mirror first, which is usually the fastest on average
  x = 'https://tlnet.yihui.org'
  if (is_tlnet(x)) return(x)
  # then try to get the automatic CTAN mirror returned from mirror.ctan.org;
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

osascript = function(cmd) {
  message("Requesting admin privilege to run: sudo ", cmd)
  escaped = gsub('"', '\\"', cmd, fixed = TRUE)
  ret = system(sprintf(
    "/usr/bin/osascript -e 'do shell script \"%s\" with administrator privileges'", escaped
  ))
  if (ret != 0) warning(
    "Please run the above command in your Terminal (password required).", call. = FALSE
  )
  ret
}

# on macOS, if the user doesn't have write permission to /usr/local/bin, we use
# /etc/paths.d instead
use_paths_d = function() {
  is_macos() && file.access('/usr/local/bin', 2) != 0
}

# add/remove TinyTeX's bin path to/from /etc/paths.d/TinyTeX on macOS;
# if adding and the file already contains the desired path, skip the operation
macos_path = function(dir = NULL, action = 'add') {
  paths_file = '/etc/paths.d/TinyTeX'
  add = action == 'add'
  cmd = if (add) {
    if (is.null(dir) || dir == '') return(1L)
    if (file.exists(paths_file) &&
        identical(readLines(paths_file, warn = FALSE), dir))
      return(0L)
    tmp = tempfile()
    writeLines(dir, tmp)
    sprintf('cp "%s" "%s"', tmp, paths_file)
  } else {
    sprintf('rm -f "%s"', paths_file)
  }
  ret = osascript(cmd)
  if (add && ret == 0) unlink(tmp)
  ret
}

install_via_script = function(pkg = '', dir = '', version = 'daily', add_path = TRUE, extra_packages = NULL, repo = 'ctan') {
  # Set env vars consumed by the install-bin-*.sh / install-bin-*.ps1 scripts
  env_vars = c(TINYTEX_INSTALLER = pkg)
  if (version != 'daily') env_vars['TINYTEX_VERSION'] = version

  # xfun::normalize_path() expands ~ so we can pass TINYTEX_TEXDIR to the script;
  # normalizePath() below (after install) resolves symlinks for the canonical path
  target = if (dir == '') default_inst() else xfun::normalize_path(dir)
  # Pass the full target path to the script only when using a custom directory
  if (dir != '') env_vars['TINYTEX_TEXDIR'] = target

  old_vars = xfun::set_envvar(env_vars)
  on.exit(xfun::set_envvar(old_vars), add = TRUE)

  if (is_windows()) {
    script = 'install-bin-windows.ps1'
    download_file('https://tinytex.yihui.org/install-bin-windows.ps1', script)
    on.exit(unlink(script), add = TRUE)
    script_args = c('-NonInteractive', '-File', script, if (!add_path) '--no-path')
    res = system2('powershell', script_args)
  } else {
    script = 'install-bin-unix.sh'
    download_file('https://tinytex.yihui.org/install-bin-unix.sh', script)
    on.exit(unlink(script), add = TRUE)
    res = system2('sh', c(script, if (!add_path) '--no-path'))
  }
  if (res != 0) stop('Failed to install TinyTeX', call. = FALSE)
  if (!dir_exists(target)) stop('Failed to install TinyTeX.')
  target = normalizePath(target)

  opts = options(tinytex.tlmgr.path = find_tlmgr(target))
  on.exit(options(opts), add = TRUE)

  r_texmf(.quiet = TRUE)
  # don't use the default random ctan mirror when installing on CI servers
  if (repo != 'ctan' || tolower(Sys.getenv('CI')) != 'true')
    tlmgr_repo(repo, stdout = FALSE, .quiet = TRUE)
  tlmgr_install(setdiff(extra_packages, tl_pkgs()))

  target
}

install_tinytex_source = function(repo = '', dir, version, add_path, extra_packages) {
  if (version != 'daily') stop(
    'tinytex::install_tinytex() does not support installing a specific version of ',
    'TinyTeX for your platform. Please use the argument version = "daily".'
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

find_tlmgr = function(dir = default_inst(), extra = FALSE) {
  bin = file.path(list.files(file.path(dir, 'bin'), full.names = TRUE), 'tlmgr')
  if (is_windows()) bin = paste0(bin, '.bat')
  if (is_macos() && extra) bin = c(bin, '/Library/TeX/texbin/tlmgr')
  head(bin[file_test('-x', bin)], 1)
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
#' @param ... Other arguments to be passed to `install_tinytex()` (note
#'   that the `extra_packages` argument will be set to `tl_pkgs()` if
#'   `packages = TRUE`).
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
#' [tinytex_root()]. Then check if the directory name is
#' `"tinytex"` (case-insensitive). If not, further check if the first line
#' of the file \file{texmf-dist/web2c/fmtutil.cnf} under the directory contains
#' `"TinyTeX"` or `".TinyTeX"`. If the binary version of TinyTeX was
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
  pkg = '', dir = '', version = 'daily', add_path = TRUE, extra_packages = NULL,
  repo = 'ctan', hash = FALSE, cache = NA
) {
  if (!binary_supported(version)) stop(
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
    installer = if (pkg == '') 'TinyTeX' else pkg
    ver = if (version != 'daily') paste0('-v', version)
    # new naming scheme introduced after v2026.03.02: TinyTeX-{N}-{os}[-{arch}][-v{VERSION}].{ext}
    # daily installs (version == '') always use the new naming
    if (version == 'daily' || version > '2026.03.02') {
      # e.g., TinyTeX-1-darwin.tar.xz, TinyTeX-1-linux-x86_64-v2026.04.tar.xz, ...
      os_arch = c('-windows', '-linux-x86_64', '-darwin')[os_index]
      if (os_index == 2) {
        if (is_musl()) os_arch = '-linuxmusl-x86_64'
        else if (is_arm64()) os_arch = '-linux-arm64'
      }
      pkg = paste0(installer, os_arch, ver, '.', c('exe', 'tar.xz', 'tar.xz')[os_index])
    } else {
      # old naming: e.g., TinyTeX-0.zip, TinyTeX-1-v2020.10.tar.gz, TinyTeX-1.tgz, ...
      pkg = paste0(installer, ver, '.', c('zip', 'tar.gz', 'tgz')[os_index])
      # full scheme is bundled as a self extracting archive on Windows
      if (os_index == 1 && installer == 'TinyTeX-2') pkg = xfun::with_ext(pkg, "exe")
    }
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
  v = paste0(if (version != 'daily') 'v', version)
  u = sprintf('https://github.com/rstudio/tinytex-releases/releases/download/%s/%s', v, file)
  download_file(u, file, mode = 'wb')
}

#' Copy TinyTeX to another location and use it in another system
#'
#' The function `copy_tinytex()` copies the existing TinyTeX installation
#' to another directory (e.g., a portable device like a USB stick). The function
#' `use_tinytex()` adds the copy of TinyTeX in an existing folder to the
#' `PATH` variable of the current system via [tlmgr_path()],
#' so that you can use utilities such as \command{tlmgr} and \command{pdflatex},
#' etc.
#' @param from The root directory of the TinyTeX installation. For
#'   `copy_tinytex()`, the default value `tinytex_root()` should be a
#'   reasonable guess if you installed TinyTeX via `install_tinytex()`. For
#'   `use_tinytex()`, if `from` is not provided, a dialog for choosing
#'   the directory interactively will pop up.
#' @param to The destination directory where you want to make a copy of TinyTeX.
#'   Like `from` in `use_tinytex()`, a dialog will pop up if `to`
#'   is not provided in `copy_tinytex()`.
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
  ret = if (use_paths_d()) macos_path(normalizePath(d)) else system2(p, c('path', 'add'))
  if (ret != 0) warning(
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
