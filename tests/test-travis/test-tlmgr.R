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
