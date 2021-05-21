system2('git', c('clone', '--depth=1', 'https://github.com/quarto-dev/quarto-cli'))

setwd('quarto-cli')

os = if (.Platform$OS.type == 'windows') 1 else if (Sys.info()['sysname'] == 'Darwin') 2 else 3

system2(c('configure-windows.cmd', './configure-macos.sh', './configure-linux.sh')[os])

setwd('package/src')
system2(
  paste0(if (os > 1) './', 'quarto-bld'),
  c(
    'compile-quarto-latexmk', '--name', 'tinytex', '', '--version', format(Sys.Date(), '%Y.%m'),
    '--description', 'Intelligent compilation of LaTeX documents with TinyTeX', '--target',
    c('x86_64-pc-windows-msvc', 'x86_64-apple-darwin', 'x86_64-unknown-linux-gnu')[os]
  )
)

b = list.files('../dist/bin/tinytex', '^tinytex([.]exe)?$', full.names = TRUE, recursive = TRUE)
message('tinytex was built at ', b)
Sys.chmod(b, '0755')
file.copy(b, '../../..')
