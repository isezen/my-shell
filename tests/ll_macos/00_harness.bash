#!/usr/bin/env bash
# tests/ll_macos/00_harness.bash
set -euo pipefail

# Run with: bats tests/ll_macos/*.bats

export LC_ALL=C
export TZ=UTC
export LL_NO_COLOR=1
export LL_NOW_EPOCH=1577836800

TESTS_DIR="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
PROJECT_ROOT="$(cd "${TESTS_DIR}/.." && pwd)"
LL_SCRIPT="${PROJECT_ROOT}/scripts/bin/ll"
LL_MACOS_IMPL="${PROJECT_ROOT}/scripts/bin/ll_macos"
LL_MACOS_DELIM=$'\037'
LL_MACOS_TAB=$'\011'
# NOTE: Filenames with literal newlines are out-of-scope (line-based records).
LL_MACOS_USER="$(id -un 2>/dev/null || printf '%s' "${USER:-}")"
: "$LL_SCRIPT"

ll_warn() {
  echo "WARNING: $*" >&2
}

ll_soft_skip() {
  ll_warn "$@"
  skip "$@"
}

ll_require_macos_userland() {
  if [ "$(uname -s)" != "Darwin" ]; then
    ll_soft_skip "ll_macos tests cannot run on Linux locally; they are validated in macOS CI. Skipping."
    return 1
  fi
  for bin in /bin/ls /usr/bin/awk /usr/bin/stat; do
    [ -x "$bin" ] || { ll_soft_skip "Required macOS binary $bin not found"; return 1; }
  done
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
  mkdir dir1
  chmod 755 file1.txt
  chmod 644 file2.txt

  printf 'space' > "a b.txt"
  printf 'lead' > " file-leading-space.txt"
  tab_name=$'a\tb.txt'
  printf 'tab' > "${tab_name}"
  printf 'utf' > "İçerik-ğüşöç.txt"
  long_name="$(printf 'a%.0s' {1..210}).txt"
  printf 'long' > "${long_name}"

  ln -s "file1.txt" "link-to-file1" 2>/dev/null || true
  ln -s "missing-target" "broken-link" 2>/dev/null || true
  mkfifo "fifo1" 2>/dev/null || true

  cp "file1.txt" "setuid-file" 2>/dev/null || true
  chmod 4755 "setuid-file" 2>/dev/null || true
  cp "file1.txt" "setgid-file" 2>/dev/null || true
  chmod 2755 "setgid-file" 2>/dev/null || true
  mkdir -p "sticky-dir" 2>/dev/null || true
  chmod 1777 "sticky-dir" 2>/dev/null || true

  printf 'future' > "future.txt"

  /usr/bin/touch -t 202001010000.00 \
    file1.txt file2.txt dir1 \
    "a b.txt" " file-leading-space.txt" "${tab_name}" "İçerik-ğüşöç.txt" \
    "${long_name}" link-to-file1 broken-link fifo1 setuid-file setgid-file sticky-dir future.txt

  /usr/bin/touch -t 203001010000.00 future.txt 2>/dev/null || true
}

ll_seed_basic_fixtures() {
  ll_seed_fixtures_common
}

ll_epoch_to_touch_ts() {
  local epoch="$1"
  if /bin/date -r "$epoch" +%Y%m%d%H%M.%S >/dev/null 2>&1; then
    /bin/date -r "$epoch" +%Y%m%d%H%M.%S
    return 0
  fi
  if command -v gdate >/dev/null 2>&1; then
    gdate -d "@${epoch}" +%Y%m%d%H%M.%S
    return 0
  fi
  return 1
}

ll_touch_epoch() {
  local path="$1"
  local epoch="$2"
  local ts

  ts="$(ll_epoch_to_touch_ts "$epoch")" || return 1
  /usr/bin/touch -t "$ts" "$path"
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

ll_norm_ws() {
  printf '%s\n' "$1" | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//'
}

ll_drop_totals() {
  perl -ne 'print unless /^\s*(toplam|total)\b/i'
}

LL_MACOS_ASIZE=0
LL_MACOS_HUMAN=0
LL_MACOS_NUMERIC=0
LL_MACOS_OWNER=1
LL_MACOS_GROUP=1
LL_MACOS_DIR=0
LL_MACOS_OPERANDS=()

ll_macos_reset_flags() {
  LL_MACOS_ASIZE=0
  LL_MACOS_HUMAN=0
  LL_MACOS_NUMERIC=0
  LL_MACOS_OWNER=1
  LL_MACOS_GROUP=1
  LL_MACOS_DIR=0
  LL_MACOS_OPERANDS=()
}

ll_macos_parse_args() {
  local arg flags seen_sep=0

  ll_macos_reset_flags

  for arg in "$@"; do
    if [ "$seen_sep" -eq 0 ] && [ "$arg" = "--" ]; then
      seen_sep=1
      continue
    fi

    if [ "$seen_sep" -eq 0 ] && [[ "$arg" == --* ]]; then
      case "$arg" in
        --directory) LL_MACOS_DIR=1 ;;
        --human-readable|--si) LL_MACOS_HUMAN=1 ;;
        --numeric-uid-gid) LL_MACOS_NUMERIC=1 ;;
        --size) LL_MACOS_ASIZE=1 ;;
        --no-group) LL_MACOS_GROUP=0 ;;
        *) ;;
      esac
      continue
    fi

    if [ "$seen_sep" -eq 0 ] && [[ "$arg" == -* ]] && [ "$arg" != "-" ]; then
      flags=${arg#-}
      for ((i=0; i<${#flags}; i++)); do
        case "${flags:i:1}" in
          d) LL_MACOS_DIR=1 ;;
          h) LL_MACOS_HUMAN=1 ;;
          n) LL_MACOS_NUMERIC=1 ;;
          g) LL_MACOS_OWNER=0 ;;
          G) LL_MACOS_GROUP=0 ;;
          o) LL_MACOS_GROUP=0 ;;
          s) LL_MACOS_ASIZE=1 ;;
          *) ;;
        esac
      done
      continue
    fi

    LL_MACOS_OPERANDS+=("$arg")
  done

  if [ "${#LL_MACOS_OPERANDS[@]}" -eq 0 ]; then
    LL_MACOS_OPERANDS=(.)
  fi
}

