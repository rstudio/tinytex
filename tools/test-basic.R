for (i in c('tlmgr', 'pdflatex', 'xelatex', 'pandoc')) {
  cat('\nThe version of', i, '\n\n')
  system2(i, '--version')
}
tinytex::tlmgr_install(readLines('tools/pkgs-yihui.txt'))
all_files = function() {
  list.files(tinytex::tinytex_root(), full.names = TRUE, recursive = TRUE)
}
files_old = all_files()

# make sure a basic Rmd document compiles with TinyTeX
options(tinytex.verbose = TRUE)
xfun::pkg_load2('rmarkdown')
for (i in c('pdflatex', 'xelatex', 'lualatex')) {
  for (j in c('pdf_document', 'beamer_presentation')) {
    rmarkdown::render('tools/test-basic.Rmd', j, output_options = list(latex_engine = i))
  }
}

if (length(files_new <- setdiff(all_files(), files_old))) {
  message(
    'Deleting files created during LaTeX compilation...\n',
    paste('  -', files_new, collapse = '\n')
  )
  file.remove(files_new)
}
