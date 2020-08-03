#!/bin/sh

mkdir -p ~/bin

[ ! -z $TINYTEX_FORCE_INSTALL ] && rm -rf ~/.TinyTeX

if [ ! -d ~/.TinyTeX/bin ]; then
  wget --progress=dot:giga https://yihui.org/tinytex/TinyTeX.tar.gz
  tar xzf TinyTeX.tar.gz -C ~/
  rm TinyTeX.tar.gz
fi

cd ~/.TinyTeX/bin/*/
./tlmgr option sys_bin ~/bin
./tlmgr path add