ll_macos_time_parts() {
  local epoch="$1"
  local dt abs

  dt=$((LL_NOW_EPOCH - epoch))
  abs="$dt"
  LL_TIME_PREFIX=""

  if [ "$dt" -lt 0 ]; then
    LL_TIME_PREFIX="in"
    abs=$(( -dt ))
  fi

  if [ "$abs" -lt 120 ]; then
    LL_TIME_NUM="$abs"
    LL_TIME_UNIT="sec"
  elif [ "$abs" -lt 3600 ]; then
    LL_TIME_NUM=$(( abs / 60 ))
    LL_TIME_UNIT="min"
  elif [ "$abs" -lt 172800 ]; then
    LL_TIME_NUM=$(( abs / 3600 ))
    LL_TIME_UNIT="hrs"
  elif [ "$abs" -lt 3888000 ]; then
    LL_TIME_NUM=$(( abs / 86400 ))
    LL_TIME_UNIT="day"
  elif [ "$abs" -lt 31536000 ]; then
    LL_TIME_NUM=$(( abs / 2592000 ))
    LL_TIME_UNIT="mon"
  else
    LL_TIME_NUM=$(( abs / 31536000 ))
    LL_TIME_UNIT="yr"
  fi
}

ll_macos_human_size() {
  local bytes="$1"
  local unit scaled

  if [[ ! "$bytes" =~ ^[0-9]+$ ]]; then
    printf '%s' "$bytes"
    return 0
  fi

  if [ "$bytes" -lt 1024 ]; then
    printf '%sB' "$bytes"
    return 0
  fi

  if [ "$bytes" -lt $((1024 * 1024)) ]; then
    unit="K"
    scaled="$(/usr/bin/awk -v b="$bytes" 'BEGIN{printf "%.1f", b/1024.0}')"
  elif [ "$bytes" -lt $((1024 * 1024 * 1024)) ]; then
    unit="M"
    scaled="$(/usr/bin/awk -v b="$bytes" 'BEGIN{printf "%.1f", b/1048576.0}')"
  elif [ "$bytes" -lt $((1024 * 1024 * 1024 * 1024)) ]; then
    unit="G"
    scaled="$(/usr/bin/awk -v b="$bytes" 'BEGIN{printf "%.1f", b/1073741824.0}')"
  else
    unit="T"
    scaled="$(/usr/bin/awk -v b="$bytes" 'BEGIN{printf "%.1f", b/1099511627776.0}')"
  fi

  scaled="$(printf '%s' "$scaled" | sed -E 's/\.0$//')"
  printf '%s%s' "$scaled" "$unit"
}

ll_macos_quote_if_needed() {
  local s="$1"
  if [[ "$s" == *"$LL_MACOS_TAB"* ]] || [[ "$s" == *" "* ]]; then
    printf '"%s"' "$s"
  else
    printf '%s' "$s"
  fi
}

