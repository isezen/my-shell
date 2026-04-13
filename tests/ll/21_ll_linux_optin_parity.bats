#!/usr/bin/env bats
# Phase 1 opt-in parity test.
#
# Ensures that ll_linux running under LL_USE_COMMON_AWK=1 (the new common-awk
# path) produces byte-identical output to the default inline standalone path
# across all 52 ll-compare fixture cases, WITH COLORS ENABLED.
#
# Why LL_NO_COLOR=0 (colors on):
#   * The default standalone path silently ignores LL_NO_COLOR (pre-existing
#     gap in ll_linux's inline AWK_PROG), so NO_COLOR=1 results in the two
#     modes legitimately disagreeing (standalone emits colors, common-awk
#     path honours NO_COLOR). Phase 2 closes that gap by deleting the inline
#     path; until then, color-on is the only regime in which the two paths
#     are expected to be byte-identical.
#   * Color-on parity is the stronger proof anyway: if the rendered ANSI
#     streams match byte-for-byte, every downstream consumer matches too.
#
# Skip rules:
#   * Always skipped on hosts without GNU coreutils reachable (probes
#     MacPorts/Homebrew gnubin paths).

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'

setup() {
  PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  LL_COMPARE="${PROJECT_ROOT}/scripts/dev/ll-compare"
  STANDALONE_DIR="${BATS_TEST_TMPDIR}/standalone"
  OPTIN_DIR="${BATS_TEST_TMPDIR}/optin"
  mkdir -p "${STANDALONE_DIR}" "${OPTIN_DIR}"

  export LC_ALL=C
  export TZ=UTC
  export LL_NO_COLOR=0
  export LL_NOW_EPOCH=1577836800
}

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

@test "ll_linux opt-in parity: standalone vs LL_USE_COMMON_AWK=1 byte-equal across fixtures" {
  if ! _ll_linux_available; then
    skip "GNU coreutils not available"
  fi

  # Standalone run (default inline AWK_PROG_STANDALONE path)
  unset LL_USE_COMMON_AWK
  "${LL_COMPARE}" --snapshot "${STANDALONE_DIR}" --fail-only ll_linux >/dev/null

  # Opt-in run (new common+ll_linux.awk path)
  export LL_USE_COMMON_AWK=1
  "${LL_COMPARE}" --snapshot "${OPTIN_DIR}" --fail-only ll_linux >/dev/null
  unset LL_USE_COMMON_AWK

  run diff -ruN "${STANDALONE_DIR}/ll_linux" "${OPTIN_DIR}/ll_linux"
  assert_success
}
