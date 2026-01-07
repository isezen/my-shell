#!/usr/bin/env bash
# tests/ll_macos/00_harness.bash
set -euo pipefail

# Run with: bats tests/ll_macos/*.bats

export LC_ALL=C
export TZ=UTC
export LL_CHATGPT_FAST=1
export LL_NOW_EPOCH=1577836800

TESTS_DIR="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
PROJECT_ROOT="$(cd "${TESTS_DIR}/.." && pwd)"
LL_SCRIPT="${PROJECT_ROOT}/scripts/bin/ll"

ll_warn() {
  echo "WARNING: $*" >&2
}

ll_soft_skip() {
  ll_warn "$@"
  skip "$@"
}

ll_require_macos_userland() {
  if [ "$(uname -s)" != "Darwin" ]; then
    ll_soft_skip "ll_macos tests cannot run on Linux locally; they are validated in macOS CI. Skipping."
    return 1
  fi
  for bin in /bin/ls /usr/bin/awk /usr/bin/stat; do
    [ -x "$bin" ] || { ll_soft_skip "Required macOS binary $bin not found"; return 1; }
  done
}
