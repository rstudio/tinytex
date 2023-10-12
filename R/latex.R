#' Compile a LaTeX document
#'
#' The function \code{latexmk()} emulates the system command \command{latexmk}
#' (\url{https://ctan.org/pkg/latexmk}) to compile a LaTeX document. The
#' functions \code{pdflatex()}, \code{xelatex()}, and \code{lualatex()} are
#' wrappers of \code{latexmk(engine =, emulation = TRUE)}.
#'
#' The \command{latexmk} emulation works like this: run the LaTeX engine once
#' (e.g., \command{pdflatex}), run \command{makeindex} to make the index if
#' necessary (the \file{*.idx} file exists), run the bibliography engine
#' \command{bibtex} or \command{biber} to make the bibliography if necessary
#' (the \file{*.aux} or \file{*.bcf} file exists), and finally run the LaTeX
#' engine a number of times (the maximum is 10 by default) to resolve all
#' cross-references.
#'
#' By default, LaTeX warnings will be converted to R warnings. To suppress these
#' warnings, set \code{options(tinytex.latexmk.warning = FALSE)}.
#'
#' If \code{emulation = FALSE}, you need to make sure the executable
#' \command{latexmk} is available in your system, otherwise \code{latexmk()}
#' will fall back to \code{emulation = TRUE}. You can set the global option
#' \code{options(tinytex.latexmk.emulation = FALSE)} to always avoid emulation
#' (i.e., always use the executable \command{latexmk}).
#'
#' The default command to generate the index (if necessary) is
#' \command{makeindex}. To change it to a different command (e.g.,
#' \command{zhmakeindex}), you may set the global option
#' \code{tinytex.makeindex}. To pass additional command-line arguments to the
#' command, you may set the global option \code{tinytex.makeindex.args} (e.g.,
#' \code{options(tinytex.makeindex = 'zhmakeindex', tinytex.makeindex.args =
#' c('-z', 'pinyin'))}).
#'
#' If you are using the LaTeX distribution TinyTeX, but its path is not in the
#' \code{PATH} variable of your operating system, you may set the global option
#' \code{tinytex.tlmgr.path} to the full path of the executable \command{tlmgr},
#' so that \code{latexmk()} knows where to find executables like
#' \command{pdflatex}. For example, if you are using Windows and your TinyTeX is
#' on an external drive \file{Z:/} under the folder \file{TinyTeX}, you may set
#' \code{options(tinytex.tlmgr.path = "Z:/TinyTeX/bin/windows/tlmgr.bat")}.
#' Usually you should not need to set this option because TinyTeX can add itself
#' to the \code{PATH} variable during installation or via
#' \code{\link{use_tinytex}()}. In case both methods fail, you can use this
#' manual approach.
#' @param file A LaTeX file path.
#' @param engine A LaTeX engine (can be set in the global option
#'   \code{tinytex.engine}, e.g., \code{options(tinytex.engine = 'xelatex')}).
#' @param bib_engine A bibliography engine (can be set in the global option
#'   \code{tinytex.bib_engine}).
#' @param engine_args Command-line arguments to be passed to \code{engine} (can
#'   be set in the global option \code{tinytex.engine_args}, e.g.,
#'   \code{options(tinytex.engine_args = '-shell-escape'}).
#' @param emulation Whether to emulate the executable \command{latexmk} using R.
#'   Note that this is unused when \code{engine == 'tectonic'}.
#' @param min_times,max_times The minimum and maximum number of times to rerun
#'   the LaTeX engine when using emulation. You can set the global options
#'   \code{tinytex.compile.min_times} or \code{tinytex.compile.max_times}, e.g.,
#'   \code{options(tinytex.compile.max_times = 3)}.
#' @param install_packages Whether to automatically install missing LaTeX
#'   packages found by \code{\link{parse_packages}()} from the LaTeX log. This
#'   argument is only for the emulation mode and TeX Live. Its value can also be
#'   set via the global option \code{tinytex.install_packages}, e.g.,
#'   \code{options(tinytex.install_packages = FALSE)}.
#' @param pdf_file Path to the PDF output file. By default, it is under the same
#'   directory as the input \code{file} and also has the same base name. When
#'   \code{engine == 'latex'}, this will be a DVI file.
#' @param clean Whether to clean up auxiliary files after compilation (can be
#'   set in the global option \code{tinytex.clean}, which defaults to
#'   \code{TRUE}).
#' @export
#' @return A character string of the path of the output file (i.e., the value of
#'   the \code{pdf_file} argument).
latexmk = function(
  file, engine = c('pdflatex', 'xelatex', 'lualatex', 'latex', 'tectonic'),
  bib_engine = c('bibtex', 'biber'), engine_args = NULL, emulation = TRUE,
  min_times = 1, max_times = 10, install_packages = emulation && tlmgr_writable(),
  pdf_file = gsub('tex$', 'pdf', file), clean = TRUE
) {
  if (!grepl('[.]tex$', file))
    stop("The input file '", file, "' does not have the .tex extension")
  file = path.expand(file)
  if (missing(engine)) engine = getOption('tinytex.engine', engine)
  engine = gsub('^(pdf|xe|lua)(tex)$', '\\1la\\2', engine)  # normalize *tex to *latex
  engine = match.arg(engine)
  is_latex = engine == 'latex'
  tweak_path()
  if (missing(emulation)) emulation = getOption('tinytex.latexmk.emulation', emulation)
  if (!emulation) {
    if (Sys.which('latexmk') == '') {
      warning('The executable "latexmk" not found in your system')
      emulation = TRUE
    } else if (system2_quiet('latexmk', '-v') != 0) {
      warning('The executable "latexmk" was found but does not work')
      emulation = TRUE
    }
  }
  if (missing(min_times)) min_times = getOption('tinytex.compile.min_times', min_times)
  if (missing(max_times)) max_times = getOption('tinytex.compile.max_times', max_times)
  if (missing(install_packages))
    install_packages = getOption('tinytex.install_packages', install_packages)
  if (missing(bib_engine)) bib_engine = getOption('tinytex.bib_engine', bib_engine)
  if (missing(engine_args)) engine_args = getOption('tinytex.engine_args', engine_args)
  if (missing(clean)) clean = getOption('tinytex.clean', TRUE)
  pdf = gsub('tex$', if (is_latex) 'dvi' else 'pdf', basename(file))
  if (!is.null(output_dir <- getOption('tinytex.output_dir'))) {
    output_dir_arg = shQuote(paste0(if (emulation) '-', '-output-directory=', output_dir))
    if (length(grep(output_dir_arg, engine_args, fixed = TRUE)) == 0) stop(
      "When you set the global option 'tinytex.output_dir', the argument 'engine_args' ",
      "must contain this value: ", capture.output(dput(output_dir_arg))
    )
    pdf = file.path(output_dir, pdf)
    if (missing(pdf_file)) pdf_file = file.path(output_dir, basename(pdf_file))
  }
  if (is_latex) pdf_file = with_ext(pdf_file, 'dvi')
  check_pdf = function() {
    if (!file.exists(pdf)) show_latex_error(file, with_ext(pdf, 'log'), TRUE)
    file_rename(pdf, pdf_file)
    pdf_file
  }
  if (engine == 'tectonic') {
    system2_quiet('tectonic', c(engine_args, shQuote(file)))
    return(check_pdf())
  }
  if (emulation) {
    latexmk_emu(
      file, engine, bib_engine, engine_args, min_times, max_times,
      install_packages, clean
    )
    return(check_pdf())
  }
  system2_quiet('latexmk', c(
    '-latexoption=-halt-on-error -interaction=batchmode',
    if (is_latex) '-latex=latex' else paste0('-pdf -pdflatex=', engine),
    engine_args, shQuote(file)
  ), error = {
    if (install_packages) warning(
      'latexmk(install_packages = TRUE) does not work when emulation = FALSE'
    )
    check_latexmk_version()
  })
  if (clean) system2('latexmk', c('-c', engine_args), stdout = FALSE)
  check_pdf()
}

