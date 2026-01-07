# Plan-LL Phase 0–9 Compliance Audit (Repo: my-shell)

## Executive Summary
Overall compliance is **NON-COMPLIANT**. Phase 1–2 split and wrapper contract are mostly present, and CI uses `make test-ll` with report capture. However, Phase 2+ items are largely unimplemented or unverifiable, and **Phase 1–2 acceptance criteria fail on this host** because `make test-ll-linux` and `make test-ll-all` fail instead of soft-skipping. Additionally, Phase 5 path-control requirements for macOS are not satisfied (BSD tools are not fully pinned to absolute paths). Several Phase 6–9 items have no evidence of implementation.

## Compliance Matrix
| Plan Item | Expected | Repo Status | Result | Evidence | Notes |
|---|---|---|---|---|---|
| Known trap: CI report steps must not run bats globs | Report steps must not run `bats ...` directly; use `make test-ll` output | Report steps read `.ci-test-ll.log` from `make test-ll` | PASS | `.github/workflows/ci.yml:45-65` and `:53-64` | Report uses log, no `bats` execution in report step |
| Known trap: macOS impl must not use tab delimiter | Internal row delimiter must not be tab | Uses ASCII US (0x1F) delimiter | PASS | `scripts/bin/ll_macos:72,325-348,368,438` | US delimiter in `stat` format and `IFS` parsing |
| Known trap: tests/ll common-only | `tests/ll` must be toolchain-independent | Contains only wrapper stub test | PASS | `tests/ll/10_wrapper_stub.bats` (entire file) and `ls -la tests/ll` output | No GNU/BSD assumptions in wrapper suite |
| Known trap: newline filenames out-of-scope | No attempt to support newline filenames | No explicit guard or documentation found | UNKNOWN | No explicit handling in `scripts/bin/ll_macos` or tests | Absence of evidence; cannot confirm compliance |
| Phase 0: baseline snapshot | Baseline branch/snapshot procedures | No artifacts found | UNKNOWN | No Phase 0 artifacts present | Plan requires actions, but no evidence |
| Phase 1: ll_linux naming + wrapper split | `scripts/bin/ll_linux` exists; `scripts/bin/ll` is wrapper | Both files present and executable | PASS | `ls -l scripts/bin/ll*` output | Wrapper is thin, see below |
| Phase 1: wrapper precedence + exit codes | LL_IMPL_PATH > LL_SCRIPT guard > LL_IMPL > uname; exit 1/2 | Implemented | PASS | `scripts/bin/ll:23-83` | Explicit precedence and exit codes |
| Phase 1: tests moved to platform suites | GNU tests under `tests/ll_linux`, wrapper tests under `tests/ll` | Present | PASS | `ls -la tests/ll*` output | Files are split by platform |
| Phase 2: macOS BSD-only target + BSD reference generator | BSD-only test harness + BSD baseline in tests | Only preflight skeleton exists | FAIL | `tests/ll_macos/10_core.bats:9-13` | No BSD reference generator/canonicalization present |
| Phase 3: ll_macos MVP feature parity | Time buckets, colors, perms, owner, size tiers, filenames, `--` | Partial implementation in code; parity unverified | UNKNOWN | `scripts/bin/ll_macos` has color/time logic but no proof vs GNU | Requires semantic validation |
| Phase 4: platform-split suite strategy | Linux suite in `tests/ll_linux`, macOS suite in `tests/ll_macos` | Implemented | PASS | `tests/ll_linux/*`, `tests/ll_macos/*` | Suites exist and separated |
| Phase 5: macOS BSD-only PATH control | Use absolute `/bin/ls`, `/usr/bin/awk`, `/usr/bin/stat` | `stat`/`awk` invoked without absolute paths | FAIL | `scripts/bin/ll_macos:340-341,438` | `stat` and `awk` are PATH-resolved |
| Phase 6: ls-compare revision | Cross-impl diff tool updated per plan | No evidence of plan-specific revisions | UNKNOWN | `scripts/dev/ls-compare` is legacy | Plan items not visible in code |
| Phase 7: performance/bench | Bench scripts/results | No evidence | UNKNOWN | No bench artifacts in repo | Not implemented |
| Phase 8: unification decision | Decision and actions recorded | No evidence | UNKNOWN | No unification artifacts found | Not implemented |
| Phase 9: Makefile test targets | test-ll-common/linux/macos/ll/all | Targets exist | PASS | `Makefile:99-131` | Targets defined |
| Phase 9: CI uses make test-ll | CI runs `make test-ll` | Implemented | PASS | `.github/workflows/ci.yml:45-50, 182-187` | Both jobs use make test-ll |
| Phase 1–2 acceptance: test-ll-common toolchain-independent | Must not require GNU/BSD tools | Passes; wrapper tests only | PASS | `make test-ll-common` output; `tests/ll/10_wrapper_stub.bats` | Toolchain-independent |
| Phase 1–2 acceptance: test-ll-linux soft-skip on macOS without GNU | Must warn+skip and exit 0 | **Fails on this host**; exits 2 | FAIL | `make test-ll-linux` output (see below) | Suite runs and fails; no soft-skip |
| Phase 1–2 acceptance: test-ll-all returns 0 via soft-skip | Must succeed on non-applicable suites | **Fails on this host**; exits 2 | FAIL | `make test-ll-all` output (see below) | Linux suite fails under macOS |
| Phase 1–2 acceptance: test-ll-macos soft-skip on non-Darwin | Must warn+skip | Cannot verify on non-Darwin here | UNKNOWN | `tests/ll_macos/00_harness.bash:25-32` | Requires non-Darwin runtime |
| Phase 1–2 acceptance: wrapper is thin | No business logic | Thin wrapper | PASS | `scripts/bin/ll:1-83` | Wrapper only dispatches |
| Phase “Mevcut Durum” statements still valid | Plan lists current state assumptions | Several are no longer true | FAIL | `tests/ll/` does not contain GNU harness; `tests/ll_linux/` does | Plan section outdated |

