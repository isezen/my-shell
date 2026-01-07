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
  ll_seed_fixtures_common

  echo "case: default"
  args=()
  ll_macos_assert_canon_equal "${args[@]}"

  echo "case: numeric uid/gid"
  args=(-n)
  ll_macos_assert_canon_equal "${args[@]}"

  echo "case: numeric uid/gid (long)"
  args=(--numeric-uid-gid)
  ll_macos_assert_canon_equal "${args[@]}"

  echo "case: owner off (-g)"
  args=(-g)
  ll_macos_assert_canon_equal "${args[@]}"

  echo "case: group off (-G)"
  args=(-G)
  ll_macos_assert_canon_equal "${args[@]}"

  echo "case: owner+group off (-g -G)"
  args=(-g -G)
  ll_macos_assert_canon_equal "${args[@]}"

  echo "case: group off (--no-group)"
  args=(--no-group)
  ll_macos_assert_canon_equal "${args[@]}"

  echo "case: group off (-o)"
  args=(-o)
  ll_macos_assert_canon_equal "${args[@]}"

  echo "case: blocks (-s)"
  args=(-s)
  ll_macos_assert_canon_equal "${args[@]}"

  echo "case: human (--si)"
  args=(--si)
  ll_macos_assert_canon_equal "${args[@]}"

  echo "case: directory entry (-d)"
  args=(-d -- dir1)
  ll_macos_assert_canon_equal "${args[@]}"

  echo "case: directory entry (--directory)"
  args=(--directory -- dir1)
  ll_macos_assert_canon_equal "${args[@]}"

  echo "case: sentinel with space filename"
  args=(-- "a b.txt")
  ll_macos_assert_canon_equal "${args[@]}"

  ll_rm_testdir
}

@test "ll_macos: tricky filenames preserved" {
  ll_require_macos_userland || skip "Not on macOS or required binaries missing"

  ll_mk_testdir
  ll_seed_fixtures_common

  run ll_macos_run_ll -- "a b.txt" " file-leading-space.txt" $'a\tb.txt' "İçerik-ğüşöç.txt"
  assert_success

  assert_output --partial '"a b.txt"'
  assert_output --partial '" file-leading-space.txt"'
  assert_output --partial $'"a\tb.txt"'
  assert_output --partial 'İçerik-ğüşöç.txt'

  ll_rm_testdir
}

@test "ll_macos: symlink arrows preserved" {
  ll_require_macos_userland || skip "Not on macOS or required binaries missing"

  ll_mk_testdir
  ll_seed_fixtures_common

  run ll_macos_run_ll -- link-to-file1 broken-link
  assert_success

  assert_output --partial "link-to-file1 -> file1.txt"
  assert_output --partial "broken-link -> missing-target"

  ll_rm_testdir
}

@test "ll_macos: time buckets and colors" {
  local now
  local clean
  local esc

  ll_require_macos_userland || skip "Not on macOS or required binaries missing"

  ll_mk_testdir
  now="${LL_NOW_EPOCH}"

  printf '' > sec.txt
  printf '' > min.txt
  printf '' > hrs.txt
  printf '' > day.txt
  printf '' > mon.txt
  printf '' > yr.txt
  printf '' > fut.txt

  if ! ll_touch_epoch sec.txt $((now - 30)); then
    ll_rm_testdir
    skip "date -r required for time fixtures"
  fi
  ll_touch_epoch min.txt $((now - 600)) || { ll_rm_testdir; skip "date -r required for time fixtures"; }
  ll_touch_epoch hrs.txt $((now - 3 * 3600)) || { ll_rm_testdir; skip "date -r required for time fixtures"; }
  ll_touch_epoch day.txt $((now - 5 * 86400)) || { ll_rm_testdir; skip "date -r required for time fixtures"; }
  ll_touch_epoch mon.txt $((now - 120 * 86400)) || { ll_rm_testdir; skip "date -r required for time fixtures"; }
  ll_touch_epoch yr.txt $((now - 400 * 86400)) || { ll_rm_testdir; skip "date -r required for time fixtures"; }
  ll_touch_epoch fut.txt $((now + 2 * 86400)) || { ll_rm_testdir; skip "date -r required for time fixtures"; }

  run ll_macos_run_ll .
  assert_success

  clean="$(ll_strip_ansi_and_controls "$output")"
  [[ "$clean" == *" sec"* ]]
  [[ "$clean" == *" min"* ]]
  [[ "$clean" == *" hrs"* ]]
  [[ "$clean" == *" day"* ]]
  [[ "$clean" == *" mon"* ]]
  [[ "$clean" == *" yr"* ]]
  [[ "$clean" == *"in "* ]]

  esc=$'\033'
  assert_output --partial "${esc}[38;5;124m"
  assert_output --partial "${esc}[38;5;215m"
  assert_output --partial "${esc}[38;5;196m"
  assert_output --partial "${esc}[38;5;230m"
  assert_output --partial "${esc}[38;5;151m"
  assert_output --partial "${esc}[38;5;241m"
  assert_output --partial "${esc}[38;5;39m"

  ll_rm_testdir
}

@test "ll_macos: perms and owner colors" {
  local esc

  ll_require_macos_userland || skip "Not on macOS or required binaries missing"

  ll_mk_testdir
  mkdir d1
  touch xfile
  chmod 755 xfile
  ln -s xfile lnk 2>/dev/null || true

  run ll_macos_run_ll .
  assert_success

  esc=$'\033'
  assert_output --partial "${esc}[38;5;122m"
  assert_output --partial "${esc}[38;5;190m"
  assert_output --partial "${esc}[38;5;119m"
  assert_output --partial "${esc}[38;5;216m"
  assert_output --partial "${esc}[38;5;124m"
  assert_output --partial "${esc}[38;5;66m"

  ll_rm_testdir
}

@test "ll_macos: size tier colors (numeric)" {
  local esc
  local -a files

  ll_require_macos_userland || skip "Not on macOS or required binaries missing"

  if ! command -v truncate >/dev/null 2>&1; then
    skip "truncate not available"
  fi

  ll_mk_testdir

  if ! truncate -s 512 bfile; then
    ll_rm_testdir
    skip "truncate failed for bfile"
  fi
  if ! truncate -s 2048 kfile; then
    ll_rm_testdir
    skip "truncate failed for kfile"
  fi
  if ! truncate -s 2097152 mfile; then
    ll_rm_testdir
    skip "truncate failed for mfile"
  fi
  if ! truncate -s 1073741824 gfile; then
    ll_rm_testdir
    skip "truncate failed for gfile"
  fi

  files=(bfile kfile mfile gfile)
  if truncate -s 1099511627776 tfile; then
    files+=(tfile)
  fi

  run ll_macos_run_ll -- "${files[@]}"
  assert_success

  esc=$'\033'
  assert_output --regexp "${esc}\\[38;5;240m[[:space:]]*512${esc}\\[0m.*bfile"
  assert_output --regexp "${esc}\\[38;5;250m[[:space:]]*2048${esc}\\[0m.*kfile"
  assert_output --regexp "${esc}\\[38;5;117m[[:space:]]*2097152${esc}\\[0m.*mfile"
  assert_output --regexp "${esc}\\[38;5;208m[[:space:]]*1073741824${esc}\\[0m.*gfile"

  if [ "${#files[@]}" -gt 4 ]; then
    assert_output --regexp "${esc}\\[38;5;160m[[:space:]]*1099511627776${esc}\\[0m.*tfile"
  fi

  ll_rm_testdir
}