#' @param ... Arguments to be passed to \code{latexmk()} (other than
#'   \code{engine} and \code{emulation}).
#' @rdname latexmk
#' @export
pdflatex = function(...) latexmk(engine = 'pdflatex', emulation = TRUE, ...)

#' @rdname latexmk
#' @export
xelatex  = function(...) latexmk(engine = 'xelatex',  emulation = TRUE, ...)

#' @rdname latexmk
#' @export
lualatex = function(...) latexmk(engine = 'lualatex', emulation = TRUE, ...)

# a quick and dirty version of latexmk (should work reasonably well unless the
# LaTeX document is extremely complicated)
latexmk_emu = function(
  file, engine, bib_engine = c('bibtex', 'biber'), engine_args = NULL, min_times = 1, max_times = 10,
  install_packages = FALSE, clean
) {
  aux = c(
    'log', 'idx', 'aux', 'bcf', 'blg', 'bbl', 'fls', 'out', 'lof', 'lot', 'toc',
    'nav', 'snm', 'vrb', 'ilg', 'ind', 'xwm', 'brf', 'run.xml'
  )
  base = gsub('[.]tex$', '', basename(file))
  aux_files = paste(base, aux, sep = '.')
  aux_files = c(aux_files, 'preview.aux')  # generated by the preview package
  if (!is.null(output_dir <- getOption('tinytex.output_dir')))
    aux_files = file.path(output_dir, aux_files)
  names(aux_files)[seq_along(aux)] = aux
  logfile = aux_files['log']; unlink(logfile)  # clean up the log before compilation

  # clean up aux files from LaTeX compilation
  files1 = exist_files(aux_files)
  keep_log = FALSE
  on.exit({
    files2 = exist_files(aux_files)
    files3 = setdiff(files2, files1)
    if (keep_log || length(latex_warning(logfile))) files3 = setdiff(files3, logfile)
    if (clean) unlink(files3)
    .global$update_noted = NULL
  }, add = TRUE)

  pkgs_last = character()
  filep = sub('.log$', if (engine == 'latex') '.dvi' else '.pdf', logfile)
  verbose = getOption('tinytex.verbose', FALSE)

  # install commands like pdflatex, bibtex, biber, and makeindex if necessary
  install_cmd = function(cmd) {
    if (install_packages && Sys.which(cmd) == '') parse_install(file = cmd)
  }
  install_cmd(engine)

  run_engine = function() {
    on_error  = function() {
      if (install_packages && file.exists(logfile)) {
        pkgs = parse_packages(logfile, quiet = !verbose)
        if (length(pkgs) && !identical(pkgs, pkgs_last)) {
          if (verbose) message('Trying to automatically install missing LaTeX packages...')
          if (tlmgr_install(pkgs, .quiet = !verbose) == 0) {
            pkgs_last <<- pkgs
            return(run_engine())
          }
        } else if (tlmgr_writable()) {
          # chances are you are the sysadmin, and don't need ~/.TinyTeX
          if (delete_texmf_user()) return(run_engine())
        }
      }
      keep_log <<- TRUE
      show_latex_error(file, logfile)
    }
    res = system2_quiet(
      engine, c('-halt-on-error', '-interaction=batchmode', engine_args, shQuote(file)),
      error = {
        if (install_packages) tlmgr_update(run_fmtutil = FALSE, .quiet = TRUE)
        on_error()
      }, logfile = logfile, fail_rerun = verbose
    )
    # PNAS you are the worst! Why don't you signal an error in case of missing packages?
    if (res == 0 && !file.exists(filep)) on_error()
    invisible(res)
  }
  run_engine()
  # some problems only trigger warnings but not errors, e.g.,
  # https://github.com/rstudio/tinytex/issues/311 fix them and re-run engine
  if (install_packages && check_extra(logfile)) run_engine()

  # generate index
  if (file.exists(idx <- aux_files['idx'])) {
    idx_engine = getOption('tinytex.makeindex', 'makeindex')
    install_cmd(idx_engine)
    run_engine()  # run the engine one more time (cf rstudio/bookdown#1274)
    system2_quiet(idx_engine, c(getOption('tinytex.makeindex.args'), shQuote(idx)), error = {
      stop("Failed to build the index via ", idx_engine, call. = FALSE)
    })
  }
  # generate bibliography
  bib_engine = match.arg(bib_engine)
  install_cmd(bib_engine)
  pkgs_last = character()
  aux = aux_files[if ((biber <- bib_engine == 'biber')) 'bcf' else 'aux']
  if (file.exists(aux)) {
    if (biber || require_bibtex(aux)) {
      blg = aux_files['blg']  # bibliography log file
      build_bib = function() system2_quiet(bib_engine, shQuote(aux), error = {
        check_blg = function() {
          if (!file.exists(blg)) return(TRUE)
          x = read_lines(blg)
          if (length(grep('error message', x)) == 0) return(TRUE)
          warn = function() {
            warning(
              bib_engine, ' seems to have failed:\n\n', paste(x, collapse = '\n'),
              call. = FALSE
            )
            TRUE
          }
          if (!tlmgr_available() || !install_packages) return(warn())
          # install the possibly missing .bst package and rebuild bib
          pkgs = parse_packages(text = x, quiet = !verbose)
          if (length(pkgs) == 0 || identical(pkgs, pkgs_last)) return(warn())
          pkgs_last <<- pkgs
          tlmgr_install(pkgs); build_bib()
          FALSE
        }
        if (check_blg())
          stop("Failed to build the bibliography via ", bib_engine, call. = FALSE)
      })
      build_bib()
    }
  }
  for (i in seq_len(max_times)) {
    if (i > min_times) {
      if (file.exists(logfile)) {
        if (!needs_rerun(logfile)) break
      } else warning('The LaTeX log file "', logfile, '" is not found')
    }
    run_engine()
  }
}

