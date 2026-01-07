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

@test "ll_macos: core parity (bsd reference)" {
  local -a args

  ll_require_macos_userland || skip "Not on macOS or required binaries missing"

  ll_mk_testdir
  ll_seed_basic_fixtures

  echo "case: default files"
  args=(-- file1.txt file2.txt)
  ll_macos_assert_canon_equal "${args[@]}"

  echo "case: numeric uid/gid"
  args=(-n -- file1.txt)
  ll_macos_assert_canon_equal "${args[@]}"

  echo "case: owner off (-g)"
  args=(-g -- file1.txt)
  ll_macos_assert_canon_equal "${args[@]}"

  echo "case: group off (-G)"
  args=(-G -- file1.txt)
  ll_macos_assert_canon_equal "${args[@]}"

  echo "case: owner+group off (-g -G)"
  args=(-g -G -- file1.txt)
  ll_macos_assert_canon_equal "${args[@]}"

  echo "case: group off (--no-group)"
  args=(--no-group -- file1.txt)
  ll_macos_assert_canon_equal "${args[@]}"

  echo "case: group off (-o)"
  args=(-o -- file1.txt)
  ll_macos_assert_canon_equal "${args[@]}"

  echo "case: blocks (-s)"
  args=(-s -- file1.txt)
  ll_macos_assert_canon_equal "${args[@]}"

  echo "case: human (--si)"
  args=(--si -- file1.txt)
  ll_macos_assert_canon_equal "${args[@]}"

  echo "case: directory entry (-d)"
  args=(-d -- dir1)
  ll_macos_assert_canon_equal "${args[@]}"

  ll_rm_testdir
}
