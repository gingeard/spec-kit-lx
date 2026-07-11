# spec-kit-lx

**LX** — методология spec-driven-разработки для проектов, которые пишут AI-агенты,
упакованная как preset + extension для [GitHub Spec Kit](https://github.com/github/spec-kit).
Спецификации здесь не выбрасываются после реализации, а живут как память проекта:
несут инварианты, привязанные к коду и тестам, и держат агента в явных границах.

---

## Зачем

Когда код пишет агент, код становится дёшев — дефицитом становится **понимание**:
намерение, границы, причины решений. Агент неутомим и лишён вкуса: он с равным
энтузиазмом реализует фичу и «улучшит» то, что трогать нельзя. LX переносит центр
тяжести с кода на то, из чего код можно собрать заново:

> Код — скомпилированный артефакт намерения. Расхождение кода со спецификацией —
> баг в коде, а не в спецификации.

Полная философия (10 принципов) — в [docs/PHILOSOPHY.md](docs/PHILOSOPHY.md).

## Что вы получаете

| Возможность | Как работает |
|---|---|
| **Спека — живой документ** | статус в front-matter (`New → … → Shipped`), спека остаётся навсегда — даже «закрытая без реализации» |
| **Инварианты как контракт** | «что НЕ меняется» записывается в EARS-форме (`WHEN … system SHALL …`) с привязкой к коду и тесту; живёт секцией «Инварианты» в SPEC (контракт+провенанс), enforcement — блоками в PLAN |
| **Трассировка в обе стороны** | маркеры `// SPEC NNN` в коде ↔ записи в спеке; `/speckit.lx.trace` проверяет их машинно, `--stubs` генерирует тест-заглушки из дыр покрытия |
| **Ритуал закрытия** | `/speckit.lx.close`: отчёт → release notes → статус → трассировка → карта корпуса |
| **Ретроспецирование** | `/speckit.lx.retrospec` восстанавливает спеки из существующего кода (инвентарь по git-истории, «кислотный тест» против пересказа кода) |
| **Аудит кодовой базы** | `/speckit.lx.audit`: findings по severity + обязательное «опровергнуто верификацией» |
| **Карта корпуса** | `spec-map.sh` генерирует `specs/README.md`: таблица всех спек + mermaid-граф зависимостей |
| **Агент в границах** | минимальный дифф, «Вне scope», git — только по явному указанию (git-расширение просто не ставится) |

## Установка

В корне **вашего** проекта (команды ставят туда, где запущены):

```bash
specify init <project> --ai claude        # если Spec Kit ещё не инициализирован

# вариант А — из клона-соседа:
git clone https://github.com/gingeard/spec-kit-lx ../spec-kit-lx
specify preset add    --dev ../spec-kit-lx/lx-preset --priority 10
specify extension add --dev ../spec-kit-lx/lx-flow-ext

# вариант Б — из релиза, без клона (на вопрос Untrusted Source ответить y):
specify preset add       --from https://github.com/gingeard/spec-kit-lx/releases/latest/download/lx-preset.zip --priority 10
specify extension add lx --from https://github.com/gingeard/spec-kit-lx/releases/latest/download/lx-flow-ext.zip
```

После установки: включите сквозную нумерацию (`.specify/init-options.json` →
`"feature_numbering": "sequential"`) и **не** ставьте расширение `git` — его
отсутствие и есть правило «git только по указанию».

## Рабочий цикл

```mermaid
flowchart LR
  C[constitution] --> S[specify] --> CL[clarify] --> P[plan] --> T[tasks] --> A[analyze] --> I[implement] --> X[lx.close]
```

| Шаг | Команда | Результат |
|---|---|---|
| Принципы | `/speckit.constitution` | инварианты проекта, запреты, губернанс жизненного цикла |
| Спецификация | `/speckit.specify` | проблема, инварианты, non-goals, критерии в EARS |
| Уточнение | `/speckit.clarify` | снятые неоднозначности вместо «Assumptions» |
| План | `/speckit.plan` | файлы, несущие решения (Decision-блок), Constitution Check |
| Задачи | `/speckit.tasks` | фазы + обязательная фаза «Закрытие» |
| Проверка | `/speckit.analyze` | согласованность spec ↔ plan ↔ tasks |
| Реализация | `/speckit.implement` | минимальный дифф, DoD, контракт выхода |
| Закрытие | `/speckit.lx.close` | отчёт, release notes, статус, трассировка, карта |

**Существующий проект** документируется в обратную сторону:
`spec-inventory.sh` строит инвентарь по git-истории → `/speckit.lx.retrospec`
восстанавливает спеки → `/speckit.analyze` + `/speckit.lx.trace` сводят корпус.
Подробная процедура — в [docs/RETROSPEC.md](docs/RETROSPEC.md).

**Гейт релиза** (CI падает, если у версии нет release notes — как у Leadaxe):

```bash
bash .specify/extensions/lx/scripts/bash/check-release-notes.sh v1.2.0
# готовый job для GitHub Actions: lx-flow-ext/ci/release-notes-gate.yml
```

## Состав

| Каталог | Механизм | Содержимое |
|---|---|---|
| `lx-preset/` | preset (переопределяет ядро) | 7 шаблонов (spec, plan, tasks, constitution, checklist, agent-file + audit-spec) и обёртки команд `specify`/`implement` |
| `lx-flow-ext/` | extension (добавляет новое) | 5 команд (`report`, `close`, `trace`, `retrospec`, `audit`), hook после реализации, скрипты (инвентарь, карта корпуса, гейт релизов), workflow параллельного ретро |

Ключевые проектные решения — коротко: статус задачи живёт во front-matter, а не в
имени папки (имя хардкодит ядро, а «статус в имени» уже ломался у первоисточника);
команды не заменяются, а оборачиваются (`wrap`) — обновления Spec Kit продолжают
приезжать; всё новое — extension, а не форк. Обоснование каждого решения — в
[docs/GAP_ANALYSIS.md](docs/GAP_ANALYSIS.md).

## Документация

| Документ | О чём |
|---|---|
| [docs/RESEARCH.md](docs/RESEARCH.md) | как проектировался LX: исследование двух корпусов Leadaxe, Spec Kit и Kiro, эксперименты и отвергнутые решения |
| [docs/PHILOSOPHY.md](docs/PHILOSOPHY.md) | философия: 10 принципов и кислотный тест |
| [docs/GAP_ANALYSIS.md](docs/GAP_ANALYSIS.md) | методология → механизмы Spec Kit, решение за решением |
| [docs/RETROSPEC.md](docs/RETROSPEC.md) | процедура ретроспецирования существующего проекта |
| [CONTRIBUTING.md](CONTRIBUTING.md) | dev-петля, нюансы манифестов, сборка релиза |
| [CHANGELOG.md](CHANGELOG.md) | история версий |

## Credits & License

MIT · методология — [Leadaxe](https://github.com/Leadaxe) (ключевые идеи) · платформа — [GitHub Spec Kit](https://github.com/github/spec-kit)
