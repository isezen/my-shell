# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Removed
- **`docs/project_folder_structure.md` deleted from tracking.** The file was a stale `tree -L 3`-style snapshot regenerated on every commit by a local-only `.git/hooks/pre-commit` block calling `~/.cursor/scripts/generate_folder_structure.py` (a Cursor IDE script outside the repo). Audit found zero readers — no source file, doc, README, AGENTS.md, or test referenced it; every fact it contained is derivable on demand from `git ls-files`, `Glob`, or `ls -R`. Removed via `git rm`, added to `.gitignore` so a future Cursor regen on a clean checkout doesn't accidentally re-stage it, and the regen+`git add` block was stripped from the local pre-commit hook (left as a dated comment in `.git/hooks/pre-commit` for context). The Cursor IDE script itself (`~/.cursor/scripts/generate_folder_structure.py`) is intentionally NOT touched — it lives outside this repo and may serve other projects. The obsolete `AGENTS.md` Gotchas bullet that documented the auto-gen behavior is also removed (the situation no longer exists). Net effect: zero impact on AI-agent navigation, zero impact on CI, ~213 lines of churning markdown out of every commit diff. Areas: docs/build-config.

## [2.0.0] - 2026-04-15

First tagged release since v1.0 (2014-11-29, 251 commits behind).
Snapshots the repo at the point where: (a) the `ll_common.awk`
cross-platform migration is complete with byte-level parity locked
by test invariants, (b) the BATS test suite has been expanded to
176 tests across 20 files and is fully covered by GitHub Actions
CI on both Ubuntu and macOS, (c) `env/activate.{bash,zsh,fish}` is
tested and safe under `set -u`, and (d) `install.sh` has a
`--backup` mode. Install the exact state via:

  git checkout v2.0.0 && ./install.sh --local --settings-only

Highlights collected from the entries below:

  * **`ll_common.awk` migration** — `ll_linux` and `ll_macos` now
    share a single render/format/color layer (`ll_common.awk`) plus
    a gawk-scoped ingress parser (`ll_linux.awk`). Under the
    deterministic baseline env (`LC_ALL=C TZ=UTC LL_NO_COLOR=1
    LL_NOW_EPOCH=1577836800`) the two drivers produce byte-identical
    output across all 52 fixture cases, enforced by a three-invariant
    lock in `tests/ll/20_baseline_snapshot.bats`.
  * **Fish non-interactive safety** — `shell/fish/init.fish` guards
    `aliases.fish` and `prompt.fish` behind `status is-interactive`
    so SSH command runs and `fish -c` invocations stop blowing up on
    missing `$TERM`.
  * **Self-locating init files** — `shell/{bash,zsh,fish}/init.*`
    resolve siblings relative to their own directory, so the same
    file works in both repo and installed layouts.
  * **`env/activate.{bash,zsh}` set -u safety** — every potentially-
    unset reference now goes through `${VAR:-}`, regression-locked
    by test helpers that turn nounset back on.
  * **`install.sh --backup`** — opt-in snapshot of existing files
    before overwrite; pairs cleanly with `-y` for unattended runs.
  * **CI hardening** — top-level `tests/*.bats` suite (81 tests
    covering alias-sync, install, bash config, dus utilities) now
    runs in CI. Previously skipped. Weekly scheduled run added.
  * **Agent-docs consolidation** — 3 overlapping agent guides
    collapsed to 2: canonical `AGENTS.md` + minimal `CLAUDE.md`
    pointer, `.github/copilot-instructions.md` deleted.
  * **Legacy `dus`/`dusf`/`dusf.`** — declared feature-frozen with
    a GNU-coreutils preflight gate (exit 2 + actionable banner) and
    a minimal BSD-surface reduction (`sed -r` → `sed -E`).

Full detail of every change below, grouped by type.

