#!/usr/bin/env bats
# Core option comparisons for scripts/bin/ll

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'
load './00_harness.bash'

@test "ll core: default" {
  local -a args=()
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll core: -d" {
  local -a args=(-d)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll core: --directory" {
  local -a args=(--directory)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll core: -d ." {
  local -a args=(-d .)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll core: -g" {
  local -a args=(-g)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll core: -G" {
  local -a args=(-G)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll core: -o" {
  local -a args=(-o)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll core: --no-group" {
  local -a args=(--no-group)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll core: -g -G" {
  local -a args=(-g -G)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll core: -s" {
  local -a args=(-s)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll core: --size" {
  local -a args=(--size)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll core: -h" {
  local -a args=(-h)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll core: --human-readable" {
  local -a args=(--human-readable)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll core: --si" {
  local -a args=(--si)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll core: -n" {
  local -a args=(-n)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll core: --numeric-uid-gid" {
  local -a args=(--numeric-uid-gid)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll core: -s -h" {
  local -a args=(-s -h)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll core: -s --si" {
  local -a args=(-s --si)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll core: -n -h" {
  local -a args=(-n -h)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll core: -n --si" {
  local -a args=(-n --si)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll core: -s -g" {
  local -a args=(-s -g)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll core: -s -h -g -G" {
  local -a args=(-s -h -g -G)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}