## Findings (Detailed)

### A) Known traps
- **CI report steps no hardcoded bats globs**: PASS. Report steps read `.ci-test-ll.log` without running `bats` (evidence: `.github/workflows/ci.yml:53-64`).
- **macOS tab delimiter ban**: PASS. `scripts/bin/ll_macos` uses `DELIM=$'\037'` and parses with `IFS="$DELIM"` (evidence: `scripts/bin/ll_macos:72,340-348,368,438`).
- **tests/ll common-only**: PASS. Only wrapper test exists (`tests/ll/10_wrapper_stub.bats`).
- **newline filenames out-of-scope**: UNKNOWN. No explicit guard or documentation found in code/tests.

### B) Phase 1–2 split (tests/ll_linux + tests/ll_macos)
- **Suite split**: PASS. GNU tests live under `tests/ll_linux/` and wrapper tests under `tests/ll/` (evidence: `ls -la tests/ll*`).
- **macOS skeleton**: PASS (minimal). `tests/ll_macos/00_harness.bash` provides soft-skip; `tests/ll_macos/10_core.bats` is a single preflight test (evidence: `tests/ll_macos/00_harness.bash:16-33`, `tests/ll_macos/10_core.bats:9-13`).
- **Phase 2 BSD reference generator**: FAIL. No BSD baseline/canonicalization in macOS suite.

### C) Wrapper contract
- **Precedence**: PASS. `LL_IMPL_PATH` then `LL_SCRIPT` guard then `LL_IMPL` then `uname` (evidence: `scripts/bin/ll:23-83`).
- **Exit codes**: PASS for invalid `LL_IMPL` (exit 2) and missing targets (exit 1) (evidence: `scripts/bin/ll:61-63,71-82`).
- **Arg forwarding**: PASS by inspection; wrapper only `exec ... "$@"` (evidence: `scripts/bin/ll:30,40,52,59,75,83`).

### D) Makefile targets
- **Targets exist**: PASS (`test-ll-common`, `test-ll-linux`, `test-ll-macos`, `test-ll`, `test-ll-all`) (evidence: `Makefile:99-131`).
- **OS switching**: PASS in Makefile logic (evidence: `Makefile:123-127`).

### E) CI workflow
- **make test-ll usage**: PASS for both Ubuntu and macOS (evidence: `.github/workflows/ci.yml:45-50` and `:182-187`).
- **Report step uses log**: PASS (evidence: `.github/workflows/ci.yml:53-64`).
- **No bats globs in report**: PASS (no `bats` invoked in report step; only file listing).

