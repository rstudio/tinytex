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
tlmgr = function(args = character(), ..., .quiet = FALSE) {
  if (!.quiet) message(paste(c('tlmgr', args), collapse = ' '))
  system2('tlmgr', args, ...)
}


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
tlmgr_install = function(pkgs = character(), path = TRUE) {
  if (length(pkgs)) {
    tlmgr(c('install', pkgs))
    if (path) tlmgr_path('add')
  }
}

#' @rdname tlmgr
#' @export
tlmgr_remove = function(pkgs = character()) {
  if (length(pkgs)) tlmgr(c('remove', pkgs))
}


#' @param self Whether to update the TeX Live Manager itself.
#' @param more_args A character vector of more arguments to be passed to the
#'   command \command{tlmgr update} or \command{tlmgr conf}.
#' @param run_fmtutil Whether to run \command{fmtutil-sys --all} to (re)create
#'   format and hyphenation files after updating \pkg{tlmgr}.
#' @rdname tlmgr
#' @export
tlmgr_update = function(all = TRUE, self = TRUE, more_args = character(), run_fmtutil = TRUE) {
  tlmgr(c('update', if (all) '--all', if (self) '--self', more_args))
  if (run_fmtutil) fmtutil()
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
  tlmgr_conf(c('auxtrees', match.arg(action), shQuote(file.path(R.home('share'), 'texmf'))))
}
