% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tlmgr.R
\name{check_installed}
\alias{check_installed}
\title{Check if certain LaTeX packages are installed}
\usage{
check_installed(pkgs)
}
\arguments{
\item{pkgs}{A character vector of LaTeX package names.}
}
\value{
A logical vector indicating if packages specified in \code{pkgs} are
  installed.
}
\description{
If a package has been installed in TinyTeX or TeX Live, the command
\command{tlmgr info PKG} should return \code{PKG} where \code{PKG} is the
package name.
}
\note{
This function only works with LaTeX distributions based on TeX Live,
  such as TinyTeX.
}
\examples{
\dontshow{if (interactive()) (if (getRversion() >= "3.4") withAutoprint else force)(\{ # examplesIf}
tinytex::check_installed('framed')
\dontshow{\}) # examplesIf}
}