### Changed
- **`.shellcheckrc` audited — 3 dead disables removed, 3 live ones documented.** Methodology: moved `.shellcheckrc` aside, ran `scripts/dev/run-shellcheck` locally (shellcheck 0.11.0) and under Ubuntu CI via `make test-act` (apt-packaged shellcheck, older series), and counted hits per rule. Dead (zero hits on both toolchains, disables removed): `SC2032` (alias + xargs), `SC2262` (alias same parsing unit), `SC2263` (multiple unused alias defs). Live (reason + hit count added to the config comment block): `SC2139` (alias expansion when defined — 2-3 hits), `SC2317` (unreachable code — 3+/9+ hits), `SC2015` (A && B || C — 0 hits locally but 4 hits on Ubuntu's older shellcheck, so the disable is CI-only load-bearing). The config header now records the audit date (2026-04-15) and the method, so the next audit has a known baseline. Areas: lint-config.

- **`dus`/`dusf`/`dusf.` declared feature-frozen + `sed -r` → `sed -E`.** A minimal follow-up to P2 #10's preflight gate. Two `sed -r` calls in `scripts/bin/dus` and `scripts/bin/dusf` converted to the portable `sed -E` form (accepted by both GNU sed 4.0+ and BSD sed, so no behavior change, just reduced surface area of GNU-only usage). Each script's preflight banner, the README Utility Scripts section, and this changelog now explicitly call the three scripts "feature-frozen" and point at modern alternatives (`ncdu`, `dust`, `duf`). A full BSD-safe rewrite is tracked in `wip/todo.md` as deferred backlog work; no code-level change there yet. Areas: scripts/docs.

### Added
- **`dus`/`dusf`/`dusf.` maintenance status clarified (P2 #10).** The three legacy disk-usage helpers (untouched in their core logic since 2014-11-24) use GNU-specific flags (`ls --color`, `du -d`, `head -n -N`, `sed -r`) that BSD userland does not support. On a clean macOS host they previously fell through to cryptic `du: illegal option` / `head: illegal line count` errors. Each script now runs a `command ls --version` preflight; on a BSD-only host it prints a self-contained error message explaining the requirement, the MacPorts/Homebrew install commands, and the PATH snippet needed to prepend `gnubin`, then exits with code 2 (usage/requirement error). On GNU hosts — native Linux or macOS with gnubin in PATH — behavior is unchanged. `tests/scripts_dus.bats` was rewritten from loose "exit 0..2" assertions into real behavioral tests: (a) on a GNU-coreutils host the scripts run end-to-end and the outputs are asserted for specific file/directory names and the absence of wrong entries (hidden/regular file segmentation); (b) on a Darwin host with a BSD-only PATH the preflight error message and exit 2 are asserted directly. `README.md` Utility Scripts section now states the GNU coreutils requirement inline. Areas: scripts/dus/tests/docs.

- **`ll_common.awk` migration complete.** After a 4-phase migration spanning commits 9a31f16 (Jan 2026) through Phase 4 (this release), `ll_linux` and `ll_macos` share a single render/format/color layer (`scripts/bin/ll_common.awk`, BSD-awk compatible, mandatory for both) with a platform-specific ingress parser for `ll_linux` (`scripts/bin/ll_linux.awk`, gawk-scoped). Under the baseline env (`LC_ALL=C TZ=UTC LL_NO_COLOR=1 LL_NOW_EPOCH=1577836800`) the two drivers produce byte-identical output across all 52 fixture cases, enforced by a three-invariant regression lock in `tests/ll/20_baseline_snapshot.bats`. Parity trajectory by phase: 2/52 (Phase 0) → 13/52 (Phase 2) → 52/52 (Phase 3). Phase details below (areas: ll/common-awk/ll_linux/ll_macos/tests/docs).
  - **Phase 4 — cleanup and docs**: `scripts/bin/ll_common.awk` header rewritten to document the MANDATORY parity contract and the BSD-awk safety rule that keeps gawk-only patterns out of the shared layer. `docs/LL_SPECS.md` §9.1 Common Contract rewritten to specify byte-level cross-driver parity and the three-invariant test lock. `README.md` Behavior Contract section refreshed with the same guarantees and a pointer to `make baseline-check`/`baseline-regen`. Plan document `docs/plans/ll-common-awk-migration.md` removed (migration executed in full). `wip/todo.md` backlog entry removed.

- `ll_common.awk` migration — **Phase 3: cross-driver byte-level parity** (areas: ll/ll_linux/ll_linux.awk/tests). With Phase 3 applied, `ll_linux` and `ll_macos` emit **byte-identical output** across every single fixture case under the baseline env (`LC_ALL=C TZ=UTC LL_NO_COLOR=1 LL_NOW_EPOCH=1577836800`). The migration goal from commit `9a31f16` — "one render contract, two platform drivers" — is met. Details:
  - `scripts/bin/ll_linux`: GNU `ls` is now called with a color mode picked from `LL_NO_COLOR`. Under `LL_NO_COLOR=1` it is `--color=never`, so GNU ls emits plain filename and symlink-target text. Under `LL_NO_COLOR=0` it is `--color=always` (explicit, not `--color` which is the deprecated "sometimes always" form, nor `--color=auto` which resolves to "never" under command substitution). Behavior change: the `NO_COLOR=1` code path now produces plain filenames matching `ll_macos`; the `NO_COLOR=0` path is unchanged (GNU LS_COLORS injected around filenames as before).
  - `scripts/bin/ll_linux`: END block now appends the `\e[K\e[0m` erase-in-line + reset suffix when `length(name_out) >= 200`, mirroring `ll_macos` exactly. This is the terminal-line-clear hack that `ll_macos` has carried for long filenames.
  - `scripts/bin/ll_linux.awk`: `parse_line()`'s post-epoch "strip one leading space" heuristic was removed. It was a latent bug that silently ate the leading space of filenames starting with whitespace under `--color=never` (where the separator space is fully captured by the epoch regex bracket and must NOT be re-stripped). In `--color=always` mode the heuristic was already a no-op because the first char after epoch was `\e` (ESC), not whitespace. Leading-space filename fixture (` file-leading-space.txt`) now renders correctly with its leading space quoted.
  - `tests/fixtures/ll_baseline/ll_linux/` regenerated one final time. All 52 cases are now byte-for-byte identical to `tests/fixtures/ll_baseline/ll_macos/`.
  - `tests/ll/20_baseline_snapshot.bats`: new 3rd test `ll parity: tests/fixtures/ll_baseline/ll_linux == tests/fixtures/ll_baseline/ll_macos`. Runs on any host (no driver invocation needed), diffs the two baseline directories directly, and fails loudly if any snapshot drifts away from cross-driver parity. Combined with the per-driver snapshot tests above, we now lock three invariants at once:
    1. `ll_linux` output matches its own locked baseline (regression guard)
    2. `ll_macos` output matches its own locked baseline (regression guard)
    3. Both baselines are identical (cross-driver contract guard)
  - Green runs: `make baseline-check` 3/3, `make test-ll-common` 10/10, `make test-ll-macos` 7/7, `make test-bats` 91/91, `make lint` clean.
  - Parity trajectory across the migration (byte-level `ll_linux` vs `ll_macos`):
    - Phase 0 (start):  2/52
    - After Phase 2:   13/52  (opt-in cutover landed)
    - After Phase 3:   **52/52** (this phase)

- `ll_common.awk` migration — **Phase 2: ll_linux single-mode cutover** (areas: ll/ll_linux/tests). The `LL_USE_COMMON_AWK` opt-in flag and the ~450-line inline `AWK_PROG_STANDALONE` duplicate driver are gone; `ll_linux` now chains `ll_common.awk` + `ll_linux.awk` + a single inline driver in every invocation.
  - `scripts/bin/ll_linux`: deleted `AWK_PROG_STANDALONE` (~450 LOC) and the `LL_USE_COMMON_AWK=1` branch; `AWK_PROG_COMMON` was renamed to `AWK_PROG` and is now the only driver. The awk call site collapsed from two ~10-line branches to one. Total script size: 813 → 353 lines.
  - `tests/ll/21_ll_linux_optin_parity.bats` deleted — it existed only to prove "standalone mode and opt-in mode are byte-identical", which is moot now that only one mode survives. The `20_baseline_snapshot.bats` regression lock still guards the surviving path.
  - `tests/fixtures/ll_baseline/ll_linux/` regenerated. 50 of 52 case snapshots changed because `ll_linux` now honors `LL_NO_COLOR=1` for the perm/links/owner/group/size/time columns (the common-awk path has always done this; the inline standalone path silently ignored it). The filename/target columns still carry GNU `ls --color`-injected LS_COLORS bytes — closing that gap is Phase 3's job.
  - `ll_macos` baselines are unchanged — Phase 2 only touches `ll_linux`.
  - Cross-driver parity measurement after the flag removal:
    - ANSI-stripped: **52/52 identical** (unchanged from Phase 0 — semantic parity was already complete)
    - Byte-level: **13/52 identical**, up from 2/52 before Phase 2 — the 39 remaining byte diffs are exactly the pre-colored GNU `ls` LS_COLORS sequences around filenames/targets that Phase 3 will normalise
  - Green runs: `make baseline-check` 2/2, `make test-ll-common` 9/9 (the opt-in parity test is gone; down from 10), `make test-ll-macos` 7/7, `make test-bats` 90/90, `make lint` clean.

- `ll_common.awk` migration — **Phase 1: common scope expansion + ll_linux.awk ingress split** (areas: ll/common-awk/ll_linux). No behavior change to any driver's default-mode output; Phase 1 is purely additive infrastructure preparing Phase 2's flag removal. Details:
  - `ll_common.awk` gained three ANSI render helpers lifted out of `ll_linux`'s inline program: `llc_strip_leading_resets`, `llc_strip_trailing_resets`, `llc_has_nonreset_sgr`. All three are BSD-safe (no 3-arg match, no gawk-only features); they live alongside `llc_strip_colors` and can be reused by `ll_macos` when it needs to preserve GNU-ls-style pre-coloured text.
  - `scripts/bin/ll_linux.awk` (new, ~200 lines) — dedicated ingress library for `ll_linux`. Hosts the GNU `ls --color -l --time-style=+%s` parser (`_is_epoch`, `_find_epoch_span`, `parse_line`) and the pre-coloured-tail renderer (`format_name_raw`). Intentionally gawk-scoped so the "ingress layer" can use 3-arg `match()` without polluting `ll_common.awk`'s BSD-compat surface.
  - `ll_linux`'s `LL_USE_COMMON_AWK=1` opt-in path is now canonical: it chains `awk -f ll_common.awk -f ll_linux.awk -f <(AWK_PROG_COMMON)` with a minimal driver that calls `ll_common_init()` in `BEGIN` and references `llc_*` helpers in row/END. The previous sed-surgery block (`/^function quote_if_needed/,/^function color_reltime_by_lbl/d` + BEGIN injection + `color_reltime_by_lbl` rename) is removed — it was structurally broken and triggered a `gawk: syntax error` at runtime. The default standalone mode (`AWK_PROG_STANDALONE`) is unchanged; Phase 2 will delete it and flip opt-in to always-on.
  - `ll_linux` now resolves `NOW_EPOCH` with a `date +%s` fallback in the shell layer (matching `ll_macos`). Previously the opt-in awk path received an empty `NOW_EPOCH` when `LL_NOW_EPOCH` was unset, and `ll_common.awk`'s `time_calc` wrapper would compute `int("" - epoch)`. Tests always set `LL_NOW_EPOCH` so the gap was latent.
  - `tests/ll/21_ll_linux_optin_parity.bats` — new BATS test proving byte-for-byte equality between `ll_linux` default and `LL_USE_COMMON_AWK=1` modes across all 52 ll-compare fixture cases under `LL_NO_COLOR=0`. Runs through `scripts/dev/ll-compare --snapshot` twice (once per mode) and `diff -ruN`s the output directories. Drift verified: inverting the `" -> "` split marker in `ll_linux.awk` produces a failing diff.
  - `tests/fixtures/ll_baseline/` is unchanged and still locks the default-mode output. Phase 0 regression check remains green (2/2).
  - Runs green on this branch: `make baseline-check` 2/2, `make test-ll-common` 10/10 (includes the new parity test), `make test-ll-macos` 7/7, `make lint` clean.

- `ll_common.awk` migration — **Phase 0: baseline fixture lock** (areas: ll/tests/dev-tools). No behavior change to `ll_macos` output contract; new regression infrastructure. Details:
  - `scripts/dev/ll-compare` gained a `--snapshot <DIR>` mode that writes each test case's raw output to `<DIR>/<script_name>/NNN_<slug>.out`, skips PASS/FAIL compare, and accepts a single-script invocation. Snapshot paths are resolved to absolute paths before the tool `cd`s into its temp fixture dir.
  - `tests/fixtures/ll_baseline/{ll_linux,ll_macos}/` — 52 × 2 = 104 locked baseline snapshots captured in deterministic env (`LC_ALL=C TZ=UTC LL_NO_COLOR=1 LL_NOW_EPOCH=1577836800`), covering defaults, flag combinations, tricky filenames (spaces, tabs, UTF-8, leading-space, long names), symlinks (broken, dir, exec, with-space-target, with-tab-target), permission edge cases (setuid, setgid, sticky, fifo), time buckets (sec/min/hrs/day/mon/yr + future) and mixed-width scenarios.
  - `tests/ll/20_baseline_snapshot.bats` — regression lock that regenerates snapshots into a tempdir via `ll-compare --snapshot` and `diff -ruN` asserts byte-for-byte equality against `tests/fixtures/ll_baseline/`. Skips `ll_macos` on non-Darwin hosts; skips `ll_linux` when GNU coreutils are unreachable (auto-probes MacPorts/Homebrew gnubin paths).
  - `Makefile` targets: `make baseline-check` (read-only BATS verification) and `make baseline-regen` (rebuild snapshots after an intentional behavior change — flagged with `USE WITH CARE`).
  - `docs/plans/ll-common-awk-migration.md` — detailed phase plan with Phase 0 findings section documenting discovered blockers, semantic parity measurement, and migration path.

### Fixed
- `scripts/bin/ll_common.awk`: `ll_common_init()` no longer divides by zero in `NO_COLOR=1` mode (areas: ll/common-awk). Behavior change: `llc_init_size_constants()` and `llc_init_time_constants()` now run unconditionally at the top of `ll_common_init()`, before the `NO_COLOR` early-return. Previously these init calls were only reached in color-enabled mode, leaving `llc_TIME_MIN`/`llc_TIME_HOUR`/`llc_TIME_DAY`/`llc_TIME_MONTH`/`llc_TIME_YEAR` at zero under `NO_COLOR`, which caused `llc_time_calc()` to divide by zero and `ll_macos` to fail on every non-empty directory. Latent since commit `7d3cb41` (Jan 11); `make test-bats` did not cover the affected suite so the regression went undetected for ~3 months.
- `tests/ll_macos/10_core.bats`: three color-assertion tests (`time buckets and colors`, `perms and owner colors`, `size tier colors (numeric)`) now explicitly override `LL_NO_COLOR=0` on their `run` invocations (areas: tests/ll_macos). Behavior change: these tests again exercise the colored output path. The harness's global `export LL_NO_COLOR=1` (introduced in commit `7d3cb41`) had been silently suppressing colors while the assertions still expected color escape sequences — the earlier division-by-zero error masked the assertion mismatch.
- Resolve sibling modules in `shell/{bash,zsh,fish}/init.*` relative to the init file's own directory instead of `$MY_SHELL_ROOT/shell/<shell>/` (areas: shell/init). Behavior change: init files now work both in the repo layout (`<repo>/shell/<shell>/`) and the installed layout (`~/.my-shell/<shell>/`). Previously the installed copy computed `MY_SHELL_ROOT=$HOME` and then tried to source `$HOME/shell/<shell>/env.*`, which does not exist — so `install.sh --settings-only` produced an init file that could not find its siblings. `MY_SHELL_ROOT` is still exported for downstream consumers but is no longer used for sibling resolution.
- Guard `shell/fish/aliases.fish` and `shell/fish/prompt.fish` behind `status is-interactive` in `shell/fish/init.fish` (areas: fish/init). Behavior change: non-interactive fish invocations (`fish -c`, SSH command runs, scripts) no longer load interactive command overrides (`head`/`tail` wrappers calling `tput cols`, colorised `grep`, `ll`, `htop`, etc.), which previously broke on missing `$TERM`. `env.fish` still loads unconditionally so PATH/CLICOLOR/LSCOLORS remain available. Fixes the breakage documented in `docs/issues/fish-non-interactive-breakage.md`.

### Added
- Commit 21: Implement FINAL POLICY for ll-compare and ls-compare dev tools (areas: dev-tools/testing). Behavior change: ll-compare now uses structured comparison (prefix fields compared strictly with ANSI codes, filenames compared after ANSI strip only), allowing color differences while preserving semantic content (spaces, tabs, total/toplam lines); ls-compare respects STRIP_ANSI flag (off by default for byte-for-byte comparison). Both scripts correctly enforce LL_NOW_EPOCH (default 1577836800), LC_ALL=C, TZ=UTC, and preserve tricky filenames. Array variables use `${array[@]:-}` syntax for robustness under strict mode. All 51 ll-compare tests pass, ls-compare runs successfully.
- Commit 20: Implement `-s -h` and `-s --si` blocks column support in ll_macos (areas: macos/blocks). Behavior change: blocks column now humanized with -h (base-1024, uppercase K/M/G/T, e.g., `4.0K`) and --si (base-1000, lowercase k/M/G/T, e.g., `4.1k`). Total line rounds to nearest integer for -h mode and uses ceiling division for --si mode (matching GNU ls). Data rows show one decimal place. Tests #17 and #18 now pass.
- Commit 19: Update plan-ll-control with final compliance status (areas: docs/control). No behavior change; docs only.
- Commit 18: Document newline-in-filename out-of-scope for ll_macos records (areas: macos/tests). No behavior change; docs only.
- Commit 17: Add Phase 0 baseline snapshot log for ll tests (areas: docs). No behavior change; docs only.
- Commit 16: Add ll implementation decision record (areas: docs/decision). No behavior change; docs only.
- Commit 15: Add ll-perf benchmark report (areas: docs/perf). No behavior change; docs only.
- Commit 14: Make ll-compare deterministic for cross-impl diff and document usage (areas: dev-tools/docs). Behavior change: LL_NOW_EPOCH default fixed; LL_CHATGPT_FAST forced in ll-compare runs.
- Commit 13: Add BSD-only PATH pruning when LL_BSD_USERLAND/LL_NO_GNUBIN is set (areas: env). Behavior change: gnubin paths are removed during activation.
- Commit 12: Expand ll_macos suite with MVP parity coverage (fixtures, time buckets, colors, and tricky filenames) (areas: tests). No behavior change; test harness only.
- Commit 11: Include legacy error substrings in wrapper selector errors to keep wrapper tests stable (areas: wrapper). Behavior change: error text updated.
- Commit 10: Switch ll_macos internal row delimiter to ASCII Unit Separator (0x1F) to avoid tab-in-filename conflicts (areas: macos). Behavior change: internal parsing delimiter updated.
- Commit 9: Enforce strict OS dispatch in ll wrapper (no fallback) (areas: wrapper). Behavior change: missing OS target now exits 1.
- Commit 8: ll_linux preflight soft-skips missing GNU date/touch and drops global gawk gating (areas: tests). No behavior change; test harness only.
- Commit 7: CI report reads make test-ll output log instead of re-running bats (areas: ci). No behavior change; refactor/test only.
- Commit 6: Clarified macOS suite preflight warning for non-Darwin hosts (areas: tests). No behavior change; refactor/test only.
- Commit 5: Hardened ll wrapper dispatch checks for executable files (areas: wrapper). No behavior change; refactor/test only.
- Commit 4: Update CI report file lists to match per-OS ll suites (areas: ci). No behavior change; refactor/test only.
- Commit 3: Added test-ll targets and GNU preflight soft-skip for ll_linux suite (areas: makefile/tests). No behavior change; refactor/test only.
- Commit 2: Added stub-based wrapper tests under `tests/ll` (areas: tests). No behavior change; refactor/test only.
- Commit 1: Split GNU ll tests into `tests/ll_linux` and add macOS suite skeleton (areas: tests). No behavior change; refactor/test only.
- Test suite split: Platform-specific test suites for ll implementation
  - `tests/ll_linux/`: GNU toolchain-based test suite (moved from `tests/ll/`)
  - `tests/ll_macos/`: BSD-only test suite skeleton with preflight helpers
  - Tests split by platform to support BSD-only macOS implementation
- Wrapper test suite: Stub-based platform-independent wrapper contract tests
  - `tests/ll/10_wrapper_stub.bats`: Tests for wrapper dispatch, override, and arg forwarding
  - `tests/ll/fixtures/ll_stub_impl.bash`: Stub executable for testing wrapper behavior
  - Tests verify LL_IMPL_PATH priority, LL_IMPL selection, LL_SCRIPT recursion guard, and exit codes
- Makefile test targets: Platform-aware test suite targets
  - `test-ll-common`: Run common/wrapper tests
  - `test-ll-linux`: Run Linux-specific tests (GNU toolchain)
  - `test-ll-macos`: Run macOS-specific tests (BSD toolchain)
  - `test-ll`: Run platform-appropriate test suite (auto-detects OS)
  - `test-ll-all`: Run all test suites (unsuitable ones will soft-skip)
- CI workflow updates: Use platform-aware test targets
  - Ubuntu job: `make test-ll` (runs common + ll_linux suite)
  - macOS job: `make test-ll` (runs common + ll_macos suite)
  - Report steps: Use `make test-ll` output instead of hardcoded globs
- Wrapper dispatch contract: Hardened thin wrapper dispatch contract
  - Priority order: LL_IMPL_PATH > LL_SCRIPT (recursion guard) > LL_IMPL > OS sniff
  - Exit codes: 1 (missing/unexecutable), 2 (invalid LL_IMPL)
  - Arg forwarding: Arguments forwarded verbatim without modification
  - No behavior change; refactor/test only
- macOS test suite: Finalized BSD-only preflight skeleton
  - `tests/ll_macos/00_harness.bash`: Preflight helpers (ll_warn, ll_soft_skip, ll_require_macos_userland)
  - `tests/ll_macos/10_core.bats`: Smoke test for preflight on Darwin
  - Suite ready for Phase 3 implementation
- Unified installer (`install.sh`): Combined `install_shell_settings.sh` and `install_shell_scripts.sh` into a single installer
  - Supports both remote and local installation modes
  - Options: `--settings-only`, `--scripts-only`, `--local`, `--repo-root`, `-y/--yes`, `-h/--help`
  - Interactive overwrite prompts (can be bypassed with `-y/--yes`)
  - Automatic shell detection (bash, zsh, fish)
  - Automatic OS detection (Darwin, Linux) with smart BIN_PREFIX selection
  - Environment variable overrides: `MY_SHELL_REMOTE_BASE`, `MY_SHELL_BIN_PREFIX`
  - Bash 3.2 compatible (no modern bash features)
- Created `CHANGELOG.md` to track project changes
- Added `.pre-commit-config.yaml` with ShellCheck and fish syntax checking hooks
- Added `Makefile` with convenient commands for linting, formatting, and testing
- Created `docs/SHELLCHECK_AND_PRE_COMMIT_EXPLANATION.md` with detailed explanations
- Added BATS (Bash Automated Testing System) test framework
- Created test suite in `tests/` directory with tests for:
  - `alias.sh` - Tests for aliases and functions (26 tests)
  - `bash.sh` - Tests for bash prompt settings (10 tests)
  - `scripts/ll` - Tests for colorful long listing script (11 tests)
  - `scripts/dus` - Tests for disk usage script (8 tests)
- Added `test-bats` Makefile target to run BATS tests
- Created `tests/README.md` with test documentation
- Created `tests/TEST_COVERAGE.md` with detailed test coverage documentation
- Added GitHub Actions CI/CD pipeline (`.github/workflows/ci.yml`)
- Created `CONTRIBUTING.md` with contribution guidelines
  - Introduced comprehensive CONTRIBUTING.md file outlining code of conduct, development workflow, coding standards, testing requirements, and pull request process
  - Included detailed instructions for setting up the development environment and making contributions
  - Established commit message guidelines to maintain consistency across contributions
- Significantly expanded `README.md` with:
  - Features overview
  - Detailed installation instructions
  - Usage examples
  - Development guidelines
  - Project structure
  - Testing information
  - CI/CD information
- Created `REQUIREMENTS.md` with system requirements and dependencies documentation
- Added environment activation system (`env/` directory):
  - `activate` - Global shell switcher (executable script)
  - `activate.bash` - Bash environment activation script
  - `activate.zsh` - Zsh environment activation script
  - `activate.fish` - Fish environment activation script
  - `reactivate` function - Reload environment files without deactivating
  - `deactivate` function - Cleanly deactivate environment
  - Features:
    - Automatic PATH management (adds `scripts/` directory)
    - Shell-specific configuration loading
    - Prompt indicator `(my-shell)` prefix
    - Shell switching support (switch between bash/zsh/fish)
    - Development-friendly: reload files with `reactivate` command
- Added Zsh support with new alias and prompt scripts:
  - Introduced `alias.zsh` and `zsh.zsh` files to provide Zsh-native aliases and prompt configurations
  - Enhanced prompt customization and history handling in Zsh to align with user expectations and Bash behavior
  - Improved prompt formatting in `zsh.zsh` to include brackets around the prompt character for better visibility
  - Enhanced prompt prefix rendering to use cyan color for better user experience

### Changed
- Reorganized development scripts:
  - Moved `check-aliases.sh` and `ll-performance.sh` from project root to `scripts/dev/` directory
  - Renamed `ll-performance.sh` to `ll-perf` for shorter name
  - Migrated alias synchronization logic from `check-aliases.sh` to BATS test `tests/alias-sync.bats`
  - Removed `check-aliases.sh` script (functionality now in `alias-sync.bats`)
  - Removed `check-aliases` Makefile target (replaced with `alias-sync`)
  - Updated `.pre-commit-config.yaml` to use `alias-sync.bats` instead of `check-aliases.sh`
  - Added `alias-sync` Makefile target to run alias synchronization BATS tests
- Fixed environment activation:
  - Fixed `reactivate` function in all shells (bash, zsh, fish) to preserve `(my-shell)` prefix after reloading environment files
  - Prefix is now properly restored after re-sourcing init files that may reset PS1/prompt
- Enhanced environment activation:
  - Added `scripts/dev/` directory to PATH when environment is activated (all shells: bash, zsh, fish)
  - Development scripts in `scripts/dev/` are now directly accessible after activation
- Enhanced pre-commit hook integration:
  - Updated `.git/hooks/pre-commit` to call pre-commit framework, ensuring all hooks from `.pre-commit-config.yaml` (including `check-aliases-sync`) are executed
  - `check-aliases.sh` is now managed exclusively through `.pre-commit-config.yaml` instead of direct hook integration
- Updated documentation and enhanced project structure:
  - Added comprehensive GitHub Actions CI/CD pipeline for automated testing
  - Moved `IMPROVEMENTS.md` to the `docs/` directory for better organization
- Refactored script for improved readability and performance:
  - Corrected spelling errors in comments for clarity
  - Introduced size and time constants to enhance code maintainability
  - Refactored functions to use local variables and improved formatting for better readability
  - Optimized size and time calculations for performance improvements
  - Updated comments for better understanding of the code flow
- Refactored environment activation scripts for improved usability and functionality:
  - Enhanced the `activate`, `reactivate`, and `deactivate` functions across Bash, Zsh, and Fish scripts
  - Updated `CONTRIBUTING.md` to clarify the new activation options and usage instructions
  - Improved error handling and user feedback during activation and deactivation processes
  - Removed global function saving in `my_settings.fish` to simplify function management
  - Added support for shell switching and temporary directory management during activation
- Enhanced shell detection and activation process in environment scripts:
  - Improved the detection of the current shell by utilizing the parent process command for better accuracy
  - Refactored activation logic to handle shell switching more effectively, ensuring that the user's interactive shell is properly activated
  - Added cleanup procedures in the `deactivate` function to manage temporary artifacts and session states
  - Enhanced user feedback during shell switching to improve the overall activation experience
- Updated activation messages in environment script for improved clarity
- Refactored shell detection logic in activation script for improved accuracy
- Enhanced environment activation scripts for improved user experience:
  - Updated prompt formatting in `bash.sh` to include a clear (my-shell) prefix
  - Refactored the `activate` scripts across Bash, Zsh, and Fish to ensure consistent spawning of new interactive shells during activation
  - Simplified the deactivation process by removing unnecessary shell switching logic and ensuring proper cleanup of temporary artifacts
  - Improved user feedback during activation and deactivation to enhance clarity and usability
- Refactored Zsh prompt configuration and activation script for improved clarity:
  - Simplified the activation logic in `activate.zsh` to source `zsh.zsh` directly and ensure consistent prompt prefixing
- Updated activation scripts to prevent loading user startup files:
  - Modified the Bash and Fish activation commands to use `--noprofile` and `--no-config` options, respectively, ensuring that user-specific startup files are not loaded during shell activation
  - Enhanced the isolation of the Zsh environment by keeping `ZDOTDIR` isolated, allowing for a clean startup without user configurations
- Refactored prompt prefix management for better separation of concerns:
  - Removed `(my-shell)` prefix from `bash.sh` and `zsh.zsh` files - these files now only handle prompt formatting
  - Moved `(my-shell)` prefix management to activation scripts (`activate.bash`, `activate.zsh`, `activate.fish`) for centralized control
  - Changed prefix color from cyan to magenta for better visual distinction
  - Activation scripts now add the prefix after sourcing prompt configuration files, ensuring consistent behavior across all shells
- Major refactor: Restructured project directory layout for better organization and maintainability:
  - **New directory structure**: 
    - `scripts/bin/` - All executable scripts moved from `scripts/` to `scripts/bin/` for clearer separation
    - `shell/{bash,zsh,fish}/` - Shell-specific configurations organized by shell type
      - Each shell has `init.*` (entrypoint), `aliases.*`, `prompt.*`, and `env.*` files
  - **Config file organization**: Split monolithic config files into modular components:
    - Bash: `alias.sh` and `bash.sh` → `shell/bash/{init,aliases,prompt,env}.bash`
    - Zsh: `alias.zsh` and `zsh.zsh` → `shell/zsh/{init,aliases,prompt,env}.zsh`
    - Fish: `my_settings.fish` → `shell/fish/{init,aliases,prompt,env}.fish`
  - **Activation system**: Updated to use single entrypoint (`init.*`) files:
    - Activation scripts now source `shell/*/init.*` instead of multiple files
    - PATH updated to use `scripts/bin/` instead of `scripts/`
    - Simplified activation logic with better separation of concerns
  - **Installer modernization**: Unified installation into single `install.sh` script:
    - Combined settings and scripts installation into one installer
    - Removed `lib/provider.sh` dependency (logic moved inline)
    - Added interactive overwrite prompts with `-y/--yes` bypass option
    - Enhanced CLI with `--settings-only`, `--scripts-only` options
    - Automatic shell and OS detection with smart defaults
    - Environment variable support for customization
- Enhanced unified installer (`install.sh`) with flexible installation paths:
  - Added `--user` flag to install scripts to `$HOME/.local/bin` (user mode)
  - Added `--bin-prefix PATH` option for custom installation directory (overrides `--user` and `MY_SHELL_BIN_PREFIX`)
  - Implemented BIN_PREFIX precedence: `--bin-prefix` > `MY_SHELL_BIN_PREFIX` > `--user` > default (`/usr/local/bin`)
  - Simplified OS detection: removed Homebrew/MacPorts checks, always defaults to `/usr/local/bin` on Darwin/Linux
  - Improved permission handling: BIN_PREFIX check only runs when installing scripts (allows settings-only installs without sudo)
  - Enhanced error messages: actionable suggestions when `/usr/local/bin` is not writable (suggests sudo, `--user`, or `--bin-prefix`)
  - Fixed file permissions: settings files use `0644`, scripts use `+x` (executable)
  - Early OS validation: installer dies immediately on unsupported OS (Darwin/Linux only)
  - Added `--dry-run=PATH` option for sandbox mode testing:
    - All file operations (installations, RC file modifications) are redirected to sandbox directory
    - No modifications to real system files (HOME, RC files, /usr/local/bin, etc.)
    - Effective path mapping: HOME → `$DRY_RUN_ROOT/HOME`, absolute paths → `$DRY_RUN_ROOT$PATH`
    - Supports both local and remote source modes in dry-run
    - Useful for testing installer behavior without affecting real system
    - Debug logging shows effective paths for easier test assertions
  - **Test updates**: Updated all test files to reference new directory structure

### Removed
- Removed old root-level config files after migration to new structure:
  - `alias.sh` - Replaced by `shell/bash/aliases.bash`
  - `alias.zsh` - Replaced by `shell/zsh/aliases.zsh`
  - `bash.sh` - Replaced by `shell/bash/prompt.bash` and `shell/bash/env.bash`
  - `zsh.zsh` - Replaced by `shell/zsh/prompt.zsh` and `shell/zsh/env.zsh`
  - `my_settings.fish` - Replaced by `shell/fish/{init,aliases,prompt,env}.fish`
- Removed old installer scripts after unified installer implementation:
  - `install_shell_settings.sh` - Replaced by unified `install.sh --settings-only`
  - `install_shell_scripts.sh` - Replaced by unified `install.sh --scripts-only`
  - `lib/provider.sh` - Provider logic moved inline into `install.sh`

### Fixed
- Fixed critical ShellCheck error in `alias.sh:50`: Added missing quotes around variable in `[ -n "$gnuls" ]` check
- Fixed critical ShellCheck error in `alias.sh:187`: Converted `hs` alias to function (aliases can't use positional parameters)
- Fixed critical ShellCheck error in `alias.sh:229`: Converted `free` alias to function in else block (aliases can't use positional parameters)
- Fixed ShellCheck warnings: SC2164 (cd error handling), SC2016 (variable expansion), SC2155 (local assignment), SC2086 (quoting), SC2046 (word splitting), SC2003 (expr usage), SC2034 (unused variables), SC2323 (unnecessary parentheses), SC2033 (alias in external commands)
- Fixed ShellCheck warnings in `colortable.sh`: SC2046 (command substitution quoting), SC2059 (printf format string)
- Fixed ShellCheck warnings in `install_shell_settings.sh`: SC2016 (added ignore comment for fish syntax)
- Fixed ShellCheck warnings in `ll-performance.sh`: SC2034 (unused variables), SC2012 (ls to find), SC2004 (arithmetic variables)
- Fixed all ShellCheck style warnings: SC2004 (arithmetic variables in alias.sh and ll-performance.sh), SC2012 (ls to find), SC2059 (printf format), SC2262 (alias definition/usage), SC2139/SC2263/SC2032/SC2317 (added to .shellcheckrc as intentional behavior)
- Created `.shellcheckrc` to disable intentional warnings (SC2139, SC2262, SC2263, SC2032, SC2317)

[Unreleased]: https://github.com/isezen/my-shell/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/isezen/my-shell/compare/v1.0...v2.0.0
