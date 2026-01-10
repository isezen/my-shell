# ll Family Specifications

**Version:** 1.0 (Current-State)  
**Date:** 2026-01-09  
**Status:** Test-Locked Behavior Documentation

## Scope

This specification documents the **current behavior** of the `ll` family (`scripts/bin/ll`, `scripts/bin/ll_linux`, `scripts/bin/ll_macos`) as **locked by existing tests** as of 2026-01-09.

This is a **current-state specification**: it documents what is tested and therefore implicitly required, not what should be or could be.

### Non-Goals

- **Untested flags**: Flags not explicitly tested (e.g., `-t`, `-S`, `-r`, `-R`) are UNSPECIFIED
- **Performance characteristics**: Performance is not part of this specification
- **Full `ls` parity**: Only behaviors explicitly tested against `ls -l` are specified
- **Future behavior**: This spec does not propose new features or changes

---

## Terminology & Conformance

### Keywords

- **MUST**: Required behavior proven by tests. Violations are specification non-conformance.
- **SHOULD**: Recommended behavior proven by tests. Deviations should be justified.
- **MAY**: Optional behavior proven by tests or implementation.
- **UNSPECIFIED**: Behavior not tested or not guaranteed. Implementations may vary.

### Components

- **Wrapper**: `scripts/bin/ll` - Platform dispatch script
- **Linux Implementation**: `scripts/bin/ll_linux` - GNU toolchain-based implementation
- **macOS Implementation**: `scripts/bin/ll_macos` - BSD toolchain-based implementation
- **Implementation**: Either `ll_linux` or `ll_macos` depending on context

### Traceability

Each normative requirement cites:
- **Test file(s)**: BATS test files that assert the behavior
- **Tooling**: Comparison scripts or canonicalization scripts that verify behavior
- **Script location**: Implementation code that enforces the behavior

---

## 1. Wrapper Specification (`scripts/bin/ll`)

### 1.1 Environment Variable Precedence

The wrapper MUST select an implementation using the following precedence order:

1. `LL_IMPL_PATH` (if set and executable)
2. `LL_SCRIPT` (if set, executable, and not pointing to wrapper itself)
3. `LL_IMPL` (if set to `linux` or `macos`)
4. OS detection (`Darwin` → `ll_macos`, otherwise → `ll_linux`)

**Traceability:**
- Test: `tests/ll/10_wrapper_stub.bats` (all wrapper tests)
- Script: `scripts/bin/ll` lines 26-89

### 1.2 Argument Forwarding

The wrapper MUST forward all arguments verbatim to the selected implementation without modification.

**Traceability:**
- Test: `tests/ll/10_wrapper_stub.bats` - "LL_IMPL_PATH wins and forwards argv verbatim"
- Script: `scripts/bin/ll` line 33, 43, 55, 62, 78, 86

### 1.3 Recursion Guard

If `LL_SCRIPT` is set to the wrapper's own path, the wrapper MUST ignore `LL_SCRIPT` and proceed to lower-priority selectors.

**Traceability:**
- Test: `tests/ll/10_wrapper_stub.bats` - "LL_SCRIPT recursion guard does not exec itself"
- Script: `scripts/bin/ll` lines 36-45

### 1.4 Error Cases

#### 1.4.1 Invalid LL_IMPL Value

If `LL_IMPL` is set to a value other than `linux` or `macos`, the wrapper MUST:
- Print an error message to stderr: `"Invalid LL_IMPL value: <value> (expected: linux|macos)"`
- Exit with code 2

**Traceability:**
- Test: `tests/ll/10_wrapper_stub.bats` - "invalid LL_IMPL returns exit 2"
- Script: `scripts/bin/ll` lines 64-67

#### 1.4.2 Non-Executable LL_IMPL_PATH

If `LL_IMPL_PATH` is set but the path is not executable or not a file, the wrapper MUST:
- Print an error message to stderr: `"selector=LL_IMPL_PATH LL_IMPL_PATH is set but not executable: <path>"`
- Exit with code 1

**Traceability:**
- Test: `tests/ll/10_wrapper_stub.bats` - "LL_IMPL_PATH set but not executable returns exit 1 and error"
- Script: `scripts/bin/ll` lines 28-34

#### 1.4.3 Non-Executable LL_SCRIPT

If `LL_SCRIPT` is set but the path is not executable or not a file, the wrapper MUST:
- Print an error message to stderr: `"selector=LL_SCRIPT LL_SCRIPT is set but not executable: <path>"`
- Exit with code 1

**Traceability:**
- Test: `tests/ll/10_wrapper_stub.bats` - "LL_SCRIPT set but not executable returns exit 1 and error"
- Script: `scripts/bin/ll` lines 36-45

#### 1.4.4 Missing Implementation File

