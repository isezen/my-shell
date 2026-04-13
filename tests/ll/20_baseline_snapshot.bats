#!/usr/bin/env bats
# Phase 0 baseline regression lock.
#
# Regenerates ll_linux/ll_macos outputs via scripts/dev/ll-compare --snapshot
# into a temp directory and diffs byte-for-byte against tests/fixtures/ll_baseline/.
# Any drift fails the test with a human-readable diff.
#
# Deterministic env (matches how the baselines were captured):
#   LC_ALL=C TZ=UTC LL_NO_COLOR=1 LL_NOW_EPOCH=1577836800
#
# Skip rules:
#   - ll_macos snapshot is only checked on Darwin
#   - ll_linux snapshot is only checked when GNU ls/awk/stat are reachable
#     (native Linux, or macOS with MacPorts/Homebrew coreutils in PATH)

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'

setup() {
  PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  BASELINE_DIR="${PROJECT_ROOT}/tests/fixtures/ll_baseline"
  LL_COMPARE="${PROJECT_ROOT}/scripts/dev/ll-compare"
  SNAP_TMPDIR="${BATS_TEST_TMPDIR}/baseline-snap"
  mkdir -p "${SNAP_TMPDIR}"

  export LC_ALL=C
  export TZ=UTC
  export LL_NO_COLOR=1
  export LL_NOW_EPOCH=1577836800
}

# Ensure GNU coreutils are reachable for ll_linux. On macOS we look up the
# MacPorts / Homebrew gnubin paths and prepend them so ll_linux's own coreutils
# probing succeeds.
_ll_linux_available() {
  if ls --color -l --time-style=+"%s" . >/dev/null 2>&1; then
    return 0
  fi
  local p
  for p in /opt/local/libexec/gnubin /opt/homebrew/opt/coreutils/libexec/gnubin /usr/local/opt/coreutils/libexec/gnubin; do
    if [ -x "$p/ls" ]; then
      export PATH="$p:$PATH"
      return 0
    fi
  done
  return 1
}

_run_snapshot() {
  local driver="$1"
  "${LL_COMPARE}" --snapshot "${SNAP_TMPDIR}" --fail-only "${driver}" >/dev/null
}

_diff_baseline() {
  local driver="$1"
  local got="${SNAP_TMPDIR}/${driver}"
  local want="${BASELINE_DIR}/${driver}"

  if [ ! -d "$want" ]; then
    skip "baseline missing: $want"
  fi

  if ! diff -ruN "$want" "$got"; then
    return 1
  fi
}

@test "ll baseline: ll_macos snapshot matches tests/fixtures/ll_baseline/ll_macos" {
  if [ "$(uname -s)" != "Darwin" ]; then
    skip "ll_macos requires Darwin (BSD userland)"
  fi

  _run_snapshot ll_macos
  _diff_baseline ll_macos
}

@test "ll baseline: ll_linux snapshot matches tests/fixtures/ll_baseline/ll_linux" {
  if ! _ll_linux_available; then
    skip "GNU coreutils not available (install coreutils for macOS or run on Linux)"
  fi

  _run_snapshot ll_linux
  _diff_baseline ll_linux
}
