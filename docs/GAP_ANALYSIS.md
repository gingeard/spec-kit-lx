# Gap Analysis: методология Leadaxe → GitHub Spec Kit

Справочник по каждому элементу методологии Leadaxe (`Leadaxe/singbox-launcher`) и тому,
как он воспроизведён средствами Spec Kit `0.12.7`/`0.12.8.dev0`. Каждое решение обосновано.

Легенда: **[Н]** — факт из репозитория, **[Г]** — гипотеза.
Механизмы Spec Kit: **preset** (override существующего), **extension** (новое: команды/hooks),
**config** (init-options / отсутствие расширения), **policy** (текст governance, не машинно).

---

## Сводная таблица

| # | Элемент Leadaxe | Источник | Аналог в Spec Kit | Воспроизв. | Механизм | Крит. |
|---|---|---|---|---|---|---|
| 1 | Поток SPEC→PLAN→TASKS→REPORT | README §Workflow [Н] | spec→plan→tasks→implement | Полн. | core | — |
| 2 | Имена `SPEC.md` (CAPS) | папки задач [Н] | `spec.md` (lower, хардкод скриптов) | Частич. | принять lower | низк. |
| 3 | `implementation_report.md` | канон 4 файлов [Н] | нет | Полн. | ext `lx.report`/`close` | выс. |
| 4 | Статус/тип в имени `NNN-T-S` | README, папки [Н] | `specs/NNN-name` (хардкод) | Перенос | preset (front-matter) | сред. |
| 5 | Constitution + инварианты | CONSTITUTION.md [Н] | `constitution-template` + `/constitution` | Полн. | preset | выс. |
| 6 | Философия + DoD | IMPLEMENTATION_PROMPT.md [Н] | нет единого | Полн. | preset: agent-file + wrap implement + checklist | выс. |
| 7 | Git — только по указанию | IMPL_PROMPT §Git [Н] | git — opt-in extension | Полн. | config (не ставить git-ext) | выс. |
| 8 | Ритуал закрытия | README §6, TASKS «Закрытие» [Н] | нет | Полн. | ext `close` + `after_implement` hook | выс. |
| 9 | Release notes + CI-гейт | AGENTS §4, RELEASE_PROCESS [Н] | нет | Полн. | ext `close` + `check-release-notes.sh` + CI job | сред. |
| 10 | Трассируемость code↔spec | `// SPEC NNN` в коде [Н] | нет | Полн. | ext `lx.trace` | сред. |
| 11 | Трассируемость spec↔spec | `Depends on`, «Связи» [Н] | handoffs (слабее) | Полн. | preset (front-matter) + ext trace | сред. |
| 12 | «Одна фича — один SPEC» | 055 консолидация [Н] | нет | Полн. | policy (Constitution governance) + `Consolidates` | сред. |
| 13 | «Закрыта без реализации» | 016 [Н] | нет | Полн. | статус `Closed-no-impl` (preset) | сред. |
| 14 | Качество спецификаций | секции SPEC [Н] | `/clarify`, `/analyze` (сильнее) | Улучш. | core | — |
| 15 | Именование `NNN` сквозное | папки [Н] | `feature_numbering: sequential` | Полн. | config (init-options) | низк. |
| 16 | Билингвальность по ролям | CONSTITUTION §8 [Н] | нет | Полн. | preset (template + agent-file) | сред. |
| 17 | Накопление знаний (ARCHITECTURE, ADR, «as of SPEC N») | docs/ARCHITECTURE.md [Н] | нет (per-feature модель) | Частич. | policy (Constitution-ссылка) + hook-напоминание | сред. |
| 18 | «Зелёная ветка» на каждой фазе | TASKS, отчёты [Н] | нет явного | Полн. | preset (plan/tasks/checklist) | сред. |

---

## Детализация ключевых решений

### #4 Статус/тип в имени папки → front-matter
**Разрыв [Н]:** Spec Kit хардкодит стабильное `specs/NNN-name` (`create-new-feature.sh: SPEC_FILE="$FEATURE_DIR/spec.md"`); на имя завязаны `.specify/feature.json`, резолверы, ссылки. Переименование ради статуса рассинхронизировало бы состояние.
**Решение:** статус (`New→Open→Merged→Shipped→Complete`, `Closed-no-impl`) и тип (`F/B/R/Q`) — во front-matter `spec.md`, имя каталога неизменно.
**Почему не форк `create-new-feature.sh`:** форк создаёт вечный merge-долг против активного апстрима; выгода (статус в имени) не оправдывает.
**Почему это улучшение, а не потеря [Н]:** Leadaxe уже страдал от хрупкости имени — кириллическая «С» (U+0421) в `029`/`031` ломает фильтры `-C-`; README отставал от практики (`R`, `M`, `S` не документированы). Поздние SPEC (`055`, `063`, `072`) **уже дублируют `**Status:**` в тело** — методология сама двигалась к front-matter. `/speckit.analyze` делает статус машинно-проверяемым.

### #3, #8, #9 Отчёт, закрытие, релиз → extension, не preset
**Почему extension:** preset умеет только override существующих артефактов/команд. Отчёт, ритуал закрытия, гейт релиза, проверка трассировки — **новые** артефакты, команды (`speckit.lx.*`) и фазовые hooks. Это по определению область extension.
**Почему `after_implement` hook:** Spec Kit завершает цикл на `implement`; hook добавляет пост-фазу, не переставляя жёсткую core-цепочку.

### #6, #7 Философия/DoD/Git → preset + отсутствие git-ext
**Два канала:** статические правила (философия, scope, контракт выхода, язык) → `agent-file-template` (материализуется в `CLAUDE.md`/`AGENTS.md`, применяется на всех фазах). Фазовое (DoD, минимальный дифф) → wrap команды `implement` + `checklist-template`.
**Git [Н]:** ветвление в Spec Kit не захардкожено — оно в opt-in extension `git`. Запрет Leadaxe реализуется **отсутствием** установки этого расширения — самый точный механизм.

### #17 Накопление знаний — единственная частичная зона
**Разрыв [Н]:** Spec Kit по природе per-feature; living-doc `docs/ARCHITECTURE.md` с ADR и привязкой «current as of SPEC 070» не имеет родного аналога.
**Решение:** ссылка в Constitution + напоминание в фазе «Закрытие»/hook обновить ARCHITECTURE при смене потоков. Машинного механизма living-doc нет — принятый компромисс.

---

## Что осталось хардкодом ядра (принято как есть)

- Имена артефактов `spec.md/plan.md/tasks.md`, каталог `specs/` — переопределяется только контент, не имена (косметика).
- Порядок фаз spec→plan→tasks→implement — расширяется hooks, но не переставляется (совпадает с Leadaxe).
- `schema_version: "1.0"`, `.specify/` как корень — инфраструктура.

## Проверенные ограничения манифестов (при разработке preset/extension)

- `extension.effect` ∈ `{read-only, read-write}` — не свободный текст.
- Каждый hook обязан иметь поле `command` (чистое `prompt`-напоминание невалидно).
- В Claude-интеграции 0.12.x команды регистрируются как **skills** (`.claude/skills/speckit-*`), а не `.claude/commands/`.