**UNSPECIFIED:**
- Error handling when OS detection selects an implementation that does not exist or is not executable (not explicitly tested)
- Error message format for missing implementation files
- Behavior when multiple environment variables are set incorrectly

**Implementation Detail (Non-Normative):**
- Script checks exist at `scripts/bin/ll` lines 74-77, 82-85, but these are not exercised by tests

---

## 2. CLI Interface Specification

### 2.1 Supported Flags

The following flags are **tested and MUST be supported**:

| Flag | Long Form | Description | Linux | macOS |
|------|-----------|-------------|-------|-------|
| `-d` | `--directory` | List directory entries, not contents | ✅ | ✅ |
| `-s` | `--size` | Show block sizes (1K blocks) | ✅ | ✅ |
| `-h` | `--human-readable` | Human-readable sizes (base-1024) | ✅ | ✅ |
| `--si` | | Human-readable sizes (base-1000) | ✅ | ❌ |
| `-n` | `--numeric-uid-gid` | Show numeric UIDs/GIDs | ✅ | ✅ |
| `-g` | | Suppress owner column | ✅ | ✅ |
| `-G` | `--no-group`, `-o` | Suppress group column | ✅ | ✅ |
| `-a` | | Include hidden files and `.`/`..` | ✅ | UNSPECIFIED |
| `-A` | | Include hidden files, exclude `.`/`..` | ✅ | UNSPECIFIED |

**Traceability:**
- Test: `tests/ll_linux/10_core.bats` - "flag matrix (144 combinations)"
- Test: `tests/ll_macos/10_core.bats` - "core parity"
- Tooling: `scripts/dev/ll-compare`, `scripts/dev/ls-compare`

**UNSPECIFIED:**
- All other `ls` flags (e.g., `-t`, `-S`, `-r`, `-R`, `-l`, `-1`, etc.)
- Flag combinations with untested flags
- Flag aliases not listed above

### 2.2 Flag Synonyms

The following flag combinations MUST be treated as equivalent:
- `-G`, `--no-group`, `-o` (all suppress group column)
- `-h`, `--human-readable` (both enable human-readable sizes)

**Traceability:**
- Test: `tests/ll_linux/10_core.bats` - alias tests
- Script: `scripts/bin/ll_linux` lines 36-69, `scripts/bin/ll_macos` lines 26-72

### 2.3 Operand Ordering

Options MAY appear after operands. For example, `ll file1.txt --no-group` MUST be equivalent to `ll --no-group file1.txt`.

**Traceability:**
- Test: `tests/ll_linux/10_core.bats` - "file then --no-group", "file then -G", "--no-group then file"
- Script: `scripts/bin/ll_linux` lines 34-69 (flag scan before operand processing)

### 2.4 `--` Sentinel

The `--` sentinel MAY be used to explicitly separate options from operands. When used, all arguments after `--` MUST be treated as operands.

**Traceability:**
- Test: `tests/ll_linux/20_paths.bats` - multiple tests use `--` with filenames containing spaces
- Script: `scripts/bin/ll_linux` lines 38, 68; `scripts/bin/ll_macos` lines 29-30, 504-515

**UNSPECIFIED:**
- Behavior when `--` appears multiple times
- Behavior when `--` is the only argument

### 2.5 Default Operand

When no operands are provided, implementations MUST list the current directory (`.`).

**Traceability:**
- Test: `tests/ll_linux/10_core.bats` - default case in flag matrix
- Script: `scripts/bin/ll_macos` lines 518-520

---

## 3. Output Format Specification

### 3.1 Line Structure

**Column Order:**

Tests verify output format via canonicalization comparison (not direct assertions about column order):

1. **Blocks** (optional, if `-s` or `--size`)
2. **Permissions**
3. **Links**
4. **Owner** (optional, if not `-g`)
5. **Group** (optional, if not `-G/-o/--no-group`)
6. **Size**
7. **Relative Time**: Format `[in ]<num> <unit>`
8. **Filename**: Quoted if contains spaces/tabs, symlink format: `"name" -> "target"`

**Traceability:**
- Test: `tests/ll_linux/10_core.bats` - canonicalization comparison (indirect verification)
- Tooling: `scripts/dev/ls-compare-canon-script.pl`, `scripts/dev/ls-compare-canon-ls.pl`

**UNSPECIFIED:**
- Exact column order (verified indirectly via canonicalization, not directly asserted)
- Exact column alignment (left/right)
- Exact column widths
- Behavior when column values exceed terminal width
- Multi-line output for very long filenames
- Directory headers format (not tested)

### 3.2 Blocks Column

**UNSPECIFIED:**
- Presence and position of blocks column when `-s` or `--size` is specified (verified indirectly via canonicalization, not directly asserted)
- Blocks column alignment
- Block size calculation method (implementation detail)
- Human-readable formatting of blocks when combined with `-h/--si` (not directly tested)
- **Exact decimal precision in blocks formatting** (e.g., `4.0K` vs `4K`) - normalized away by test tooling (see section 3.9.1)
- Behavior when blocks cannot be determined

