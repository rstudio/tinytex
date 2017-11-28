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
download  https://github.com/yihui/tinytex/raw/master/tools/install-base.sh | sh -s "$@"
rm -r install-tl-* texlive.profile

rm -rf $TEXDIR
mkdir -p $TEXDIR
mv texlive/* $TEXDIR
rm -r texlive

cd $TEXDIR/bin/*
PATH=.:$PATH
download https://github.com/yihui/tinytex/raw/master/tools/install-recommended.sh | sh

if [ "$1" = '--admin' ]; then
  sudo $TEXDIR/bin/*/tlmgr path add
else
  $TEXDIR/bin/*/tlmgr path add
fi
