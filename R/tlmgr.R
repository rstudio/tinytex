#' Run the TeX Live Manager
#'
#' Execute the \command{tlmgr} command to search for LaTeX packages, install
#' packages, update packages, and so on.
#'
#' The \code{tlmgr()} function is a wrapper of \code{system2('tlmgr')}. All
#' other \code{tlmgr_*()} functions are based on \code{tlmgr} for specific
#' tasks. For example, \code{tlmgr_install()} runs the command \command{tlmgr
#' install} to install LaTeX packages, and \code{tlmgr_update} runs the command
#' \command{tlmgr update}, etc. Note that \code{tlmgr_repo} runs \command{tlmgr
#' options repository} to query or set the CTAN repository. Please consult the
#' \pkg{tlmgr} manual for full details.
#' @param args A character vector of arguments to be passed to the command
#'   \command{tlmgr}.
#' @param usermode (For expert users only) Whether to use TeX Live's
#'   \href{https://www.tug.org/texlive/doc/tlmgr.html#USER-MODE}{user mode}. If
#'   \code{TRUE}, you must have run \code{tlmgr('init-usertree')} once before.
#'   This option allows you to manage a user-level texmf tree, e.g., install a
#'   LaTeX package to your home directory instead of the system directory, to
#'   which you do not have write permission. This option should not be needed on
#'   personal computers, and has some limitations, so please read the
#'   \pkg{tlmgr} manual very carefully before using it.
#' @param ... For \code{tlmgr()}, additional arguments to be passed to
#'   \code{\link{system2}()} (e.g., \code{stdout = TRUE} to capture stdout). For
#'   other functions, arguments to be passed to \code{tlmgr()}.
#' @param .quiet Whether to hide the actual command before executing it.
#' @references The \pkg{tlmgr} manual:
#'   \url{https://www.tug.org/texlive/doc/tlmgr.html}
#' @export
#' @examples
#' # search for a package that contains titling.sty
#' tlmgr_search('titling.sty')
#'
#' #' to match titling.sty exactly, add a slash before the keyword, e.g.
#' #' tlmgr_search('/titling.sty')
#'
#' #' use a regular expression if you want to be more precise, e.g.
#' #' tlmgr_search('/titling\\.sty$')
#'
#' # list all installed LaTeX packages
#' tlmgr(c('info', '--list', '--only-installed', '--data', 'name'))
tlmgr = function(args = character(), usermode = FALSE, ..., .quiet = FALSE) {
  tweak_path()
  if (!.quiet && !tlmgr_available()) warning(
    '\nTeX Live does not seem to be installed. See https://yihui.org/tinytex/.\n'
  )
  if (usermode) args = c('--usermode', args)
  if (!.quiet) message(paste(c('tlmgr', args), collapse = ' '))
  system2('tlmgr', args, ...)
}

# add ~/bin to PATH if necessary on Linux, because sometimes PATH may not be
# inherited (https://github.com/rstudio/rstudio/issues/1878), and TinyTeX is
# installed to ~/bin by default; on Windows, prioritize win_app_dir('TinyTeX')
# if it exists (so TinyTeX can be used even when MiKTeX is installed); on macOS,
# check if it is necessary to add ~/Library/TinyTeX/bin/*/ to PATH

#' @importFrom xfun is_linux is_unix is_macos is_windows with_ext
tweak_path = function() {
  # check tlmgr exists under the default installation dir of TinyTeX, or the
  # global option tinytex.tlmgr.path
  f = getOption('tinytex.tlmgr.path', find_tlmgr())
  if (length(f) == 0 || !file_test('-x', f)) return()
  bin = normalizePath(dirname(f))
  # if the pdftex from TinyTeX is already on PATH, no need to adjust the PATH
  if ((p <- Sys.which('pdftex')) != '') {
    p2 = with_ext(file.path(bin, 'pdftex'), xfun::file_ext(p))
    if (xfun::same_path(p, p2)) return()
  }
  old = Sys.getenv('PATH')
  one = unlist(strsplit(old, s <- .Platform$path.sep, fixed = TRUE))
  Sys.setenv(PATH = paste(c(bin, setdiff(one, bin)), collapse = s))
  do.call(
    on.exit, list(substitute(Sys.setenv(PATH = x), list(x = old)), add = TRUE),
    envir = parent.frame()
  )
}

