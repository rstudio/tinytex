#' @import stats utils tools
#' @importFrom xfun grep_sub dir_exists download_file in_dir
#' @keywords internal
'_PACKAGE'

os = .Platform$OS.type

.global = new.env(parent = emptyenv())
