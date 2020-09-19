#!/bin/sh

cd ${TMPDIR:-/tmp}

[ -z $(which tlmgr) ] || TL_INSTALLED_PKGS=$(tlmgr info --list --only-installed --data name | tr '\n' ' ')
[ -z "$TL_INSTALLED_PKGS" ] ||
  echo "If you want to reinstall currently installed packages, use this command after the TinyTeX installation is done:

    tlmgr install $TL_INSTALLED_PKGS"

OSNAME=$(uname)
[ -z $OSNAME ] && echo "This operating system is not supported." && exit 1

if [ $OSNAME = 'Darwin' ]; then
  TEXDIR=${TINYTEX_DIR:-~/Library}/TinyTeX
else
  TEXDIR=${TINYTEX_DIR:-~}/.TinyTeX
fi

rm -rf $TEXDIR

case $OSNAME in
  "Darwin")
    curl -LO https://yihui.org/tinytex/TinyTeX-1.tgz
    tar xzf TinyTeX-1.tgz -C $(dirname $TEXDIR)
    rm TinyTeX-1.tgz
    ;;
  "Linux")
    wget --progress=dot:giga https://yihui.org/tinytex/TinyTeX-1.tar.gz
    tar xzf TinyTeX-1.tar.gz -C $(dirname $TEXDIR)
    rm TinyTeX-1.tar.gz
    ;;
  *)
    echo "We do not have a prebuilt TinyTeX package for the operating system $(uname)."
    echo "I will try to install from source for you instead."
    wget https://yihui.org/tinytex/installer-unix.tar.gz
    tar xzf installer-unix.tar.gz
    ./install.sh
    mkdir -p $TEXDIR
    mv texlive/* $TEXDIR
    rm -r texlive installer-unix.tar.gz install.sh
    ;;
esac

cd $TEXDIR/bin/*/
[ $OSNAME != "Darwin" ] && ./tlmgr option sys_bin ~/bin
./tlmgr path add
