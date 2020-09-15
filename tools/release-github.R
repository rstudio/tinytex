# set an env var to true once a month, and make a Github release on this day
releasing = Sys.getenv('TINYTEX_RELEASE_DATE') == 'true'
if (!releasing) releasing = as.integer(format(Sys.Date(), '%d')) == 1
writeLines(paste0('set TINYTEX_RELEASE_DATE=', tolower(releasing)), 'tools/env-appveyor.bat')

if (!releasing || Sys.getenv('GH_TOKEN') == '') q('no')

# TODO: use xfun >= 0.17.4 when it's available on CRAN and remove the following function
process_file = function(file, FUN = identity, x = xfun::read_utf8(file)) {
  x = FUN(x)
  if (missing(file)) x else xfun::write_utf8(x, file)
}

system(sprintf(
  'git clone https://%s@github.com/yihui/chocolatey-tinytex.git',
  Sys.getenv('GH_TOKEN')
))
xfun::in_dir('chocolatey-tinytex', {
  m = tools::md5sum('../TinyTeX-1.zip')
  f = function(x, r, val) {
    if (length(i <- grep(r, x)) != 1) stop('There must be a line that matches ', r)
    x[i] = gsub(r, sprintf('\\1%s\\3', val), x[i])
    x
  }
  v = format(Sys.Date(), '%Y.%m')  # version number of the format YEAR.MONTH
  process_file('tinytex.nuspec', function(x) {
    f(x, '^(\\s*<version>)([0-9.]+)(</version>\\s*)$', v)
  })
  process_file('tools/chocolateyinstall.ps1', function(x) {
    f(x, "^(\\s*checksum      = ')([0-9a-f]{32})('\\s*)$", m)
  })
  system('git config user.email "xie@yihui.name"')
  system('git config user.name "Yihui Xie"')
  system('git add --all')
  system(sprintf('git commit -m"TinyTeX release v%s"', v))
  system(sprintf('git tag v%s', v))
  system('git push -q --tags origin master')
  cat(paste0('set TINYTEX_TAG=v', v), file = '../tools/env-appveyor.bat', append = TRUE)
})
