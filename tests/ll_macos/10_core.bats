#!/usr/bin/env bats
# Core tests for scripts/bin/ll_macos (BSD-only)

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'
load './00_harness.bash'

@test "ll_macos: preflight passes on Darwin" {
  ll_require_macos_userland
  # If we get here, preflight passed
  assert_success
}