tlmgr_available = function() Sys.which('tlmgr') != ''

#' @param what A search keyword as a (Perl) regular expression.
#' @param file Whether to treat \code{what} as a filename (pattern).
#' @param all For \code{tlmgr_search()}, whether to search in everything,
#'   including package names, descriptions, and filenames. For
#'   \code{tlmgr_update()}, whether to update all installed packages.
#' @param global Whether to search the online TeX Live Database or locally.
#' @param word Whether to restrict the search of package names and descriptions
#'   to match only full words.
#' @rdname tlmgr
#' @export
tlmgr_search = function(what, file = TRUE, all = FALSE, global = TRUE, word = FALSE, ...) {
  tlmgr(c(
    'search', if (file) '--file', if (all) '--all', if (global) '--global',
    if (word) '--word', shQuote(what)
  ), ...)
}

#' @param pkgs A character vector of LaTeX package names.
#' @param path Whether to run \code{tlmgr_path('add')} after installing packages
#'   (\code{path = TRUE} is a conservative default: it is only necessary to do
#'   this after a binary package is installed, such as the \pkg{metafont}
#'   package, which contains the executable \command{mf}, but it does not hurt
#'   even if no binary packages were installed).
#' @rdname tlmgr
#' @export
tlmgr_install = function(pkgs = character(), usermode = FALSE, path = !usermode && os != 'windows', ...) {
  if (length(pkgs) == 0) return(invisible(0L))

  res = tlmgr(c('install', pkgs), usermode, ...)
  if (res != 0 || !check_installed(pkgs)) {
    tlmgr_update(all = FALSE, usermode = usermode)
    res = tlmgr(c('install', pkgs), usermode, ...)
  }
  if ('epstopdf' %in% pkgs && is_unix() && Sys.which('gs') == '') {
    if (is_macos() && Sys.which('brew') != '') {
      message('Trying to install GhostScript via Homebrew for the epstopdf package.')
      system('brew install ghostscript')
    }
    if (Sys.which('gs') == '') warning('GhostScript is required for the epstopdf package.')
  }
  if (missing(path)) path = path && need_add_path()
  if (path) tlmgr_path('add')
  invisible(res)
}

# we should run `tlmgr path add` after `tlmgr install` only when the `tlmgr`
# found from PATH is a symlink that links to another symlink (typically under
# TinyTeX/bin/platform/tlmgr, which is typically a symlink to tlmgr.pl)
need_add_path = function() {
  is_writable(p <- Sys.which('tlmgr')) &&
    (p2 <- Sys.readlink(p)) != '' && basename(Sys.readlink(p2)) == 'tlmgr.pl' &&
    basename(dirname(dirname(p2))) == 'bin'
}

is_writable = function(p) file.access(p, 2) == 0

tlmgr_writable = function() is_writable(Sys.which('tlmgr'))

#' Check if certain LaTeX packages are installed
#'
#' If a package has been installed in TinyTeX or TeX Live, the command
#' \command{tlmgr info PKG} should return \code{PKG} where \code{PKG} is the
#' package name.
#' @param pkgs A character vector of LaTeX package names.
#' @return A logical vector indicating if packages specified in \code{pkgs} are
#'   installed.
#' @note This function only works with LaTeX distributions based on TeX Live,
#'   such as TinyTeX.
#' @export
#' @examples tinytex::check_installed('framed')
check_installed = function(pkgs) {
  if (length(pkgs) == 0) return(TRUE)
  res = tryCatch(
    tl_list(pkgs, stdout = TRUE, stderr = FALSE, .quiet = TRUE),
    error = function(e) NULL, warning = function(e) NULL
  )
  pkgs %in% res
}

#' @rdname tlmgr
#' @export
tlmgr_remove = function(pkgs = character(), usermode = FALSE) {
  if (length(pkgs)) tlmgr(c('remove', pkgs), usermode)
}


