# set an env var to true once a month, and make a Github release on this day
env_file = normalizePath('tools/env-appveyor.bat')
set_env = function(name, value) {
  cat(
    sprintf('%s %s=%s\n', if (xfun::is_windows()) 'set' else 'export', name, value),
    file = env_file, append = TRUE
  )
}
releasing = Sys.getenv('TINYTEX_RELEASE_DATE') == 'true'
if (!releasing) releasing = as.integer(format(Sys.Date(), '%d')) == 1
set_env('TINYTEX_RELEASE_DATE', tolower(releasing))

if (!releasing || Sys.getenv('GH_TOKEN') == '') q('no')

# TODO: use xfun >= 0.17.4 when it's available on CRAN and remove the following function
process_file = function(file, FUN = identity, x = xfun::read_utf8(file)) {
  x = FUN(x)
  if (missing(file)) x else xfun::write_utf8(x, file)
}

v = format(Sys.Date(), '%Y.%m')  # version number of the format YEAR.MONTH
set_env('TINYTEX_TAG', v2 <- paste0('v', v))

system(sprintf(
  'git clone https://%s@github.com/yihui/tinytex-windows.git',
  Sys.getenv('GH_TOKEN')
))

xfun::in_dir('tinytex-windows', if (xfun::is_windows()) {
  m = tools::md5sum('../TinyTeX-1.zip')
  f = function(x, r, val) {
    if (length(i <- grep(r, x)) != 1) stop('There must be a line that matches ', r)
    x[i] = gsub(r, sprintf('\\1%s\\3', val), x[i])
    x
  }
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
  system(sprintf('git tag %s', v2))
  system('git push -q --tags origin master')
})
