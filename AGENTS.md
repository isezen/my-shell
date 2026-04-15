# AGENTS.md

Cross-tool guidance for AI coding agents (Claude Code, Cursor, Codex CLI,
GitHub Copilot, Aider, Continue, OpenCode, etc.) working in this repo.
Follows the [agents.md](https://agents.md) Linux Foundation convention.
This is the **canonical** instruction file; per-tool wrappers (e.g.
`CLAUDE.md`) defer to it.

## Project Overview

Cross-platform shell environment + utility scripts for **bash, zsh, fish**
on **Linux and macOS**. Two surfaces:

1. **Shell config** (`shell/{bash,zsh,fish}/`) — aliases, prompt, env,
   init. Installed to `~/.my-shell/<shell>/` by `install.sh`.
2. **Utility scripts** (`scripts/bin/`) — primarily the `ll` family
   (colorful long listing with cross-platform byte-level parity) plus
   `dus`/`dusf`/`dusf.` disk usage helpers. Installed to
   `/usr/local/bin` (or `~/.local/bin` with `--user`).

Environment activation works like a Python virtualenv via `env/activate`.

## Setup & Daily Commands

```bash
make help                # List all targets
make lint                # ShellCheck (bash/sh) + fish -n
make lint-bash           # ShellCheck only
make lint-fish           # fish syntax only
make alias-sync          # Verify shell/aliases.yml ↔ bash/zsh/fish in sync
make check               # lint + alias-sync
make test                # Full BATS suite + linting
make test-bats           # Top-level BATS only (tests/*.bats + tests/ll/)
make test-ll             # Platform-aware ll suite (auto-detects OS)
make test-ll-common      # Wrapper tests (platform-independent)
make test-ll-linux       # GNU coreutils tests
make test-ll-macos       # BSD userland tests
make test-ll-all         # All ll suites (unsuitable ones soft-skip)
make baseline-check      # Read-only baseline regression lock
make baseline-regen      # Rebuild baselines (USE WITH CARE — review diff)
make format-fish         # fish_indent -w
make test-act            # Run GitHub Actions Ubuntu job locally (Docker)
make install-hooks       # pre-commit install
```

Run a single test file:

```bash
bats tests/alias.bats
bats tests/ll/20_baseline_snapshot.bats
bats -v tests/ll_macos/10_core.bats   # verbose
```

Before running local shell tooling, source `./env/activate` (or its
shell-specific variant) to get the correct PATH, ShellCheck and hooks.
`reactivate` reloads configs without spawning a new session; `deactivate`
restores the original environment.

## Project Structure

- `shell/` — per-shell modules (`bash/`, `zsh/`, `fish/`). Each has
  `init.*`, `aliases.*`, `prompt.*`, `env.*`. **`shell/aliases.yml` is
  the source of truth** for alias names and descriptions.
- `scripts/bin/` — user-facing executables (`ll`, `ll_linux`, `ll_macos`,
  `dus`, `dusf`, `dusf.`). The `ll` script is a thin platform dispatcher;
  see Architecture below.
- `scripts/bin/ll_common.awk` — shared BSD-awk-safe render/format/color
  layer used by both `ll_linux` and `ll_macos`.
- `scripts/bin/ll_linux.awk` — gawk-scoped GNU `ls -l` ingress parser
  (used only by `ll_linux`).
- `scripts/dev/` — maintainer tools (`ll-compare`, `ls-compare`, `ll-perf`,
  `run-shellcheck`). Added to `PATH` only when the env is activated.
- `env/` — `activate`, `activate.bash`, `activate.zsh`, `activate.fish`
  + `deactivate`/`reactivate` helpers.
- `tests/` — BATS suite. Layout:
  - `tests/*.bats` — top-level suite (alias, alias-sync, bash, install,
    scripts_dus, scripts_ll)
  - `tests/ll/` — platform-independent wrapper + baseline snapshot tests
  - `tests/ll_linux/` — GNU coreutils tests with `00_harness.bash`
  - `tests/ll_macos/` — BSD userland tests with `00_harness.bash`
  - `tests/test_helper/` — bats-support / bats-assert
  - `tests/fixtures/ll_baseline/` — locked byte-level snapshots
- `docs/` — `LL_SPECS.md` (ll behavior contract),
  `ACTIVATION_SPECIFICATION.md`, `proj_summary.md`.
- `install.sh` — unified installer (settings + scripts modes).
- `.github/workflows/ci.yml` — GitHub Actions: Ubuntu + macOS runners,
  push/PR/weekly cron triggers.

## Architecture

### Multi-shell abstraction

Each shell directory (`shell/{bash,zsh,fish}/`) provides parallel modules:

- `init.*` — entrypoint that sources the other three in order
- `aliases.*` — aliases and helper functions
- `prompt.*` — prompt customization
- `env.*` — exported environment variables

**Alias synchronization rule (project's central invariant):** Adding or
modifying an alias requires updating `shell/aliases.yml` (the source of
truth) AND all three `shell/*/aliases.*` files. `tests/alias-sync.bats`
enforces this in CI and locally; `make alias-sync` is the verification
entry point.

### `ll` platform dispatcher

`scripts/bin/ll` is a thin wrapper that selects an implementation by
**precedence**:

1. `LL_IMPL_PATH` — explicit absolute path override (highest)
2. `LL_SCRIPT` — legacy override with recursion guard
3. `LL_IMPL=linux|macos` — force a specific implementation
4. `uname -s` — Darwin → `ll_macos`, otherwise → `ll_linux`

Exit codes: `1` for missing executable, `2` for invalid `LL_IMPL` value.
Errors emit `selector=...` diagnostics to stderr.

### Byte-level cross-driver parity (locked)

`ll_linux` and `ll_macos` produce **byte-identical output** for every
fixture case under the deterministic baseline env:

```
LC_ALL=C TZ=UTC LL_NO_COLOR=1 LL_NOW_EPOCH=1577836800
```

This is enforced by three invariants in `tests/ll/20_baseline_snapshot.bats`:

1. `ll_linux` matches its locked baseline (`tests/fixtures/ll_baseline/ll_linux/`)
2. `ll_macos` matches its locked baseline (`tests/fixtures/ll_baseline/ll_macos/`)
3. The two baseline directories are byte-identical to each other

The shared render/format/color layer is `scripts/bin/ll_common.awk`
(BSD-awk safe — no 3-arg `match()`, no `gensub`, no gawk-only features —
because `ll_macos` runs it under `/usr/bin/awk`). `ll_linux`'s GNU `ls -l`
ingress parser lives separately in `scripts/bin/ll_linux.awk` (gawk-only,
intentionally kept out of the common layer).

**Driver invocation:**
- `ll_macos`: `awk -f ll_common.awk -f <(inline driver)` over `stat`-built rows
- `ll_linux`: `awk -f ll_common.awk -f ll_linux.awk -f <(inline driver)` over `ls -l` lines, where `ls`'s color flag is picked from `LL_NO_COLOR` (`--color=never` if set, `--color=always` otherwise)

### Environment activation

`env/activate` detects the current shell and spawns a new session with
PATH/hooks wired up. Per-shell variants `activate.{bash,zsh,fish}` modify
PATH and source `shell/<shell>/init.<shell>`. They expose:

- `deactivate` — restore original environment
- `reactivate` — reload configs without spawning a new session
  (preserves prompt prefix)

`scripts/dev/` is added to `PATH` only when activated.

### Installer (`install.sh`)

Modes: `--local` (from a local clone), `--settings-only`, `--scripts-only`,
`--user` (writes to `~/.local/bin` instead of `/usr/local/bin`),
`--dry-run=PATH` (sandbox, requires `-y`).

`BIN_PREFIX` precedence: `--bin-prefix` > `MY_SHELL_BIN_PREFIX` env >
`--user` flag > default `/usr/local/bin`.

## Conventions

### Coding style

- Two-space indent in shell. Use `printf '%s' "$var"` for user input,
  `"$@"` to forward arguments verbatim, `DELIM=$'\037'` (ASCII US) when
  a record separator is needed — never tab, since tab is legal in
  filenames.
- Annotate non-obvious logic with concise comments; explain *why*
  (e.g., the BSD `stat -f %N` trap), not *what*.
- Helper existence checks use `__my_shell_has cmd`; prefer `command -v`
  over `which`. Platform detection via `uname -s` (Darwin vs Linux).
- POSIX-compliant where possible. `bash` features only where the
  shebang says so.
- Executable user surface: `scripts/bin/`. Maintainer tools:
  `scripts/dev/`. Activation: `env/`. Specs: `docs/`.
- ShellCheck must pass (`scripts/dev/run-shellcheck`). Fish is checked
  with `fish -n`. The `.shellcheckrc` documents intentionally-disabled
  rules — keep that file in sync if you add a new disable.

### `ll` traps to remember

- Internal record separator is `$'\037'` (ASCII US). Never tab.
- `LL_NOW_EPOCH=1577836800` pins "now" for deterministic time-bucket
  tests. Always set it when running `ll-compare` / `baseline-check`.
- `LL_NO_COLOR=1` disables ANSI in both drivers (the canonical
  baseline-capture environment).
- Any change to `ll_common.awk` or `ll_linux.awk` that touches rendering
  must be validated with `make baseline-check`. If output legitimately
  changes, run `make baseline-regen` and commit the new snapshots
  *with a CHANGELOG entry explaining the diff*.

### Documentation hygiene

- Update `CHANGELOG.md` `[Unreleased]` after each meaningful change.
  Note the affected `areas:` and whether behavior changed
  ("docs-only", "test-only", or a real behavior change with detail).
- Update `README.md` test-count badge when adding/removing tests.
- New tests go next to existing ones (e.g., `tests/ll_macos/case-*`).
- `docs/LL_SPECS.md` is the test-locked behavior contract for the `ll`
  family. Update §9.1 when changing the cross-driver parity surface.

### Commit & PR style

- Imperative subject line, ≤72 chars: "Fix ll_macos broken symlink coloring"
- Body explains *why*, references file paths/line numbers when relevant.
- Run `make test`, `make lint`, `make alias-sync` (or `make check`)
  before pushing.
- No squash on feature-branch merges if commit history is meaningful;
  use `git merge --no-ff` for multi-phase work to preserve the
  branch shape.

## Common Tasks

| Task | Command(s) |
|------|------------|
| Add an alias | Edit `shell/aliases.yml` + all three `shell/*/aliases.*` → `make alias-sync` |
| Add a test | Create `*.bats` next to a similar one → `make test-bats` |
| Reproduce a CI failure locally | `make test-act` (requires Docker + `act`) |
| Force a specific `ll` impl | `LL_IMPL=linux ll …` or `LL_IMPL=macos ll …` |
| Compare ll implementations | `scripts/dev/ll-compare ll_linux ll_macos` |
| Compare against canonical `ls` | `scripts/dev/ls-compare ll_macos` |
| Investigate a baseline diff | `make baseline-check` (will print a unified diff) |
| Regenerate baselines (intentional) | `make baseline-regen` then `git diff tests/fixtures/ll_baseline/` |
| Format a fish script | `make format-fish` |

## Gotchas

- **`make test-bats` does NOT run `tests/ll_linux/` or `tests/ll_macos/`.**
  Use `make test-ll` for those. CI runs both.
- **`ll_linux` on macOS host** dispatches via `gnubin` if MacPorts/
  Homebrew coreutils is in PATH. The locked baselines are captured on
  this configuration. Real Linux hosts produce *different* bytes
  (ext4 vs APFS semantics: symlink mode bits, dir block size, default
  group, `total` line, `touch +Nyr` clamping). The Linux-side baseline
  test soft-skips on non-Darwin; `tests/ll_linux/` is the authoritative
  Linux coverage.
- **`tests/ll_linux/40_color.bats` color tests** explicitly override
  `LL_NO_COLOR=0` because the harness sets `LL_NO_COLOR=1` globally.
- **`mem` shell function** (in `shell/bash/aliases.bash`) is macOS-only;
  the bats test for it skips if `vm_stat` is missing.
- **`chmod 0555` does not block root.** Two `tests/install.bats` cases
  rely on it and skip when `id -u == 0` (CI containers run as root).
- **Latent bug pattern:** any `gawk:` or `awk:` error from `ll_linux` /
  `ll_macos` likely means a function in `ll_common.awk` was added that
  uses a gawk-only feature (3-arg `match()`, `gensub`, etc.). Move it
  to `ll_linux.awk` instead.

## References

- `docs/LL_SPECS.md` — full behavior contract for the `ll` family
- `docs/ACTIVATION_SPECIFICATION.md` — `env/activate` semantics
- `docs/proj_summary.md` — narrative project overview
- `tests/TEST_COVERAGE.md` — test inventory
- `CHANGELOG.md` — chronological history
- [agents.md](https://agents.md) — community convention this file follows
