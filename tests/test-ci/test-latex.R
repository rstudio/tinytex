library(testit)

assert('latexmk() can generate DVI output', {
  latexmk2 = function(e, a = NULL) latexmk('test-dvi.tex', e, engine_args = a)
  (latexmk2('latex') %==% 'test-dvi.dvi')
  (latexmk2('xelatex', '--no-pdf') %==% 'test-dvi.xdv')
  (latexmk2('lualatex', '--output-format=dvi') %==% 'test-dvi.dvi')
})

assert('latexmk() generates the PDF output to the dir of the .tex file by default', {
  (latexmk('sub/test.tex') %==% 'sub/test.pdf')
  # can also specify a custom pdf output path
  (latexmk('sub/test.tex', pdf_file = 'foo.pdf') %==% 'foo.pdf')
})

assert('latexmk() infers biber from the .bcf file when bib_engine is not set', {
  # a biblatex + biber document does not generate the \bibdata/\bibstyle info in
  # the .aux file that bibtex needs, so bibtex would silently do nothing; the
  # bibliography is only built if biber is (correctly) inferred from the .bcf
  owd = setwd('bib'); on.exit(setwd(owd), add = TRUE)
  latexmk('biber.tex', clean = FALSE)
  bbl = readLines('biber.bbl', warn = FALSE)
  file.remove(list.files('.', '^biber[.](aux|bbl|bcf|blg|log|pdf|run[.]xml)$'))
  (any(grepl('R Core Team', bbl, fixed = TRUE)))
})
