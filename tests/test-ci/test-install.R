library(testit)

assert('normalize_repo() creates a valid url', {
  # This test is flaky on GHA
  # (normalize_repo('https://mirrors.mit.edu/CTAN/') %==%
  #   'https://mirrors.mit.edu/CTAN/systems/texlive/tlnet')
  (normalize_repo('https://ftp.tu-chemnitz.de/pub/tug/historic/systems/texlive/2020/tlnet-final/') %==%
     'https://ftp.tu-chemnitz.de/pub/tug/historic/systems/texlive/2020/tlnet-final')
})

assert('normalize_repo() leaves special values and I() urls alone', {
  (is.null(normalize_repo(NULL)))
  (normalize_repo('ctan') %==% 'ctan')
  (normalize_repo(I('https://example.org/x/')) %==% I('https://example.org/x/'))
  (normalize_repo('illinois') %==% 'https://ctan.math.illinois.edu/systems/texlive/tlnet')
  # already normalized (trailing slashes are dropped)
  (normalize_repo('https://example.org/texlive/tlnet/') %==% 'https://example.org/texlive/tlnet')
})

assert('valid_path() rejects spaces and non-ASCII characters', {
  (valid_path('C:/TinyTeX'))
  (!valid_path('C:/Tiny TeX'))
  (!valid_path('C:/\u4e2d\u6587'))
})

assert('is_arm64() recognizes arm64 architecture names', {
  (is_arm64('aarch64')); (is_arm64('arm64')); (!is_arm64('x86_64'))
})

assert('binary_supported() depends on OS and architecture', {
  (is.logical(binary_supported()))
  (is.logical(is_musl()))
  if (tinytex:::os_index == 2 && !is_musl() && Sys.info()[['machine']] == 'x86_64') {
    (binary_supported())
    (binary_supported('daily'))
  }
})

assert('win_app_dir() prefers TINYTEX_DIR', {
  v = Sys.getenv('TINYTEX_DIR', NA)
  Sys.setenv(TINYTEX_DIR = '/x/y')
  (win_app_dir('TinyTeX') %==% '/x/y/TinyTeX')
  if (is.na(v)) Sys.unsetenv('TINYTEX_DIR') else Sys.setenv(TINYTEX_DIR = v)
})

assert('uninstall_tinytex() refuses to remove a non-TinyTeX installation without force', {
  if (!is_tinytex()) (has_error(uninstall_tinytex()))
})
