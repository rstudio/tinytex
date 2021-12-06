library(testit)

assert('normalize_repo() creates a valid url', {
  (normalize_repo('https://ctan.math.illinois.edu/') %==%
     'https://ctan.math.illinois.edu/systems/texlive/tlnet')
  (normalize_repo('https://ftp.tu-chemnitz.de/pub/tug/historic/systems/texlive/2020/tlnet-final/') %==%
     'https://ftp.tu-chemnitz.de/pub/tug/historic/systems/texlive/2020/tlnet-final')
})
