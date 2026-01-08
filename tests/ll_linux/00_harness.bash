#!/usr/bin/env bash
# tests/ll_linux/00_harness.bash
set -euo pipefail

# Run with: bats tests/ll_linux/*.bats

export LC_ALL=C
export TZ=UTC
export LL_CHATGPT_FAST=1
export LL_NOW_EPOCH=1577836800

TESTS_DIR="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
PROJECT_ROOT="$(cd "${TESTS_DIR}/.." && pwd)"
LL_SCRIPT="${PROJECT_ROOT}/scripts/bin/ll"

LL_ARGS_RAW=()
LL_ARGS_OPTS=()
LL_ARGS_OPERANDS=()
LL_ARGS_EFFECTIVE=()
LL_ARGS_HAS_SEP=0

LL_GNU_LS=""
if ls --color -l --time-style=+"%s" . >/dev/null 2>&1; then
  LL_GNU_LS="ls"
elif command -v gls >/dev/null 2>&1; then
  LL_GNU_LS="$(command -v gls)"
elif [ -x /opt/local/libexec/gnubin/ls ]; then
  LL_GNU_LS="/opt/local/libexec/gnubin/ls"
fi

LL_GNU_AWK=""
if command -v gawk >/dev/null 2>&1; then
  LL_GNU_AWK="$(command -v gawk)"
fi

LL_GNU_DATE=""
if date -d "@0" "+%Y-%m-%d %H:%M:%S" >/dev/null 2>&1; then
  LL_GNU_DATE="date"
elif command -v gdate >/dev/null 2>&1; then
  LL_GNU_DATE="$(command -v gdate)"
elif [ -x /opt/local/libexec/gnubin/date ]; then
  LL_GNU_DATE="/opt/local/libexec/gnubin/date"
fi

LL_GNU_TOUCH=""
if touch -d "@0" /tmp/.ll-touch-test >/dev/null 2>&1; then
  LL_GNU_TOUCH="touch"
  rm -f /tmp/.ll-touch-test
elif command -v gtouch >/dev/null 2>&1; then
  LL_GNU_TOUCH="$(command -v gtouch)"
elif [ -x /opt/local/libexec/gnubin/touch ]; then
  LL_GNU_TOUCH="/opt/local/libexec/gnubin/touch"
fi

ll_warn() {
  echo "WARNING: $*" >&2
}

ll_soft_skip() {
  ll_warn "$@"
  skip "$@"
}

ll_require_gnu_ls() {
  if [ -z "$LL_GNU_LS" ]; then
    ll_soft_skip "GNU ls required"
  fi
}

ll_require_gnu_awk() {
  if [ -z "$LL_GNU_AWK" ]; then
    ll_soft_skip "GNU awk required"
  fi
}

ll_require_gnu_date() {
  if [ -z "$LL_GNU_DATE" ]; then
    ll_soft_skip "GNU date required"
  fi
}

ll_require_gnu_touch() {
  if [ -z "$LL_GNU_TOUCH" ]; then
    ll_soft_skip "GNU touch required"
  fi
}

setup_file() {
  if [ "$(uname -s)" = "Darwin" ] && [ -z "$LL_GNU_LS" ]; then
    ll_soft_skip "GNU ls required on macOS (install coreutils to run ll_linux suite)"
  fi
  ll_require_gnu_ls
}

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
  ln -s "file1.txt" "symlink-to-file1" 2>/dev/null || true
  ln -s "does-not-exist" "broken-symlink" 2>/dev/null || true
  mkfifo "fifo1" 2>/dev/null || true

  cp "file1.txt" "setuid-file" 2>/dev/null || true
  chmod 4755 "setuid-file" 2>/dev/null || true
  cp "file1.txt" "setgid-file" 2>/dev/null || true
  chmod 2755 "setgid-file" 2>/dev/null || true
  mkdir -p "setgid-dir" 2>/dev/null || true
  chmod 2755 "setgid-dir" 2>/dev/null || true
  mkdir -p "sticky-dir" 2>/dev/null || true
  chmod 1777 "sticky-dir" 2>/dev/null || true

  printf "future" > "future.txt"

  touch -t 202001010000.00 \
    file1.txt file2.txt file3.txt dir1 dir2 \
    "a b.txt" " file-leading-space.txt" "${tab_name}" "İçerik-ğüşöç.txt" \
    "${long_name}" link-to-file1 broken-link symlink-to-file1 broken-symlink \
    fifo1 setuid-file setgid-file setgid-dir sticky-dir future.txt

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
  if [ -z "$LL_GNU_LS" ]; then
    echo "GNU ls is required for ll tests" >&2
    return 1
  fi
  "$LL_GNU_LS" --color -l --time-style=+"%s" "$@" 2>&1
}

