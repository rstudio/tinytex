# make sure the default installation includes all LaTeX packages required to
# compile basic R Markdown documents and bookdown books to PDF

xfun::in_dir('..', xfun::install_dir('tinytex'))
owd = setwd('tools')

system('sh install-base.sh && mv texlive ../../ && ../../texlive/bin/*/tlmgr path add')
unlink(normalizePath('~/texlive'), recursive = TRUE)
x0 = tinytex::tl_pkgs()  # packages from the minimal installation
cat('\nBase packages are:', sort(x0), '\n\n')

render = function(..., FUN = rmarkdown::render) {
  xfun::Rscript_call(FUN, list(...))
}

xfun::pkg_load2('bookdown')
# render some Rmd files to automatically install LaTeX packages to TinyTeX
render('test-basic.Rmd', 'pdf_document', quiet = TRUE)
bookdown:::bookdown_skeleton('book')
xfun::in_dir('book', for (i in c('pdflatex', 'xelatex', 'lualatex')) render(
  FUN = bookdown::render_book, 'index.Rmd', 'bookdown::pdf_book',
  output_options = list(latex_engine = i), quiet = TRUE
))

# report the size of TeX Live after installing the above packages
system('du -sh ../../texlive')

# now see which packages are required to compile the above Rmd files
x1 = sort(unique(c(
  setdiff(tinytex::tl_pkgs(), x0),
  'latexmk',  # https://github.com/yihui/tinytex/issues/51
  'float', # https://github.com/yihui/tinytex/issues/122
  # https://github.com/yihui/tinytex/issues/73
  'ec', 'inconsolata', 'times', 'tex', 'helvetic', 'dvips', 'metafont', 'mfware', 'xkeyval'
)))
tinytex::tlmgr_install(x1)
x2 = sort(readLines('pkgs-custom.txt'))
if (!identical(x1, x2)) stop(
  'pkgs-custom.txt needs to be updated.\n\nPackages required are:\n',
  paste(x1, collapse = '\n')
)

# any new packages need to be added to pkgs-yihui.txt?
tinytex::tlmgr_install(readLines('pkgs-yihui.txt'))
x3 = tinytex::tl_pkgs()
build_more = function() {
  render('test-basic.Rmd', 'beamer_presentation', quiet = TRUE)
  render('test-kableExtra.Rmd', quiet = TRUE)
}
build_more()
# were there any new packages installed?
x4 = tinytex::tl_pkgs()
if (length(x5 <- setdiff(x4, x3))) stop(
  'pkgs-yihui.txt needs to include:\n', paste(x5, collapse = '\n')
)

setwd(owd)