require_bibtex = function(aux) {
  x = read_lines(aux)
  r = length(grep('^\\\\citation\\{', x)) && length(grep('^\\\\bibdata\\{', x)) &&
    length(grep('^\\\\bibstyle\\{', x))
  if (r && !tlmgr_available() && os == 'windows') tweak_aux(aux, x)
  r
}

# remove the .bib extension in \bibdata{} in the .aux file, because bibtex on
# Windows requires no .bib extension (sigh)
tweak_aux = function(aux, x = read_lines(aux)) {
  r = '^\\\\bibdata\\{.+\\}\\s*$'
  if (length(i <- grep(r, x)) == 0) return()
  x[i] = gsub('[.]bib([,}])', '\\1', x[i])
  writeLines(x, aux)
}

needs_rerun = function(log, text = read_lines(log)) {
  any(grepl(
    '(Rerun to get |Please \\(?re\\)?run | Rerun LaTeX\\.)', text,
    useBytes = TRUE
  ))
}

system2_quiet = function(..., error = NULL, logfile = NULL, fail_rerun = TRUE) {
  # system2(stdout = FALSE) fails on Windows with MiKTeX's pdflatex in the R
  # console in RStudio: https://github.com/rstudio/rstudio/issues/2446 so I have
  # to redirect stdout and stderr to files instead
  f1 = tempfile('stdout'); f2 = tempfile('stderr')
  on.exit(unlink(c(f1, f2)), add = TRUE)

  # run the command quietly if possible
  res = system2(..., stdout = if (use_file_stdout()) f1 else FALSE, stderr = f2)
  if (is.character(logfile) && file.exists(f2) && length(e <- read_lines(f2))) {
    i = grep('^\\s*$', e, invert = TRUE)
    e[i] = paste('!', e[i])  # prepend ! to non-empty error messages
    cat('', e, file = logfile, sep = '\n', append = TRUE)
  }

  # if failed, use the normal mode
  if (fail_rerun && res != 0) res = system2(...)
  # if still fails, run the error callback
  if (res != 0) error  # lazy evaluation
  invisible(res)
}

