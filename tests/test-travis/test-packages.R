# make sure the default installation includes all LaTeX packages required to
# compile basic R Markdown documents and bookdown books to PDF
if (.Platform$OS.type == 'unix') xfun::in_dir('../../../tinytex/tools', {
  system('sh install-base.sh && ./texlive/bin/*/tlmgr path add')
  xfun::pkg_load2('bookdown')
  bookdown:::bookdown_skeleton('book')
  xfun::in_dir('book', for (i in c('pdflatex', 'xelatex', 'lualatex')) {
    bookdown::render_book(
      'index.Rmd', 'bookdown::pdf_book', output_options = list(latex_engine = i)
    )
  })
  x1 = sort(tinytex::tl_pkgs())
  x2 = sort(readLines('pkgs-custom.txt'))
  if (!identical(x1, x2)) stop(
    'pkgs-custom.txt needs to be updated.\n\nPackages installed are:\n',
    paste(x2, collapse = '\n'), '\n\nPackages required are:\n',
    paste(x1, collapse = '\n')
  )
})
