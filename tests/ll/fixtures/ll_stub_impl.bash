#!/usr/bin/env bash
set -euo pipefail

# Simple stub for wrapper tests.
# Behavior:
# - Prints a single machine-parsable line to stdout.
# - Exits with 0 unless STUB_EXIT is set.

role="${STUB_ROLE:-unknown}"

# Print role + argv in a stable format.
# We intentionally use NUL-safe-ish separators: a visible unit separator token.
printf 'STUB_ROLE=%s\n' "$role"
printf 'ARGV_COUNT=%s\n' "$#"

idx=0
for a in "$@"; do
  idx=$((idx+1))
  printf 'ARGV_%02d=%s\n' "$idx" "$a"
done

exit "${STUB_EXIT:-0}"