### F) Soft-skip standard
- **ll_linux suite soft-skip on unsupported hosts**: FAIL on this host (Darwin). `make test-ll-linux` runs and fails instead of warning+skip. Evidence (runtime):
  - `make test-ll-linux` output shows multiple failing tests and non-zero exit.
- **ll_macos suite soft-skip on non-Darwin**: UNKNOWN (not testable on this host). Preflight exists (evidence: `tests/ll_macos/00_harness.bash:25-32`).

### G) “Mevcut Durum” section validity
- Plan claims (now outdated): `tests/ll/00_harness.bash` and GNU tests under `tests/ll/`. Current repo has moved these to `tests/ll_linux/`. Therefore the “Mevcut Durum” statements are **no longer true**.
  - Evidence: `ls -la tests/ll` vs `tests/ll_linux`.

## Runtime Evidence (Key excerpts)

### make test-ll-common (exit 0)
```
1..7
ok 1 ll wrapper: LL_IMPL_PATH wins and forwards argv verbatim
ok 2 ll wrapper: LL_IMPL=linux selects ll_linux in the same directory
ok 3 ll wrapper: LL_IMPL=macos selects ll_macos in the same directory
ok 4 ll wrapper: invalid LL_IMPL returns exit 2
ok 5 ll wrapper: LL_SCRIPT recursion guard does not exec itself
ok 6 ll wrapper: LL_SCRIPT set but not executable returns exit 1 and error
ok 7 ll wrapper: LL_IMPL_PATH set but not executable returns exit 1 and error
```

### make test-ll (exit 0)
```
1..7
ok 1 ll wrapper: LL_IMPL_PATH wins and forwards argv verbatim
ok 2 ll wrapper: LL_IMPL=linux selects ll_linux in the same directory
ok 3 ll wrapper: LL_IMPL=macos selects ll_macos in the same directory
ok 4 ll wrapper: invalid LL_IMPL returns exit 2
ok 5 ll wrapper: LL_SCRIPT recursion guard does not exec itself
ok 6 ll wrapper: LL_SCRIPT set but not executable returns exit 1 and error
ok 7 ll wrapper: LL_IMPL_PATH set but not executable returns exit 1 and error
1..1
ok 1 ll_macos: preflight passes on Darwin
```

### make test-ll-linux (exit 2)
```
1..25
not ok 1 ll core: flag matrix (144 combinations)
# ...
make: *** [test-ll-linux] Error 1
```

### make test-ll-all (exit 2)
```
1..7
ok 1 ll wrapper: LL_IMPL_PATH wins and forwards argv verbatim
...
make: *** [test-ll-all] Error 2
```

### make test-ll-macos (exit 0)
```
1..1
ok 1 ll_macos: preflight passes on Darwin
```

### bats tests/ll/10_wrapper_stub.bats (exit 0)
```
1..7
ok 1 ll wrapper: LL_IMPL_PATH wins and forwards argv verbatim
...
```

## Gaps / Risks (Top 10)
1) **Phase 1–2 soft-skip criterion fails** on this host: `make test-ll-linux` and `make test-ll-all` return non-zero (evidence above).
2) **Phase 2 BSD reference generator missing** in macOS suite; only preflight is present.
3) **Phase 5 PATH control not met**: `scripts/bin/ll_macos` uses PATH-resolved `stat` and `awk` (evidence: `scripts/bin/ll_macos:340-341,438`).
4) **Phase 3 parity is unverified**: ll_macos behavior vs ll_linux lacks canonicalization-based tests.
5) **Phase 6 (ls-compare revision)** absent; only legacy `scripts/dev/ls-compare` exists.
6) **Phase 7 performance/bench** artifacts missing.
7) **Phase 8 unification decision** artifacts missing.
8) **“Mevcut Durum” section** in plan is outdated relative to repo state (risk of misaligned expectations).
9) **newline filename out-of-scope** is not enforced/documented in code (unclear compliance).
10) **CI optional suite behavior** is not validated here (Linux/macOS cross-run skip semantics not proven in CI logs).

