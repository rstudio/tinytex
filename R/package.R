#' @import stats utils tools
NULL

os = .Platform$OS.type

is_linux = function() Sys.info()[['sysname']] == 'Linux'
