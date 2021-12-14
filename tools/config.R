writeLines('options(repos = "https://cran.rstudio.com")', '~/.Rprofile')
if (.Platform$OS.type == 'unix' || Sys.getenv('R_LIBS_USER') == '') {
  dir.create('~/R', FALSE, TRUE)
  writeLines('R_LIBS_USER="~/R"', '~/.Renviron')
}
