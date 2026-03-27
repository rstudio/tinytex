#!/bin/sh

set -e

PREVWD=${PWD}
cd ${TMPDIR:-/tmp}

if [ $(uname) = 'Darwin' ]; then
  TEXDIR=${TINYTEX_DIR:-~/Library/TinyTeX}
  alias download='curl -sL'
else
  TEXDIR=${TINYTEX_DIR:-~/.TinyTeX}
  alias download='wget -qO-'
fi

rm -f install-tl-unx.tar.gz tinytex.profile
download https://tinytex.yihui.org/install-base.sh | sh -s - "$@"

rm -rf $TEXDIR
mkdir -p $TEXDIR
mv texlive/* $TEXDIR
# a token to differentiate TinyTeX with other TeX Live distros
touch $TEXDIR/.tinytex
rm -r texlive
cd $PREVWD
# finished base

rm -r $OLDPWD/install-tl-*

$TEXDIR/bin/*/tlmgr install $(download https://tinytex.yihui.org/pkgs-custom.txt | tr '\n' ' ')

if [ $(uname) = 'Darwin' ]; then
  # write TinyTeX's bin path to /etc/paths.d instead of creating symlinks in /usr/local/bin;
  # skip only when --admin AND --no-path are both given (i.e. ! (admin && no-path))
  if [ "$1" != '--admin' ] || [ "$2" != '--no-path' ]; then
    echo "Admin privilege (password) is required to set up the PATH for TinyTeX:"
    printf '%s\n' "$(ls -d $TEXDIR/bin/*/)" | sudo tee /etc/paths.d/TinyTeX > /dev/null || true
  fi
else
  if [ "$1" = '--admin' ]; then
    if [ "$2" != '--no-path' ]; then
      sudo $TEXDIR/bin/*/tlmgr path add
    fi
  else
    $TEXDIR/bin/*/tlmgr path add || true
  fi
fi
