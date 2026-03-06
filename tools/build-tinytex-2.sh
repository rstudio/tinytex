#!/bin/sh
# Optimized TinyTeX-2 build: reuse the daily release when the TeX Live year
# matches, otherwise fall back to a full scheme-full install.
#
# Required environment variables:
#   TEXLIVE_YEAR  - TeX Live year from the validate-ctan job
#   CTAN_REPO     - CTAN repository URL

set -e

TOOLS=$(dirname "$0")

RELEASE_YEAR=$(gh release view daily -R rstudio/tinytex-releases --json body -q '.body' \
  | grep -oE 'TeX Live [0-9]+' | grep -oE '[0-9]+' | head -1)

if [ -n "$RELEASE_YEAR" ] && [ "$RELEASE_YEAR" = "$TEXLIVE_YEAR" ]; then
  TINYTEX_INSTALLER=TinyTeX-2 sh "$TOOLS/install-bin-unix.sh"
  tlmgr option repository "$CTAN_REPO"

  # Capture installed packages before update so we can detect any removed from remote
  PKGS_BEFORE=$(tlmgr info --list --only-installed --data name | grep -v '^$' | sort)

  tlmgr update --self --all
  tlmgr install scheme-full

  # Remove packages that are no longer present in the remote repo
  PKGS_AFTER=$(tlmgr info --list --only-installed --data name | grep -v '^$' | sort)
  TMPD=$(mktemp -d)
  echo "$PKGS_BEFORE" > "$TMPD/before"
  echo "$PKGS_AFTER" > "$TMPD/after"
  REMOVED=$(comm -23 "$TMPD/before" "$TMPD/after" | grep -v '^$' || true)
  rm -rf "$TMPD"
  if [ -n "$REMOVED" ]; then
    tlmgr remove $REMOVED
  fi

  Rscript "$TOOLS/clean-tlpdb.R"
else
  Rscript "$TOOLS/build-scheme-full.R"
fi
