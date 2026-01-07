# ll-before.md

## Snapshot
- Date: 2025-01-05
- Host: Darwin (local)
- Purpose: Baseline snapshot of current ll test state and commands (Phase 0).

## Commands and Results

### make test-ll-common (exit 0)
```
1..7
ok 1 ll wrapper: LL_IMPL_PATH wins and forwards argv verbatim
ok 2 ll wrapper: LL_IMPL=linux selects ll_linux in the same directory
ok 3 ll wrapper: LL_IMPL=macos selects ll_macos in the same directory
ok 4 ll wrapper: invalid LL_IMPL returns exit 2
ok 5 ll wrapper: LL_SCRIPT recursion guard does not exec itself
ok 6 ll wrapper: LL_SCRIPT set but not executable returns exit 1 and error
ok 7 ll wrapper: LL_IMPL_PATH set but not executable returns exit 1 and error
```

### make test-ll (exit 0)
```
1..7
ok 1 ll wrapper: LL_IMPL_PATH wins and forwards argv verbatim
ok 2 ll wrapper: LL_IMPL=linux selects ll_linux in the same directory
ok 3 ll wrapper: LL_IMPL=macos selects ll_macos in the same directory
ok 4 ll wrapper: invalid LL_IMPL returns exit 2
ok 5 ll wrapper: LL_SCRIPT recursion guard does not exec itself
ok 6 ll wrapper: LL_SCRIPT set but not executable returns exit 1 and error
ok 7 ll wrapper: LL_IMPL_PATH set but not executable returns exit 1 and error
1..7
ok 1 ll_macos: preflight passes on Darwin
ok 2 ll_macos: core parity (bsd reference)
ok 3 ll_macos: tricky filenames preserved
ok 4 ll_macos: symlink arrows preserved
ok 5 ll_macos: time buckets and colors
ok 6 ll_macos: perms and owner colors
ok 7 ll_macos: size tier colors (numeric)
```

### make test-ll-all (exit 0)
```
1..7
ok 1 ll wrapper: LL_IMPL_PATH wins and forwards argv verbatim
ok 2 ll wrapper: LL_IMPL=linux selects ll_linux in the same directory
ok 3 ll wrapper: LL_IMPL=macos selects ll_macos in the same directory
ok 4 ll wrapper: invalid LL_IMPL returns exit 2
ok 5 ll wrapper: LL_SCRIPT recursion guard does not exec itself
ok 6 ll wrapper: LL_SCRIPT set but not executable returns exit 1 and error
ok 7 ll wrapper: LL_IMPL_PATH set but not executable returns exit 1 and error
1..25
ok 1 ll core: flag matrix (144 combinations)
ok 2 ll paths: -h file1.txt
ok 3 ll paths: a b.txt
ok 4 ll paths: leading space file
ok 5 ll paths: tab file
ok 6 ll paths: unicode file
ok 7 ll paths: link-to-file1
ok 8 ll paths: broken-link
ok 9 ll paths: fifo1
ok 10 ll paths: setuid-file
ok 11 ll paths: setgid-file
ok 12 ll paths: sticky-dir
ok 13 ll paths: future.txt
ok 14 ll edge: symlink target space
ok 15 ll edge: symlink target tab
ok 16 ll edge: mixed time widths
ok 17 ll edge: future-only prefix column
ok 18 ll colors: future time uses cfut
ok 19 ll colors: time bucket colors
ok 20 ll colors: perms codes
ok 21 ll colors: perms plus (optional) # skip setfacl not available
ok 22 ll colors: owner you
ok 23 ll colors: owner root (optional) # skip sudo not permitted
ok 24 ll colors: size tiers (numeric)
ok 25 ll colors: size labels (human)
1..7
ok 1 ll_macos: preflight passes on Darwin
ok 2 ll_macos: core parity (bsd reference)
ok 3 ll_macos: tricky filenames preserved
ok 4 ll_macos: symlink arrows preserved
ok 5 ll_macos: time buckets and colors
ok 6 ll_macos: perms and owner colors
ok 7 ll_macos: size tier colors (numeric)
```

### make test-ll-linux (exit 0)
```
1..25
ok 1 ll core: flag matrix (144 combinations)
ok 2 ll paths: -h file1.txt
ok 3 ll paths: a b.txt
ok 4 ll paths: leading space file
ok 5 ll paths: tab file
ok 6 ll paths: unicode file
ok 7 ll paths: link-to-file1
ok 8 ll paths: broken-link
ok 9 ll paths: fifo1
ok 10 ll paths: setuid-file
ok 11 ll paths: setgid-file
ok 12 ll paths: sticky-dir
ok 13 ll paths: future.txt
ok 14 ll edge: symlink target space
ok 15 ll edge: symlink target tab
ok 16 ll edge: mixed time widths
ok 17 ll edge: future-only prefix column
ok 18 ll colors: future time uses cfut
ok 19 ll colors: time bucket colors
ok 20 ll colors: perms codes
ok 21 ll colors: perms plus (optional) # skip setfacl not available
ok 22 ll colors: owner you
ok 23 ll colors: owner root (optional) # skip sudo not permitted
ok 24 ll colors: size tiers (numeric)
ok 25 ll colors: size labels (human)
```

### make test-ll-macos (exit 0)
```
1..7
ok 1 ll_macos: preflight passes on Darwin
ok 2 ll_macos: core parity (bsd reference)
ok 3 ll_macos: tricky filenames preserved
ok 4 ll_macos: symlink arrows preserved
ok 5 ll_macos: time buckets and colors
ok 6 ll_macos: perms and owner colors
ok 7 ll_macos: size tier colors (numeric)
```
