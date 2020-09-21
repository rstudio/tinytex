# TinyTeX

[![Build Status](https://travis-ci.com/yihui/tinytex.svg)](https://travis-ci.com/yihui/tinytex)
[![AppVeyor build status](https://ci.appveyor.com/api/projects/status/github/yihui/tinytex?svg=true&branch=master)](https://ci.appveyor.com/project/yihui/tinytex)
[![Coverage status](https://codecov.io/gh/yihui/tinytex/branch/master/graph/badge.svg)](https://codecov.io/github/yihui/tinytex?branch=master)
[![Downloads from the RStudio CRAN mirror](https://cranlogs.r-pkg.org/badges/tinytex)](https://cran.r-project.org/package=tinytex)

<a href="https://yihui.org/tinytex/"><img src="https://yihui.org/images/logo-tinytex.png" alt="tinytex logo" align="right" width="200px" /></a>

The motivation behind TinyTeX was from two common problems in installing and maintaining LaTeX distributions:

1. You have to either install a basic version that is relatively small (several hundred MB) but basically doesn't work, because it is very likely that certain frequently used LaTeX packages are missing; or you install the full version that is several GB, but in your whole life, you probably will only use 1% of the packages.

2. The documentation for installation and maintenance is often too long for beginners. For example, [the `tlmgr` manual](https://www.tug.org/texlive/doc/tlmgr.html) is comprehensive and very useful, but it is often hard to figure out what to do when running into a LaTeX issue that says a certain `.sty` file is not found.

I believe these problems can be solved by TinyTeX, a custom LaTeX distribution based on TeX Live that is small in size but still functions well in most cases. Even if you run into the problem of missing LaTeX packages, it should be super clear to you what you need to do. In fact, if you are an R Markdown user, there is nothing you need to do, because missing packages will just be installed automatically. You may not even know the existence of LaTeX at all since it should rarely bother you.

This repo contains the installation scripts of TinyTeX (under the `tools` directory) and the R companion package **tinytex**. Please see the full documentation at <https://yihui.org/tinytex/>. Obviously I hope it is not too long.

The R package **tinytex** is licensed under MIT. The LaTeX distribution TinyTeX is [licensed under GPL-2](https://github.com/yihui/tinytex-releases#license).
