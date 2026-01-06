#!/usr/bin/env bash
set -euo pipefail

# Run with: bats tests/ll/*.bats

export LC_ALL=C
export TZ=UTC
export LL_CHATGPT_FAST=1
export LL_NOW_EPOCH=1577836800

TESTS_DIR="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
PROJECT_ROOT="$(cd "${TESTS_DIR}/.." && pwd)"
LL_SCRIPT="${PROJECT_ROOT}/scripts/bin/ll"

ll_mk_testdir() {
  LL_TEST_DIR_TMP="$(mktemp -d)"
  LL_TEST_DIR_OLD="${PWD}"
  cd "${LL_TEST_DIR_TMP}"
}

ll_rm_testdir() {
  if [ -n "${LL_TEST_DIR_TMP:-}" ] && [ -d "${LL_TEST_DIR_TMP}" ]; then
    cd /tmp || cd "${LL_TEST_DIR_OLD:-/tmp}" || true
    rm -rf "${LL_TEST_DIR_TMP}"
  fi

  if [ -n "${LL_TEST_DIR_OLD:-}" ] && [ -d "${LL_TEST_DIR_OLD}" ]; then
    cd "${LL_TEST_DIR_OLD}" || true
  fi

  LL_TEST_DIR_TMP=""
}

ll_seed_fixtures_common() {
  local long_name
  local tab_name

  touch file1.txt file2.txt
  mkdir dir1 dir2
  echo "test" > file3.txt
  chmod 755 file1.txt
  chmod 644 file2.txt

  printf "space" > "a b.txt"
  printf "lead" > " file-leading-space.txt"
  tab_name=$'a\tb.txt'
  printf "tab" > "${tab_name}"
  printf "utf" > "İçerik-ğüşöç.txt"
  long_name="$(printf 'a%.0s' {1..210}).txt"
  printf "long" > "${long_name}"

  ln -s "file1.txt" "link-to-file1" 2>/dev/null || true
  ln -s "missing-target" "broken-link" 2>/dev/null || true
  mkfifo "fifo1" 2>/dev/null || true

  cp "file1.txt" "setuid-file" 2>/dev/null || true
  chmod 4755 "setuid-file" 2>/dev/null || true
  cp "file1.txt" "setgid-file" 2>/dev/null || true
  chmod 2755 "setgid-file" 2>/dev/null || true
  mkdir -p "sticky-dir" 2>/dev/null || true
  chmod 1777 "sticky-dir" 2>/dev/null || true

  printf "future" > "future.txt"

  touch -t 202001010000.00 \
    file1.txt file2.txt file3.txt dir1 dir2 \
    "a b.txt" " file-leading-space.txt" "${tab_name}" "İçerik-ğüşöç.txt" \
    "${long_name}" link-to-file1 broken-link fifo1 setuid-file setgid-file sticky-dir future.txt

  touch -t 203001010000.00 future.txt 2>/dev/null || true
}

ll_strip_ansi_and_controls() {
  local text="$1"

  text=$(printf '%s' "$text" | perl -pe '
    s/\e\[[0-9;?]*[ -\/]*[@-~]//g;          # CSI ... cmd (colors, erase-in-line, etc.)
    s/\e\][^\a]*(\a|\e\\)//g;              # OSC ... BEL or ST
    s/\e[P^_].*?(\e\\)//gs;                # DCS/PM/APC ... ST
    s/\e[()#][0-9A-Za-z]//g;               # Charset selects
    s/\e[\x40-\x5F]//g;                    # 2-char ESC sequences
    s/\x1b\[[0-9;]*K//g;                   # Erase in line
    s/\r//g;                               # CR
  ')

  text=$(printf '%s' "$text" | tr -d '\v')
  printf '%s' "$text"
}

ll_drop_ls_totals() {
  perl -ne 'print unless /^\s*(toplam|total)\b/i'
}

ll_canon_ls() {
  local raw="$1"

  raw="$(ll_strip_ansi_and_controls "$raw")"

  printf '%s\n' "$raw" \
    | ll_drop_ls_totals \
    | perl "${PROJECT_ROOT}/scripts/dev/ls-compare-canon-ls.pl"
}

ll_canon_ll() {
  local raw="$1"

  raw="$(ll_strip_ansi_and_controls "$raw")"

  printf '%s\n' "$raw" \
    | ll_drop_ls_totals \
    | perl "${PROJECT_ROOT}/scripts/dev/ls-compare-canon-script.pl"
}

ll_run_ls() {
  \ls --color -l --time-style=+"%s" "$@" 2>&1
}

ll_run_ll() {
  "${LL_SCRIPT}" "$@" 2>&1
}

ll_set_compare_env() {
  local arg

  LS_COMPARE_HAS_BLOCKS=0
  LS_COMPARE_HAS_HUMAN=0

  for arg in "$@"; do
    case "$arg" in
      --)
        break
        ;;
      -s|--size)
        LS_COMPARE_HAS_BLOCKS=1
        ;;
      -h|--human-readable|--si)
        LS_COMPARE_HAS_HUMAN=1
        ;;
      *)
        ;;
    esac
  done

  export LS_COMPARE_HAS_BLOCKS LS_COMPARE_HAS_HUMAN
  export LS_COMPARE_USER LS_COMPARE_NOW_EPOCH
  LS_COMPARE_USER="$(id -un 2>/dev/null || printf '%s' "${USER:-}")"
  LS_COMPARE_NOW_EPOCH="${LL_NOW_EPOCH:-}"
}

ll_assert_canon_equal() {
  local -a args
  local ls_raw
  local ll_raw
  local ls_canon
  local ll_canon
  local tmp_ls
  local tmp_ll

  args=("$@")
  ll_set_compare_env "${args[@]}"

  ls_raw="$(ll_run_ls "${args[@]}")"
  ll_raw="$(ll_run_ll "${args[@]}")"

  ls_canon="$(ll_canon_ls "$ls_raw")"
  ll_canon="$(ll_canon_ll "$ll_raw")"

  if [ "$ls_canon" != "$ll_canon" ]; then
    tmp_ls="$(mktemp)"
    tmp_ll="$(mktemp)"
    printf '%s\n' "$ls_canon" > "${tmp_ls}"
    printf '%s\n' "$ll_canon" > "${tmp_ll}"

    if command -v diff >/dev/null 2>&1; then
      diff -u "${tmp_ls}" "${tmp_ll}" || true
    else
      echo "=== ls canonical ==="
      printf '%s\n' "$ls_canon"
      echo "=== ll canonical ==="
      printf '%s\n' "$ll_canon"
    fi

    rm -f "${tmp_ls}" "${tmp_ll}"
    return 1
  fi
}