use_file_stdout = function() {
  getOption('tinytex.stdout.file', {
    os == 'windows' && interactive() && !is.na(Sys.getenv('RSTUDIO', NA))
  })
}

# parse the LaTeX log and show error messages
show_latex_error = function(
  file, logfile = gsub('[.]tex$', '.log', basename(file)), force = FALSE
) {
  e = c('LaTeX failed to compile ', file, '. See https://yihui.org/tinytex/r/#debugging for debugging tips.')
  if (!file.exists(logfile)) stop(e, call. = FALSE)
  x = read_lines(logfile)
  b = grep('^\\s*$', x)  # blank lines
  b = c(b, which(x == "Here is how much of TeX's memory you used:"))
  m = NULL
  for (i in grep('^! ', x)) {
    # ignore the last error message about the fatal error
    if (grepl('==> Fatal error occurred', x[i], fixed = TRUE)) next
    n = b[b > i]
    n = if (length(n) == 0) i else min(n) - 1L
    m = c(m, x[i:n], '')
  }
  if (length(m)) {
    message(paste(m, collapse = '\n'))
    latex_hints(m, file)
    stop(e, ' See ', logfile, ' for more info.', call. = FALSE)
  } else if (force) stop(e, call. = FALSE)
}

latex_hints = function(x, f) {
  check_inline_math(x, f)
  check_unicode(x)
}

