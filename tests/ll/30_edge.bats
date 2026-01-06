#!/usr/bin/env bats
# Edge-case comparisons for scripts/bin/ll

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'
load './00_harness.bash'

@test "ll edge: symlink target space" {
  ll_mk_testdir
  printf "space" > "target file.txt"
  ln -s "target file.txt" "link name.txt" 2>/dev/null || true
  touch -t 202001010000.00 "target file.txt"
  touch -h -t 202001010000.00 "link name.txt" 2>/dev/null || true
  ll_assert_canon_equal
  ll_rm_testdir
}

@test "ll edge: symlink target tab" {
  local tab_target
  local tab_link

  ll_mk_testdir
  tab_target=$'t\ta'
  tab_link=$'l\ti'
  printf "tab" > "${tab_target}"
  ln -s "${tab_target}" "${tab_link}" 2>/dev/null || true
  touch -t 202001010000.00 "${tab_target}"
  touch -h -t 202001010000.00 "${tab_link}" 2>/dev/null || true
  ll_assert_canon_equal
  ll_rm_testdir
}

@test "ll edge: mixed time widths" {
  ll_mk_testdir
  printf "" > old.txt
  printf "" > new.txt
  touch -d '120 days ago' old.txt
  touch -d '2 days ago' new.txt
  ll_assert_canon_equal
  ll_rm_testdir
}

@test "ll edge: future-only prefix column" {
  local f1_str
  local f2_str

  ll_mk_testdir
  printf "" > f1.txt
  printf "" > f2.txt
  f1_str="$(date -d '2 days' '+%Y-%m-%d %H:%M:%S')"
  f2_str="$(date -d '12 days' '+%Y-%m-%d %H:%M:%S')"
  touch -d "${f1_str}" f1.txt
  touch -d "${f2_str}" f2.txt
  ll_assert_canon_equal
  ll_rm_testdir
}
