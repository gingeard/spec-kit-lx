#!/usr/bin/env bash
# check-release-notes.sh — гейт release notes в стиле Leadaxe CI.
#
# Зеркалит проверку singbox-launcher (docs/RELEASE_PROCESS.md §0): тело релиза
# читается из docs/release_notes/<slug>.md, и CI ПАДАЕТ, если файла нет.
# Здесь та же проверка, вынесенная в переиспользуемый скрипт: годится и для
# /speckit.lx.close, и для GitHub Actions.
#
# Использование:
#   check-release-notes.sh <version>       # напр. v1.2.0 или 1.2.0
#   check-release-notes.sh                 # возьмёт версию из `git describe --tags`
#
# slug = VERSION без ведущего 'v', точки заменены на '-'  (v1.2.0 → 1-2-0).
# Ищет файл в $RELEASE_NOTES_DIR (default: docs/release_notes).
# Пустой файл считается отсутствующим (by design — чтобы не выпускать без тела).
set -euo pipefail

RELEASE_NOTES_DIR="${RELEASE_NOTES_DIR:-docs/release_notes}"

version="${1:-}"
if [[ -z "$version" ]]; then
  version="$(git describe --tags --exclude='*-prerelease' 2>/dev/null || true)"
fi
if [[ -z "$version" ]]; then
  echo "ERROR: версия не задана и не выводится из git tag" >&2
  exit 2
fi

slug="${version#v}"      # убрать ведущий v
slug="${slug//./-}"      # точки → дефисы
file="${RELEASE_NOTES_DIR}/${slug}.md"

if [[ ! -f "$file" ]]; then
  echo "RELEASE NOTES GATE: FAIL — нет файла ${file}" >&2
  echo "  Перед релизом ${version} перенеси ${RELEASE_NOTES_DIR}/upcoming.md → ${file}" >&2
  echo "  и создай новый пустой upcoming.md (см. docs/RELEASE_PROCESS.md)." >&2
  exit 1
fi
if [[ ! -s "$file" ]]; then
  echo "RELEASE NOTES GATE: FAIL — ${file} пустой" >&2
  exit 1
fi

echo "RELEASE NOTES GATE: OK — ${file} ($(wc -l < "$file") строк)"
