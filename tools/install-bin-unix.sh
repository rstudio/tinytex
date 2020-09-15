#!/bin/sh

cd ${TMPDIR:-/tmp}

if [ $(uname) = 'Darwin' ]; then
  curl -LO https://yihui.org/tinytex/TinyTeX-1.tgz
  rm -r ~/Library/TinyTeX
  tar xzf TinyTeX-1.tgz -C ~/Library/
  rm TinyTeX-1.tgz
  ~/Library/TinyTeX/bin/*/tlmgr path add
else
  wget --progress=dot:giga https://yihui.org/tinytex/TinyTeX-1.tar.gz
  rm -r ~/.TinyTeX
  tar xzf TinyTeX-1.tar.gz -C ~/
  rm TinyTeX-1.tar.gz
  cd ~/.TinyTeX/bin/*/
  ./tlmgr option sys_bin ~/bin
  ./tlmgr path add
fi
