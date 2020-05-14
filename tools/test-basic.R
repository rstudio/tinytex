# make sure a basic Rmd document compiles with TinyTeX
options(tinytex.verbose = TRUE)
for (i in c('pdflatex', 'xelatex', 'lualatex')) {
  for (j in c('pdf_document', 'beamer_presentation')) {
    rmarkdown::render('tools/test-basic.Rmd', j, output_options = list(latex_engine = i))
  }
}
