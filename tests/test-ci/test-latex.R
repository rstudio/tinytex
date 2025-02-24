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