**Implementation Detail (Non-Normative):**
- Tests include `-s` variants in flag matrix at `tests/ll_linux/10_core.bats`
- Canonicalization comparison verifies blocks column presence indirectly
- Scripts implement blocks column at `scripts/bin/ll_linux` lines 488-515, 599-608; `scripts/bin/ll_macos` lines 869-879

### 3.3 Owner/Group Suppression

- When `-g` is specified, the owner column MUST be omitted
- When `-G`, `--no-group`, or `-o` is specified, the group column MUST be omitted
- When both `-g` and `-G` are specified, both columns MUST be omitted

**Traceability:**
- Test: `tests/ll_linux/10_core.bats` - owner variants in flag matrix
- Script: `scripts/bin/ll_linux` lines 494-515, 615-627; `scripts/bin/ll_macos` lines 921-926

### 3.4 "You" Substitution

When the current user's name matches the file owner name:
- The owner name MUST be replaced with the string `"you"` (unless `-n` or `--numeric-uid-gid` is specified)
- The string `"you"` MUST be colorized (see Color Specification)

**Traceability:**
- Test: `tests/ll_linux/40_color.bats` - "owner you"
- Script: `scripts/bin/ll_linux` lines 583-586, 616-620; `scripts/bin/ll_macos` lines 843-846

**UNSPECIFIED:**
- Behavior when `USER` environment variable is unset
- Behavior when `id -un` fails
- Case sensitivity of username matching

### 3.5 Symlink Formatting

Symlinks MUST be formatted as:
```
"name" -> "target"
```

Where:
- Both `name` and `target` are quoted if they contain spaces or tabs
- The arrow `->` is surrounded by spaces
- The format is used even for broken symlinks

**Traceability:**
- Test: `tests/ll_linux/20_paths.bats` - "symlink-to-file1", "broken-symlink"
- Test: `tests/ll_linux/30_edge.bats` - "symlink target space", "symlink target tab"
- Test: `tests/ll_macos/10_core.bats` - "symlink arrows preserved"
- Script: `scripts/bin/ll_linux` lines 321-328; `scripts/bin/ll_macos` lines 100-117

**UNSPECIFIED:**
- Behavior when symlink target cannot be read
- Behavior for symlinks to directories vs files
- Formatting when symlink name or target contains quotes

### 3.6 Hidden Files

#### 3.6.1 Default Behavior

By default, hidden files (files starting with `.`) MUST be excluded from directory listings.

**Traceability:**
- Test: `tests/ll_linux/20_paths.bats` - "hidden files default excluded"
- Script: `scripts/bin/ll_linux` (delegates to `ls`), `scripts/bin/ll_macos` lines 623

#### 3.6.2 `-a` Flag

When `-a` is specified:
- Hidden files MUST be included
- The entries `.` and `..` MUST be included

**Traceability:**
- Test: `tests/ll_linux/20_paths.bats` - "-a includes hidden and dot entries"
- Script: `scripts/bin/ll_linux` (delegates to `ls -a`)

#### 3.6.3 `-A` Flag

When `-A` is specified:
- Hidden files MUST be included
- The entries `.` and `..` MUST be excluded

**Traceability:**
- Test: `tests/ll_linux/20_paths.bats` - "-A includes hidden but excludes dot entries"
- Script: `scripts/bin/ll_linux` (delegates to `ls -A`)

**UNSPECIFIED:**
- Hidden file behavior for `ll_macos` (not explicitly tested)
- Behavior when listing specific hidden files as operands (e.g., `ll .hidden_file`)

### 3.7 Total Line

**UNSPECIFIED:**
- Presence, format, and position of total line (not directly tested)
- Format: `total <blocks>` or `toplam <blocks>` (locale-aware) - not asserted by tests
- Behavior for empty directories
- Locale detection method

**Implementation Detail (Non-Normative):**
- Canonicalization scripts (`scripts/dev/ls-compare-canon-*.pl`) drop total lines, suggesting they exist in output
- Scripts generate total lines at `scripts/bin/ll_linux` lines 114-122, 656-659; `scripts/bin/ll_macos` lines 540-545, 979-991
- However, no tests directly assert the presence, format, or content of total lines

### 3.8 Single File Listing

**UNSPECIFIED:**
- Output format when listing a single file (not a directory) - not explicitly tested
- Single file listing behavior for both `ll_linux` and `ll_macos`

**Implementation Detail (Non-Normative):**
- `ll_linux` implements a fast path for single file listings at `scripts/bin/ll_linux` lines 130-206
- However, no tests directly assert the output format for single file listings

### 3.9 Tooling Normalization (Non-Normative)

Test comparison tooling applies normalization to ensure deterministic comparisons. These normalizations are **not part of the user-visible contract** and are applied only during test comparisons.

