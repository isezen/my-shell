#!/usr/bin/env bats
# Color output checks for scripts/bin/ll

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'
load './00_harness.bash'

@test "ll colors: future time uses cfut" {
  local f1_str
  local f2_str

  ll_mk_testdir
  printf "" > f1.txt
  printf "" > f2.txt
  f1_str="$(date -d '2 days' '+%Y-%m-%d %H:%M:%S')"
  f2_str="$(date -d '12 days' '+%Y-%m-%d %H:%M:%S')"
  touch -d "${f1_str}" f1.txt
  touch -d "${f2_str}" f2.txt

  run "${LL_SCRIPT}" .
  assert_success

  local esc=$'\033'
  assert_output --partial "${esc}[38;5;39m"

  ll_rm_testdir
}

@test "ll colors: time bucket colors" {
  local now
  local esc

  ll_mk_testdir
  now="${LL_NOW_EPOCH}"

  touch -d "@${now}" base.txt
  touch -d "@$((now - 30))" sec.txt
  touch -d "@$((now - 600))" min.txt
  touch -d "@$((now - 3 * 3600))" hrs.txt
  touch -d "@$((now - 5 * 86400))" day.txt
  touch -d "@$((now - 120 * 86400))" mon.txt
  touch -d "@$((now - 400 * 86400))" yr.txt

  run "${LL_SCRIPT}" .
  assert_success

  esc=$'\033'
  assert_output --partial "${esc}[38;5;124m"
  assert_output --partial "${esc}[38;5;215m"
  assert_output --partial "${esc}[38;5;196m"
  assert_output --partial "${esc}[38;5;230m"
  assert_output --partial "${esc}[38;5;151m"
  assert_output --partial "${esc}[38;5;241m"

  ll_rm_testdir
}

@test "ll colors: perms codes" {
  local esc

  ll_mk_testdir
  mkdir d1
  touch xfile
  chmod 755 xfile
  ln -s xfile lnk 2>/dev/null || true

  run "${LL_SCRIPT}" .
  assert_success

  esc=$'\033'
  assert_output --partial "${esc}[38;5;122m"
  assert_output --partial "${esc}[38;5;190m"
  assert_output --partial "${esc}[38;5;119m"
  assert_output --partial "${esc}[38;5;216m"
  assert_output --partial "${esc}[38;5;124m"

  ll_rm_testdir
}

@test "ll colors: perms plus (optional)" {
  local esc

  if ! command -v setfacl >/dev/null 2>&1; then
    skip "setfacl not available"
  fi
  if ! command -v getfacl >/dev/null 2>&1; then
    skip "getfacl not available"
  fi

  ll_mk_testdir
  touch aclfile
  if ! setfacl -m u::rwx aclfile; then
    ll_rm_testdir
    skip "setfacl failed"
  fi

  run "${LL_SCRIPT}" .
  assert_success

  esc=$'\033'
  assert_output --partial "${esc}[38;5;129m"

  ll_rm_testdir
}

@test "ll colors: owner you" {
  local esc

  ll_mk_testdir
  touch youfile

  run "${LL_SCRIPT}" .
  assert_success

  esc=$'\033'
  assert_output --partial "${esc}[38;5;66m"

  ll_rm_testdir
}

@test "ll colors: owner root (optional)" {
  local esc

  if ! command -v sudo >/dev/null 2>&1; then
    skip "sudo not available"
  fi
  if ! sudo -n true >/dev/null 2>&1; then
    skip "sudo not permitted"
  fi

  ll_mk_testdir
  touch rootfile
  if ! sudo chown root:root rootfile; then
    ll_rm_testdir
    skip "sudo chown failed"
  fi

  run "${LL_SCRIPT}" .
  assert_success

  esc=$'\033'
  assert_output --partial "${esc}[38;5;160m"

  ll_rm_testdir
}

@test "ll colors: size tiers (numeric)" {
  local esc
  local -a expected

  if ! command -v truncate >/dev/null 2>&1; then
    skip "truncate not available"
  fi

  ll_mk_testdir
  esc=$'\033'
  expected=()

  if truncate -s 2K kfile; then
    expected+=("${esc}[38;5;250m")
  fi
  if truncate -s 2M mfile; then
    expected+=("${esc}[38;5;117m")
  fi
  if truncate -s 2G gfile; then
    expected+=("${esc}[38;5;208m")
  fi
  if truncate -s 2T tfile; then
    expected+=("${esc}[38;5;160m")
  fi

  if [ "${#expected[@]}" -eq 0 ]; then
    ll_rm_testdir
    skip "truncate failed to create size files"
  fi

  run "${LL_SCRIPT}" .
  assert_success

  for code in "${expected[@]}"; do
    assert_output --partial "$code"
  done

  ll_rm_testdir
}

@test "ll colors: size labels (human)" {
  local esc

  if ! command -v truncate >/dev/null 2>&1; then
    skip "truncate not available"
  fi

  ll_mk_testdir
  if ! truncate -s 2K kfile; then
    ll_rm_testdir
    skip "truncate failed"
  fi
  if ! truncate -s 2M mfile; then
    ll_rm_testdir
    skip "truncate failed"
  fi

  run "${LL_SCRIPT}" -h .
  assert_success

  esc=$'\033'
  assert_output --partial "${esc}[1;38;5;107m"
  assert_output --partial "${esc}[1;38;5;123m"

  ll_rm_testdir
}
