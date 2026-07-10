#!/usr/bin/env bash
# pack.sh — собрать release-ZIP'ы preset и extension для `specify … add --from <URL>`.
# Каждый ZIP содержит манифест (preset.yml / extension.yml) в КОРНЕ архива.
#
#   bash scripts/pack.sh            # → dist/lx-preset.zip, dist/lx-flow-ext.zip
# Затем приложи ZIP'ы к GitHub Release; пользователи ставят:
#   specify preset add    --from https://github.com/gingeard/spec-kit-lx/releases/download/vX/lx-preset.zip
#   specify extension add --from https://github.com/gingeard/spec-kit-lx/releases/download/vX/lx-flow-ext.zip
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p dist
rm -f dist/lx-preset.zip dist/lx-flow-ext.zip

( cd lx-preset && zip -qr ../dist/lx-preset.zip . -x '*.DS_Store' )
( cd lx-flow-ext && zip -qr ../dist/lx-flow-ext.zip . -x '*.DS_Store' )

echo "built:"
ls -lh dist/*.zip | awk '{print "  "$9" ("$5")"}'
echo "manifest at archive root?"
# без `grep -q` в пайпе: его ранний выход шлёт unzip SIGPIPE → pipefail валит скрипт
check_root() { # $1=zip $2=manifest
  local listing
  listing="$(unzip -l "$1")"
  if printf '%s\n' "$listing" | grep -E " $2\$" >/dev/null; then
    echo "  ✓ $(basename "$1"): $2"
  else
    echo "  ✗ $(basename "$1"): $2 НЕ в корне архива" >&2; return 1
  fi
}
check_root dist/lx-preset.zip   preset.yml
check_root dist/lx-flow-ext.zip extension.yml
