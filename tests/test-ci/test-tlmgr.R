library(testit)

assert('tlmgr is available', {
  tlmgr_available()
})

assert('tlmgr_search() searches the online TeX Live database', {
  res = tlmgr_search('/framed', stdout = TRUE)

  ('framed:' %in% res)
  (any(grepl('/framed[.]sty$', res)))
})

assert('`tlmgr info` can list the installed packages', {
  res = tlmgr(c('info', '--list', '--only-installed', '--data', 'name'), stdout = TRUE)
  # only check a few basic packages
  (c('xetex', 'luatex', 'graphics') %in% res)
})

assert('`tl_size()` can correctly list name and size', {
  res = tl_sizes(pkgs = "luatex")$package
  # only check a few basic packages
  ('luatex' %==% tl_sizes(pkgs = "luatex")$package)
})

assert('fonts package are correctly identified', {
  p_q = function(...) parse_packages(..., quiet = c(TRUE, TRUE, TRUE))
  (p_q(text = "! Font U/psy/m/n/10=psyr at 10.0pt not loadable: Metric (TFM) file not found") %==% 'symbol')
  (p_q(text = '! The font "FandolSong-Regular" cannot be found.') %==% 'fandol')
  (p_q(text = '!pdfTeX error: /usr/local/bin/pdflatex (file tcrm0700): Font tcrm0700 at 600 not found') %==% 'ec')
  (p_q(text = '! Package fontspec Error: The font "Caladea" cannot be found.') %==% 'caladea')
})

assert('tlmgr_version() reports TeX Live and tlmgr versions', {
  l = tlmgr_version('list')
  (l$texlive >= 2020)
  (inherits(l$tlmgr, 'Date'))
  (is.logical(l$tinytex))
  s = tlmgr_version('string')
  (grepl('^TeX Live \\d+ .*with tlmgr \\d{4}-\\d{2}-\\d{2}$', s))
  (any(grepl('tlmgr revision', tlmgr_version())))
})

assert('check_installed() tells installed packages from unknown ones', {
  (check_installed(c('graphics', 'no-such-pkg-xyz')) %==% c(TRUE, FALSE))
  (check_installed(character()))
})

assert('tl_pkgs() lists installed packages without platform suffixes', {
  p = tl_pkgs()
  (c('xetex', 'luatex', 'graphics') %in% p)
  (!any(grepl('[.]x86_64-linux$', p)))
})

assert('tl_platform() returns a known platform', {
  (tl_platform() %in% tinytex:::.tl_platforms)
})

assert('tlmgr_install() with no packages does nothing', {
  (tlmgr_install() %==% 0L)
  (is.null(tlmgr_remove()))
})

assert('tlmgr_repo() shows the current repository', {
  r = tlmgr_repo(stdout = TRUE, .quiet = TRUE)
  (any(grepl('repository', r)))
})

assert('tl_unrelocatable() returns package names', {
  (is.character(tl_unrelocatable()))
})

assert('check_tl_version() is silent unless a new TeX Live release is announced', {
  (!check_tl_version('tlmgr: package repository https://example.org'))
  (!check_tl_version(character()))
  op = options(tinytex.upgrade = FALSE); on.exit(options(op), add = TRUE)
  (tryCatch(
    { check_tl_version('Local TeX Live (2020) is older than remote repository (2021)'); TRUE },
    message = function(e) grepl('new version of TeX Live', conditionMessage(e))
  ))
})

assert('tinytex_root() and find_tlmgr() locate the installation', {
  r = tinytex_root()
  (dir.exists(file.path(r, 'bin')))
  (xfun::sans_ext(basename(find_tlmgr(r))) %==% 'tlmgr')
  (is.logical(is_tinytex()))
  (find_tinytex_bin() != '')
  (nchar(Sys.which('tlmgr')) > 0)
  # symlinks are resolved to the real tlmgr.pl (no symlinks on Windows)
  if (xfun::is_unix()) {
    (basename(symlink_root(Sys.which('tlmgr'))) %==% 'tlmgr.pl')
  }
})

assert('r_texmf_path() points to a directory with Rd.sty', {
  p = r_texmf_path()
  (length(list.files(p, 'Rd[.]sty$', recursive = TRUE)) > 0)
})

assert('xfun_session_info() describes the LaTeX installation', {
  (grepl('LaTeX version used', xfun_session_info()))
})
