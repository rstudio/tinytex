# TinyTeX

[![Build Status](https://travis-ci.com/yihui/tinytex.svg)](https://travis-ci.com/yihui/tinytex)
[![AppVeyor build status](https://ci.appveyor.com/api/projects/status/github/yihui/tinytex?svg=true&branch=master)](https://ci.appveyor.com/project/yihui/tinytex)
[![Coverage status](https://codecov.io/gh/yihui/tinytex/branch/master/graph/badge.svg)](https://codecov.io/github/yihui/tinytex?branch=master)
[![Downloads from the RStudio CRAN mirror](https://cranlogs.r-pkg.org/badges/tinytex)](https://cran.r-project.org/package=tinytex)

<a href="https://yihui.org/tinytex/"><img src="https://yihui.org/images/logo-tinytex.png" alt="tinytex logo" align="right" width="200px" /></a>

The installation and maintenance of LaTeX have bothered me for several years. Yes, there are MiKTeX, MacTeX, and TeX Live, but the common problems are:

1. You have to either install a basic version that is relatively small (several hundred MB) but basically doesn't work, because it is very likely that certain frequently used LaTeX packages are missing; or you install the full version that is several GB, but in your whole life, you probably will only use 1% of the packages.

2. The documentation for installation and maintenance is often way too long for beginners. For example, I doubt if anyone has the courage or patience to read [the `tlmgr` manual](https://www.tug.org/texlive/doc/tlmgr.html) (yes, it is very useful).

I believe these problems can be solved by TinyTeX, a custom LaTeX distribution based on TeX Live that is small in size (about 150Mb) but still functions well in most cases. Even if you run into the problem of missing LaTeX packages, it should be super clear to you what you need to do. The manual should be at most two pages long. In fact, if you are an R Markdown user, there is nothing you need to do, because missing packages will just be installed automatically. You may not even know the existence of LaTeX at all since it should rarely bother you.

This repo contains the installation scripts of TinyTeX (under the `tools` directory) and the R companion package **tinytex**. Please see the full documentation at <https://yihui.org/tinytex/>. Obviously I hope it is not too long.
