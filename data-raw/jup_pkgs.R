## code to prepare `jup_pkgs` dataset goes here

jup_pkgs <- c(
  "adjustbox",
  "caption",
  "collectbox",
  "enumitem",
  "environ",
  "eurosym",
  "jknapltx",
  "parskip",
  "pgf",
  "rsfs",
  "tcolorbox",
  "titling",
  "trimspaces",
  "ucs",
  "ulem",
  "upquote"
)

usethis::use_data(jup_pkgs, overwrite = TRUE)