#### 3.9.1 Blocks Token Normalization

When `LS_COMPARE_HAS_BLOCKS=1` (set when `-s` or `--size` flags are used), canonicalization scripts normalize blocks column tokens:

- **Trailing `.0` removal**: `4.0K` → `4K`, `12.0M` → `12M`
- **Decimal separator unification**: Comma separators (locale-dependent) are converted to dots: `4,0K` → `4.0K` → `4K`
- **Zero blocks normalization**: `0B` or `0.0B` → `0`
- **Unit letter normalization**: 
  - With `--si` flag (`LS_COMPARE_HAS_SI=1`): `K` → `k` (lowercase kilo)
  - With `-h` flag (default): `k` → `K` (uppercase kilo)

**UNSPECIFIED:**
- Exact decimal precision in blocks column output (e.g., whether `4.0K` vs `4K` is emitted)
- Locale-dependent decimal separator handling in raw output
- These details are normalized away by tooling and not part of the tested contract

**Implementation Detail (Non-Normative):**
- Normalization implemented in `scripts/dev/ls-compare-canon-ls.pl` lines 69-95 (`normalize_blocks_token` function)
- Normalization implemented in `scripts/dev/ls-compare-canon-script.pl` lines 38-64 (`normalize_blocks_token` function)
- Applied when `LS_COMPARE_HAS_BLOCKS=1` is set by test harness (`tests/ll_linux/00_harness.bash` lines 304-326)

#### 3.9.2 macOS Path Prefix Normalization

In macOS test comparisons, the reference implementation strips leading `./` prefixes from filenames to match `ll_macos` behavior.

**UNSPECIFIED:**
- Whether leading `./` prefixes are preserved in filename output when listing current directory entries
- This detail is normalized away by test harness and not part of the tested contract

**Implementation Detail (Non-Normative):**
- Reference implementation strips `./` prefix at `tests/ll_macos/00_harness.bash` lines 313-316 (`ll_macos_ref_line` function)
- `ll_macos` implementation strips `./` prefix at `scripts/bin/ll_macos` lines 478-480, 580-581, 650-651
- Normalization ensures parity comparison succeeds regardless of whether `stat -f %N` includes the prefix

---

## 4. Relative Time Specification

### 4.1 Time Buckets

Relative time MUST be formatted using the following buckets and labels:

| Condition | Label | Example |
|-----------|-------|---------|
| `delta < 120` seconds | `sec` | `5 sec` |
| `120 <= delta < 3600` seconds | `min` | `10 min` |
| `3600 <= delta < 172800` seconds | `hrs` | `3 hrs` |
| `172800 <= delta < 3888000` seconds | `day` | `5 day` |
| `3888000 <= delta < 31536000` seconds | `mon` | `2 mon` |
| `delta >= 31536000` seconds | `yr` | `1 yr` |

Where `delta = abs(now - mtime)` and `now` is controlled by `LL_NOW_EPOCH` environment variable if set, otherwise system time.

**Traceability:**
- Test: `tests/ll_linux/30_edge.bats` - "mixed time widths (future years)"
- Test: `tests/ll_macos/10_core.bats` - "time buckets and colors"
- Script: `scripts/bin/ll_linux` lines 375-391; `scripts/bin/ll_macos` lines 176-210

### 4.2 Future Time Prefix

When file modification time is in the future (relative to `now`):
- The prefix `"in"` MUST appear before the number
- Format: `in <num> <unit>`
- The entire time field MUST be colorized (see Color Specification)

**Traceability:**
- Test: `tests/ll_linux/30_edge.bats` - "future-only prefix column"
- Test: `tests/ll_linux/40_color.bats` - "future time uses cfut"
- Script: `scripts/bin/ll_linux` lines 380, 643; `scripts/bin/ll_macos` lines 183-186, 891-892

### 4.3 Time Field Alignment

**UNSPECIFIED:**
- Time field alignment (left/right alignment of number and unit components)
- Width calculation and accommodation rules
- Behavior when time values exceed expected ranges

**Implementation Detail (Non-Normative):**
- Canonicalization tooling (`scripts/dev/ls-compare-canon-script.pl` lines 235-240) calculates widths
- Scripts implement alignment at `scripts/bin/ll_linux` lines 568-571, 640-647; `scripts/bin/ll_macos` lines 886-897
- However, no tests directly assert alignment behavior

---

## 5. Color Specification

### 5.1 Color Output

Tests assert that ANSI color codes are present in output under test conditions.

**Traceability:**
- Test: `tests/ll_linux/40_color.bats` - all color tests assert specific ANSI codes are present
- Test: `tests/ll_macos/10_core.bats` - color assertions verify ANSI codes

