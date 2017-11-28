#!/bin/sh

echo "Downloading install-tl-unx.tar.gz ..."
TLURL="http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz"
which curl && curl -LO $TLURL || wget $TLURL
tar -xzf install-tl-unx.tar.gz && rm install-tl-unx.tar.gz

mkdir texlive
cd texlive
TEXLIVE_INSTALL_ENV_NOCHECK=true TEXLIVE_INSTALL_NO_WELCOME=true ../install-tl-*/install-tl -profile=../texlive.profile

rm install-tl.log

cd bin/*

./tlmgr install latex-bin luatex xetex
