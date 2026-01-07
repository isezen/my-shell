# ll-perf.md

## Environment
- Host: Darwin (local)
- Timing tool: `/usr/bin/time -p`
- Date: 2025-01-05

## Setup
- Created temp dirs with 1k and 10k files.
- Commands (stdout redirected to /dev/null):
  - `/bin/ls -l`
  - `scripts/bin/ll_macos` (with `LL_CHATGPT_FAST=1`)

## Commands
```
# Create fixtures
TMP_DIR=$(mktemp -d)
mkdir -p "$TMP_DIR/small" "$TMP_DIR/large"
seq 1 1000 | xargs -I{} touch "$TMP_DIR/small/file_{}"
seq 1 10000 | xargs -I{} touch "$TMP_DIR/large/file_{}"

# Small (~1k entries)
/usr/bin/time -p sh -c "cd '$TMP_DIR/small' && /bin/ls -l >/dev/null"
/usr/bin/time -p sh -c "cd '$TMP_DIR/small' && LL_CHATGPT_FAST=1 /Users/isezen/proj/my-shell/scripts/bin/ll_macos >/dev/null"

# Large (~10k entries)
/usr/bin/time -p sh -c "cd '$TMP_DIR/large' && /bin/ls -l >/dev/null"
/usr/bin/time -p sh -c "cd '$TMP_DIR/large' && LL_CHATGPT_FAST=1 /Users/isezen/proj/my-shell/scripts/bin/ll_macos >/dev/null"
```

## Results

### Small (~1k entries)
- `/bin/ls -l`
  - real 0.24
  - user 0.03
  - sys 0.10
- `ll_macos`
  - real 13.09
  - user 2.54
  - sys 7.90

### Large (~10k entries)
- `/bin/ls -l`
  - real 2.21
  - user 0.32
  - sys 1.05
- `ll_macos`
  - real 152.90
  - user 27.79
  - sys 96.08

## Notes
- `ll_macos` is significantly slower than `/bin/ls -l` on this host.
- This supports Phase 7: future optimization should reduce per-entry process spawn overhead.