**UNSPECIFIED:**
- Whether colors are always emitted or conditionally emitted (tests only verify presence under test conditions)
- TTY detection behavior
- `NO_COLOR` environment variable support
- `CLICOLOR` environment variable support
- `--color=never` / `--color=none` flag behavior
- Behavior when output is piped to non-TTY

### 5.2 Color Palette

The following ANSI escape sequences MUST be used:

#### 5.2.1 Permission Colors

| Character | ANSI Code | Description |
|-----------|-----------|-------------|
| `d` (directory) | `\033[38;5;122m` | Cyan-green |
| `l` (symlink) | `\033[38;5;190m` | Yellow |
| `r` (read) | `\033[38;5;119m` | Green |
| `w` (write) | `\033[38;5;216m` | Orange |
| `x` (execute) | `\033[38;5;124m` | Red |
| `+` (ACL) | `\033[38;5;129m` | Magenta |

**Traceability:**
- Test: `tests/ll_linux/40_color.bats` - "perms codes", "perms plus (optional)"
- Script: `scripts/bin/ll_linux` lines 242-247, 330-343; `scripts/bin/ll_macos` lines 216-221, 247-268

#### 5.2.2 Owner Colors

| Owner | ANSI Code | Condition |
|-------|-----------|-----------|
| `you` | `\033[38;5;66m` | When current user matches file owner |
| `root` | `\033[38;5;160m` | When owner is root |

**Traceability:**
- Test: `tests/ll_linux/40_color.bats` - "owner you", "owner root (optional)"
- Script: `scripts/bin/ll_linux` lines 250-251, 619-620; `scripts/bin/ll_macos` lines 223-224, 850-854

#### 5.2.3 Size Colors (Numeric)

| Size Range | ANSI Code |
|------------|-----------|
| `< 1024` bytes | `\033[38;5;240m` |
| `< 1048576` bytes (1MB) | `\033[38;5;250m` |
| `< 1073741824` bytes (1GB) | `\033[38;5;117m` |
| `< 1099511627776` bytes (1TB) | `\033[38;5;208m` |
| `>= 1099511627776` bytes (1TB) | `\033[38;5;160m` |

**Traceability:**
- Test: `tests/ll_linux/40_color.bats` - "size tiers (numeric)"
- Script: `scripts/bin/ll_linux` lines 254-258, 345-351; `scripts/bin/ll_macos` lines 226-230, 270-278

#### 5.2.4 Size Colors (Human-Readable Suffixes)

| Suffix | ANSI Code | Style |
|--------|-----------|-------|
| `K` | `\033[1;38;5;107m` | Bold green |
| `M` | `\033[1;38;5;123m` | Bold cyan |
| `G` | `\033[1;38;5;220m` | Bold yellow |
| `T` | `\033[1;38;5;167m` | Bold red |
| `B` | `\033[1;38;5;248m` | Bold gray |

**Traceability:**
- Test: `tests/ll_linux/40_color.bats` - "size labels (human)"
- Script: `scripts/bin/ll_linux` lines 260-265, 353-373; `scripts/bin/ll_macos` lines 232-236, 280-307

#### 5.2.5 Time Bucket Colors

| Unit | ANSI Code |
|------|-----------|
| `sec` | `\033[38;5;124m` |
| `min` | `\033[38;5;215m` |
| `hrs` | `\033[38;5;196m` |
| `day` | `\033[38;5;230m` |
| `mon` | `\033[38;5;151m` |
| `yr` | `\033[38;5;241m` |
| Future (`in`) | `\033[38;5;39m` |

**Traceability:**
- Test: `tests/ll_linux/40_color.bats` - "time bucket colors", "future time uses cfut"
- Script: `scripts/bin/ll_linux` lines 268-274, 392-402; `scripts/bin/ll_macos` lines 238-245, 426-445

#### 5.2.6 Reset Code

**UNSPECIFIED:**
- Whether color sequences are terminated with reset codes (not directly tested)

**Implementation Detail (Non-Normative):**
- Scripts include reset codes (`\033[0m`) at `scripts/bin/ll_linux` lines 239, all color functions; `scripts/bin/ll_macos` lines 214, all color functions
- However, tests only assert presence of color codes, not their termination

---

## 6. Size Formatting Specification

### 6.1 Human-Readable Sizes (`-h`)

When `-h` or `--human-readable` is specified, sizes are formatted in human-readable format.

**Traceability:**
- Test: `tests/ll_linux/10_core.bats` - flag matrix includes `-h`, canonicalization verifies format

**UNSPECIFIED:**
- Exact unit labels (base-1024 vs base-1000) - verified indirectly via canonicalization
- Unit casing (uppercase vs lowercase) - verified indirectly via canonicalization
- Decimal precision - verified indirectly via canonicalization
- Trailing `.0` trimming behavior - verified indirectly via canonicalization

