# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Cross-platform shell configuration (bash, zsh, fish) plus utility scripts (`ll`, `dus`, `dusf`) for Linux and macOS. Installed via `install.sh` to `~/.my-shell/` and `/usr/local/bin`. Environment activation works like a Python virtualenv via `env/activate`.

## Commands

```bash
make help                # List targets
make lint                # ShellCheck (bash/sh) + fish -n
make alias-sync          # Verify shell/aliases.yml <-> bash/zsh/fish in sync
make check               # lint + alias-sync
make test                # Full BATS suite + linting
make test-bats           # BATS only
make test-ll             # Platform-aware ll suite (auto-detects OS)
make test-ll-common      # Wrapper tests (platform independent)
make test-ll-linux       # GNU-specific
make test-ll-macos       # BSD-specific
make format-fish         # fish_indent -w
make test-act            # Run GitHub Actions locally (Docker)
make install-hooks       # pre-commit install

# Run a single test file
bats tests/alias.bats
bats tests/ll_macos/10_core.bats
bats -v tests/ll/10_wrapper_stub.bats   # verbose

# Cross-platform parity check for ll (authoritative)
scripts/dev/ll-compare --show-ansi --only=50 ll_macos ll_linux
scripts/dev/ls-compare ll_macos         # vs canonical `ls -l`
```

Before running local shell tooling, source `./env/activate` (or `activate.fish`) to get the correct PATH, ShellCheck and hooks. `reactivate` reloads configs without deactivating.

## Architecture

### Multi-shell abstraction (`shell/`)
Each of `bash/`, `zsh/`, `fish/` contains parallel modules with identical responsibilities:
- `init.*` — entrypoint that sources the other modules in order
- `aliases.*` — aliases and functions
- `prompt.*` — prompt customization
- `env.*` — environment variables

**`shell/aliases.yml` is the source of truth** for aliases. Editing aliases requires updating `aliases.yml` AND all three `shell/*/aliases.*` files, then running `make alias-sync`. CI fails on drift; `tests/alias-sync.bats` enforces it.

### `ll` platform dispatcher (`scripts/bin/`)
`ll` is a wrapper that dispatches to a platform implementation. Precedence:
1. `LL_IMPL_PATH` — explicit path override
2. `LL_SCRIPT` — legacy override (with recursion guard)
3. `LL_IMPL=linux|macos` — force implementation
4. `uname -s` — Darwin → `ll_macos`, else → `ll_linux`

Exit codes: `1` missing executable, `2` invalid `LL_IMPL`. Errors emit `selector=...` diagnostics to stderr.

`ll_linux` and `ll_macos` are independent implementations (GNU coreutils vs BSD userland) that **must produce byte-identical output**. They share logic via `scripts/bin/ll_common.awk`. Both parse `stat`, bucket mtimes into relative strings ("2 days ago"), ANSI-color by file type, and quote filenames containing whitespace.

**Traps to remember:**
- Internal record separator is ASCII US (`$'\037'`), never tab — tabs are legal in filenames.
- `LL_NOW_EPOCH` pins "now" for deterministic time-bucket tests.
- `LL_NO_COLOR=1` disables ANSI for comparison runs (replaces old `LL_CHATGPT_FAST`).
- Any fast-path change must be validated with `ll-compare --show-ansi --only=50` before broader test runs.

### Test layout (`tests/`)
BATS-based. Harnesses in `tests/test_helper/` and `tests/ll_*/00_harness.bash`.
- `tests/ll/` — wrapper dispatch tests using stub implementations (platform independent)
- `tests/ll_linux/`, `tests/ll_macos/` — platform-specific core tests
- `tests/alias*.bats`, `tests/bash.bats`, `tests/scripts_*.bats` — shell/script unit tests

`make test-ll` auto-picks `common + linux` or `common + macos`. CI reads `.ci-test-ll.log` produced by `make test-ll` — never invoke `bats` directly in CI report steps.

New tests should update `tests/TEST_COVERAGE.md` and the test-count badge in `README.md`.

### Environment activation (`env/`)
`env/activate` detects the current shell and spawns a new session with PATH/hooks wired up. Per-shell variants `activate.{bash,zsh,fish}` expose `deactivate` and `reactivate`. `scripts/dev/` is added to PATH only when activated.

### Installer (`install.sh`)
Modes: `--local`, `--settings-only`, `--scripts-only`, `--user` (writes to `~/.local/bin`), `--dry-run=PATH` (sandbox, requires `-y`). `BIN_PREFIX` precedence: `--bin-prefix` > `MY_SHELL_BIN_PREFIX` env > `--user` > default `/usr/local/bin`.

## Conventions

- POSIX-compliant where possible; platform detection via `uname -s`.
- Prefer `command -v` over `which`; helper `__my_shell_has cmd` for existence checks.
- Two-space indent in shell; `printf '%s' "$var"` for user input; `"$@"` to forward args; `DELIM=$'\037'` for record separators.
- Executable helpers: `scripts/bin/`; dev helpers: `scripts/dev/`; activation: `env/`; docs: `docs/`, `README.md`.
- ShellCheck severity=warning must pass (`scripts/dev/run-shellcheck`). Fish is checked with `fish -n`.
- Keep diffs small. Update `CHANGELOG.md` `[Unreleased]` with `areas:` and whether behavior changed. Update `README.md` badges (CI, test count) when relevant.

## Executing scripts (fish host caveat)

The user's primary shell is fish. When running multi-line shell snippets via Bash tool, wrap them in `bash -c '...'` or `zsh -c '...'`; do not rely on fish-incompatible syntax being interpreted by the active shell.