ll_run_ll() {
  if [ "$(uname -s)" = "Darwin" ]; then
    if [ -n "$LL_GNU_LS" ]; then
      if [ -n "$LL_GNU_AWK" ]; then
        LL_IMPL=linux LL_CHATGPT_FAST=1 LL_CHATGPT_LS="$LL_GNU_LS" LL_CHATGPT_AWK="$LL_GNU_AWK" "${LL_SCRIPT}" "$@" 2>&1
      else
        LL_IMPL=linux LL_CHATGPT_FAST=1 LL_CHATGPT_LS="$LL_GNU_LS" "${LL_SCRIPT}" "$@" 2>&1
      fi
    else
      if [ -n "$LL_GNU_AWK" ]; then
        LL_IMPL=linux LL_CHATGPT_FAST=1 LL_CHATGPT_AWK="$LL_GNU_AWK" "${LL_SCRIPT}" "$@" 2>&1
      else
        LL_IMPL=linux LL_CHATGPT_FAST=1 "${LL_SCRIPT}" "$@" 2>&1
      fi
    fi
    return
  fi

  if [ -n "$LL_GNU_LS" ]; then
    if [ -n "$LL_GNU_AWK" ]; then
      LL_CHATGPT_FAST=1 LL_CHATGPT_LS="$LL_GNU_LS" LL_CHATGPT_AWK="$LL_GNU_AWK" "${LL_SCRIPT}" "$@" 2>&1
    else
      LL_CHATGPT_FAST=1 LL_CHATGPT_LS="$LL_GNU_LS" "${LL_SCRIPT}" "$@" 2>&1
    fi
  else
    if [ -n "$LL_GNU_AWK" ]; then
      LL_CHATGPT_FAST=1 LL_CHATGPT_AWK="$LL_GNU_AWK" "${LL_SCRIPT}" "$@" 2>&1
    else
      LL_CHATGPT_FAST=1 "${LL_SCRIPT}" "$@" 2>&1
    fi
  fi
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

ll_split_args() {
  local arg
  local seen_sep=0

  LL_ARGS_OPTS=()
  LL_ARGS_OPERANDS=()
  LL_ARGS_HAS_SEP=0

  for arg in "$@"; do
    if [ "$seen_sep" -eq 0 ] && [ "$arg" = "--" ]; then
      LL_ARGS_HAS_SEP=1
      seen_sep=1
      continue
    fi

    if [ "$seen_sep" -eq 0 ]; then
      LL_ARGS_OPTS+=("$arg")
    else
      LL_ARGS_OPERANDS+=("$arg")
    fi
  done
}

ll_build_args() {
  if [ "$LL_ARGS_HAS_SEP" -eq 0 ]; then
    LL_ARGS_EFFECTIVE=("${LL_ARGS_RAW[@]}")
    return
  fi

  LL_ARGS_EFFECTIVE=("${LL_ARGS_OPTS[@]}")
  LL_ARGS_EFFECTIVE+=(--)
  if [ "${#LL_ARGS_OPERANDS[@]}" -gt 0 ]; then
    LL_ARGS_EFFECTIVE+=("${LL_ARGS_OPERANDS[@]}")
  fi
}

ll_assert_canon_equal() {
  local -a args
  local ls_raw
  local ll_raw
  local ls_canon
  local ll_canon
  local tmp_ls
  local tmp_ll
  local ls_status
  local ll_status

  args=("$@")
  LL_ARGS_RAW=("${args[@]}")
  ll_split_args "${LL_ARGS_RAW[@]}"
  ll_build_args
  ll_set_compare_env "${LL_ARGS_RAW[@]}"

  set +e
  ls_raw="$(ll_run_ls "${LL_ARGS_EFFECTIVE[@]}")"
  ls_status=$?
  ll_raw="$(ll_run_ll "${LL_ARGS_EFFECTIVE[@]}")"
  ll_status=$?
  set -e

  if [ "$ls_status" -ne 0 ] || [ "$ll_status" -ne 0 ]; then
    echo "ll comparison failed to run"
    echo "ls status: ${ls_status}"
    echo "ll status: ${ll_status}"
    echo "args: ${LL_ARGS_RAW[*]}"
    if [ -n "$ls_raw" ]; then
      echo "--- ls output ---"
      printf '%s\n' "$ls_raw"
    fi
    if [ -n "$ll_raw" ]; then
      echo "--- ll output ---"
      printf '%s\n' "$ll_raw"
    fi
    return 1
  fi

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
