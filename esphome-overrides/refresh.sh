#!/usr/bin/env bash
#
# refresh.sh — populate ./esphome/components/esp32/ with symlinks to the
# pip-installed ESPHome's esp32 component, EXCEPT preferences.h which is
# the locally-maintained patched version (un-final + virtual).
#
# Run after every `pip install -U esphome` in the .venv, so symlinks
# always point at the current upstream version of all sibling files.
#
# Why: we want to override only ONE file (preferences.h) for our local
# build. external_components requires a complete component directory,
# so we make every other file a symlink to upstream — they "follow"
# pip upgrades automatically. Only preferences.h is real and version-
# controlled here; we manually rebase it when upstream changes.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PIP_ESP32="${HERE}/../.venv/lib/python3.14/site-packages/esphome/components/esp32"
OVERRIDE="${HERE}/esphome/components/esp32"
KEEP_LOCAL=("preferences.h" "preference_backend.h")

if [ ! -d "${PIP_ESP32}" ]; then
  echo "ERROR: pip esp32 not found at ${PIP_ESP32}" >&2
  echo "Have you run pip install esphome in the .venv?" >&2
  exit 1
fi

mkdir -p "${OVERRIDE}"

# Cleanup pass:
#  - remove stale symlinks pointing to files that no longer exist upstream
#  - remove symlinks for files that are now in KEEP_LOCAL (so the user
#    can drop a real patched file in their place; only symlinks are
#    removed, never real files)
for existing in "${OVERRIDE}"/* "${OVERRIDE}"/.[!.]*; do
  [ -e "${existing}" ] || [ -L "${existing}" ] || continue
  basename=$(basename "${existing}")
  if [[ " ${KEEP_LOCAL[*]} " =~ " ${basename} " ]]; then
    if [ -L "${existing}" ]; then
      echo "  - removing symlink for newly KEEP_LOCAL file: ${basename}"
      rm "${existing}"
    fi
    continue
  fi
  if [ -L "${existing}" ] && [ ! -e "${PIP_ESP32}/${basename}" ]; then
    echo "  - removing stale symlink: ${basename}"
    rm "${existing}"
  fi
done

# Symlink everything from pip esp32 except KEEP_LOCAL
n_links=0
for src in "${PIP_ESP32}"/* "${PIP_ESP32}"/.[!.]*; do
  [ -e "${src}" ] || continue
  basename=$(basename "${src}")
  if [[ " ${KEEP_LOCAL[*]} " =~ " ${basename} " ]]; then
    continue
  fi
  ln -sfn "${src}" "${OVERRIDE}/${basename}"
  n_links=$((n_links + 1))
done

# Sanity: warn if any upstream KEEP_LOCAL file drifted from cached snapshot
for kept in "${KEEP_LOCAL[@]}"; do
  SNAPSHOT="${OVERRIDE}/.${kept}.upstream"
  if [ -f "${SNAPSHOT}" ]; then
    if ! diff -q "${PIP_ESP32}/${kept}" "${SNAPSHOT}" > /dev/null 2>&1; then
      echo ""
      echo "  ⚠  upstream ${kept} CHANGED since last refresh"
      echo "     diff:"
      diff -u "${SNAPSHOT}" "${PIP_ESP32}/${kept}" | sed 's/^/       /'
      echo "     → review and manually update ${OVERRIDE}/${kept} if needed"
    fi
  fi
  cp "${PIP_ESP32}/${kept}" "${SNAPSHOT}"
done

# Summary
n_real=${#KEEP_LOCAL[@]}
echo ""
echo "✓ ${n_links} symlinks + ${n_real} local file(s) (${KEEP_LOCAL[*]})"
echo "  override dir: ${OVERRIDE}"
