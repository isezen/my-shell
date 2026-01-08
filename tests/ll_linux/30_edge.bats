#!/usr/bin/env bats
# tests/ll_linux/30_edge.bats
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

@test "ll edge: mixed time widths (future years)" {
  local now
  local sec_epoch
  local hrs_epoch
  local day_epoch
  local mon_epoch
  local future_3yr
  local future_35yr
  local future_125yr
  local future_1000yr

  ll_require_gnu_touch

  ll_mk_testdir
  now="${LL_NOW_EPOCH}"

  printf "" > sec.txt
  printf "" > hrs.txt
  printf "" > day.txt
  printf "" > mon.txt
  printf "" > future-3yr.txt
  printf "" > future-35yr.txt
  printf "" > future-125yr.txt
  printf "" > future-1000yr.txt

  sec_epoch=$((now - 5))
  hrs_epoch=$((now - 3 * 3600))
  day_epoch=$((now - 12 * 24 * 3600))
  mon_epoch=$((now - 120 * 24 * 3600))
  future_3yr=$((now + 3 * 31536000))
  future_35yr=$((now + 35 * 31536000))
  future_125yr=$((now + 125 * 31536000))
  future_1000yr=9223372036

  "${LL_GNU_TOUCH}" -d "@${sec_epoch}" sec.txt
  "${LL_GNU_TOUCH}" -d "@${hrs_epoch}" hrs.txt
  "${LL_GNU_TOUCH}" -d "@${day_epoch}" day.txt
  "${LL_GNU_TOUCH}" -d "@${mon_epoch}" mon.txt
  "${LL_GNU_TOUCH}" -d "@${future_3yr}" future-3yr.txt
  "${LL_GNU_TOUCH}" -d "@${future_35yr}" future-35yr.txt
  "${LL_GNU_TOUCH}" -d "@${future_125yr}" future-125yr.txt
  if ! "${LL_GNU_TOUCH}" -d "@${future_1000yr}" future-1000yr.txt; then
    ll_rm_testdir
    skip "touch does not support large epoch ${future_1000yr}"
  fi

  ll_assert_canon_equal
  ll_rm_testdir
}

@test "ll edge: future-only prefix column" {
  local f1_str
  local f2_str

  ll_require_gnu_date
  ll_require_gnu_touch

  ll_mk_testdir
  printf "" > f1.txt
  printf "" > f2.txt
  f1_str="$("${LL_GNU_DATE}" -d '2 days' '+%Y-%m-%d %H:%M:%S')"
  f2_str="$("${LL_GNU_DATE}" -d '12 days' '+%Y-%m-%d %H:%M:%S')"
  "${LL_GNU_TOUCH}" -d "${f1_str}" f1.txt
  "${LL_GNU_TOUCH}" -d "${f2_str}" f2.txt
  ll_assert_canon_equal
  ll_rm_testdir
}
