# check if we need to update the downloaded TinyTeX-2 bundle
u = grep('^update: ', tinytex::tlmgr(c('update', '--list'), stdout = TRUE), value = TRUE)
if (length(u)) {
  message(paste(c('Needs update:\n', u), collapse = '\n'))
  quit(status = 1)
}
if (!tinytex::check_installed('scheme-full')) {
  message('Needs update: scheme-full is not installed')
  quit(status = 1)
}
