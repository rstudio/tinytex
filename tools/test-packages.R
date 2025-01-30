# make sure the default installation includes all LaTeX packages required to
# compile basic R Markdown documents and bookdown books to PDF

xfun::in_dir('..', xfun::install_dir('tinytex'))
if (!tinytex:::tlmgr_available()) stop("tlmgr not available")

system2('git', c('checkout', '--', '.'))  # drop changes if exist

owd = setwd('tools')

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
system(sprintf('du -sh %s', tinytex::tinytex_root()))

# now see which packages are required to compile the above Rmd files
x1 = sort(unique(c(
  setdiff(tinytex::tl_pkgs(), x0),
  'latexmk',  # https://github.com/rstudio/tinytex/issues/51
  'float', # https://github.com/rstudio/tinytex/issues/122
  'psnfss', # https://github.com/rstudio/tinytex/issues/303
  # https://github.com/rstudio/tinytex/issues/73
  'ec', 'inconsolata', 'times', 'tex', 'helvetic', 'dvips', 'metafont', 'mfware', 'xkeyval'
)))
tinytex::tlmgr_install(x1)
writeLines(x1, 'pkgs-custom.txt')

# any new packages need to be added to pkgs-yihui.txt?
x2 = readLines('pkgs-yihui.txt')
tinytex::tlmgr_install(x2)
x3 = tinytex::tl_pkgs()
build_more = function() {
  render('test-basic.Rmd', 'beamer_presentation', quiet = TRUE)
  render('test-kableExtra.Rmd', quiet = TRUE)
}
build_more()
# were there any new packages installed?
x4 = setdiff(tinytex::tl_pkgs(), x3)
writeLines(sort(c(x2, x4)), 'pkgs-yihui.txt')

setwd(owd)

p = tinytex:::tl_platforms()
writeLines(c(
  '# a copy of the returned result from tl_platform() is saved here because',
  '# tl_platforms() is a little slow and requires Internet connection',
  strwrap(sprintf('.tl_platforms = c(%s)', paste0("'", p, "'", collapse = ', ')), 80, exdent = 2)
), 'R/platforms.R')
