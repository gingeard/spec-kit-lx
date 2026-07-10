#!/usr/bin/env bash
# spec-inventory.sh — инвентарь слотов для ретроспецирования (LX).
#
# Детерминированный пред-шаг: парсит git-историю, модули и теги и предлагает
# СЛОТЫ (кандидаты в SPEC), пронумерованные по хронологии появления. LLM не зовёт.
# Выход — markdown в stdout; результат КУРИРУЕТСЯ вручную:
#   единица спеки = способность/решение, а не коммит и не файл;
#   мелкие/служебные коммиты — схлопывать/выкидывать.
# Затем по каждому слоту гоняется /speckit.lx.retrospec.
#
# Использование (в корне целевого репозитория):
#   spec-inventory.sh                  > SLOTS.md
#   spec-inventory.sh --since v1.0.0   # только начиная с тега/ревизии
#   SRC_DIRS="core internal ui" spec-inventory.sh   # ограничить модули
set -euo pipefail

command -v git >/dev/null || { echo "git не найден" >&2; exit 2; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "не git-репозиторий" >&2; exit 2; }

SINCE=""
if [[ "${1:-}" == "--since" && -n "${2:-}" ]]; then SINCE="$2..HEAD"; fi

# Стартовый номер: max существующий NNN в specs/ или SPECS/ + 1, иначе 1
start=1
for d in specs SPECS; do
  if [[ -d "$d" ]]; then
    max=$(find "$d" -maxdepth 1 -type d -name '[0-9][0-9][0-9]-*' 2>/dev/null \
          | sed -E 's#.*/([0-9]{3})-.*#\1#' | sort -n | tail -1 || true)
    [[ -n "${max:-}" ]] && start=$((10#$max + 1))
  fi
done

# Тип по conventional-commit-префиксу
maptype() {
  case "$1" in
    feat) echo F ;;              # Feature
    fix)  echo B ;;              # Bug
    refactor|perf) echo R ;;     # Refactor
    revert) echo B ;;
    *) echo "" ;;                # прочее — низкий сигнал, не нумеруем
  esac
}
slug() { echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g' | cut -c1-48; }

echo "# SLOTS — инвентарь для ретроспецирования"
echo
echo "> Сгенерировано \`spec-inventory.sh\`. **Курировать вручную:** единица = способность/решение,"
echo "> не коммит. Схлопни родственное, выкинь служебное, уточни имена. Затем по каждому слоту —"
echo "> \`/speckit.lx.retrospec\`. Номера — предложение (продолжают существующие спеки)."
echo

echo "## 1. Слоты из значимых коммитов (feat/fix/refactor/perf), по хронологии"
echo
echo "| NNN | Type | Имя (slug) | Область (scope) | Коммит |"
echo "|-----|------|------------|-----------------|--------|"
n=$start
while IFS=$'\x1f' read -r h subj; do
  [[ -z "${h:-}" ]] && continue
  # разобрать conventional-commit: type(scope)!: subject
  if [[ "$subj" =~ ^([a-z]+)(\(([^\)]*)\))?!?:\ *(.*)$ ]]; then
    ctype="${BASH_REMATCH[1]}"; scope="${BASH_REMATCH[3]:-}"; title="${BASH_REMATCH[4]}"
  else
    ctype=""; scope=""; title="$subj"
  fi
  T=$(maptype "$ctype")
  [[ -z "$T" ]] && continue   # только F/B/R
  printf "| %03d | %s | %s | %s | \`%s\` |\n" "$n" "$T" "$(slug "$title")" "${scope:-—}" "$h"
  n=$((n+1))
done < <(git log --reverse ${SINCE:+$SINCE} --no-merges --pretty=format:'%h%x1f%s' 2>/dev/null || true)
[[ "$n" -eq "$start" ]] && echo "| — | — | *конвенциональных коммитов не найдено — используй раздел 2 и git log вручную* | | |"
echo

echo "## 2. Структурные модули (топ-уровень исходников) — крупные слоты-подсистемы"
echo
echo "| Модуль | Файлов | Заметка |"
echo "|--------|--------|---------|"
roots="${SRC_DIRS:-}"
if [[ -z "$roots" ]]; then
  roots=$(find . -maxdepth 1 -mindepth 1 -type d \
    ! -name '.*' ! -name node_modules ! -name vendor ! -name dist ! -name build \
    ! -name target ! -name .specify ! -name .claude 2>/dev/null | sed 's#^\./##' | sort || true)
fi
for m in $roots; do
  [[ -d "$m" ]] || continue
  cnt=$(git ls-files "$m" 2>/dev/null | wc -l | tr -d ' ')
  [[ "${cnt:-0}" -eq 0 ]] && continue
  echo "| \`$m/\` | $cnt | несёт ли инвариант? граница слоя? → кандидат в SPEC |"
done
echo

echo "## 3. Релизные якоря (теги) — привязка Release/Shipped"
echo
if git tag >/dev/null 2>&1 && [[ -n "$(git tag)" ]]; then
  echo "| Тег | Дата |"
  echo "|-----|------|"
  git for-each-ref --sort=creatordate --format='| %(refname:short) | %(creatordate:short) |' refs/tags 2>/dev/null | tail -40
else
  echo "*тегов нет — Release проставлять вручную по CHANGELOG/release notes*"
fi