## Recommended Next Actions (Max 5)
1) Make `test-ll-linux` soft-skip on macOS when GNU toolchain is absent and ensure the linux suite can target `ll_linux` directly when GNU is present.
2) Implement the Phase 2 BSD reference generator/canonicalization for the macOS suite.
3) Enforce Phase 5 absolute paths for BSD tools in `scripts/bin/ll_macos` (`/bin/ls`, `/usr/bin/awk`, `/usr/bin/stat`).
4) Update or replace `scripts/dev/ls-compare` per Phase 6 requirements for cross-impl comparison.
5) Reconcile the “Mevcut Durum” section in the plan with the current repo structure to avoid stale guidance.

Overall Verdict: NON-COMPLIANT

## Remediation Update

### Changes Applied (Files)
- `tests/ll_linux/00_harness.bash`: force `LL_IMPL=linux` on Darwin runs of ll_linux suite; retain GNU-ls soft-skip; keep gawk optional.
- `scripts/bin/ll_macos`: pin `/usr/bin/stat` and `/usr/bin/awk`; fix `time_parts` return to avoid `set -e` exits on non-future times; ensure US delimiter is consistently used for internal row parsing.
- `tests/ll_macos/00_harness.bash`: add BSD reference generator + canonicalization helpers; add deterministic fixtures; run ll_macos directly for parity checks.
- `tests/ll_macos/10_core.bats`: add minimal BSD reference parity matrix covering `-n`, `-g`, `-G`, `-g -G`, `--no-group`, `-o`, `-s`, `--si`, `-d`, and `--` operands.

### Test Results (Post-change)
- `make test-ll`: exit 0 (wrapper suite + macOS preflight + BSD parity).
- `make test-ll-all`: exit 0 (common + ll_linux + ll_macos on this host).
- `make test-ll-linux`: exit 0 (ll_linux suite runs under Darwin with GNU coreutils present).
- `make test-ll-macos`: exit 0 (preflight + BSD parity).
- `bats tests/ll/10_wrapper_stub.bats`: exit 0.

### Findings Resolved
- Phase 1–2 acceptance gap (macOS host): `make test-ll-linux` and `make test-ll-all` now pass when GNU coreutils are present.
- Phase 2 BSD reference generator: minimal BSD reference generator and parity tests implemented in `tests/ll_macos`.
- Phase 5 PATH control: `/usr/bin/stat` and `/usr/bin/awk` are now pinned in `scripts/bin/ll_macos`.

### Remaining / Deferred
- **DEFERRED:** Phase 6–9 items (ls-compare revision, perf/bench, unification decision) — not addressed in this patch.
- **UNKNOWN:** Soft-skip behavior for ll_linux suite on macOS **without** GNU coreutils (not verifiable on this host).
- **UNKNOWN:** Non-Darwin behavior of ll_macos suite soft-skip (requires Linux host).

Overall Verdict: NON-COMPLIANT (improved; remaining gaps are Phase 6–9 and unverified cross-OS soft-skip behavior).

## Audit Snapshot #1 (2025-01-05)

### Checklist (Phase 0–9)
- Phase 0 (baseline snapshot + determinism docs): NOT DONE. No “before” logs or determinism documentation found in repo (expected under `wip/` or docs).
- Phase 1 (binary split + thin wrapper): DONE. `scripts/bin/ll`, `scripts/bin/ll_linux`, `scripts/bin/ll_macos` present; wrapper is thin and dispatch-only.
- Phase 2 (BSD reference generator for macOS tests): DONE. `tests/ll_macos/00_harness.bash` includes BSD reference generator; parity test exists.
- Phase 3 (ll_macos MVP feature parity): NOT DONE. Implementation exists in `scripts/bin/ll_macos`, but parity coverage is limited (no full MUST coverage for symlink/edge filenames/colors).
- Phase 4 (suite split + soft-skip standard): DONE. `tests/ll/` wrapper-only, GNU tests in `tests/ll_linux/`, macOS tests in `tests/ll_macos/`.
- Phase 5 (BSD-only PATH control in env/activate): NOT DONE. `env/activate` has no LL_BSD_USERLAND/LL_NO_GNUBIN path pruning.
- Phase 6 (ls-compare revision): NOT DONE. `scripts/dev/ls-compare` remains GNU-only; no cross-impl diff wrapper.
- Phase 7 (perf bench): NOT DONE. `wip/ll-perf.md` missing.
- Phase 8 (unification decision): NOT DONE. `wip/ll-decision.md` missing.
- Phase 9 (CI/Makefile stabilization): NOT DONE. CI and Makefile are mostly aligned, but Phase 9’s full stabilization (cross-OS soft-skip verification + docs) is incomplete.

