#!/usr/bin/env bats
# tests/ll_linux/20_paths.bats
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

@test "ll paths: symlink-to-file1" {
  local -a args=(-- symlink-to-file1)
  ll_mk_testdir
  ll_seed_fixtures_common
  ll_assert_canon_equal "${args[@]}"
  ll_rm_testdir
}

@test "ll paths: broken-symlink" {
  local -a args=(-- broken-symlink)
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

@test "ll paths: setgid-dir" {
  local -a args=(-- setgid-dir)
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

@test "ll paths: hidden files default excluded" {
  ll_mk_testdir
  ll_seed_fixtures_common

  ll_capture_ll
  if [ "$LL_CAPTURE_STATUS" -ne 0 ]; then
    ll_fail "expected ll to succeed, got status $LL_CAPTURE_STATUS"
  fi
  ll_set_compare_env
  ll_canon="$(ll_canon_ll "$LL_CAPTURE_STDOUT")"
  if printf '%s\n' "$ll_canon" | grep -Fq ".hidden_file"; then
    ll_fail "expected .hidden_file to be excluded without -a/-A"
  fi

  ll_rm_testdir
}

@test "ll paths: -a includes hidden and dot entries" {
  local ls_out
  local ll_out
  local ls_canon
  local ll_canon

  ll_mk_testdir
  ll_seed_fixtures_common

  ll_capture_ls -a
  if [ "$LL_CAPTURE_STATUS" -ne 0 ]; then
    ll_fail "expected ls to succeed, got status $LL_CAPTURE_STATUS"
  fi
  ls_out="$LL_CAPTURE_STDOUT"

  ll_capture_ll -a
  if [ "$LL_CAPTURE_STATUS" -ne 0 ]; then
    ll_fail "expected ll to succeed, got status $LL_CAPTURE_STATUS"
  fi
  ll_out="$LL_CAPTURE_STDOUT"

  ll_set_compare_env -a
  ll_canon="$(ll_canon_ll "$ll_out")"
  if ! printf '%s\n' "$ll_canon" | grep -Fq ".hidden_file"; then
    ll_fail "expected .hidden_file to be included with -a"
  fi
  if ! printf '%s\n' "$ll_canon" | grep -Eq '[[:space:]]\.[[:space:]]*$'; then
    ll_fail "expected '.' entry to be included with -a"
  fi
  if ! printf '%s\n' "$ll_canon" | grep -Eq '[[:space:]]\.\.[[:space:]]*$'; then
    ll_fail "expected '..' entry to be included with -a"
  fi

  ls_canon="$(ll_canon_ls "$ls_out")"
  if [ "$ll_canon" != "$ls_canon" ]; then
    ll_fail "canonicalized -a output mismatch"
  fi

  ll_rm_testdir
}

@test "ll paths: -A includes hidden but excludes dot entries" {
  local ls_out
  local ll_out
  local ls_canon
  local ll_canon

  ll_mk_testdir
  ll_seed_fixtures_common

  ll_capture_ls -A
  if [ "$LL_CAPTURE_STATUS" -ne 0 ]; then
    ll_fail "expected ls to succeed, got status $LL_CAPTURE_STATUS"
  fi
  ls_out="$LL_CAPTURE_STDOUT"

  ll_capture_ll -A
  if [ "$LL_CAPTURE_STATUS" -ne 0 ]; then
    ll_fail "expected ll to succeed, got status $LL_CAPTURE_STATUS"
  fi
  ll_out="$LL_CAPTURE_STDOUT"

  ll_set_compare_env -A
  ll_canon="$(ll_canon_ll "$ll_out")"
  if ! printf '%s\n' "$ll_canon" | grep -Fq ".hidden_file"; then
    ll_fail "expected .hidden_file to be included with -A"
  fi
  if printf '%s\n' "$ll_canon" | grep -Eq '[[:space:]]\.[[:space:]]*$'; then
    ll_fail "expected '.' entry to be excluded with -A"
  fi
  if printf '%s\n' "$ll_canon" | grep -Eq '[[:space:]]\.\.[[:space:]]*$'; then
    ll_fail "expected '..' entry to be excluded with -A"
  fi

  ls_canon="$(ll_canon_ls "$ls_out")"
  if [ "$ll_canon" != "$ls_canon" ]; then
    ll_fail "canonicalized -A output mismatch"
  fi

  ll_rm_testdir
}