**Implementation Detail (Non-Normative):**
- Scripts implement base-1024 units (`B`, `K`, `M`, `G`, `T`) with uppercase at `scripts/bin/ll_linux` lines 353-373; `scripts/bin/ll_macos` lines 138-173
- Canonicalization scripts normalize format for comparison

### 6.2 SI Sizes (`--si`)

When `--si` is specified, sizes are formatted in SI (base-1000) human-readable format.

**Traceability:**
- Test: `tests/ll_linux/10_core.bats` - flag matrix includes `--si`, canonicalization verifies format

**UNSPECIFIED:**
- Exact unit labels and casing (lowercase `k` vs uppercase `K`) - verified indirectly via canonicalization
- Decimal precision - verified indirectly via canonicalization
- Trailing `.0` trimming behavior - verified indirectly via canonicalization

**Implementation Detail (Non-Normative):**
- Script implements base-1000 units with lowercase `k` at `scripts/bin/ll_linux` lines 353-373
- Canonicalization scripts normalize format for comparison

**UNSPECIFIED:**
- Behavior when `--si` is used with `ll_macos` (tests skip this case, no assertion about rejection or behavior)
- Whether `ll_macos` rejects `--si`, ignores it, or handles it differently

**Implementation Detail (Non-Normative):**
- Comparison tooling (`scripts/dev/ls-compare` lines 574-578) skips `--si` tests for `ll_macos` because BSD `ls` does not support it
- However, no test directly asserts what happens when `--si` is passed to `ll_macos`

### 6.3 Numeric Sizes

When neither `-h` nor `--si` is specified:
- Sizes MUST be displayed as raw byte counts
- Sizes MUST be colorized according to Size Colors (Numeric) specification

**Traceability:**
- Test: `tests/ll_linux/10_core.bats` - flag matrix default case
- Script: `scripts/bin/ll_linux` lines 634-638; `scripts/bin/ll_macos` lines 862-866

---

## 7. Filename Handling Specification

### 7.1 Quoting Rules

Filenames MUST be quoted if they contain:
- Spaces
- Tabs

Filenames MUST NOT be quoted if they contain only:
- Regular characters (letters, numbers, punctuation)
- Unicode characters (without spaces/tabs)

**Traceability:**
- Test: `tests/ll_linux/20_paths.bats` - "a b.txt", "leading space file", "tab file", "unicode file"
- Script: `scripts/bin/ll_linux` lines 317-318; `scripts/bin/ll_macos` lines 88-98

### 7.2 Special Characters

The following special characters in filenames MUST be preserved:
- Leading spaces
- Tabs
- Unicode characters (e.g., `İçerik-ğüşöç.txt`)

**Traceability:**
- Test: `tests/ll_linux/20_paths.bats` - all filename edge cases
- Test: `tests/ll_macos/10_core.bats` - "tricky filenames preserved"
- Script: `scripts/bin/ll_linux` lines 454-477 (tail preservation); `scripts/bin/ll_macos` lines 88-98

**UNSPECIFIED:**
- Behavior for filenames containing newlines
- Behavior for filenames containing control characters
- Maximum filename length handling

---

## 8. Error Handling & Exit Codes

### 8.1 Tested Error Scenarios

#### 8.1.1 Nonexistent Path

When a path operand does not exist:
- Exit code MUST match `ls -l` exit code
- stderr output MUST match `ls -l` stderr output exactly

**Traceability:**
- Test: `tests/ll_linux/30_edge.bats` - "nonexistent path errors match ls"
- Script: `scripts/bin/ll_linux` (error propagation from `ls`)

#### 8.1.2 Invalid Option

When an invalid option is provided:
- Exit code MUST match `ls -l` exit code
- stderr output MUST match `ls -l` stderr output exactly

**Traceability:**
- Test: `tests/ll_linux/30_edge.bats` - "invalid option errors match ls"
- Script: `scripts/bin/ll_linux` (error propagation from `ls`)

#### 8.1.3 Unreadable Directory

When a directory operand cannot be read (permission denied):
- Exit code MUST match `ls -l` exit code
- stderr output MUST match `ls -l` stderr output exactly

**Traceability:**
- Test: `tests/ll_linux/30_edge.bats` - "unreadable directory errors match ls"
- Script: `scripts/bin/ll_linux` (error propagation from `ls`)

**UNSPECIFIED:**
- Exit code for successful runs (assumed 0, not explicitly tested)
- Exit codes for other error conditions
- stderr content for other error conditions
- Error handling for permission denied on individual files (only directories tested)

---

## 9. Platform-Specific Behavior

### 9.1 Common Contract

Tests assert that the following behaviors are identical across both implementations:
- Color palette (same ANSI codes) - directly tested
- Time bucket thresholds and labels - directly tested
- Filename quoting rules - directly tested
- Owner "you" substitution - directly tested
- Permission color mapping - directly tested

