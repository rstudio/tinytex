# make sure the default installation includes all LaTeX packages required to
# compile basic R Markdown documents and bookdown books to PDF
if (.Platform$OS.type == 'unix') xfun::in_dir('../../../tools', {
  system('sh install-base.sh && ./texlive/bin/*/tlmgr path add')
  unlink(normalizePath('~/texlive'), recursive = TRUE)
  x0 = tinytex::tl_pkgs()  # packages from the infraonly scheme

  # render some Rmd files to automatically install LaTeX packages to TinyTeX
  rmarkdown::render('test-basic.Rmd', 'pdf_document')
  bookdown:::bookdown_skeleton('book')
  xfun::in_dir('book', for (i in c('pdflatex', 'xelatex', 'lualatex')) {
    x = readLines('_output.yml')
    writeLines(gsub('^(\\s+latex_engine:).+$', paste('\\1', i), x), '_output.yml')
    bookdown::render_book('index.Rmd', 'bookdown::pdf_book', quiet = TRUE)
  })

  # now see which packages are required to compile the above Rmd files
  x1 = sort(setdiff(tinytex::tl_pkgs(), x0))
  x2 = sort(readLines('pkgs-custom.txt'))
  if (!identical(x1, x2)) stop(
    'pkgs-custom.txt needs to be updated.\n\nPackages required are:\n',
    paste(x1, collapse = '\n')
  )
})
