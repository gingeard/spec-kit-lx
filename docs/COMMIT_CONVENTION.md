# Коммит-конвенция LX

Скелет — [Conventional Commits](https://www.conventionalcommits.org/). Ссылка на спеку
кладётся в **конец subject'а** — чтобы «одним взглядом в `git log --oneline` понимать, над
какой спекой шла работа». Футер-trailer'ы не используем (не видны в oneline).

## Формат

```
<type>(<area>): <subject> [SPEC-NNN[ (Phase N)]]
```

- **type** — стандартный CC: `feat` `fix` `refactor` `docs` `chore` `build` `ci` `perf` `revert` `style` `test`.
- **area** (scope) — **область кода**, НЕ номер спеки: `oidc`, `sops`, `banka`, `spec`, `auto-update`, …
  Одна доминирующая область на коммит.
- **SPEC-NNN** — ссылка на спеку в конце subject'а, для коммитов спековой работы.
  Опускается для инфраструктурных/тулинговых коммитов, не привязанных к спеке.
- **(Phase N)** — дописывается, когда коммит относится к фазе спеки; для диапазона — `(Phases 1-6)`;
  для draft-спеки без фаз — только `SPEC-NNN`.

## Примеры

```
feat(oidc): OIDC identity auth for banka k3s (Dex + web generator) SPEC-001 (Phases 1-6)
fix(oidc): persist Dex signing keys + structured apiserver auth SPEC-001 (Phase 7)
refactor(sops): single age key for all secrets (DR hardening) SPEC-001 (Phase 8)
docs(spec): draft external IdP connectors (Google + GitHub) SPEC-002
fix(auto-update): sync macmini checkout before flake bump            ← без спеки
```

## Почему в subject, а не в footer

Каноничное место CC для ссылок — футер (`Refs: #N` / кастомный `Spec: 001`, git-trailer). Но
футер **не виден** в `git log --oneline`. LX-цель — глаз-скан по спеке, поэтому ссылка идёт в конец
subject'а как ticket-key `SPEC-NNN`. Греп: `git log --oneline | grep SPEC-001`.

Префикс `SPEC-` выбран намеренно вместо `#NNN`: `#001` на GitHub автолинкуется на **issue №1**
(коллизия с issue-нумерацией), а `SPEC-NNN` — нет.

## Enforcement (опционально)

`commitlint` умеет форсить ссылку — правило `references-empty` + `parserOpts.issuePrefixes: ['SPEC-']`
находит `SPEC-NNN` в header и требует его для спековых типов. Либо голый `commit-msg` regex-hook:

```
^(feat|fix|refactor|docs|chore|build|ci|perf|revert|style|test)(\([a-z0-9-]+\))?: .+( SPEC-[0-9]{3}( \(Phases? [0-9-]+\))?)?$
```

## Отношение к трассировке

Коммит-ссылка — **вспомогательна**. Первичная трасса LX — маркеры `// SPEC NNN` в коде и раздел
«Связи» в `spec.md` (см. `/speckit.lx.trace`). Провенанс «почему» — `R<n>` / `§Const` / «инцидент: …»,
НЕ git-хеш (точный коммит даёт `git blame`).