check_inline_math = function(x, f) {
  r = 'l[.][0-9]+\\s*|\\s*[0-9.]+\\\\times.*'
  if (!any('! Missing $ inserted.' == x) || !length(i <- grep(r, x))) return()
  m = gsub(r, '', x[i]); m = m[m != '']
  s = with_ext(f, 'Rmd')
  if (file.exists(s)) message(
    if (length(m)) c('Try to find the following text in ', s, ':\n', paste(' ', m, '\n'), '\n'),
    'You may need to add $ $ around a certain inline R expression `r ` in ', s,
    if (length(m)) ' (see the above hint)',
    '. See https://github.com/rstudio/rmarkdown/issues/385 for more info.'
  )
}

check_unicode = function(x) {
  if (length(grep('! (Package inputenc|LaTeX) Error: Unicode character', x))) message(
    'Try other LaTeX engines instead (e.g., xelatex) if you are using pdflatex.',
    if ('rmarkdown' %in% loadedNamespaces())
      ' See https://bookdown.org/yihui/rmarkdown-cookbook/latex-unicode.html'
  )
}

# whether a LaTeX log file contains LaTeX or package (e.g. babel) warnings
latex_warning = function(file, show = getOption('tinytex.latexmk.warning', TRUE)) {
  if (!file.exists(file)) return()
  # if the option tinytex.latexmk.warning = FALSE, delete the log in latexmk_emu()
  if (!show && missing(show)) return()
  x = read_lines(file)
  if (length(i <- grep('^(LaTeX|Package [[:alnum:]]+) Warning:', x)) == 0) return()
  # these warnings may be okay (our Pandoc LaTeX template in rmarkdown may need an update)
  i = i[grep('^Package (fixltx2e|caption|hyperref) Warning:', x[i], invert = TRUE)]
  if (length(i) == 0) return()
  b = grep('^\\s*$', x)
  i = unlist(lapply(i, function(j) {
    n = b[b > j]
    n = if (length(n) == 0) i else min(n) - 1L
    j:n
  }))
  i = sort(unique(i))
  if (show) for(msg in x[i]) warning(msg, call. = FALSE, immediate. = TRUE)
  x[i]
}

# check if any babel/glossaries/... packages are missing
check_extra = function(file) {
  length(m <- latex_warning(file, FALSE)) > 0 &&
    length(grep('^Package ([^ ]+) Warning:', m)) > 0 &&
    any(
      check_babel(m),
      check_glossaries(m),
      check_datetime2(m),
      check_polyglossia(m)
    )
}

