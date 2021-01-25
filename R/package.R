#' @import stats utils tools
#' @importFrom xfun grep_sub dir_exists in_dir
NULL

os = .Platform$OS.type

.global = new.env(parent = emptyenv())
