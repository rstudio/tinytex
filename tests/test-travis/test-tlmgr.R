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