check_babel = function(text) {
  r = "^(\\(babel\\).* |Package babel Warning: No hyphenation patterns were preloaded for the )language [`']([^']+)'.*$"
  if (length(m <- grep_sub(r, 'hyphen-\\2', text)) == 0) return(FALSE)
  # (babel) the language `German (new orthography)' into the format
  m = gsub('\\s.*', '', m)
  m[m == 'hyphen-pinyin'] = 'hyphen-chinese'
  tlmgr_install(tolower(m)) == 0
}

# Package glossaries Warning: No language module detected for `english'.
# (glossaries)                Language modules need to be installed separately.
# (glossaries)                Please check on CTAN for a bundle called
# (glossaries)                `glossaries-english' or similar.
check_glossaries = function(text) {
  r = "^\\(glossaries).* [`']([^']+)'.*$"
  if (length(m <- grep_sub(r, '\\1', text)) == 0) return(FALSE)
  tlmgr_install(m) == 0
}

# Package polyglossia Warning: No hyphenation patterns were loaded for `hungarian'
# Package polyglossia Warning: No hyphenation patterns were loaded for British English
check_polyglossia = function(text) {
  r = "^Package polyglossia Warning: No hyphenation patterns were loaded for ([`'][^']+'|British English).*"
  if (length(m <- grep_sub(r, '\\1', text)) == 0) return(FALSE)
  m[m == 'British English'] = 'english'
  m = gsub("[`']", '', m)
  tlmgr_install(paste0('hyphen-', m)) == 0
}

# Package datetime2 Warning: Date-Time Language Module `english' not installed on
# input line xxx.
check_datetime2 = function(text) {
  r = "^Package datetime2 Warning: Date-Time Language Module [`']([^']+)' not installed.*$"
  if (length(m <- grep_sub(r, '\\1', text)) == 0) return(FALSE)
  tlmgr_install(paste0('datetime2-', m)) == 0
}

# check the version of latexmk
check_latexmk_version = function() {
  out = system2('latexmk', '-v', stdout = TRUE)
  reg = '^.*Version (\\d+[.]\\d+).*$'
  out = grep_sub(reg, '\\1', out)
  if (length(out) == 0) return()
  ver = as.numeric_version(out[1])
  if (ver >= '4.43') return()
  system2('latexmk', '-v')
  warning(
    'Your latexmk version seems to be too low. ',
    'You may need to update the latexmk package or your LaTeX distribution.',
    call. = FALSE
  )
}

# return file paths that exist
exist_files = function(files) {
  files[utils::file_test('-f', files)]
}

# use file.copy() if file.rename() fails
file_rename = function(from, to) {
  if (from == to) return(TRUE)
  if (!suppressWarnings(file.rename(from, to))) {
    if (file.copy(from, to, overwrite = TRUE)) file.remove(from)
  }
}

