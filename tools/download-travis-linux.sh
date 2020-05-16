#!/bin/sh

mkdir -p ~/bin

[ ! -z $TINYTEX_FORCE_INSTALL ] && rm -rf ~/.TinyTeX

if [ ! -d ~/.TinyTeX/bin ]; then
  wget --progress=dot:giga https://travis-bin.yihui.org/tinytex.tar.gz
  tar xzf tinytex.tar.gz -C ~/
  rm tinytex.tar.gz
fi

cd ~/.TinyTeX/bin/*/
./tlmgr option sys_bin ~/bin
./tlmgr path add
