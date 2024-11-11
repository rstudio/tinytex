library(testit)

assert('latexmk() can generate DVI output', {
  latexmk2 = function(e, a = NULL) latexmk('test-dvi.tex', e, engine_args = a)
  (latexmk2('latex') %==% 'test-dvi.dvi')
  (latexmk2('xelatex', '--no-pdf') %==% 'test-dvi.xdv')
  (latexmk2('lualatex', '--output-format=dvi') %==% 'test-dvi.dvi')
})
