#!/bin/sh
# Optimized TinyTeX-2 build: reuse the daily release when the TeX Live year
# matches, otherwise fall back to a full scheme-full install.
#
# Required environment variables:
#   TEXLIVE_YEAR    - TeX Live year from the validate-ctan job
#   CTAN_REPO       - CTAN repository URL
#   FORCE_REBUILD   - set to 'true' to skip the fast path and do a full rebuild

set -e

TOOLS=$(dirname "$0")

RELEASE_YEAR=$(gh release view daily -R rstudio/tinytex-releases --json body -q '.body' \
  | grep -oE 'TeX Live [0-9]+' | grep -oE '[0-9]+' | head -1)

if [ "${FORCE_REBUILD}" != "true" ] && [ -n "$RELEASE_YEAR" ] && [ "$RELEASE_YEAR" = "$TEXLIVE_YEAR" ]; then
  echo ">> Years match (TeX Live $TEXLIVE_YEAR): reusing daily TinyTeX-2 bundle and applying incremental updates"
  TINYTEX_INSTALLER=TinyTeX-2 sh "$TOOLS/install-bin-unix.sh"
  Rscript -e "tinytex::tlmgr(c('option', 'repository', Sys.getenv('CTAN_REPO')))"

  # Capture installed packages before update so we can detect any removed from remote
  PKGS_BEFORE=$(Rscript -e "cat(tinytex::tl_pkgs(), sep = '\n')" | grep -v '^$' | sort)

  Rscript -e "tinytex::tlmgr_update()"

  # Remove packages that are no longer present in the remote repo
  PKGS_AFTER=$(Rscript -e "cat(tinytex::tl_pkgs(), sep = '\n')" | grep -v '^$' | sort)
  TMPD=$(mktemp -d)
  echo "$PKGS_BEFORE" > "$TMPD/before"
  echo "$PKGS_AFTER" > "$TMPD/after"
  REMOVED=$(comm -23 "$TMPD/before" "$TMPD/after" | grep -v '^$' || true)
  rm -rf "$TMPD"
  if [ -n "$REMOVED" ]; then
    echo ">> Removing packages no longer in remote repo: $REMOVED"
    REMOVED_PKGS="$REMOVED" Rscript -e "tinytex::tlmgr(c('remove', scan(text=Sys.getenv('REMOVED_PKGS'), what='', quiet=TRUE)))"
  fi

  Rscript "$TOOLS/clean-tlpdb.R"
else
  if [ "${FORCE_REBUILD}" = "true" ]; then
    echo ">> Force rebuild requested: installing TinyTeX-2 from scratch"
  else
    echo ">> Years do not match (local: $TEXLIVE_YEAR, release: ${RELEASE_YEAR:-none}): installing TinyTeX-2 from scratch"
  fi
  Rscript "$TOOLS/build-scheme-full.R"
fi