ll_macos_ref_line() {
  local path="$1"
  local stat_path="$path"
  local st b512 perms links su sg uid gid size epoch name target
  local stat_fmt

  if [[ "$stat_path" == -* ]]; then
    stat_path="./$stat_path"
  fi

  target=""
  stat_fmt="%b${LL_MACOS_DELIM}%Sp${LL_MACOS_DELIM}%l${LL_MACOS_DELIM}%Su${LL_MACOS_DELIM}%Sg${LL_MACOS_DELIM}%u${LL_MACOS_DELIM}%g${LL_MACOS_DELIM}%z${LL_MACOS_DELIM}%m${LL_MACOS_DELIM}%N"
  st="$(/usr/bin/stat -f "$stat_fmt" "$stat_path" 2>/dev/null || true)"
  if [ -z "$st" ]; then
    return 0
  fi

  IFS="$LL_MACOS_DELIM" read -r b512 perms links su sg uid gid size epoch name <<<"$st"

  if [[ "$perms" == l* ]] && [[ "$name" == *" -> "* ]]; then
    name="${name%% -> *}"
  fi
  
  # Strip ./ prefix to match ll_macos behavior
  if [[ "$name" == ./* ]]; then
    name="${name#./}"
  fi

  if [[ "$perms" == l* ]]; then
    target="$(/usr/bin/readlink "$stat_path" 2>/dev/null || true)"
  fi

  local blocks1k owner group size_disp name_out
  blocks1k=$(( (b512 + 1) / 2 ))

  if [ "$LL_MACOS_NUMERIC" -eq 1 ]; then
    owner="$uid"
    group="$gid"
  else
    owner="$su"
    group="$sg"
  fi
  if [ "$LL_MACOS_NUMERIC" -eq 0 ] && [ -n "$LL_MACOS_USER" ] && [ "$owner" = "$LL_MACOS_USER" ]; then
    owner="you"
  fi

  if [ "$LL_MACOS_HUMAN" -eq 1 ]; then
    size_disp="$(ll_macos_human_size "$size")"
  else
    size_disp="$size"
  fi

  ll_macos_time_parts "$epoch"
  name_out="$(ll_macos_quote_if_needed "$name")"
  if [ -n "$target" ]; then
    name_out="${name_out} -> $(ll_macos_quote_if_needed "$target")"
  fi

  local parts=()
  if [ "$LL_MACOS_ASIZE" -eq 1 ]; then
    parts+=("$blocks1k")
  fi
  parts+=("$perms" "$links")
  if [ "$LL_MACOS_OWNER" -eq 1 ]; then
    parts+=("$owner")
  fi
  if [ "$LL_MACOS_GROUP" -eq 1 ]; then
    parts+=("$group")
  fi
  parts+=("$size_disp")
  if [ -n "$LL_TIME_PREFIX" ]; then
    parts+=("$LL_TIME_PREFIX" "$LL_TIME_NUM" "$LL_TIME_UNIT")
  else
    parts+=("$LL_TIME_NUM" "$LL_TIME_UNIT")
  fi
  parts+=("$name_out")

  (IFS=" "; printf '%s\n' "${parts[*]}")
}

ll_macos_ref_dir() {
  local d="$1"
  local entry
  local dir_path="$d"

  if [[ "$dir_path" == -* ]]; then
    dir_path="./$dir_path"
  fi

  /bin/ls -1A "$dir_path" 2>/dev/null | sed -E '/^\./d' | while IFS= read -r entry; do
    ll_macos_ref_line "${d%/}/$entry"
  done
}

ll_macos_ref_generate() {
  ll_macos_parse_args "$@"

  local op
  for op in "${LL_MACOS_OPERANDS[@]}"; do
    if [ -d "$op" ] && [ ! -L "$op" ] && [ "$LL_MACOS_DIR" -eq 0 ]; then
      ll_macos_ref_dir "$op"
    else
      ll_macos_ref_line "$op"
    fi
  done
}

ll_macos_run_ll() {
  LL_NO_COLOR=1 "${LL_MACOS_IMPL}" "$@" 2>&1
}

ll_macos_canon_output() {
  local raw="$1"
  raw="$(ll_strip_ansi_and_controls "$raw")"
  printf '%s\n' "$raw" \
    | ll_drop_totals \
    | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//'
}

ll_macos_assert_canon_equal() {
  local ll_raw ref_raw ll_canon ref_canon

  set +e
  ll_raw="$(ll_macos_run_ll "$@")"
  local ll_status=$?
  ref_raw="$(ll_macos_ref_generate "$@")"
  local ref_status=$?
  set -e

  if [ "$ll_status" -ne 0 ] || [ "$ref_status" -ne 0 ]; then
    echo "ll_macos comparison failed to run"
    echo "ll status: ${ll_status}"
    echo "ref status: ${ref_status}"
    echo "args: $*"
    if [ -n "$ll_raw" ]; then
      echo "--- ll output ---"
      printf '%s\n' "$ll_raw"
    fi
    if [ -n "$ref_raw" ]; then
      echo "--- ref output ---"
      printf '%s\n' "$ref_raw"
    fi
    return 1
  fi

  ll_canon="$(ll_macos_canon_output "$ll_raw")"
  ref_canon="$(ll_macos_canon_output "$ref_raw")"

  if [ "$ll_canon" != "$ref_canon" ]; then
    local tmp_ll tmp_ref
    tmp_ll="$(mktemp)"
    tmp_ref="$(mktemp)"
    printf '%s\n' "$ll_canon" > "$tmp_ll"
    printf '%s\n' "$ref_canon" > "$tmp_ref"
    if command -v diff >/dev/null 2>&1; then
      diff -u "$tmp_ref" "$tmp_ll" || true
    else
      echo "=== ref canonical ==="
      printf '%s\n' "$ref_canon"
      echo "=== ll canonical ==="
      printf '%s\n' "$ll_canon"
    fi
    rm -f "$tmp_ll" "$tmp_ref"
    return 1
  fi
}