**Traceability:**
- Test: `tests/ll_linux/40_color.bats`, `tests/ll_macos/10_core.bats` - color parity assertions
- Test: `tests/ll_linux/30_edge.bats`, `tests/ll_macos/10_core.bats` - time bucket tests
- Test: `tests/ll_linux/20_paths.bats`, `tests/ll_macos/10_core.bats` - filename handling tests

**UNSPECIFIED:**
- Column order and formatting parity (verified via tooling canonicalization, not direct test assertions)
- Relative time calculation logic parity (verified via tooling, not direct test assertions)

**Implementation Detail (Non-Normative):**
- Tooling (`scripts/dev/ll-compare`) compares outputs across platforms, suggesting parity
- However, cross-platform parity is primarily verified via canonicalization comparison, not direct test assertions

### 9.2 Linux Implementation Requirements

#### 9.2.1 Test Environment Notes

**UNSPECIFIED:**
- Tooling requirements for `ll_linux` (not part of user-visible contract)

**Implementation Detail (Non-Normative):**
- `ll_linux` implementation checks for GNU `ls` with `--time-style=+%s` support at `scripts/bin/ll_linux` lines 72-107
- Test harness detects GNU ls at `tests/ll_linux/00_harness.bash` lines 22-29
- These are implementation and test environment details, not user-visible contract requirements

#### 9.2.2 Test Environment Notes

**UNSPECIFIED:**
- Exact `ls` invocation flags (not part of user-visible contract)

**Implementation Detail (Non-Normative):**
- `ll_linux` invokes `ls` with `--color -l --time-style=+%s` at `scripts/bin/ll_linux` line 112
- Test harness uses same flags at `tests/ll_linux/00_harness.bash` line 211
- These are implementation details, not user-visible contract requirements

### 9.3 macOS Implementation Requirements

#### 9.3.1 Test Environment Notes

**UNSPECIFIED:**
- Tooling requirements for `ll_macos` (not part of user-visible contract)

**Implementation Detail (Non-Normative):**
- `ll_macos` uses BSD toolchain (`/bin/ls`, `/usr/bin/stat`, `/usr/bin/awk`) as seen at `scripts/bin/ll_macos` lines 612-623, 462-496
- Test harness checks for these binaries at `tests/ll_macos/00_harness.bash` lines 36-38
- These are implementation and test environment details, not user-visible contract requirements

#### 9.3.2 `--si` Flag

**UNSPECIFIED:**
- Behavior when `--si` is passed to `ll_macos` (tests skip this case, no assertion about rejection or behavior)

**Implementation Detail (Non-Normative):**
- Comparison tooling (`scripts/dev/ls-compare` lines 574-578) skips `--si` tests for `ll_macos` because BSD `ls` does not support it
- However, no test directly asserts what happens when `--si` is passed to `ll_macos`

#### 9.3.3 Locale-Aware Decimal Separator

**UNSPECIFIED:**
- Locale-aware decimal separator behavior (not directly tested)

**Implementation Detail (Non-Normative):**
- Script implements locale-aware decimal separator at `scripts/bin/ll_macos` lines 534-538, 354-359
- However, no tests directly assert this behavior

---

## 10. File Type Handling

### 10.1 Tested File Types

The following file types are **tested and MUST be handled**:

| Type | Test Case | Linux | macOS |
|------|-----------|-------|-------|
| Regular files | `file1.txt` | ✅ | ✅ |
| Directories | `dir1` | ✅ | ✅ |
| Symlinks | `symlink-to-file1` | ✅ | ✅ |
| Broken symlinks | `broken-symlink` | ✅ | ✅ |
| FIFOs | `fifo1` | ✅ | ✅ |
| Setuid files | `setuid-file` | ✅ | ✅ |
| Setgid files | `setgid-file` | ✅ | ✅ |
| Setgid directories | `setgid-dir` | ✅ | ✅ |
| Sticky directories | `sticky-dir` | ✅ | ✅ |
| Hidden files | `.hidden_file` | ✅ | UNSPECIFIED |

**Traceability:**
- Test: `tests/ll_linux/20_paths.bats` - all file type tests
- Test: `tests/ll_macos/10_core.bats` - basic file types

**UNSPECIFIED:**
- Block devices
- Character devices
- Sockets
- Files with extended attributes (beyond ACL `+` marker)
- Permission denied errors for individual files (only directories tested)

---

## 11. Traceability Appendix

### 11.1 Specification Section → Test/Tooling Mapping

