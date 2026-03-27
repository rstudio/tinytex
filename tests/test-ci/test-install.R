library(testit)

assert('normalize_repo() creates a valid url', {
  (normalize_repo('https://mirrors.mit.edu/CTAN/') %==%
     'https://mirrors.mit.edu/CTAN/systems/texlive/tlnet')
  (normalize_repo('https://ftp.tu-chemnitz.de/pub/tug/historic/systems/texlive/2020/tlnet-final/') %==%
     'https://ftp.tu-chemnitz.de/pub/tug/historic/systems/texlive/2020/tlnet-final')
})
