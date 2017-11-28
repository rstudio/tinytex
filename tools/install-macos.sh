#!/bin/sh

cd $TMPDIR
curl -LO https://github.com/yihui/tinytex/raw/master/tools/texlive.profile
curl -L https://github.com/yihui/tinytex/raw/master/tools/install-base.sh | sh
rm -r install-tl-* texlive.profile

TEXDIR=~/Library/TinyTeX
mkdir -p $TEXDIR
mv texlive/* $TEXDIR
$TEXDIR/bin/*/tlmgr path add

curl -L https://github.com/yihui/tinytex/raw/master/tools/install-recommended.sh | sh
tlmgr path add
