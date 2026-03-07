u = grep('^update: ', tinytex::tlmgr(c('update', '--list'), stdout = TRUE), value = TRUE)
if (length(u)) {
  message(paste(c('Needs update:\n', u), collapse = '\n'))
  quit(status = 1)
}
