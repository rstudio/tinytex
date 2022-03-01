library(testit)

assert('detect_files() can detect filenames from LaTeX log', {
  # Fonts are tested in test-tlmgr.R also
  (detect_files("! Font U/psy/m/n/10=psyr at 10.0pt not loadable: Metric (TFM) file not found") %==% font_ext("psyr"))
  (detect_files('! The font "FandolSong-Regular" cannot be found.') %==% font_ext("FandolSong-Regular"))
  (detect_files('!pdfTeX error: /usr/local/bin/pdflatex (file tcrm0700): Font tcrm0700 at 600 not found') %==% font_ext('tcrm0700'))

  (length(detect_files("asdf qwer")) == 0)
  (detect_files("! LaTeX Error: File `framed.sty' not found.") %==% 'framed.sty')
  (detect_files("/usr/local/bin/mktexpk: line 123: mf: command not found") %==% 'mf')
  (detect_files("or the language definition file ngerman.ldf was not found") %==% 'ngerman.ldf')
  (detect_files("!pdfTeX error: pdflatex (file 8r.enc): cannot open encoding file for reading") %==% '8r.enc')
  (detect_files("! CTeX fontset `fandol' is unavailable in current mode") %==% 'fandol')
  (detect_files('Package widetext error: Install the flushend package which is a part of sttools') %==% 'flushend.sty')
  (detect_files('! Package isodate.sty Error: Package file substr.sty not found.') %==% 'substr.sty')
  (detect_files("! Package fontenc Error: Encoding file `t2aenc.def' not found.") %==% 't2aenc.def')
  (detect_files("! I can't find file `hyph-de-1901.ec.tex'.") %==% 'hyph-de-1901.ec.tex')
  (detect_files("luaotfload-features.lua:835: module 'lua-uni-normalize' not found:") %==% 'lua-uni-algos.lua')
})


assert('rerun are correctly detected', {
  (needs_rerun(text = "Package biblatex Warning: Please rerun LaTeX."))
  (needs_rerun(text = "Please (re)run the file"))
  (needs_rerun(text = "error: Rerun LaTeX."))
  (needs_rerun(text = "Rerun to get the final file"))
})
