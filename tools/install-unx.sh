#!/bin/sh

cd ${TMPDIR:-/tmp}

if [ $(uname) = 'Darwin' ]; then
  TEXDIR=~/Library/TinyTeX
  alias download='curl -sL'
  alias download2='curl -sLO'
else
  TEXDIR=~/.TinyTeX
  alias download='wget -qO-'
  alias download2='wget -q'
fi

download2 https://github.com/yihui/tinytex/raw/master/tools/texlive.profile
download  https://github.com/yihui/tinytex/raw/master/tools/install-base.sh | sh -s - "$@"
rm texlive.profile

rm -rf $TEXDIR
mkdir -p $TEXDIR
mv texlive/* $TEXDIR
rm -r texlive

$TEXDIR/bin/*/tlmgr install $(download https://github.com/yihui/tinytex/raw/master/tools/pkgs-custom.txt | tr '\n' ' ')

if [ "$1" = '--admin' ]; then
  if [ "$2" != '--no-path' ]; then
    sudo $TEXDIR/bin/*/tlmgr path add
  fi
else
  $TEXDIR/bin/*/tlmgr path add
fi