#' @param self Whether to update the TeX Live Manager itself.
#' @param more_args A character vector of more arguments to be passed to the
#'   command \command{tlmgr update} or \command{tlmgr conf}.
#' @param run_fmtutil Whether to run \command{fmtutil-sys --all} to (re)create
#'   format and hyphenation files after updating \pkg{tlmgr}.
#' @param delete_tlpdb Whether to delete the \file{texlive.tlpdb.HASH} files
#'   (where \verb{HASH} is an MD5 hash) under the \file{tlpkg} directory of the
#'   root directory of TeX Live after updating.
#' @rdname tlmgr
#' @export
tlmgr_update = function(
  all = TRUE, self = TRUE, more_args = character(), usermode = FALSE,
  run_fmtutil = TRUE, delete_tlpdb = getOption('tinytex.delete_tlpdb', FALSE), ...
) {
  # if unable to update due to a new release of TeX Live, skip the update
  if (isTRUE(.global$update_noted)) return(invisible(NULL))
  res = suppressWarnings(tlmgr(
    c('update', if (all) '--all', if (self && !usermode) '--self', more_args),
    usermode, ..., stdout = TRUE, stderr = TRUE
  ))
  check_tl_version(res)
  if (run_fmtutil) fmtutil(usermode, stdout = FALSE)
  if (delete_tlpdb) delete_tlpdb_files()
  invisible()
}

# check if a new version of TeX Live has been released and give instructions on
# how to upgrade
check_tl_version = function(x) {
  if (length(x) == 0) return()
  i = grep('Local TeX Live \\([0-9]+) is older than remote repository \\([0-9]+)', x)
  if (length(i) == 0) return()
  message(
    'A new version of TeX Live has been released. If you need to install or update ',
    'any LaTeX packages, you have to upgrade ',
    if (!is_tinytex()) 'TeX Live.' else c(
      'TinyTeX with tinytex::reinstall_tinytex(). If it fails to upgrade, you ',
      'might be using a default random CTAN mirror that has not been fully synced ',
      'to the main CTAN repository, and you need to wait for a few more days or ',
      'use a CTAN mirror that is known to be up-to-date (see the "repository" ',
      'argument on the help page ?tinytex::install_tinytex()).'
    )
  )
  .global$update_noted = TRUE
}

delete_tlpdb_files = function() {
  if ((root <- tinytex_root(FALSE)) != '') file.remove(list.files(
    file.path(root, 'tlpkg'), '^texlive[.]tlpdb[.][0-9a-f]{32}$', full.names = TRUE
  ))
}

#' @param action On Unix, add/remove symlinks of binaries to/from the system's
#'   \code{PATH}. On Windows, add/remove the path to the TeXLive binary
#'   directory to/from the system environment variable \code{PATH}.
#' @rdname tlmgr
#' @export
tlmgr_path = function(action = c('add', 'remove'))
  tlmgr(c('path', match.arg(action)), .quiet = TRUE)

#' @rdname tlmgr
#' @export
tlmgr_conf = function(more_args = character(), ...) {
  tlmgr(c('conf', more_args), ...)
}

#' @param url The URL of the CTAN mirror. If \code{NULL}, show the current
#'   repository, otherwise set the repository. See the \code{repository}
#'   argument of \code{\link{install_tinytex}()} for examples.
#' @rdname tlmgr
#' @export
tlmgr_repo = function(url = NULL, ...) {
  tlmgr(c('option', 'repository', shQuote(normalize_repo(url))), ...)
}

#' Add/remove R's texmf tree to/from TeX Live
#'
#' R ships a custom texmf tree containing a few LaTeX style and class files,
#' which are required when compiling R packages manuals (\file{Rd.sty}) or
#' Sweave documents (\file{Sweave.sty}). This tree can be found under the
#' directory \code{file.path(R.home('share'), 'texmf')}. This function can be
#' used to add/remove R's texmf tree to/from TeX Live via
#' \code{\link{tlmgr_conf}('auxtrees')}.
#' @param action Add/remove R's texmf tree to/from TeX Live.
#' @param ... Arguments passed to \code{\link{tlmgr}()}.
#' @references See the \pkg{tlmgr} manual for detailed information about
#'   \command{tlmgr conf auxtrees}. Check out
#'   \url{https://tex.stackexchange.com/q/77720/9128} if you don't know what
#'   \code{texmf} means.
#' @export
#' @examples
#' # running the code below will modify your texmf tree; please do not run
#' # unless you know what it means
#'
#' # r_texmf('remove')
#' # r_texmf('add')
#'
#' # all files under R's texmf tree
#' list.files(file.path(R.home('share'), 'texmf'), recursive = TRUE, full.names = TRUE)
r_texmf = function(action = c('add', 'remove'), ...) {
  tlmgr_conf(c('auxtrees', match.arg(action), shQuote(r_texmf_path())), ...)
}

