library(testit)

assert('detect_files() can detect filenames from LaTeX log', {
  (length(detect_files("asdf qwer")) == 0)

  (detect_files("! LaTeX Error: File `framed.sty' not found.") %==% 'framed.sty')

  (detect_files("/usr/local/bin/mktexpk: line 123: mf: command not found") %==% 'mf')

  (grepl('^psyr\\[\\.\\]', detect_files("! Font U/psy/m/n/10=psyr at 10.0pt not loadable: Metric (TFM) file not found")))

  (grepl('^FandolSong-Regular\\[\\.\\]', detect_files('! The font "FandolSong-Regular" cannot be found.')))

  (grepl('^tcrm0700\\[\\.\\]', detect_files('!pdfTeX error: /usr/local/bin/pdflatex (file tcrm0700): Font tcrm0700 at 600 not found')))

  (detect_files("or the language definition file ngerman.ldf was not found") %==% 'ngerman.ldf')

  (detect_files("!pdfTeX error: pdflatex (file 8r.enc): cannot open encoding file for reading") %==% '8r.enc')

  (detect_files("! CTeX fontset `fandol' is unavailable in current mode") %==% 'fandol')

  (detect_files('Package widetext error: Install the flushend package which is a part of sttools') %==% 'flushend.sty')
})