#' Find missing LaTeX packages from a LaTeX log file
#'
#' Analyze the error messages in a LaTeX log file to figure out the names of
#' missing LaTeX packages that caused the errors. These packages can be
#' installed via \code{\link{tlmgr_install}()}. Searching for missing packages
#' is based on \code{\link{tlmgr_search}()}.
#' @param log Path to the LaTeX log file (typically named \file{*.log}).
#' @param text A character vector of the error log (read from the file provided
#'   by the \code{log} argument by default).
#' @param files A character vector of names of the missing files (automatically
#'   detected from the \code{log} by default).
#' @param quiet Whether to suppress messages when finding packages. It should be
#'   a logical vector of length 3: the first element indicates whether to
#'   suppress the message when no missing LaTeX packages could be detected from
#'   the log, the second element indicate whether to suppress the message when
#'   searching for packages via \code{tlmgr_search()}, and the third element
#'   indicates whether to warn if no packages could be found via
#'   \code{tlmgr_search()}.
#' @return A character vector of LaTeX package names.
#' @export
parse_packages = function(
  log, text = read_lines(log), files = detect_files(text), quiet = rep(FALSE, 3)
) {
  pkgs = character(); quiet = rep_len(quiet, length.out = 3)
  x = unique(c(files, miss_font()))
  if (length(x) == 0) {
    if (!quiet[1]) message(
      'I was unable to find any missing LaTeX packages from the error log',
      if (missing(log)) '.' else c(' ', log, '.')
    )
    return(invisible(pkgs))
  }
  for (j in seq_along(x)) {
    l = tlmgr_search(paste0('/', x[j]), stdout = TRUE, .quiet = quiet[2])
    if (length(l) == 0) next
    if (x[j] == 'fandol') return(x[j])  # a known package
    # why $? e.g. searching for mf returns a list like this
    # metafont.x86_64-darwin:
    #     bin/x86_64-darwin/mf       <- what we want
    # metapost.x86_64-darwin:
    #     bin/x86_64-darwin/mfplain  <- but this also matches /mf
    k = grep(paste0('/', x[j], '$'), l)  # only match /mf exactly
    if (length(k) == 0) {
      if (!quiet[3]) warning('Failed to find a package that contains ', x[j])
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

regex_errors = function() {
  # possible errors are like:
  # ! LaTeX Error: File `framed.sty' not found.
  # /usr/local/bin/mktexpk: line 123: mf: command not found
  # ! Font U/psy/m/n/10=psyr at 10.0pt not loadable: Metric (TFM) file not found
  # !pdfTeX error: /usr/local/bin/pdflatex (file tcrm0700): Font tcrm0700 at 600 not found
  # xdvipdfmx:fatal: Unable to find TFM file "rsfs10"
  # ! The font "FandolSong-Regular" cannot be found.
  # ! Package babel Error: Unknown option `ngerman'. Either you misspelled it
  # (babel)                or the language definition file ngerman.ldf was not found.
  # !pdfTeX error: pdflatex (file 8r.enc): cannot open encoding file for reading
  # ! CTeX fontset `fandol' is unavailable in current mode
  # Package widetext error: Install the flushend package which is a part of sttools
  # Package biblatex Info: ... file 'trad-abbrv.bbx' not found
  # ! Package pdftex.def Error: File `logo-mdpi-eps-converted-to.pdf' not found
  # ! xdvipdfmx:fatal: pdf_ref_obj(): passed invalid object.
  # ! Package tikz Error: I did not find the tikz library 'hobby'... named tikzlibraryhobby.code.tex
  # support file `supp-pdf.mkii' (supp-pdf.tex) is missing
  # ! I can't find file `hyph-de-1901.ec.tex'.
  # ! Package pdfx Error: No color profile sRGB_IEC61966-2-1_black_scaled.icc found
  # No file LGRcmr.fd. ! LaTeX Error: This NFSS system isn't set up properly.
  list(
    font = c(
      # error messages about missing fonts (don't move the first item below, as
      # it is special and emitted by widetext; the rest can be freely reordered)
      '.*Package widetext error: Install the ([^ ]+) package.*',
      ".*! Font [^=]+=([^ ]+).+ not loadable.*",
      '.*! .*The font "([^"]+)" cannot be found.*',
      '.*!.+ error:.+\\(file ([^)]+)\\): .*',
      '.*Unable to find TFM file "([^"]+)".*'
    ),
    fd = c(
      # font definition files
      ".*No file ([^`'. ]+[.]fd)[.].*"
    ),
    epstopdf = c(
      # possible errors when epstopdf is missing
      ".* File [`'](.+eps-converted-to.pdf)'.*",
      ".*xdvipdfmx:fatal: pdf_ref_obj.*"
    ),
    colorprofiles.sty = c(
      '.* Package pdfx Error: No color profile ([^ ]+).*'
    ),
    `lua-uni-algos.lua` = c(
      ".* module '(lua-uni-normalize)' not found:.*"
    ),
    tikz = c(
      # when a required tikz library is missing
      '.* (tikzlibrary[^ ]+?[.]code[.]tex).*'
    ),
    style = c(
      # missing .sty or commands
      ".* Loading '([^']+)' aborted!",
      ".*! LaTeX Error: File [`']([^']+)' not found.*",
      ".* [fF]ile ['`]?([^' ]+)'? not found.*",
      '.*the language definition file ([^ ]+) .*',
      '.* \\(file ([^)]+)\\): cannot open .*',
      '.* open style file ([^ ]+).*',
      ".*file [`']([^']+)' .*is missing.*",
      ".*! CTeX fontset [`']([^']+)' is unavailable.*",
      ".*: ([^:]+): command not found.*",
      ".*! I can't find file [`']([^']+)'.*"
    )
  )
}

# find filenames (could also be font names) from LaTeX error logs
detect_files = function(text) {
  r = regex_errors()
  x = grep(paste(unlist(r), collapse = '|'), text, value = TRUE)
  if (length(x) > 0) unique(unlist(lapply(unlist(r), function(p) {
    v = grep_sub(p, '\\1', x)
    if (length(v) == 0) return(v)
    if (p == r$tikz && length(grep('! Package tikz Error:', text)) == 0) return()
    # these are some known filenames
    for (i in c('epstopdf', grep('[.]', names(r), value = TRUE))) {
      if (p %in% r[[i]]) return(i)
    }
    if (p == r$fd) v = tolower(v)  # LGRcmr.fd -> lgrcmr.fd
    if (!(p %in% r$font)) return(v)
    if (p == r$font[1]) paste0(v, '.sty') else font_ext(v)
  })))
}

#' Parse the LaTeX log and install missing LaTeX packages if possible
#'
#' This is a helper function that combines \code{\link{parse_packages}()} and
#' \code{\link{tlmgr_install}()}.
#' @param ... Arguments passed to \code{\link{parse_packages}()}.
#' @export
parse_install = function(...) {
  tlmgr_install(parse_packages(...))
}

# check missfont.log and detect the missing font packages; missfont.log
# typically looks like this:
#   mktexpk --mfmode / --bdpi 600 --mag 1+0/600 --dpi 600 ecrm0900
miss_font = function() {
  if (!file.exists(f <- 'missfont.log')) return()
  on.exit(unlink(f), add = TRUE)
  x = gsub('\\s*$', '', read_lines(f))
  x = grep('.+\\s+.+', x, value = TRUE)
  if (length(x) == 0) return()
  x1 = gsub('.+\\s+', '', x)  # possibly missing fonts
  x2 = gsub('\\s+.+', '', x)  # the command to make fonts
  unique(c(font_ext(x1), x2))
}

font_ext = function(x) {
  i = !grepl('[.]', x)
  x[i] = paste0(x[i], '(-(Bold|Italic|Regular).*)?[.](tfm|afm|mf|otf|ttf)')
  x
}

# it should be rare that we need to manually run texhash
texhash = function() {
  tweak_path()
  system2('texhash')
}

updmap = function(usermode = FALSE) {
  tweak_path()
  system2(if (usermode) 'updmap-user' else 'updmap-sys')
}

fmtutil = function(usermode = FALSE, ...) {
  tweak_path()
  system2(if (usermode) 'fmtutil-user' else 'fmtutil-sys', '--all', ...)
}

fc_cache = function(args = c('-v', '-r')) {
  tweak_path()
  # run fc-cache on default dirs, then on the TinyTeX root dir
  for (i in unique(c('', tinytex_root(error = FALSE))))
    system2('fc-cache', shQuote(c(args, if (i != '') i)))
}

# refresh/update/regenerate everything
refresh_all = function(...) {
  fc_cache(); fmtutil(...); updmap(...); texhash()
}

# look up files in the Kpathsea library, e.g., kpsewhich('Sweave.sty')
kpsewhich = function(filename, options = character()) {
  tweak_path()
  system2('kpsewhich', c(options, shQuote(filename)))
}
