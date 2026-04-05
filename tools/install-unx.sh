#!/bin/sh

set -e

PREVWD=${PWD}
cd ${TMPDIR:-/tmp}

if [ $(uname) = 'Darwin' ]; then
  TEXDIR=${TINYTEX_DIR:-~/Library/TinyTeX}
else
  TEXDIR=${TINYTEX_DIR:-~/.TinyTeX}
fi

if command -v curl > /dev/null 2>&1; then
  download() { curl -sL --retry 10 --retry-delay 30 "$1"; }
else
  download() { wget -qO- --tries=11 --waitretry=30 "$1"; }
fi

rm -f install-tl-unx.tar.gz tinytex.profile
download https://tinytex.yihui.org/install-base.sh | sh -s - "$@"

rm -rf $TEXDIR
mkdir -p $TEXDIR
mv texlive/* $TEXDIR
# a token to differentiate TinyTeX with other TeX Live distros
touch $TEXDIR/.tinytex
rm -r texlive
cd $PREVWD
# finished base

rm -r $OLDPWD/install-tl-*

$TEXDIR/bin/*/tlmgr install $(download https://tinytex.yihui.org/pkgs-custom.txt | tr '\n' ' ')

if [ "$1" = '--admin' ]; then
  if [ "$2" != '--no-path' ]; then
    sudo $TEXDIR/bin/*/tlmgr path add
  fi
else
  $TEXDIR/bin/*/tlmgr path add || true
fi