### Known Traps (must-fix)
- CI report steps do not run bats globs: DONE. Reports read `.ci-test-ll.log` (see `.github/workflows/ci.yml`).
- ll_macos internal delimiter not tab: DONE. `scripts/bin/ll_macos` uses US (0x1F) delimiter.
- tests/ll common-only: DONE. `tests/ll/10_wrapper_stub.bats` only.
- newline filename out-of-scope: NOT DONE. No explicit guard or documentation found.

### Commands Run (this host)
- `make test-ll-common` (exit 0)
  - Output: 1..7, all ok (wrapper stub tests)
- `make test-ll` (exit 0)
  - Output: wrapper tests + macOS preflight + macOS parity (2 tests)
- `make test-ll-all` (exit 0)
  - Output: wrapper suite + ll_linux suite (25 tests, 2 optional skips) + ll_macos suite (2 tests)
- `make test-ll-linux` (exit 0)
  - Output: ll_linux suite (25 tests, 2 optional skips)
- `make test-ll-macos` (exit 0)
  - Output: ll_macos suite (2 tests)

### Evidence Pointers (selected)
- Wrapper contract: `scripts/bin/ll`
- ll_linux harness + GNU baseline: `tests/ll_linux/00_harness.bash`
- ll_macos BSD reference generator: `tests/ll_macos/00_harness.bash`
- macOS parity test: `tests/ll_macos/10_core.bats`
- Makefile targets: `Makefile`
- CI log capture/report: `.github/workflows/ci.yml`
- Missing deliverables: `wip/ll-perf.md`, `wip/ll-decision.md`

## Remediation Update #1

### Changes Applied
- `tests/ll_macos/00_harness.bash`: added common fixture seeding, epoch-based touch helpers, and symlink target formatting in BSD reference generator.
- `tests/ll_macos/10_core.bats`: expanded macOS suite with MVP parity cases, tricky filename checks, time bucket/color checks, perms/owner colors, and size tier colors.
- `CHANGELOG.md`: added Commit 12 entry for macOS test coverage.

### Tests Run
- `make test-ll-macos` (exit 0)
- `make test-ll` (exit 0)

### Status Impact
- Phase 3 MVP verification: improved coverage (parity + colors + tricky filenames); still pending full Phase 5–9 deliverables.

## Remediation Update #2

### Changes Applied
- `env/activate.bash`: prune gnubin PATH entries when LL_BSD_USERLAND/LL_NO_GNUBIN is set.
- `env/activate.zsh`: same BSD-only PATH pruning for Zsh activation.
- `env/activate.fish`: same BSD-only PATH pruning for Fish activation.
- `CHANGELOG.md`: added Commit 13 entry for BSD-only PATH mode.

### Tests Run
- `make test-ll-common` (exit 0)

### Status Impact
- Phase 5 PATH control: implemented for activation scripts (requires validation with LL_BSD_USERLAND/LL_NO_GNUBIN).

## Remediation Update #3

### Changes Applied
- `scripts/dev/ll-compare`: deterministic env (LC_ALL/TZ/LL_NOW_EPOCH), robust test-case parsing, and LL_CHATGPT_FAST enforced for comparisons.
- `wip/ls-compare.md`: documented cross-impl usage for ll-compare.
- `CHANGELOG.md`: added Commit 14 entry for ll-compare revision.

### Tests Run
- `scripts/dev/ll-compare --only default ll_linux ll_linux` (exit 0)

### Status Impact
- Phase 6 ll-compare revision: implemented via deterministic cross-impl compare tool.

## Remediation Update #4

### Changes Applied
- `wip/ll-perf.md`: added performance measurements for ll_macos vs /bin/ls (1k and 10k entries).
- `CHANGELOG.md`: added Commit 15 entry for perf report.

### Tests Run
- Performance commands in `wip/ll-perf.md` (captured results).

### Status Impact
- Phase 7 perf benchmark: initial report captured (macOS host).
