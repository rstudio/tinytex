#!/bin/sh

cd $TMPDIR
curl -sLO https://github.com/yihui/tinytex/raw/master/tools/texlive.profile
curl -sL https://github.com/yihui/tinytex/raw/master/tools/install-base.sh | sh
rm -r install-tl-* texlive.profile

TEXDIR=~/Library/TinyTeX
rm -rf $TEXDIR
mkdir -p $TEXDIR
mv texlive/* $TEXDIR
rm -r texlive
$TEXDIR/bin/*/tlmgr path add

curl -sL https://github.com/yihui/tinytex/raw/master/tools/install-recommended.sh | sh
