#!/bin/sh

set -e

cd ${TMPDIR:-/tmp}

[ -z $(which tlmgr) ] || TL_INSTALLED_PKGS=$(tlmgr info --list --only-installed --data name | tr '\n' ' ')
[ -z "$TL_INSTALLED_PKGS" ] ||
  echo "If you want to reinstall currently installed packages, use this command after the TinyTeX installation is done:

tlmgr install $TL_INSTALLED_PKGS

"

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
  TINYTEX_URL="https://github.com/rstudio/tinytex-releases/releases/download/v$TINYTEX_VERSION/$TINYTEX_INSTALLER-v$TINYTEX_VERSION"
fi

if [ $OSNAME = 'Darwin' ]; then
    curl -L -f --retry 10 --retry-delay 30 ${TINYTEX_URL}.tgz -o TinyTeX.tgz
    tar xf TinyTeX.tgz -C $(dirname $TEXDIR)
    rm TinyTeX.tgz
else if [ $TINYTEX_INSTALLER != 'installer-unix' ]; then
    wget --retry-connrefused --progress=dot:giga -O TinyTeX.tar.gz ${TINYTEX_URL}.tar.gz
    tar xf TinyTeX.tar.gz -C $(dirname $TEXDIR)
    rm TinyTeX.tar.gz
  else
    echo "We do not have a prebuilt TinyTeX package for this operating system ${OSTYPE}."
    echo "I will try to install from source for you instead."
    wget --retry-connrefused -O ${TINYTEX_INSTALLER}.tar.gz ${TINYTEX_URL}.tar.gz
    tar xf ${TINYTEX_INSTALLER}.tar.gz
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
