#!/bin/sh

set -e

perl -mFile::Find /dev/null ||
  (echo "perl is required but not found (https://github.com/rstudio/tinytex/issues/419)" && exit 1)

cd ${TMPDIR:-/tmp}

[ -z $(command -v tlmgr) ] || [ -n "$FORCE_REBUILD" ] || TL_INSTALLED_PKGS=$(tlmgr info --list --only-installed --data name | tr '\n' ' ')
[ -z "$TL_INSTALLED_PKGS" ] ||
  echo "If you want to reinstall currently installed packages, use this command after the TinyTeX installation is done:

tlmgr install $TL_INSTALLED_PKGS

"

OSNAME=$(uname)
[ -z $OSNAME ] && echo "This operating system is not supported." && exit 1

TINYTEX_INSTALLER=${TINYTEX_INSTALLER:-"TinyTeX-1"}

# new naming scheme: TinyTeX-{N}-{os}[-{arch}][-v{VERSION}].tar.xz
# introduced after v2026.03.02; daily installs always use the new naming
USE_NEW_NAMES=true
if [ -n "$TINYTEX_VERSION" ] && [ ! "$TINYTEX_VERSION" \> "2026.03.02" ]; then
  USE_NEW_NAMES=false
fi

ARCH=$(uname -m)

# detect musl libc
is_musl() {
  if ls /lib/libc.musl-*.so.1 2>/dev/null | grep -q .; then
    return 0
  elif ldd --version 2>&1 | grep -qi musl; then
    return 0
  else
    return 1
  fi
}

if [ $OSNAME = 'Darwin' ]; then
  TEXDIR=${TINYTEX_DIR:-~/Library}/TinyTeX
else
  TEXDIR=${TINYTEX_DIR:-~}/.TinyTeX
  if [ $OSNAME != 'Linux' ]; then
    TINYTEX_INSTALLER="installer-unix"
  elif is_musl; then
    # musl linux: only x86_64 is supported with prebuilt binaries
    [ "$ARCH" != 'x86_64' ] && TINYTEX_INSTALLER="installer-unix"
  elif [ "$USE_NEW_NAMES" = true ]; then
    # new naming supports x86_64 and aarch64 (arm64) on linux-gnu
    [ "$ARCH" != 'x86_64' -a "$ARCH" != 'aarch64' ] && TINYTEX_INSTALLER="installer-unix"
  else
    # old naming only supports x86_64
    [ "$ARCH" != 'x86_64' ] && TINYTEX_INSTALLER="installer-unix"
  fi
fi

rm -rf $TEXDIR

# determine the OS/arch suffix and file extension based on the naming scheme
if [ "$USE_NEW_NAMES" = true ] && [ "${TINYTEX_INSTALLER#"TinyTeX"}" != "$TINYTEX_INSTALLER" ]; then
  # new naming: TinyTeX-{N}-{os}[-{arch}].tar.xz
  if [ $OSNAME = 'Darwin' ]; then
    OS_ARCH="-darwin"
  elif is_musl; then
    OS_ARCH="-linuxmusl-x86_64"
  elif [ "$ARCH" = 'aarch64' ]; then
    OS_ARCH="-linux-arm64"
  else
    OS_ARCH="-linux-x86_64"
  fi
  EXT="tar.xz"
else
  OS_ARCH=""
  if [ $OSNAME = 'Darwin' ]; then
    EXT="tgz"
  else
    EXT="tar.gz"
  fi
fi

if [ -z "$TINYTEX_VERSION" ]; then
  TINYTEX_URL="https://github.com/rstudio/tinytex-releases/releases/download/daily/${TINYTEX_INSTALLER}${OS_ARCH}.${EXT}"
else
  # the installer was accidentally named "install-unix" instead of "installer-unix" before v2025.01
  if [ "$TINYTEX_INSTALLER" = "installer-unix" ] && [ "$TINYTEX_VERSION" \< "2025.02" ]; then
    TINYTEX_INSTALLER="install-unix"
  fi
  TINYTEX_URL="https://github.com/rstudio/tinytex-releases/releases/download/v$TINYTEX_VERSION/${TINYTEX_INSTALLER}${OS_ARCH}-v$TINYTEX_VERSION.${EXT}"
fi

INSTALLER_FILE="${TINYTEX_INSTALLER}${OS_ARCH}.${EXT}"

if [ "${TINYTEX_INSTALLER#"TinyTeX"}" != "$TINYTEX_INSTALLER" ]; then
  # prebuilt TinyTeX bundle: download with platform-appropriate tool
  if [ $OSNAME = 'Darwin' ]; then
    curl -L -f --retry 10 --retry-delay 30 ${TINYTEX_URL} -o "${INSTALLER_FILE}"
  else
    wget --retry-connrefused --progress=dot:giga -O "${INSTALLER_FILE}" ${TINYTEX_URL}
  fi
  tar xf "${INSTALLER_FILE}" -C $(dirname $TEXDIR)
  if [ -n "$1" ]; then mv "${INSTALLER_FILE}" "$1/"; else rm "${INSTALLER_FILE}"; fi
else
  echo "We do not have a prebuilt TinyTeX package for this operating system ($(uname -s) $(uname -m))."
  echo "I will try to install from source for you instead."
  wget --retry-connrefused -O "${INSTALLER_FILE}" ${TINYTEX_URL}
  tar xf "${INSTALLER_FILE}"
  ./install.sh
  mkdir -p $TEXDIR
  mv texlive/* $TEXDIR
  rm -r texlive "${INSTALLER_FILE}" install.sh
fi

cd $TEXDIR/bin/*/

BINDIR="$HOME/.local/bin"
if [ ! -d  $BINDIR ]; then
  BINDIR="$HOME/bin"
fi

[ $OSNAME != "Darwin" ] && ./tlmgr option sys_bin $BINDIR
./tlmgr postaction install script xetex  # GH issue #313
([ -z $CI ] || [ $(echo $CI | tr "[:upper:]" "[:lower:]") != "true" ]) && ./tlmgr option repository ctan

if [ $OSNAME = 'Darwin' ]; then
  # create the dir if it doesn't exist
  if [ ! -d /usr/local/bin ]; then
    echo "Admin privilege (password) is required to create the directory /usr/local/bin:"
    sudo mkdir -p /usr/local/bin
  fi
  # change owner of the dir
  if [ ! -w /usr/local/bin ]; then
    echo "Admin privilege (password) is required to make /usr/local/bin writable:"
    sudo chown -R `whoami`:admin /usr/local/bin
  fi
fi

./tlmgr path add
