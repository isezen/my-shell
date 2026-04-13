#!/usr/bin/env bats
# tests/ll_linux/40_color.bats
# Color output checks for scripts/bin/ll

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'
load './00_harness.bash'

@test "ll colors: future time uses cfut" {
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

  LL_NO_COLOR=0 run "${LL_SCRIPT}" .
  assert_success

  local esc=$'\033'
  assert_output --partial "${esc}[38;5;39m"

  ll_rm_testdir
}

@test "ll colors: time bucket colors" {
  local now
  local esc

  ll_require_gnu_touch

  ll_mk_testdir
  now="${LL_NOW_EPOCH}"

  "${LL_GNU_TOUCH}" -d "@${now}" base.txt
  "${LL_GNU_TOUCH}" -d "@$((now - 30))" sec.txt
  "${LL_GNU_TOUCH}" -d "@$((now - 600))" min.txt
  "${LL_GNU_TOUCH}" -d "@$((now - 3 * 3600))" hrs.txt
  "${LL_GNU_TOUCH}" -d "@$((now - 5 * 86400))" day.txt
  "${LL_GNU_TOUCH}" -d "@$((now - 120 * 86400))" mon.txt
  "${LL_GNU_TOUCH}" -d "@$((now - 400 * 86400))" yr.txt

  LL_NO_COLOR=0 run "${LL_SCRIPT}" .
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

  LL_NO_COLOR=0 run "${LL_SCRIPT}" .
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

  if [ -z "${LL_GNU_LS:-}" ]; then
    ll_rm_testdir
    skip "GNU ls required"
  fi

  run ll_run_ls -- aclfile
  if [ "$status" -ne 0 ]; then
    ll_rm_testdir
    skip "ls failed"
  fi

  local ls_clean
  ls_clean="$(ll_strip_ansi_and_controls "$output")"
  if ! [[ "$ls_clean" =~ ^[-bcdlps][rwxstST-]{9}\+ ]]; then
    ll_rm_testdir
    skip "ACL marker '+' not present"
  fi

  LL_NO_COLOR=0 run "${LL_SCRIPT}" .
  assert_success

  esc=$'\033'
  assert_output --partial "${esc}[38;5;129m"

  ll_rm_testdir
}

@test "ll colors: owner you" {
  local esc

  ll_mk_testdir
  touch youfile

  LL_NO_COLOR=0 run "${LL_SCRIPT}" .
  assert_success

  esc=$'\033'
  assert_output --partial "${esc}[38;5;66m"

  ll_rm_testdir
}

@test "ll colors: owner root (optional)" {
  local esc
  local os
  local chown_ok
  local wheel_ok

  # When the test runner itself is root (e.g. a CI container), ll_linux's
  # "you" substitution replaces owner=root with "you" and colors it with
  # cusr, never reaching the croot branch. Skip in that case — the colored
  # root case can only be exercised by a non-root user.
  if [ "$(id -u)" = "0" ]; then
    skip "test runner is root; 'you' substitution hides the croot color path"
  fi
  if ! command -v sudo >/dev/null 2>&1; then
    skip "sudo not available"
  fi
  if ! sudo -n true >/dev/null 2>&1; then
    skip "sudo not permitted"
  fi

  ll_mk_testdir
  touch rootfile
  os="$(uname -s 2>/dev/null || printf 'unknown')"
  chown_ok=0
  wheel_ok=1

  if [ "$os" = "Darwin" ]; then
    if command -v dscl >/dev/null 2>&1; then
      if ! dscl . -read /Groups/wheel >/dev/null 2>&1; then
        wheel_ok=0
      fi
    elif command -v dseditgroup >/dev/null 2>&1; then
      if ! dseditgroup -o read wheel >/dev/null 2>&1; then
        wheel_ok=0
      fi
    fi

    if [ "$wheel_ok" -eq 1 ]; then
      if sudo chown root:wheel rootfile >/dev/null 2>&1; then
        chown_ok=1
      fi
    fi

    if [ "$chown_ok" -ne 1 ]; then
      if sudo chown root:0 rootfile >/dev/null 2>&1; then
        chown_ok=1
      fi
    fi
  else
    if sudo chown root:root rootfile >/dev/null 2>&1; then
      chown_ok=1
    fi
  fi

  if [ "$chown_ok" -ne 1 ]; then
    ll_rm_testdir
    skip "sudo chown not supported"
  fi

  LL_NO_COLOR=0 run "${LL_SCRIPT}" .
  assert_success

  esc=$'\033'
  assert_output --partial "${esc}[38;5;160m"

  ll_rm_testdir
}

@test "ll colors: size tiers (numeric)" {
  local esc

  if ! command -v truncate >/dev/null 2>&1; then
    skip "truncate not available"
  fi

  ll_mk_testdir
  esc=$'\033'

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
  if ! truncate -s 1099511627776 tfile; then
    ll_rm_testdir
    skip "truncate failed for tfile"
  fi

  LL_NO_COLOR=0 run "${LL_SCRIPT}" -- bfile kfile mfile gfile tfile
  assert_success

  assert_output --regexp "${esc}\\[38;5;240m[[:space:]]*512${esc}\\[0m.*bfile"
  assert_output --regexp "${esc}\\[38;5;250m[[:space:]]*2048${esc}\\[0m.*kfile"
  assert_output --regexp "${esc}\\[38;5;117m[[:space:]]*2097152${esc}\\[0m.*mfile"
  assert_output --regexp "${esc}\\[38;5;208m[[:space:]]*1073741824${esc}\\[0m.*gfile"
  assert_output --regexp "${esc}\\[38;5;160m[[:space:]]*1099511627776${esc}\\[0m.*tfile"

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

  LL_NO_COLOR=0 run "${LL_SCRIPT}" -h .
  assert_success

  esc=$'\033'
  assert_output --partial "${esc}[1;38;5;107m"
  assert_output --partial "${esc}[1;38;5;123m"

  ll_rm_testdir
}