| Spec Section | Test Files | Tooling Files | Script Locations |
|--------------|------------|---------------|------------------|
| 1. Wrapper | `tests/ll/10_wrapper_stub.bats` | | `scripts/bin/ll` |
| 2.1 Supported Flags | `tests/ll_linux/10_core.bats`, `tests/ll_macos/10_core.bats` | `scripts/dev/ll-compare`, `scripts/dev/ls-compare` | `scripts/bin/ll_linux` lines 26-69, `scripts/bin/ll_macos` lines 16-72 |
| 2.2 Flag Synonyms | `tests/ll_linux/10_core.bats` | | `scripts/bin/ll_linux` lines 36-69 |
| 2.3 Operand Ordering | `tests/ll_linux/10_core.bats` | | `scripts/bin/ll_linux` lines 34-69 |
| 2.4 `--` Sentinel | `tests/ll_linux/20_paths.bats` | | `scripts/bin/ll_linux` lines 38, 68 |
| 3.1 Line Structure | `tests/ll_linux/10_core.bats` | `scripts/dev/ls-compare-canon-*.pl` | Both implementations |
| 3.2 Blocks Column | `tests/ll_linux/10_core.bats` | | `scripts/bin/ll_linux` lines 488-515 |
| 3.3 Owner/Group Suppression | `tests/ll_linux/10_core.bats` | | `scripts/bin/ll_linux` lines 494-515 |
| 3.4 "You" Substitution | `tests/ll_linux/40_color.bats` | | `scripts/bin/ll_linux` lines 583-586 |
| 3.5 Symlink Formatting | `tests/ll_linux/20_paths.bats`, `tests/ll_linux/30_edge.bats` | | `scripts/bin/ll_linux` lines 321-328 |
| 3.6 Hidden Files | `tests/ll_linux/20_paths.bats` | | `scripts/bin/ll_linux` (delegates to ls) |
| 3.7 Total Line | Canonicalization scripts | `scripts/dev/ls-compare-canon-*.pl` | `scripts/bin/ll_linux` lines 114-122 |
| 3.8 Single File Fast Path | | | `scripts/bin/ll_linux` lines 130-206 |
| 3.9 Tooling Normalization | `tests/ll_linux/10_core.bats`, `tests/ll_macos/10_core.bats` | `scripts/dev/ls-compare-canon-ls.pl` lines 69-95, `scripts/dev/ls-compare-canon-script.pl` lines 38-64 | `tests/ll_linux/00_harness.bash` lines 304-326, `tests/ll_macos/00_harness.bash` lines 313-316 |
| 4.1 Time Buckets | `tests/ll_linux/30_edge.bats`, `tests/ll_macos/10_core.bats` | | `scripts/bin/ll_linux` lines 375-391 |
| 4.2 Future Time Prefix | `tests/ll_linux/30_edge.bats`, `tests/ll_linux/40_color.bats` | | `scripts/bin/ll_linux` lines 380 |
| 4.3 Time Field Alignment | | `scripts/dev/ls-compare-canon-script.pl` | `scripts/bin/ll_linux` lines 568-571 |
| 5.1 Color Output | `tests/ll_linux/40_color.bats`, `tests/ll_macos/10_core.bats` | | Both implementations |
| 5.2 Color Palette | `tests/ll_linux/40_color.bats` | | `scripts/bin/ll_linux` lines 242-274 |
| 6.1 Human-Readable Sizes | `tests/ll_linux/10_core.bats` | | `scripts/bin/ll_linux` lines 353-373 |
| 6.2 SI Sizes | `tests/ll_linux/10_core.bats` | `scripts/dev/ls-compare` | `scripts/bin/ll_linux` lines 353-373 |
| 7.1 Quoting Rules | `tests/ll_linux/20_paths.bats`, `tests/ll_macos/10_core.bats` | | `scripts/bin/ll_linux` lines 317-318 |
| 7.2 Special Characters | `tests/ll_linux/20_paths.bats` | | `scripts/bin/ll_linux` lines 454-477 |
| 8.1 Error Scenarios | `tests/ll_linux/30_edge.bats` | | `scripts/bin/ll_linux` (error propagation) |
| 9.1 Common Contract | `scripts/dev/ll-compare` | | Both implementations |
| 9.2 Linux Requirements | `tests/ll_linux/00_harness.bash` | | `scripts/bin/ll_linux` lines 72-107 |
| 9.3 macOS Requirements | `tests/ll_macos/00_harness.bash` | `scripts/dev/ls-compare` | `scripts/bin/ll_macos` |
| 10.1 File Types | `tests/ll_linux/20_paths.bats` | | Both implementations |

---

## 12. Change Log

| Version | Date | Changes |
|---------|------|---------|
| 1.1 | 2026-01-09 | Revised to remove normative claims not directly proven by tests; moved implementation details to non-normative sections |
| 1.0 | 2026-01-09 | Initial specification based on test-locked behavior |

---

## References

- **Current-State Report**: `wip/ll_current_state_report.md`
- **Test Suites**: `tests/ll/`, `tests/ll_linux/`, `tests/ll_macos/`
- **Comparison Tools**: `scripts/dev/ll-compare`, `scripts/dev/ls-compare`
- **Implementations**: `scripts/bin/ll`, `scripts/bin/ll_linux`, `scripts/bin/ll_macos`
