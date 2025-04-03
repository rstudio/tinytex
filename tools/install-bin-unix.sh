#!/bin/sh

set -e

perl -mFile::Find /dev/null ||
  (echo "perl is required but not found (https://github.com/rstudio/tinytex/issues/419)" && exit 1)

cd ${TMPDIR:-/tmp}

[ -z $(command -v tlmgr) ] || TL_INSTALLED_PKGS=$(tlmgr info --list --only-installed --data name | tr '\n' ' ')
[ -z "$TL_INSTALLED_PKGS" ] ||
  echo "If you want to reinstall currently installed packages, use this command after the TinyTeX installation is done:

tlmgr install $TL_INSTALLED_PKGS

"

TAR_FLAGS=""
if tar --version 2>/dev/null | grep -q 'GNU tar'; then
    TAR_FLAGS="--no-same-owner"
elif tar --version 2>/dev/null | grep -q 'bsdtar'; then
    TAR_FLAGS="--no-same-permissions"
elif tar --version 2>/dev/null | grep -q 'busybox'; then
    TAR_FLAGS="-o"
fi

OSNAME=$(uname)
[ -z $OSNAME ] && echo "This operating system is not supported." && exit 1

if [ -z $OSTYPE ]; then
  OSTYPE=$([ -x "$(command -v bash)" ] && bash -c 'echo $OSTYPE')
fi

TINYTEX_INSTALLER=${TINYTEX_INSTALLER:-"TinyTeX-1"}

if [ $OSNAME = 'Darwin' ]; then
  TEXDIR=${TINYTEX_DIR:-~/Library}/TinyTeX
else
  TEXDIR=${TINYTEX_DIR:-~}/.TinyTeX
  if [ $OSNAME != 'Linux' -o $(uname -m) != 'x86_64' -o "$OSTYPE" != 'linux-gnu' ]; then
    TINYTEX_INSTALLER="installer-unix"
  fi
fi

rm -rf $TEXDIR

if [ -z $TINYTEX_VERSION ]; then
  TINYTEX_URL="https://github.com/rstudio/tinytex-releases/releases/download/daily/$TINYTEX_INSTALLER"
else
  # the installer was accidentally named "install-unix" instead of "installer-unix" before v2025.01
  if [ "$TINYTEX_INSTALLER" = "installer-unix" ] && [ "$TINYTEX_VERSION" \< "2025.02" ]; then
    TINYTEX_INSTALLER="install-unix"
  fi
  TINYTEX_URL="https://github.com/rstudio/tinytex-releases/releases/download/v$TINYTEX_VERSION/$TINYTEX_INSTALLER-v$TINYTEX_VERSION"
fi

if [ $OSNAME = 'Darwin' ]; then
    curl -L -f --retry 10 --retry-delay 30 ${TINYTEX_URL}.tgz -o TinyTeX.tgz
    tar -x ${TAR_FLAGS} -f TinyTeX.tgz -C $(dirname $TEXDIR)
    rm TinyTeX.tgz
else if [ "${TINYTEX_INSTALLER#"TinyTeX"}" != "$TINYTEX_INSTALLER" ]; then
    wget --retry-connrefused --progress=dot:giga -O TinyTeX.tar.gz ${TINYTEX_URL}.tar.gz
    tar -x ${TAR_FLAGS} -f TinyTeX.tar.gz -C $(dirname $TEXDIR)
    rm TinyTeX.tar.gz
  else
    echo "We do not have a prebuilt TinyTeX package for this operating system ${OSTYPE}."
    echo "I will try to install from source for you instead."
    wget --retry-connrefused -O ${TINYTEX_INSTALLER}.tar.gz ${TINYTEX_URL}.tar.gz
    tar -x ${TAR_FLAGS} -f ${TINYTEX_INSTALLER}.tar.gz
    ./install.sh
    mkdir -p $TEXDIR
    mv texlive/* $TEXDIR
    rm -r texlive ${TINYTEX_INSTALLER}.tar.gz install.sh
  fi
fi

cd $TEXDIR/bin/*/

BINDIR="$HOME/.local/bin"
if [ ! -d  $BINDIR ]; then
  BINDIR="$HOME/bin"
fi

[ $OSNAME != "Darwin" ] && ./tlmgr option sys_bin $BINDIR
./tlmgr postaction install script xetex  # GH issue #313
([ -z $CI ] || [ $(echo $CI | tr "[:upper:]" "[:lower:]") != "true" ]) && ./tlmgr option repository ctan

if [ $OSNAME = 'Darwin' ]; then
  # create the dir if it doesn't exist
  if [ ! -d /usr/local/bin ]; then
    echo "Admin privilege (password) is required to create the directory /usr/local/bin:"
    sudo mkdir -p /usr/local/bin
  fi
  # change owner of the dir
  if [ ! -w /usr/local/bin ]; then
    echo "Admin privilege (password) is required to make /usr/local/bin writable:"
    sudo chown -R `whoami`:admin /usr/local/bin
  fi
fi

./tlmgr path add
