#!/usr/bin/env bats
# Path and filename comparisons for scripts/bin/ll

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'
load './00_harness.bash'

@test "ll paths: -h file1.txt" {
  local -a args=(-h file1.txt)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll paths: a b.txt" {
  local -a args=(-- "a b.txt")
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll paths: leading space file" {
  local -a args=(-- " file-leading-space.txt")
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll paths: tab file" {
  local -a args=(-- $'a\tb.txt')
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll paths: unicode file" {
  local -a args=(-- "İçerik-ğüşöç.txt")
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll paths: link-to-file1" {
  local -a args=(-- link-to-file1)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll paths: broken-link" {
  local -a args=(-- broken-link)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll paths: fifo1" {
  local -a args=(-- fifo1)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll paths: setuid-file" {
  local -a args=(-- setuid-file)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll paths: setgid-file" {
  local -a args=(-- setgid-file)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll paths: sticky-dir" {
  local -a args=(-- sticky-dir)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll paths: future.txt" {
  local -a args=(-- future.txt)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}
