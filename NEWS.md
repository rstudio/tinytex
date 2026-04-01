# CHANGES IN tinytex VERSION 0.60

- The backward-compatible `TinyTeX.tar.gz` (Linux) and `TinyTeX.tgz` (macOS) bundles are now truly gzip-compressed instead of being XZ-compressed copies with misleading extensions. Backward-compatible copies are only provided for the `TinyTeX` bundle (used by Quarto's `quarto install tinytex`), not for `TinyTeX-0`, `TinyTeX-1`, or `TinyTeX-2` (thanks, @knstmrd @pebenbow, rstudio/tinytex-releases#58).

# CHANGES IN tinytex VERSION 0.59

- Fixed font package detection for fonts with spaces in their names (e.g., "Noto Emoji", "DejaVu Sans"). Previously, `latexmk()` failed to automatically install the missing font package because the search pattern preserved the space, but font files never have spaces in their names (thanks, @cderv, #478, #479).

- Added detection for PDF/A errors and automatic installation of the **latex-lab** package when `\DocumentMetadata` support files are missing (thanks, @cderv).

- Added the **colorprofiles**, **latex-lab**, and **pdfmanagement-testphase** packages to the `TinyTeX` bundle to better support PDF/A document compilation (thanks, @cderv, @gordonwoodhull, #481, #482).

- Support TeX Live on macOS when symlinks are installed to `/Library/TeX/texbin` (a standard MacTeX-style installation), so that users no longer need to manually adjust `PATH`.

- TinyTeX prebuilt binaries are now provided for ARM64 Linux (`aarch64`) (thanks, @edavidaja, #483).

- TinyTeX prebuilt binaries are now provided for x86_64 musl Linux (Alpine Linux and other musl-based distributions), so Docker/Alpine users can install TinyTeX with a fast binary download instead of a slow source build (#485, #487).

- The TinyTeX release binary naming scheme has been updated to `TinyTeX-{N}-{os}[-{arch}].{ext}` (e.g., `TinyTeX-1-linux-x86_64.tar.xz`, `TinyTeX-1-linux-arm64.tar.xz`, `TinyTeX-1-darwin.tar.xz`). Old-style names remain available as backward-compatible copies (#484).

- `install_tinytex()` and `install-bin-unix.sh` now automatically detect and use the new naming scheme for versions after `2026.03.02`, and fall back to the old naming for older versions.

- The default CTAN repository is now `https://tlnet.yihui.org` (a CDN-based mirror hosted on Cloudflare). If this is not accessible, the installer falls back to `https://mirror.ctan.org`.

- The Windows installation scripts (`install-windows.bat` and `install-bin-windows.bat`) have been rewritten in PowerShell; the `.bat` files are now thin wrappers that download and run the corresponding `.ps1` scripts (#492, #493).

- Suppress spurious warnings from `tlmgr_version()` when `tlmgr` cannot be executed (https://github.com/rstudio/rmarkdown/issues/2612).

- On macOS, TinyTeX now uses `/etc/paths.d/TinyTeX` to add the TinyTeX binary directory to `PATH` when `/usr/local/bin` is not writable, instead of recursively changing the ownership of `/usr/local/bin`. The previous behavior (using `tlmgr path add`) is preserved for users who have already made `/usr/local/bin` writable. This fixes a filesystem security issue (thanks, @r2evans, #463, #489).

# CHANGES IN tinytex VERSION 0.58

- Detect missing language definition files from babel errors `! Package babel Error: Unknown option 'xxx'` (thanks, @cderv, #476).

# CHANGES IN tinytex VERSION 0.57

- Added the missing font detection for the **[haranoaji](https://ctan.org/pkg/haranoaji)** package (thanks, @kenjisato @cderv, #465).

- The [daily TinyTeX release](https://github.com/rstudio/tinytex-releases/releases/tag/daily) includes `texlive-local.deb` now (thanks, @salim-b, #467).

# CHANGES IN tinytex VERSION 0.56

- Fixed a bug introduced in v0.55 that changed `latexmk()`'s default output path inadvertently, causing errors when compiling a `.tex` input file that is not under the current working directory (thanks, @thanasisn @solvi808, https://github.com/rstudio/rmarkdown/issues/2589).

# CHANGES IN tinytex VERSION 0.55

- `latexmk()` supports the engine arguments `--no-pdf` and `--output-format=dvi` now (thanks, @pmur002, #455).

- Corrected the filename of TeX Live source package installer from `install-unix.tar.gz` to `installer-unix.tar.gz` (thanks, @csoneson, #460).

# CHANGES IN tinytex VERSION 0.54

- Provided an internal function `tinytex:::ctan_mirrors()` to return a data frame containing information about all CTAN mirrors (#450).

- Changed `which` to `command -v` in the installation script for *nix. The latter is more portable because it is a built-in shell feature, and `which` is an external utility that is not necessarily installed (#451).

# CHANGES IN tinytex VERSION 0.53

- Detects the missing font from the `fontspec` error `The font "***" cannot be found` (thanks, @cderv, #448).

# CHANGES IN tinytex VERSION 0.52

- Added independent packages in lieu of the **ms** package to the `TinyTeX` bundle (thanks, @benz0li, #445).

- Added the **anyfontsize** package to the `TinyTeX` bundle (thanks, @olivroy, #446).

- Disabled the automatic search and installation of missing LaTeX packages by default when the LaTeX distribution is not TinyTeX.

# CHANGES IN tinytex VERSION 0.51

- Added a global option `tinytex.upgrade` to automatically upgrade TinyTeX when it fails due to a new release of TeX Live each year. By default, this option is `FALSE`. If you set `options(tinytex.upgrade = TRUE)` (e.g., in `.Rprofile`), TinyTeX will try to upgrade itself when it is not possible to install or update LaTeX packages from CTAN due to the fact that it is still based on a previous year's TeX Live.

# CHANGES IN tinytex VERSION 0.50

- The installation script `install-bin-unix.sh` will throw an error early if `perl` is not found (thanks, @jangorecki, #431). Note that on Linux, `perl-base` is insufficient.

- `options(tinytex.tlmgr_update = FALSE)` can be set to prevent `tlmgr update --self --all` when `tinytex::tlmgr_install()` tries to install packages (thanks, @matthewgson, #434).

- Fixed bugs in `tinytex:::auto_repo()` that prevented `tinytex::install_tinytex()` from setting the CTAN repository after installation (thanks, @dmkaplan2000, #436).

# CHANGES IN tinytex VERSION 0.49

- On Windows, TinyTeX will be installed to the directory defined by the environment variable `ProgramData` when `APPDATA` points to a path that contains spaces or non-ASCII characters (thanks, @AJThurston @wesleyburr #420, @norbusan #427).

- Detect and fix the error caused by the L3 programming layer mismatch (thanks, @wesleyburr, #424).

# CHANGES IN tinytex VERSION 0.48

- The script to ask users to `chmod /usr/local/bin` failed to work on newer versions of macOS.

- More efforts to avoid releasing broken versions of TinyTeX.

- Deal with invalid characters in LaTeX logs (thanks, @martinmodrak, #425).

# CHANGES IN tinytex VERSION 0.47

- Documented on the help page `?tinytex::install_tinytex` that installing TinyTeX requires `perl`, and `perl-base` on Linux is not sufficient (thanks, @mfansler, #419).

- Enhanced the instruction message when users run into Unicode problems in `latexmk()` (thanks, @LexiangYang).

# CHANGES IN tinytex VERSION 0.46

- Changed `tlmgr_version(raw = TRUE/FALSE)` to `tlmgr_version(format = 'raw'/'string'/'list')`: the previous `raw = TRUE` means `format = 'raw'`; `raw = FALSE` means `format = 'string'`; `format = 'list'` returns structured data that can be used for computation.

# CHANGES IN tinytex VERSION 0.45

- TeX Live has renamed the `win32` directory under `bin/` to `windows`.

- Automatically correct the spelling of `TinyTeX` in the `bundle` argument of `install_tinytex()` (thanks, @kellijohnson-NOAA, #408).

- Fixed a bug that `check_installed()` returns `FALSE` for the entire vector when a single package is missing (thanks, @ThierryO, #404).

- The babel language `pinyin` should be treated as `chinese` (thanks, @nigeder).

- Removed the LaTeX package **soulutf8** from TinyTeX (thanks, @benz0li, #402).

# CHANGES IN tinytex VERSION 0.44

- For the `TinyTeX-2` bundle, its file format has been changed from `.gz` to `.xz` on Linux and macOS (#394), and from `.zip` to `.exe` on Windows (#398).

- The installation script `install-unx.sh` no longer changes the working directory (#386).

# CHANGES IN tinytex VERSION 0.43

- Added the LaTeX package **pdfcol** to the `TinyTeX` bundle (#387).

# CHANGES IN tinytex VERSION 0.42

- Querying CTAN might time out, which can cause failure in installing TinyTeX (thanks, Lillian Welsh, https://stackoverflow.com/q/73404800/559676).

- When installing TinyTeX on macOS and the directory `/usr/local/bin` does not exist, users will be prompted to create it. Then if it is not writable, users will be prompted to make it writable via `chown`.

# CHANGES IN tinytex VERSION 0.41

- TinyTeX no longer defines the `TEXMFHOME` variable (thanks, @vsheg, #377).

# CHANGES IN tinytex VERSION 0.40

- Added a `bundle` argument to `tinytex::install_tinytex()`, so that users can choose to install [any TinyTeX bundle](https://github.com/rstudio/tinytex-releases#releases), e.g., `TinyTeX-0` or `TinyTeX-2`.

# CHANGES IN tinytex VERSION 0.39

- The `tinytex` and `tinytex-releases` repositories have been moved from @yihui's account to @rstudio, i.e., their addresses are https://github.com/rstudio/tinytex/ and https://github.com/rstudio/tinytex-releases/ now.

- The full TeX Live has been pre-built as the `TinyTeX-2` bundle in the daily release of TinyTeX: https://github.com/rstudio/tinytex-releases/releases/tag/daily

- If `tinytex::install_tinytex()` detects an existing LaTeX distribution in the system, it will ask if you want to continue the installation in an interactive R session. In a non-interactive R session, it will throw an error unless `force = TRUE` is used. The environment variable `TINYTEX_PREVENT_INSTALL=true` can also be set to prevent the installation.

- On *nix, if the dir `~/.local/bin` exists, it will be used as the bin path for TinyTeX. If it does not exist, `~/bin/` will be used as usual (thanks, @salim-b, #365).

# CHANGES IN tinytex VERSION 0.38

- Fixed #354: set the env var `TEXLIVE_PREFER_OWN=1` before calling `tlmgr()` to use TeX Live's own `curl` instead of `curl` on `PATH` (thanks, @netique).

- Detect the `lua-uni-algos` package in case of error `module 'lua-uni-normalize' not found` (thanks, @dragonstyle).

- Added the help page `?tinytex` (thanks, @AmeliaMN, #361).

- Use `set -e` and `curl -f` to fail immediately in the *nix installation script (thanks, @gaborcsardi, #356).

# CHANGES IN tinytex VERSION 0.37

- Fixed rstudio/bookdown#1274: `latexmk()` should run the LaTeX engine one more time before calling `makeindex` (thanks, @trevorcampbell @ttimbers).

# CHANGES IN tinytex VERSION 0.36

- Fixed the failure to detect the **hyphen-french** package from the LaTeX log.

- `xfun::session_info('tinytex')` can report the TeX Live (TinyTeX) version now.

- Improved the way `tinytex::tlmgr_repo()` normalizes the repo URL (#346).

# CHANGES IN tinytex VERSION 0.35

- `install_tinytex()` will automatically switch to using https://github.com/yihui/tinytex-releases/releases/tag/daily to install the daily version of TinyTeX if accessing https://yihui.org fails (#332).

- `install-bin-unix.sh` and `install-bin-windows.bat` now install TinyTeX from https://github.com/yihui/tinytex-releases/releases/tag/daily instead of `https://yihui.org/tinytex/TinyTeX.*` (#270).

- Fixed #322: automatically install `hyphen-*` packages in case of **polyglossia** warnings.

- Run `tlmgr conf texmf max_print_line 10000` to prevent LaTeX from wrapping log lines. If you do not like this configuration, you may run `tlmgr conf texmf --delete max_print_line` to delete it.

# CHANGES IN tinytex VERSION 0.34

- The `--data` argument in `tl_sizes()` is properly quoted now to make it work on Windows (thanks, @IndrajeetPatil #329, @cderv #330).

# CHANGES IN tinytex VERSION 0.33

- Fixed the paths in `texmf-var/fonts/conf/fonts.conf` (thanks, @igelstorm @norbusan, #313).

- Each LaTeX warning is now converted to a single R warning, which is printed immediately (thanks, @krivit, #315).

- Remove the character `v` from the `version` argument of `install_tinytex()` (thanks, @cderv, #318).

# CHANGES IN tinytex VERSION 0.32

- The latest release of TinyTeX from https://github.com/yihui/tinytex-releases can be installed via `tinytex::install_tinytex(version = 'latest')` now.

- Provide a global option `options(tinytex.source.install = TRUE)` to force `tinytex::install_tinytex()` to use the source installer instead of installing the prebuilt binary (#301).

- The LaTeX package **psnfss** is included in the default TinyTeX distribution now (#303).

- Fixed #295: use the environment variable `$OSTYPE` in bash to make sure we install the prebuilt TinyTeX binary only for `linux` but not other distributions such as `linux-musl`.

- Fixed #299: handle the error `! Package pdfx Error: No color profile sRGB_IEC61966-2-1_black_scaled.icc found` and install the **colorprofiles** package.

- Fixed ulyngs/oxforddown#4: also detect missing font definition files like `LGRcmr.fd` and install missing packages accordingly.

- Fixed #311: install the glossary and datetime2 language module when a warning like `Package glossaries Warning: No language module detected for 'english'` is detected.

- Fixed #302: the environment variable `TINYTEX_VERSION` does not work for `tools/install-bin-unix.sh` when trying to install TinyTeX from the source installer.

# CHANGES IN tinytex VERSION 0.31

- Support `tectonic` as a new engine (thanks, @dpryan79, #290).

- Also recompile the `.tex` document if required by `biblatex` (thanks, @cderv, #288).

- `check_installed()` returns a logical vector instead of a scalar now, to indicate if individual LaTeX packages are installed or not.

- Fixed #291: detect the `l3kernel` package from the error message about `expl3.sty`, and update existing packages when they are required to be installed, since they might be too old to remain compatible with other packages.

- Bundled more LaTeX packages in the `TinyTeX.*` bundles.

# CHANGES IN tinytex VERSION 0.30

- Exported functions `is_tinytex()` and `check_installed()` (thanks, @cderv, #269).

- When `options(tinytex.latexmk.warning = FALSE)`, delete the log file in `latex_emu()` if it contains warnings (thanks, @guang-yu-zhu, #281).

- Removed warnings against existing LaTeX distributions in `install_tinytex()` (thanks, @AmeliaMN, #275).

- Set `TEXMFHOME` to `./texmf-home` instead of `$TEXMFLOCAL`.

# CHANGES IN tinytex VERSION 0.29

- Missing fonts are better detected now, e.g., for the font name `Caladea`, **tinytex** also tries to find files `Caladea-(Bold|Italic|Regular)` (thanks, @cderv, #268).

# CHANGES IN tinytex VERSION 0.28

- It is possible to suppress LaTeX warnings via the global option `options(tinytex.latexmk.warning = FALSE)` now (thanks, @fgoerlich #256, @cderv #260).

# CHANGES IN tinytex VERSION 0.27

- Fixed the installation script for non-Linux platforms (#243).

- When `bibtex` fails, `tinytex::latexmk()` should try to find out the missing packages instead of stopping immediately.

- Run `rd %APPDATA/TinyTeX%` twice to remove TinyTeX on Windows to avoid installation failures. Also deleted `install-tl` and `install-tl-windows.bat` in the prebuilt TinyTeX binaries.

- Added the `tinytex::tlmgr_repo()` function to query or set the CTAN repository for TinyTeX.

- Fixed `tinytex::install_tinytex()` for Linux machines that are not `x86_64` (#252).

# CHANGES IN tinytex VERSION 0.26

- The R function `tinytex::install_tinytex()` now installs prebuilt binaries of TinyTeX. Previously it used the TeX Live installer to install packages. Now it downloads a single prebuilt package and extracts it locally. If the operating system is not Windows, macOS, or Linux, the previous method (the TeX Live installer) is still used.

- By default, `tinytex::install_tinytex()` will reinstall all currently installed LaTeX packages after reinstalling TinyTeX, so you won't lose any packages. If you want a fresh installation (keeping the previous behavior), use `install_tinytex(extra_packages = NULL)`.

- Added a `version` argument to `install_tinytex()`, so users can install a specific version of TinyTeX.

# CHANGES IN tinytex VERSION 0.25

- Improved the search for missing TikZ libraries (thanks, @boltomli, #221).

- Fixed the installation of TinyTeX on Unix-alikes such as FreeBSD (thanks, @rhurlin, #222).

- Added an argument `delete_tlpdb` to `tlmgr_update()` to automatically delete the `tlpkg/texlive.tlpdb.*` files after `tlmgr update`. The value of this argument can be set via a global option `options(tinytex.delete_tlpdb = TRUE)` (thanks, @AlfonsoMuskedunder, #226).

# CHANGES IN tinytex VERSION 0.24

- The value of the `install_packages` argument of `tinytex::latexmk()` can be set via a global option, e.g., `options(tinytex.install_packages = FALSE)` to disable the automatic installation of missing LaTeX packages.

- By default, the automatic installation of missing packages only works when the `tlmgr` executable is writable. This means that, by default, `tinytex::latexmk()` will no longer try to install missing packages if you are using the `texlive-*` packages of your OS (e.g., Debian/Ubuntu/Fedora).

# CHANGES IN tinytex VERSION 0.23

- `tinytex::latexmk()` can automatically install missing `hyphen-*` packages now (thanks, @boltomli, #204).

- Added tests to make sure the default installation of TinyTeX is able to compile basic R Markdown documents and **bookdown** projects against `pdflatex`, `xelatex`, and `lualatex` (thanks, @AlfonsoMuskedunder, #207).

- `tinytex:::install_prebuilt()` supports Windows, macOS, and Ubuntu now.

# CHANGES IN tinytex VERSION 0.22

- Provided a more informative message to R users about upgrading TeX Live yearly.

- Exported the `parse_install()` function.

- Fixed the bug that `latexmk()` could accidentally delete TinyTeX on Linux (#197). Linux users are strongly recommended to update **tinytex** to v0.22.

# CHANGES IN tinytex VERSION 0.21

- Do not run `tlmgr path add` if `/usr/local/bin/tlmgr` doesn't exist (thanks, @cboettig, #181).

- Do not use `$HOME` in texmf variables, otherwise they might create `~/.TinyTeX` (#150).

# CHANGES IN tinytex VERSION 0.20

- `tinytex:::is_tinytex()` will no longer signal an error if TinyTeX is not found; it returns `FALSE` instead.

- `uninstall_tinytex()` will cleanly uninstall TinyTeX and delete the `~/.TinyTeX` folder if it exists.

- Added an argument `add_path` to `install_tinytex()` so users can disable `tlmgr path add` (thanks, @norbusan, #179).

# CHANGES IN tinytex VERSION 0.19

- Added more LaTeX packages to the default installation due to changes on CTAN (thanks, @ateucher @jonkeane, #158 #166 #167 #169).

- Support installing older versions of TeX Live from https://texlive.info.

- Automatically install `mktexpk` when necessary (#173).

- Correctly detect the missing file from error messages of the form `Encoding file 't2aenc.def' not found` (thanks, @ngriffiths21, #174).

- Emit fewer messages when trying to automatically install missing LaTeX packages (#174).

# CHANGES IN tinytex VERSION 0.18

- Added a few LaTeX packages to the default installation of TinyTeX (#158, #160, #163).

- Automatically install **epstopdf** when there is an error `! xdvipdfmx:fatal: pdf_ref_obj(): passed invalid object.` (#161).

- When a `.tex` document fails to compile, run `tinytex::tlmgr_update()` to avoid package compatibility issues.

# CHANGES IN tinytex VERSION 0.17

- Missing LaTeX packages can be detected from error messages like `! Package isodate.sty Error: Package file substr.sty not found` (thanks, @boltomli, #144).

- Added an argument `min_times` to `tinytex::latexmk()` to specify the minimum number of compilation times (thanks, @billdenney, #148).

- The `repository` argument of `tinytex::install_tinytex()` is more intelligent now: if you only provide `repository = "http://mirrors.tuna.tsinghua.edu.cn/CTAN/"`, the path to `tlnet` will be appended automatically.

# CHANGES IN tinytex VERSION 0.16

- Allow `tlmgr path add` to fail on macOS when installing TinyTeX.

# CHANGES IN tinytex VERSION 0.15

- Fixed #129: redirect xelatex error messages to the LaTeX log file, so that missing font packages (e.g., **rsfs**) can be parsed and automatically installed (thanks, @uninyhart).

- Fixed #132: `tinytex.profile` contains broken paths on Windows (thanks, @twwd).

# CHANGES IN tinytex VERSION 0.14

- Missing TikZ libraries can be identified from the LaTeX error message and automatically installed by `tinytex::latexmk()`.

- The missing `mptopdf` package can be correctly detected from the LaTeX error message and automatically installed.

- `tinytex::tl_pkgs()` correctly returns package names containing dots, such as `texlive.infra` (thanks, @riccardoporreca, #120).

- Added the **float** package to the default installation of TinyTeX (thanks, @ivan-krukov, #122).

- Compile LaTeX documents for enough times when `longtable` is used (thanks, @eheinzen, #124).

# CHANGES IN tinytex VERSION 0.13

- `tinytex::reinstall_tinytex()` will print out the instruction on how to reinstall previously installed LaTeX packages, in case the reinstall fails.

- `tinytex::reinstall_tinytex()` will try to preserve the `texmf-local` directory if it is not empty (#117).

- For the shell/batch scripts to install TinyTeX, the CTAN mirror can be set via the environment variable `CTAN_REPO` (#114).

# CHANGES IN tinytex VERSION 0.12

- Fixed #108: if the `repository` argument is provided in `tinytex::install_tinytex()`, the TeX Live network installer will be downloaded from this repository instead of the default CTAN mirror.

- When an error like `! Package inputenc Error: Unicode character` is detected in the LaTeX compilation log, `tinytex::latexmk()` will remind users of using `xelatex` instead of the default `pdflatex` (#109).

# CHANGES IN tinytex VERSION 0.11

- `latexmk()` will try to automatically install babel hyphenation packages (#97).

- **tinytex** received a hex logo designed by @haozhu233.

- Also read `missfont.log` to automatically install missing font packages.

- `latexmk(engine = 'latex')` is also supported to generate `.dvi` output from `.tex`.

- Allow TinyTeX to be installed alongside with other LaTeX distributions (#102).

- No longer require `/usr/local/bin` to be writable on macOS (#24).

- When there is a LaTeX error `! Missing $ inserted`, `latexmk()` will try to provide more context for R Markdown users to find out where the error comes from.

# CHANGES IN tinytex VERSION 0.10

- `latexmk()` will do a better job of detecting and installing font packages.

- When the LaTeX compilation generates warnings in the log file, the log file will not be deleted.

# CHANGES IN tinytex VERSION 0.9

- Five LaTeX packages (`dvips`, `helvetic`, `inconsolata`, `tex`, `times`) were added to the default TinyTeX installation (#73).

- On macOS, if `/usr/local/bin` is not writable during `tinytex::install_tinytex()`, the installation script will ask for password to gain the admin privilege to make this directory writable (#24).

- Patch `tlpkg/TeXLive/TLPDB.pm` to remove the false alarm when (un)installing LaTeX packages via `tlmgr` in a system-wide TinyTeX installation (#77).

# CHANGES IN tinytex VERSION 0.8

- Fixed #69: `install_tinytex()` failed on Windows.

- Added a function `tinytex_root()` to return the root directory of TinyTeX.

- Added functions `copy_tinytex()` and `use_tinytex()` to make it easier to copy an existing TinyTeX installation to another location and use it in another system.

# CHANGES IN tinytex VERSION 0.7

- It is possible to provide a custom command to generate the LaTeX index via the global option `tinytex.makeindex`.

- Fixed #60: R's texmf tree cannot be found on Manjaro Linux via `R.home('share')`.

- When both MiKTeX (or another LaTeX distribution) and TinyTeX are installed on Windows, TinyTeX will be used.

- Always expand the path of the input file in `latexmk()` (#64).

# CHANGES IN tinytex VERSION 0.6

- Added a new function `tl_pkgs()` to list installed LaTeX packages.

- Added a new function `reinstall_tinytex()` to uninstall and reinstall TinyTeX.

- The package **epstopdf** will be automatically installed if needed.

- The package **latexmk** is included in the default installation of TinyTeX now (#51).

# CHANGES IN tinytex VERSION 0.5

- Fixed #26: suppress warnings about invalid input in the current locale.

- Fixed #28: `system2('pdflatex', stdout = FALSE)` does not work in RStudio's R console.

- Fixed #29: override the PDF output file directly.

- Support the global option `tinytex.output_dir` (#32).

# CHANGES IN tinytex VERSION 0.4

- Added a way to show more information for debugging when compiling `.tex` documents.

- Added a `clean` argument to `latexmk()`, so that users can choose to keep the auxiliary files (#21).

- Do not (temporarily) change the working directory to the parent directory of the `.tex` file before compiling it to PDF (#22).

- Added a `pdf_file` argument to `latexmk()`.

- Check if `wget` exists on Linux (or `curl` on macOS) in `install_tinytex()` (#23).

# CHANGES IN tinytex VERSION 0.3

- `~/bin` does not need to be on `PATH` on Linux now for `latexmk()` to work.

- `emulation = TRUE` is the new default for `latexmk()`.

- Added the `tl_sizes()` function to show the sizes of LaTeX packages installed.

- Added an `engine_args` argument to `latexmk()`.

- Made it possible to specify the CTAN mirror in `install_tinytex()` (#14).

# CHANGES IN tinytex VERSION 0.2

- Fixed a minor bug on Windows (`latexmk()` may fail to install packages automatically).

- More informative messages during `install_tinytex()`.

# CHANGES IN tinytex VERSION 0.1

- The first CRAN release.

# CHANGES IN tinytex VERSION 0.0

- The first draft version.
