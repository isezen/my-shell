#!/usr/bin/env bats
# tests/ll_macos/10_core.bats
# Core tests for scripts/bin/ll_macos (BSD-only)

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'
load './00_harness.bash'

@test "ll_macos: preflight passes on Darwin" {
  ll_require_macos_userland || skip "Not on macOS or required binaries missing"
  # If we get here, preflight passed
  # No command was run, so we just verify we're on Darwin
  [ "$(uname -s)" = "Darwin" ]
}

