#!/usr/bin/env bats
# tests/ll/30_driver_flag_parity.bats
#
# Drift-detection for the flag-parser blocks in scripts/bin/ll_linux
# and scripts/bin/ll_macos. The two drivers must accept the same
# user-visible flag set — both long (--directory, --human-readable,
# --no-group, --numeric-uid-gid, --si, --size) and short (d/g/G/h/n/o/s).
#
# These tests extract the option names out of each driver's
# `# BEGIN flag-parser` / `# END flag-parser` block and compare the
# sets. They deliberately do NOT assert on variable assignments or
# case-arm ordering — that would block legitimate refactors. The
# contract is: the accepted flag alphabet is symmetric.
#
# Why this matters (P3 #11 rationale): shell-layer refactoring of
# ll_linux and ll_macos was rejected because their data flows are
# fundamentally different (macOS stat-based rows, Linux `ls -l` text
# parsing) and a shared helper would leak. But one block is genuinely
# duplicated across both drivers: the flag scan that detects
# user-facing options. Without this test, adding a new flag (e.g.,
# `-R` or `--reverse`) to one driver and forgetting the other would
# silently drop the flag on the forgotten platform.

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'

setup() {
  PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  LL_LINUX="${PROJECT_ROOT}/scripts/bin/ll_linux"
  LL_MACOS="${PROJECT_ROOT}/scripts/bin/ll_macos"
  [ -r "$LL_LINUX" ] || skip "ll_linux not readable"
  [ -r "$LL_MACOS" ] || skip "ll_macos not readable"
}

# Extract the sorted unique set of long options (--foo) declared as
# case arms inside the driver's flag-parser block. Strips the trailing
# `)` and the `|--alias` form so `--human-readable|--si)` yields both
# `--human-readable` and `--si`.
_extract_long_options() {
  local file="$1"
  sed -n '/# BEGIN flag-parser/,/# END flag-parser/p' "$file" \
    | grep -oE '\-\-[a-z][a-z-]*' \
    | sort -u
}

# Extract the sorted unique set of short-option characters handled in
# the `case "${_flags:i:1}"` inner switch. Captures a single
# [a-zA-Z?] character followed by `)` at the start of a line
# (ignoring indentation).
_extract_short_options() {
  local file="$1"
  sed -n '/# BEGIN flag-parser/,/# END flag-parser/p' "$file" \
    | awk '/case "\$\{_flags:i:1\}"/,/esac/' \
    | sed -nE 's/^[[:space:]]*([a-zA-Z?])\).*/\1/p' \
    | sort -u
}

@test "ll driver flag parity: flag-parser markers present in both drivers" {
  grep -q '^# BEGIN flag-parser' "$LL_LINUX"
  grep -q '^# END flag-parser'   "$LL_LINUX"
  grep -q '^# BEGIN flag-parser' "$LL_MACOS"
  grep -q '^# END flag-parser'   "$LL_MACOS"
}

@test "ll driver flag parity: long options are symmetric between ll_linux and ll_macos" {
  local linux_opts macos_opts
  linux_opts=$(_extract_long_options "$LL_LINUX")
  macos_opts=$(_extract_long_options "$LL_MACOS")

  if [ "$linux_opts" != "$macos_opts" ]; then
    echo "long option drift detected — each driver must declare the same set." >&2
    echo "ll_linux options:" >&2
    echo "$linux_opts" >&2
    echo "ll_macos options:" >&2
    echo "$macos_opts" >&2
    diff <(printf '%s\n' "$linux_opts") <(printf '%s\n' "$macos_opts") >&2 || true
    return 1
  fi

  # Sanity: must cover at least the currently-documented flags.
  for expected in --directory --human-readable --no-group --numeric-uid-gid --si --size; do
    if ! printf '%s\n' "$linux_opts" | grep -qx -- "$expected"; then
      echo "expected long option '$expected' missing from ll_linux" >&2
      return 1
    fi
  done
}

@test "ll driver flag parity: short options are symmetric between ll_linux and ll_macos" {
  local linux_short macos_short
  linux_short=$(_extract_short_options "$LL_LINUX")
  macos_short=$(_extract_short_options "$LL_MACOS")

  if [ "$linux_short" != "$macos_short" ]; then
    echo "short option drift detected — each driver must handle the same chars." >&2
    echo "ll_linux short:" >&2
    echo "$linux_short" >&2
    echo "ll_macos short:" >&2
    echo "$macos_short" >&2
    diff <(printf '%s\n' "$linux_short") <(printf '%s\n' "$macos_short") >&2 || true
    return 1
  fi

  # Sanity: current contract is d/g/G/h/n/o/s. If this set changes
  # the expected list below must also change, which is exactly the
  # moment to audit whether the sibling driver was kept in sync.
  local expected
  expected=$(printf '%s\n' d g G h n o s | sort -u)
  [ "$linux_short" = "$expected" ] || {
    echo "short option set deviated from the documented d/g/G/h/n/o/s." >&2
    echo "Current ll_linux set:" >&2
    echo "$linux_short" >&2
    return 1
  }
}

# Regression: unknown long options (e.g. --group-directories-first,
# which the fish/bash/zsh `ll` wrapper functions routinely append) must
# NOT be mis-decomposed into individual short flags by the `-*)` branch.
# The `d` character in such a long name would previously set
# LISTDIRECTORY=1 and collapse the whole listing into a single `.` row.
@test "ll drivers: unknown long options are not mis-parsed as short flags" {
  local tmpdir driver
  tmpdir="$(mktemp -d)"
  : > "$tmpdir/file_a"
  : > "$tmpdir/file_b"
  : > "$tmpdir/file_c"

  for driver in "$LL_MACOS" "$LL_LINUX"; do
    # ll_linux needs a working GNU ls; soft-skip on hosts without one
    # (macOS without gnubin). The macOS driver runs on any BSD stat.
    if [ "$driver" = "$LL_LINUX" ]; then
      if ! ls --color -l --time-style=+"%s" "$tmpdir" >/dev/null 2>&1 \
         && ! command -v gls >/dev/null 2>&1 \
         && [ ! -x /opt/local/libexec/gnubin/ls ]; then
        continue
      fi
    fi

    LL_NO_COLOR=1 run "$driver" --group-directories-first "$tmpdir"
    assert_success

    # Must list all three files, not collapse to a single `.` row.
    assert_output --partial 'file_a'
    assert_output --partial 'file_b'
    assert_output --partial 'file_c'
  done

  rm -rf "$tmpdir"
}
