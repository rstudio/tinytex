#' Run the TeX Live Manager
#'
#' Execute the \command{tlmgr} command to search for LaTeX packages, install
#' packages, update packages, and so on.
#'
#' The \code{tlmgr()} function is a wrapper of \code{system2('tlmgr')}. All
#' other \code{tlmgr_*()} functions are based on \code{tlmgr} for specific
#' tasks. Please consult the \pkg{tlmgr} manual for full details.
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
#' @param ... Additional arguments passed to \code{\link{system2}()} (e.g.,
#'   \code{stdout = TRUE} to capture stdout).
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
  if (!tlmgr_available()) {
    warning('TeX Live does not seem to be installed. See https://yihui.name/tinytex/.')
  }
  if (usermode) args = c('--usermode', args)
  if (!.quiet) message(paste(c('tlmgr', args), collapse = ' '))
  system2('tlmgr', args, ...)
}

# add ~/bin to PATH if necessary on Linux, because sometimes PATH may not be
# inherited (https://github.com/rstudio/rstudio/issues/1878), and TinyTeX is
# installed to ~/bin by default

#' @importFrom xfun is_linux is_unix is_macos
tweak_path = function() {
  if (!is_linux()) return()
  if (tlmgr_available()) return()
  # if tlmgr is not found, and OS is not Linux, just give up
  if (!is_linux() ) return()
  # check if ~/bin/tlmgr exists (created by TinyTeX by default)
  if (!file_test('-x', '~/bin/tlmgr')) return()
  old = Sys.getenv('PATH')
  bin = normalizePath('~/bin')
  if (bin %in% unlist(strsplit(old, s <- .Platform$path.sep, fixed = TRUE))) return()
  Sys.setenv(PATH = paste(bin, old, sep = s))
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
tlmgr_install = function(pkgs = character(), usermode = FALSE, path = !usermode && os != 'windows') {
  res = 0L
  if (length(pkgs)) {
    res = tlmgr(c('install', pkgs), usermode)
    if (res != 0 || tl_list(pkgs, stdout = FALSE, stderr = FALSE, .quiet = TRUE) != 0) {
      tlmgr_update(all = FALSE, usermode = usermode)
      res = tlmgr(c('install', pkgs), usermode)
    }
    if ('epstopdf' %in% pkgs && is_unix() && Sys.which('gs') == '') {
      if (is_macos() && Sys.which('brew')) {
        message('Trying to install GhostScript via Homebrew for the epstopdf package.')
        system('brew install ghostscript')
      }
      if (Sys.which('gs') == '') warning('GhostScript is required for the epstopdf package.')
    }
    if (path) tlmgr_path('add')
  }
  invisible(res)
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
#' @rdname tlmgr
#' @export
tlmgr_update = function(all = TRUE, self = TRUE, more_args = character(), usermode = FALSE, run_fmtutil = TRUE) {
  tlmgr(c('update', if (all) '--all', if (self && !usermode) '--self', more_args), usermode)
  if (run_fmtutil) fmtutil(usermode)
}


#' @param action On Unix, add/remove symlinks of binaries to/from the system's
#'   \code{PATH}. On Windows, add/remove the path to the TeXLive binary
#'   directory to/from the system environment variable \code{PATH}.
#' @rdname tlmgr
#' @export
tlmgr_path = function(action = c('add', 'remove')) tlmgr(c('path', match.arg(action)))


#' @rdname tlmgr
#' @export
tlmgr_conf = function(more_args = character()) {
  tlmgr(c('conf', more_args))
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
#' @references See the \pkg{tlmgr} manual for detailed information about
#'   \command{tlmgr conf auxtrees}. Check out
#'   \url{https://tex.stackexchange.com/q/77720/9128} if you don't know what
#'   \code{texmf} means.
#' @export
#' @examples
#' r_texmf('remove')
#' r_texmf('add')
#'
#' # all files under R's texmf tree
#' list.files(file.path(R.home('share'), 'texmf'), recursive = TRUE, full.names = TRUE)
r_texmf = function(action = c('add', 'remove')) {
  tlmgr_conf(c('auxtrees', match.arg(action), r_texmf_path()))
}

r_texmf_path = function() shQuote(file.path(R.home('share'), 'texmf'))

#' Sizes of LaTeX packages in TeX Live
#'
#' Use the command \command{tlmgr info --list --only-installed} to obtain the
#' sizes of installed LaTeX packages.
#' @param show_total Whether to show the total size.
#' @export
#' @return A data frame of three columns: \code{package} is the package names,
#'   \code{size} is the sizes in bytes, and \code{size_h} is the human-readable
#'   version of sizes.
tl_sizes = function(show_total = TRUE) {
  info = tl_list(NULL, 'name,size', stdout = TRUE)
  info = read.table(sep = ',', text = info, stringsAsFactors = FALSE, col.names = c('package', 'size'))
  info = info[order(info[, 'size'], decreasing = TRUE), , drop = FALSE]
  info$size_h = sapply(info[, 'size'], auto_size)
  rownames(info) = NULL
  if (show_total) message('The total size is ', auto_size(sum(info$size)))
  info
}

# human-readable size from bytes
auto_size = function(bytes) format(structure(bytes, class = 'object_size'), 'auto')

#' List the names of installed TeX Live packages
#'
#' Calls \command{tlmgr info --list --only-installed --data name} to obtain the
#' names of all installed TeX Live packages. Platform-specific strings in
#' package names are removed, e.g., \code{"tex"} is returned for the package
#' \pkg{tex.x86_64-darwin}.
#' @export
#' @return A character vector of package names.
tl_pkgs = function() gsub('[.].*', '', tl_list(stdout = TRUE))

tl_list = function(pkgs = NULL, field = 'name', ...) {
  tlmgr(c('info', '--list', '--only-installed', '--data', field, pkgs), ...)
}
