#!/bin/sh

mkdir -p ~/bin

[ ! -z $TINYTEX_FORCE_INSTALL ] && rm -rf ~/.TinyTeX

  wget -q https://travis-bin.yihui.name/tinytex.tar.gz;
  tar xzf tinytex.tar.gz -C ~/;
  rm tinytex.tar.gz;

cd ~/.TinyTeX/bin/*/
./tlmgr path add
