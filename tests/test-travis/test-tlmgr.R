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

suppressMessages(
  assert('fonts package are correctly identified', {
    parse_packages(text = "! Font U/psy/m/n/10=psyr at 10.0pt not loadable: Metric (TFM) file not found") %==% "symbol"
    parse_packages(text = '! Package fontspec Error: The font "Caladea" cannot be found.') %==% 'caladea'
  })
)
