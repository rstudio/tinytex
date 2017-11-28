#!/bin/sh

echo "Downloading install-tl-unx.tar.gz ..."
TLURL="http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz"
if [ $(uname) = 'Darwin' ]; then
  curl -LO $TLURL
else
  wget $TLURL
  # ask `tlmgr path add` to add binaries to ~/bin instead of /usr/local/bin
  # because the latter is usually not writable on Linux
  mkdir -p $HOME/bin
  echo "tlpdbopt_sys_bin ${HOME}/bin" >> texlive.profile
fi
tar -xzf install-tl-unx.tar.gz
rm install-tl-unx.tar.gz

mkdir texlive
cd texlive
TEXLIVE_INSTALL_ENV_NOCHECK=true TEXLIVE_INSTALL_NO_WELCOME=true ../install-tl-*/install-tl -profile=../texlive.profile

rm install-tl.log

cd bin/*

./tlmgr install latex-bin luatex xetex
