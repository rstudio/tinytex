#' Find missing LaTeX packages from a LaTeX log file
#'
#' Analyze the error messages in a LaTeX log file to figure out the names of
#' missing LaTeX packages that caused the errors. These packages can be
#' installed via \code{\link{tlmgr_install}()}. Searching for missing packages
#' is based on \command{tlmgr search --global --file}.
#' @param log Path to the LaTeX log file (typically named \file{*.log}).
#' @param text A character vector of the error log (read from the file provided
#'   by the \code{log} argument by default).
#' @param quiet Whether to suppress messages when finding packages.
#' @return A character vector of LaTeX package names.
#' @export
find_packages = function(log, text = readLines(log), quiet = FALSE) {
  # possible errors are like:
  # ! LaTeX Error: File `framed.sty' not found.
  # /usr/local/bin/mktexpk: line 123: mf: command not found
  r = c(
    ".*! LaTeX Error: File `([-[:alnum:]]+[.][[:alpha:]]{1,3})' not found.*",
    ".*! Font [^=]+=([^ ]+).+ not loadable.*",
    ".*: ([a-z]+): command not found.*"
  )
  x = grep(paste(r, collapse = '|'), text, value = TRUE)
  pkgs = character()
  if (length(x) == 0) {
    if (!quiet) message(
      'I was unable to find any missing LaTeX packages from the error log',
      if (missing(log)) '.' else c(' ', log, '.')
    )
    return(invisible(pkgs))
  }
  x = unique(unlist(lapply(r, function(p) {
    gsub(p, '\\1', grep(p, x, value = TRUE))
  })))
  for (j in seq_along(x)) {
    l = tlmgr_search(paste0('/', x[j]), stdout = TRUE, .quiet = quiet)
    if (length(l) == 0) next
    # why $? e.g. searching for mf returns a list like this
    # metafont.x86_64-darwin:
    #     bin/x86_64-darwin/mf       <- what we want
    # metapost.x86_64-darwin:
    #     bin/x86_64-darwin/mfplain  <- but this also matches /mf
    k = grep(paste0('/', x[j], '$'), l)  # only match /mf exactly
    if (length(k) == 0) {
      if (!quiet) warning('Failed to find a package that contains ', x[j])
      next
    }
    k = k[k > 2]
    p = grep(':$', l)
    if (length(p) == 0) next
    for (i in k) {
      pkg  = gsub(':$', '', l[max(p[p < i])])  # find the package name
      pkgs = c(pkgs, setNames(pkg, x[j]))
    }
  }
  pkgs = gsub('[.].*', '', pkgs)  # e.g., 'metafont.x86_64-darwin'
  unique(pkgs)
}

# it should be rare that we need to manually run texhash
texhash = function() system2('texhash')

fmtutil = function() system2('fmtutil-sys', '--all')
