for (i in c('tlmgr', 'pdflatex', 'xelatex', 'pandoc')) {
  cat('\nThe version of', i, '\n\n')
  system2(i, '--version')
}
tinytex::tlmgr_install(readLines('tools/pkgs-yihui.txt'))
all_files = function() {
  list.files(tinytex::tinytex_root(), full.names = TRUE, recursive = TRUE)
}
files_old = all_files()
pkgs_old  = tinytex::tl_pkgs()

# make sure a basic Rmd document compiles with TinyTeX
options(tinytex.verbose = TRUE)
xfun::pkg_load2('rmarkdown')
for (i in c('pdflatex', 'xelatex', 'lualatex')) {
  for (j in c('pdf_document', 'beamer_presentation')) {
    rmarkdown::render('tools/test-basic.Rmd', j, output_options = list(latex_engine = i))
  }
}

pkgs_new = setdiff(tinytex::tl_pkgs(), pkgs_old)

if (length(files_new <- setdiff(all_files(), files_old))) {
  message(
    'Deleting files created during LaTeX compilation...\n',
    paste('  -', files_new, collapse = '\n')
  )
  file.remove(files_new)
}

# in case some packages are cleaned up in the previous step, reinstall them
tinytex::tlmgr_remove(pkgs_new)
tinytex::tlmgr_install(pkgs_new)
