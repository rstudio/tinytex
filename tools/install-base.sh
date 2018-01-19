#!/bin/sh

rm -f install-tl-unx.tar.gz texlive.profile
echo "Downloading install-tl-unx.tar.gz to ${PWD} ..."
TLURL="http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz"
PRURL "https://github.com/yihui/tinytex/raw/master/tools/texlive.profile"
if [ $(uname) = 'Darwin' ]; then
  curl -LO $TLURL
  curl -LO $PRURL
else
  wget $TLURL
  wget $PRURL
  # ask `tlmgr path add` to add binaries to ~/bin instead of the default
  # /usr/local/bin unless this script is invoked with the argument '--admin'
  # (e.g., users want to make LaTeX binaries available system-wide)
  if [ "$1" != '--admin' ]; then
    mkdir -p $HOME/bin
    echo "tlpdbopt_sys_bin ${HOME}/bin" >> texlive.profile
  fi
fi
tar -xzf install-tl-unx.tar.gz
rm install-tl-unx.tar.gz

mkdir texlive
cd texlive
TEXLIVE_INSTALL_ENV_NOCHECK=true TEXLIVE_INSTALL_NO_WELCOME=true ../install-tl-*/install-tl -profile=../texlive.profile
rm -r ../install-tl-* ../texlive.profile install-tl.log

cd bin/*
if [ $3 != '' ]; then
  ./tlmgr option repository $3
  # test if the repository is accessible; if not, set the default CTAN repo
  ./tlmgr update --list || ./tlmgr option repository ctan
fi
./tlmgr install latex-bin luatex xetex
