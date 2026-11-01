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

assert('pdflatex(), xelatex(), and lualatex() compile a document', {
  d = tempfile(); dir.create(d); owd = setwd(d); on.exit({setwd(owd); unlink(d, recursive = TRUE)}, add = TRUE)
  file.copy(file.path(owd, 'sub', 'test.tex'), 'a.tex')
  (pdflatex('a.tex') %==% 'a.pdf')
  (file.exists('a.pdf')); unlink('a.pdf')
  (xelatex('a.tex') %==% 'a.pdf')
  unlink('a.pdf')
  (lualatex('a.tex') %==% 'a.pdf')
  # engine names like pdftex are normalized
  unlink('a.pdf')
  (latexmk('a.tex', 'pdftex') %==% 'a.pdf')
})

assert('latexmk() fails on a bad extension and on a LaTeX error', {
  (has_error(latexmk('a.txt')))
  d = tempfile(); dir.create(d); owd = setwd(d); on.exit({setwd(owd); unlink(d, recursive = TRUE)}, add = TRUE)
  writeLines(c('\\documentclass{article}', '\\begin{document}', '\\undefinedmacro', '\\end{document}'), 'bad.tex')
  (has_error(suppressMessages(latexmk('bad.tex', install_packages = FALSE))))
})

assert('latexmk() reruns and builds a bibliography with bibtex', {
  d = tempfile(); dir.create(d); owd = setwd(d); on.exit({setwd(owd); unlink(d, recursive = TRUE)}, add = TRUE)
  writeLines(c(
    '\\documentclass{article}', '\\begin{document}', 'See \\cite{k}. \\ref{s}\\label{s}',
    '\\bibliographystyle{plain}', '\\bibliography{r}', '\\end{document}'
  ), 'b.tex')
  writeLines('@book{k, author={A. Author}, title={Some Title}, year={2020}, publisher={P}}', 'r.bib')
  latexmk('b.tex', clean = FALSE)
  (any(grepl('Some Title', readLines('b.bbl'))))
})

assert('parse_packages() maps a missing .sty to its package via tlmgr', {
  (parse_packages(text = "! LaTeX Error: File `framed.sty' not found.", quiet = TRUE) %==% 'framed')
})

assert('miss_font() reads and removes missfont.log', {
  d = tempfile(); dir.create(d); owd = setwd(d); on.exit({setwd(owd); unlink(d, recursive = TRUE)}, add = TRUE)
  (is.null(miss_font()))
  writeLines('mktexpk --mfmode / --bdpi 600 --mag 1+0/600 --dpi 600 ecrm0900', 'missfont.log')
  (miss_font() %==% c(font_ext('ecrm0900'), 'mktexpk'))
  (!file.exists('missfont.log'))
})

assert('kpsewhich() finds installed files', {
  (grepl('article[.]cls$', kpsewhich('article.cls', stdout = TRUE)))
  (length(kpsewhich('no-such-file.xyz', stdout = TRUE)) == 0)
})

assert('prescan_install() does nothing when all packages are installed', {
  f = tempfile(fileext = '.tex'); on.exit(unlink(f))
  writeLines(c('\\documentclass{article}', '\\usepackage{graphicx}', '\\begin{document}x\\end{document}'), f)
  (is.null(prescan_install(f)))
  writeLines('\\documentclass{article}', f)
  (is.null(prescan_install(f)))
})

assert('latex hints are given for common errors', {
  (grepl('xelatex', tryCatch(check_unicode('! LaTeX Error: Unicode character x'), message = conditionMessage)))
  d = tempfile(); dir.create(d); on.exit(unlink(d, recursive = TRUE))
  f = file.path(d, 'a.tex'); file.create(file.path(d, 'a.Rmd'))
  (grepl('inline R expression', tryCatch(
    check_inline_math(c('! Missing $ inserted.', 'l.5 x_1'), f), message = conditionMessage
  )))
})

assert('latex_warning() reads warnings from a real compilation log', {
  d = tempfile(); dir.create(d); owd = setwd(d); on.exit({setwd(owd); unlink(d, recursive = TRUE)}, add = TRUE)
  writeLines(c('\\documentclass{article}', '\\begin{document}\\ref{nope}\\end{document}'), 'w.tex')
  latexmk('w.tex', clean = FALSE)
  (any(grepl('undefined', latex_warning('w.log', FALSE))))
})
