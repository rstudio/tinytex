#!/bin/sh

cd ${TMPDIR:-/tmp}

if [ $(uname) = 'Darwin' ]; then
  curl -LO https://yihui.org/tinytex/TinyTeX-1.tgz
  tar xzf TinyTeX-1.tar.gz -C ~/Library/
  rm TinyTeX-1.tgz
  ~/Library/TinyTeX/bin/*/tlmgr path add
else
  wget --progress=dot:giga https://yihui.org/tinytex/TinyTeX-1.tar.gz
  tar xzf TinyTeX-1.tar.gz -C ~/
  rm TinyTeX-1.tar.gz
  cd ~/.TinyTeX/bin/*/
  ./tlmgr option sys_bin ~/bin
  ./tlmgr path add
fi