r_texmf_path = function() {
  d = file.path(R.home('share'), 'texmf')
  if (dir_exists(d)) return(d)
  # retry another directory: https://github.com/yihui/tinytex/issues/60
  if ('Rd.sty' %in% basename(list.files(d2 <- '/usr/share/texmf', recursive = TRUE))) {
    return(d2)
  }
  warning("Cannot find R's texmf tree; returning '", d, "'")
  d
}

#' Sizes of LaTeX packages in TeX Live
#'
#' Use the command \command{tlmgr info --list} to obtain the sizes of LaTeX
#' packages.
#' @param show_total Whether to show the total size.
#' @param pkgs A character vector of package names (by default, all packages).
#' @param field A character vector of field names in the package information.
#'   See \url{https://www.tug.org/texlive/doc/tlmgr.html#info} for more info.
#' @inheritParams tl_pkgs
#' @export
#' @return By default, a data frame of three columns: \code{package} is the
#'   package names, \code{size} is the sizes in bytes, and \code{size_h} is the
#'   human-readable version of sizes. If different field names are provided in
#'   the \code{field} argument, the returned data frame will contain these
#'   columns.
tl_sizes = function(show_total = TRUE, pkgs = NULL, only_installed = TRUE, field = 'size') {
  info = tl_list(pkgs, paste(c('name', field), collapse = ','), only_installed, stdout = TRUE)
  info = read.table(sep = ',', text = info, stringsAsFactors = FALSE, col.names = c('package', field))
  info = info[info$package %in% tl_names(info$package), , drop = FALSE]
  if ('size' %in% names(info)) {
    info = info[order(info[, 'size'], decreasing = TRUE), , drop = FALSE]
    info$size_h = sapply(info[, 'size'], auto_size)
    if (show_total) message('The total size is ', auto_size(sum(info$size)))
  }
  rownames(info) = NULL
  info
}

# human-readable size from bytes
auto_size = function(bytes) format(structure(bytes, class = 'object_size'), 'auto')

#' List the names of installed TeX Live packages
#'
#' Calls \command{tlmgr info --list --data name} to obtain the names of all
#' (installed) TeX Live packages. Platform-specific strings in package names are
#' removed, e.g., \code{"tex"} is returned for the package
#' \pkg{tex.x86_64-darwin}.
#' @param only_installed Whether to list installed packages only.
#' @export
#' @return A character vector of package names.
tl_pkgs = function(only_installed = TRUE) {
  x = tl_list(NULL, 'name', only_installed, stdout = TRUE, .quiet = TRUE)
  tl_names(x, NULL)
}

tl_list = function(pkgs = NULL, field = 'name', only_installed = TRUE, ...) {
  tlmgr(c('info', '--list', if (only_installed) '--only-installed', '--data', field, pkgs), ...)
}

tl_platform = function() tlmgr('print-platform', stdout = TRUE, .quiet = TRUE)

# get all supported platforms (this needs Internet connection since the info is
# fetched from CTAN)
tl_platforms = function() {
  x = tlmgr(c('platform', 'list'), stdout = TRUE, .quiet = TRUE)
  x = sub('^\\(i)', '   ', x)
  trimws(grep('^    ', x, value = TRUE))
}

# a copy of the returned result from tl_platform() is saved here because
# tl_platform() is a little slow and requires Internet connection
.tl_platforms = c(
  'aarch64-linux', 'amd64-freebsd', 'amd64-netbsd', 'armhf-linux', 'i386-cygwin',
  'i386-freebsd', 'i386-linux', 'i386-netbsd', 'i386-solaris', 'win32', 'x86_64-cygwin',
  'x86_64-darwin', 'x86_64-darwinlegacy', 'x86_64-linux', 'x86_64-linuxmusl', 'x86_64-solaris'
)

# remove the platform suffixes from texlive package names, and optionally keep
# the suffixes for certain platforms
tl_names = function(x, platform = tl_platform()) {
  unique(sub(paste0(
    '[.](', paste(setdiff(.tl_platforms, platform), collapse = '|'), ')$'
  ), '', x))
}

# get the names of packages that are not relocatable
tl_unrelocatable = function() {
  x = tl_list(NULL, 'name,relocatable', FALSE, stdout = TRUE, .quiet = TRUE)
  x = grep_sub(',0$', '', x)
  tl_names(x)
}
