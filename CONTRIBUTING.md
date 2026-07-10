# Contributing

Thanks for improving the LX preset/extension for Spec Kit.

## Layout
- `lx-preset/` — preset (templates + command wraps + `preset.yml`).
- `lx-flow-ext/` — extension (commands + hooks + scripts + workflow + `extension.yml`).
- `docs/` — design rationale (philosophy, gap analysis, retrospec guide).

## Dev loop
Presets/extensions are copied into `.specify/…` at install time, so changes are
picked up only on reinstall:

```bash
# in a Spec Kit project (any test dir after `specify init`)
specify preset remove lx    ; specify preset add --dev ../spec-kit-lx/lx-preset --priority 10
specify extension remove lx ; specify extension add --dev ../spec-kit-lx/lx-flow-ext
```

Verify:
```bash
specify preset resolve spec-template     # → presets/lx/…  (preset layer wins over core)
specify extension list                   # → LX Flow · Enabled (5 commands, 1 hook)
ls .claude/skills | grep speckit-lx      # → 5 skills registered
```

Expected on a clean install: preset reports 10 artifacts (8 templates + 2 command
wraps); the wrapped `implement` skill contains BOTH the core prompt and the LX block
(that's `strategy: wrap` working). `check-release-notes.sh` is covered by a 3-branch
smoke: missing file → exit 1, empty → 1, present → 0.

## Manifest gotchas (spec-kit 0.12.x)
- `extension.effect` must be `read-only` or `read-write` (not free text).
- Every hook needs a `command` field.
- Preset/extension `add --dev` on an existing id errors — `remove` first.
- Claude registers commands as **skills** (`.claude/skills/speckit-lx-*`), dots→dashes.

## Conventions
- Templates: keep the visual-conventions header in `spec-template.md` authoritative.
- Attribution to the Leadaxe methodology stays; don't strip it.
- Bump `CHANGELOG.md` and the manifest `version` for releases.

## Cutting a release
```bash
bash scripts/pack.sh    # → dist/lx-preset.zip, dist/lx-flow-ext.zip
                        #   (validates that each manifest sits at the archive root)
gh release create vX.Y.Z dist/lx-preset.zip dist/lx-flow-ext.zip -t "vX.Y.Z" -F CHANGELOG.md
```
Users then install via `--from <release URL>` (see README, вариант Б). Note the
extension form requires the positional name: `specify extension add lx --from <url>`,
and URL installs outside configured catalogs prompt an Untrusted Source confirmation.
