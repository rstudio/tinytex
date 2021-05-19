system2('git', c('clone', '--depth=1', 'https://github.com/quarto-dev/quarto-cli'))

setwd('quarto-cli')

os = if (.Platform$OS.type == 'windows') 1 else if (Sys.info()['sysname'] == 'Darwin') 2 else 3

system2(c('configure-windows.cmd', './configure-macos.sh', './configure-linux.sh')[os])

setwd('package/src')
system2(
  paste0(if (os > 1) './', 'quarto-bld'),
  c(
    'compile-quarto-latexmk', '--target',
    c('x86_64-pc-windows-msvc', 'x86_64-apple-darwin', 'x86_64-unknown-linux-gnu')[os]
  )
)

b = list.files('../..', '^quarto-latexmk([.]exe)?$', full.names = TRUE, recursive = TRUE)
message('quarto-latexmk was built at ', b)
dir.create('../../../bin')
file.copy(b, file.path('../../../bin', paste0('tinytex', if (os == 1) '.exe')))
