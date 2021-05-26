system2('git', c('clone', '--depth=1', 'https://github.com/quarto-dev/quarto-cli'))

setwd('quarto-cli')

os = if (.Platform$OS.type == 'windows') 1 else if (Sys.info()['sysname'] == 'Darwin') 2 else 3

system2(c('configure-windows.cmd', './configure-macos.sh', './configure-linux.sh')[os])

setwd('package/src')
system2(
  paste0(if (os > 1) './', 'quarto-bld'),
  c(
    'compile-quarto-latexmk', '--name', 'tinitex', '', '--version', format(Sys.Date(), '%Y.%m'),
    '--description', 'Intelligent compilation of LaTeX documents with TinyTeX or TeX Live', '--target',
    c('x86_64-pc-windows-msvc', 'x86_64-apple-darwin', 'x86_64-unknown-linux-gnu')[os]
  )
)

# gzip a file without including its path in the tarball
gzip_file = function(f, ...) {
  owd = setwd(dirname(f)); on.exit(setwd(owd), add = TRUE)
  tar(..., files = basename(f), compression = 'gzip')
}

b = list.files('../dist/bin/tinitex', '^tinitex([.]exe)?$', full.names = TRUE, recursive = TRUE)
message('tinitex was built at ', b)
Sys.chmod(b, '0755')
print(file.info(b))

if (os == 1) {
  system2("powershell", c("-Command", shQuote(sprintf('Compress-Archive %s %s', b, p <- 'tinitex.zip'))))
} else {
  gzip_file(b, p <- paste0('tinitex.', if (os == 2) 'tgz' else 'tar.gz'))
}

file.copy(p, '../../..')
