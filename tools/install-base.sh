#!/bin/sh

rm -f install-tl-unx.tar.gz tinytex.profile
echo "Downloading install-tl-unx.tar.gz to ${PWD} ..."
TLREPO=${CTAN_REPO:-http://mirror.ctan.org/systems/texlive/tlnet}
TLURL="${TLREPO}/install-tl-unx.tar.gz"
PRURL="https://yihui.name/gh/tinytex/tools/tinytex.profile"
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
    echo "tlpdbopt_sys_bin ${HOME}/bin" >> tinytex.profile
  fi
fi
tar -xzf install-tl-unx.tar.gz
rm install-tl-unx.tar.gz

mkdir texlive
cd texlive
TEXLIVE_INSTALL_ENV_NOCHECK=true TEXLIVE_INSTALL_NO_WELCOME=true ../install-tl-*/install-tl -no-gui -profile=../tinytex.profile -repository $TLREPO
rm -r ../install-tl-* ../tinytex.profile install-tl.log

cd bin/*

./tlmgr option repository "$TLREPO"

if [ "$3" != '' ]; then
  ./tlmgr option repository "$3"
  if [ "$4" != '' ]; then
    ./tlmgr --repository http://www.preining.info/tlgpg/ install tlgpg
  fi
  # test if the repository is accessible; if not, set the default CTAN repo
  ./tlmgr update --list || ./tlmgr option repository ctan
fi
./tlmgr install latex-bin luatex xetex
