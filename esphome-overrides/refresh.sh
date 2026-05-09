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
KEEP_LOCAL=("preferences.h")

if [ ! -d "${PIP_ESP32}" ]; then
  echo "ERROR: pip esp32 not found at ${PIP_ESP32}" >&2
  echo "Have you run pip install esphome in the .venv?" >&2
  exit 1
fi

mkdir -p "${OVERRIDE}"

# Remove stale symlinks that no longer exist upstream (cleanup)
for existing in "${OVERRIDE}"/* "${OVERRIDE}"/.[!.]*; do
  [ -e "${existing}" ] || continue
  basename=$(basename "${existing}")
  if [[ " ${KEEP_LOCAL[*]} " =~ " ${basename} " ]]; then
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

# Sanity: warn if upstream preferences.h drifted from cached snapshot
SNAPSHOT="${HERE}/esphome/components/esp32/.preferences.h.upstream"
if [ -f "${SNAPSHOT}" ]; then
  if ! diff -q "${PIP_ESP32}/preferences.h" "${SNAPSHOT}" > /dev/null 2>&1; then
    echo ""
    echo "  ⚠  upstream preferences.h CHANGED since last refresh"
    echo "     diff:"
    diff -u "${SNAPSHOT}" "${PIP_ESP32}/preferences.h" | sed 's/^/       /'
    echo "     → review and manually update ${OVERRIDE}/preferences.h if needed"
  fi
fi
cp "${PIP_ESP32}/preferences.h" "${SNAPSHOT}"

# Summary
n_real=${#KEEP_LOCAL[@]}
echo ""
echo "✓ ${n_links} symlinks + ${n_real} local file(s) (${KEEP_LOCAL[*]})"
echo "  override dir: ${OVERRIDE}"
