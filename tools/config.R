writeLines('options(repos = "https://cran.rstudio.com")', '~/.Rprofile')
dir.create('~/R', FALSE, TRUE)
writeLines('R_LIBS_USER="~/R"', '~/.Renviron')
