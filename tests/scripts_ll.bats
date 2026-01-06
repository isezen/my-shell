#!/usr/bin/env bats
# tests/scripts_ll.bats
# Deprecated: use tests/ll/*.bats for ll comparisons

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

@test "ll tests moved to new suite" {
  run echo "Deprecated: run bats tests/ll/*.bats"
  assert_success
}
