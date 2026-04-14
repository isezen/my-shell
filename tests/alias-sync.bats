#!/usr/bin/env bats
# tests/alias-sync.bats
# Test suite for alias synchronization across all shell files
# Verifies that all aliases in shell/aliases.yml are present in all shell-specific aliases.* files
# Uses file parsing instead of environment validation

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Setup: Get project root and verify files exist
setup() {
  TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
  PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"
  ALIASES_YML="${PROJECT_ROOT}/shell/aliases.yml"
  SHELL_DIR="${PROJECT_ROOT}/shell"

  # Verify aliases.yml exists
  [ -f "$ALIASES_YML" ] || skip "aliases.yml not found"
}

# Function to extract alias information from YAML
# Returns: name|shell (one per line)
extract_aliases_from_yaml() {
  local section="$1"
  local in_section=false
  local current_name=""
  local current_shell=""
  local in_alias=false

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Check if we're entering the target section
    if [[ "$line" =~ ^${section}: ]]; then
      in_section=true
      continue
    fi

    # Check if we're leaving the section (next top-level key). Requires
    # the line to be exactly `<key>:` possibly followed by whitespace —
    # this rules out indented nested keys like `  description: foo` and
    # inline-valued fields like `shell: bash`, which the old regex
    # (`^[a-zA-Z_]+:`) would also have matched and silently terminated
    # the section early.
    if [[ "$in_section" == true ]] && [[ "$line" =~ ^[a-z_]+:[[:space:]]*$ ]]; then
      # Output last alias if any
      if [[ -n "$current_name" ]]; then
        echo "${current_name}|${current_shell}"
      fi
      break
    fi

    # Extract alias information
    if [[ "$in_section" == true ]]; then
      # Start of new alias entry
      if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+name:[[:space:]]+(.+)$ ]]; then
        # Output previous alias if any
        if [[ -n "$current_name" ]]; then
          echo "${current_name}|${current_shell}"
        fi
        # Start new alias
        current_name="${BASH_REMATCH[1]}"
        # Remove quotes if present
        current_name="${current_name#\"}"
        current_name="${current_name%\"}"
        current_name="${current_name#\'}"
        current_name="${current_name%\'}"
        # Remove leading/trailing whitespace
        current_name="${current_name#"${current_name%%[![:space:]]*}"}"
        current_name="${current_name%"${current_name##*[![:space:]]}"}"
        current_shell=""
        in_alias=true
      # Shell parameter
      elif [[ "$in_alias" == true ]] && [[ "$line" =~ ^[[:space:]]+shell:[[:space:]]+(.+)$ ]]; then
        current_shell="${BASH_REMATCH[1]}"
        current_shell="${current_shell#\"}"
        current_shell="${current_shell%\"}"
        current_shell="${current_shell#\'}"
        current_shell="${current_shell%\'}"
        current_shell="${current_shell#"${current_shell%%[![:space:]]*}"}"
        current_shell="${current_shell%"${current_shell##*[![:space:]]}"}"
      # End of alias entry (next alias or end of section)
      elif [[ "$in_alias" == true ]] && [[ "$line" =~ ^[[:space:]]*-[[:space:]]+name: ]] || [[ "$line" =~ ^[[:space:]]*$ ]]; then
        # Continue (empty line is OK)
        :
      fi
    fi
  done < "$ALIASES_YML"

  # Output last alias if any
  if [[ -n "$current_name" ]]; then
    echo "${current_name}|${current_shell}"
  fi
}

# Escape POSIX extended regex metacharacters so an alias name can be
# inlined into a grep -E pattern as a literal. Critical for names that
# contain regex metacharacters — the project has '..', '...', '....',
# '.....', '......', '.1'..'.5', 'du.', 'dusf.', 'rm!'. Without escaping,
# '..' would match "any two characters" and false-positive on almost
# every function definition.
_escape_regex() {
  printf '%s' "$1" | sed 's/[][\.*^$/()+?{}|]/\\&/g'
}

# Function to check if alias exists in file (file parsing).
# Uses word-anchored extended-regex patterns so that e.g. 'c' does NOT
# match 'clhist()' / 'function clhist'. Before this change the test
# used grep -F on a bare prefix and silently false-positived across
# every prefix-ambiguous name.
check_alias_in_file() {
  local file="$1"
  local alias_name="$2"
  local shell_type="$3"
  local re_name
  re_name="$(_escape_regex "$alias_name")"

  case "$shell_type" in
    bash|zsh)
      # Match any of these *complete-token* declarations at line start
      # (possibly indented inside an if-block):
      #   alias NAME=...             alias "NAME"=...  alias 'NAME'=...
      #   NAME() { ... }             NAME () { ... }
      #   function NAME() { ... }    function NAME { ... }   (bash rm!)
      #
      # The token boundary is enforced by requiring the character AFTER
      # ${re_name} to be one of (, space, or {, so 'c' cannot match
      # 'clhist(' and 'du.' cannot match 'du.fish'-like substrings.
      if grep -qE "^[[:space:]]*alias[[:space:]]+${re_name}=" "$file" 2>/dev/null \
      || grep -qE "^[[:space:]]*alias[[:space:]]+['\"]${re_name}['\"]=" "$file" 2>/dev/null \
      || grep -qE "^[[:space:]]*${re_name}[[:space:]]*\(\)[[:space:]]*\{" "$file" 2>/dev/null \
      || grep -qE "^[[:space:]]*function[[:space:]]+${re_name}[[:space:]]*(\(\))?[[:space:]]*\{" "$file" 2>/dev/null; then
        return 0
      fi
      return 1
      ;;
    fish)
      # fish requires "function NAME" on its own logical line, NAME must
      # be followed by whitespace or end-of-line (NOT another identifier
      # character). This prevents 'c' from matching 'function cdh'.
      if grep -qE "^[[:space:]]*function[[:space:]]+${re_name}([[:space:]]|$)" "$file" 2>/dev/null; then
        return 0
      fi
      return 1
      ;;
    *)
      return 1
      ;;
  esac
}
export -f _escape_regex check_alias_in_file

# Function to check if alias should be checked for this shell
should_check_alias() {
  local alias_shell="$1"
  local current_shell="$2"

  # If shell is specified and doesn't match, skip
  if [[ -n "$alias_shell" ]] && [[ "$alias_shell" != "$current_shell" ]]; then
    return 1
  fi

  return 0
}

# Extract all aliases from both sections
# Use parallel arrays instead of associative array for bash 3.2 compatibility
load_aliases_from_yaml() {
  alias_names=()
  alias_shells=()

  while IFS='|' read -r name shell; do
    if [[ -n "$name" ]]; then
      alias_names+=("$name")
      alias_shells+=("$shell")
    fi
  done < <(extract_aliases_from_yaml "aliases")

  while IFS='|' read -r name shell; do
    if [[ -n "$name" ]]; then
      alias_names+=("$name")
      alias_shells+=("$shell")
    fi
  done < <(extract_aliases_from_yaml "dynamic_aliases")
}

# Test: All aliases from YAML are present in bash aliases file
@test "all aliases from YAML are present in bash aliases.bash" {
  load_aliases_from_yaml

  [ ${#alias_names[@]} -gt 0 ] || skip "No aliases found in aliases.yml"

  bash_file="${SHELL_DIR}/bash/aliases.bash"
  [ -f "$bash_file" ] || skip "bash aliases file not found"

  missing=()
  for i in $(seq 0 $((${#alias_names[@]} - 1))); do
    alias_name="${alias_names[$i]}"
    alias_shell="${alias_shells[$i]}"

    # Check if this alias should be checked for bash
    if should_check_alias "$alias_shell" "bash"; then
      if ! check_alias_in_file "$bash_file" "$alias_name" "bash"; then
        missing+=("$alias_name")
      fi
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    echo "Missing aliases in bash: ${missing[*]}" >&2
  fi

  [ ${#missing[@]} -eq 0 ]
}

# Test: All aliases from YAML are present in zsh aliases file
@test "all aliases from YAML are present in zsh aliases.zsh" {
  load_aliases_from_yaml

  [ ${#alias_names[@]} -gt 0 ] || skip "No aliases found in aliases.yml"

  zsh_file="${SHELL_DIR}/zsh/aliases.zsh"
  [ -f "$zsh_file" ] || skip "zsh aliases file not found"

  missing=()
  for i in $(seq 0 $((${#alias_names[@]} - 1))); do
    alias_name="${alias_names[$i]}"
    alias_shell="${alias_shells[$i]}"

    # Check if this alias should be checked for zsh
    if should_check_alias "$alias_shell" "zsh"; then
      if ! check_alias_in_file "$zsh_file" "$alias_name" "zsh"; then
        missing+=("$alias_name")
      fi
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    echo "Missing aliases in zsh: ${missing[*]}" >&2
  fi

  [ ${#missing[@]} -eq 0 ]
}

# Test: All aliases from YAML are present in fish aliases file
@test "all aliases from YAML are present in fish aliases.fish" {
  load_aliases_from_yaml

  [ ${#alias_names[@]} -gt 0 ] || skip "No aliases found in aliases.yml"

  fish_file="${SHELL_DIR}/fish/aliases.fish"
  [ -f "$fish_file" ] || skip "fish aliases file not found"

  missing=()
  for i in $(seq 0 $((${#alias_names[@]} - 1))); do
    alias_name="${alias_names[$i]}"
    alias_shell="${alias_shells[$i]}"

    # Check if this alias should be checked for fish
    if should_check_alias "$alias_shell" "fish"; then
      if ! check_alias_in_file "$fish_file" "$alias_name" "fish"; then
        missing+=("$alias_name")
      fi
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    echo "Missing aliases in fish: ${missing[*]}" >&2
  fi

  [ ${#missing[@]} -eq 0 ]
}

# ----------------------------------------------------------------------
# Unit tests for check_alias_in_file (P2 #9 regex hardening)
# ----------------------------------------------------------------------
# These exercise the matcher directly on controlled fixtures to prevent
# the word-boundary regressions that used to slip past the integration
# tests above. Without these, a future edit could reintroduce grep -F
# and the three YAML-driven tests would still pass by accident (because
# every name in aliases.yml also appears in every aliases.* file).

@test "check_alias_in_file: bash NAME() {} is detected" {
  local f="$BATS_TEST_TMPDIR/bash.sh"
  printf 'foo() { echo hi; }\n' > "$f"
  check_alias_in_file "$f" "foo" "bash"
}

@test "check_alias_in_file: bash does NOT false-positive on prefix (foo vs foobar)" {
  local f="$BATS_TEST_TMPDIR/bash.sh"
  printf 'foobar() { echo hi; }\n' > "$f"
  run check_alias_in_file "$f" "foo" "bash"
  assert_failure
}

@test "check_alias_in_file: bash 'function NAME { ... }' style (rm! case) is detected" {
  local f="$BATS_TEST_TMPDIR/bash.sh"
  printf 'function rm! { command rm -rf -- "$@"; }\n' > "$f"
  check_alias_in_file "$f" "rm!" "bash"
}

@test "check_alias_in_file: fish 'function NAME' is detected" {
  local f="$BATS_TEST_TMPDIR/fn.fish"
  printf 'function foo\n  echo hi\nend\n' > "$f"
  check_alias_in_file "$f" "foo" "fish"
}

@test "check_alias_in_file: fish does NOT false-positive on prefix (c vs cdh)" {
  local f="$BATS_TEST_TMPDIR/fn.fish"
  printf 'function cdh\n  echo hi\nend\n' > "$f"
  run check_alias_in_file "$f" "c" "fish"
  assert_failure
}

@test "check_alias_in_file: dotted name '..' matches literal dots, not any-char" {
  # '..' as ERE would match any two characters. The _escape_regex helper
  # must escape it to '\.\.' so 'ab()' below does not match.
  local f="$BATS_TEST_TMPDIR/bash.sh"
  printf 'ab() { echo no; }\n..() { cd ..; }\n' > "$f"
  # Positive: literal '..' matches '..() {'
  check_alias_in_file "$f" ".." "bash"
  # Negative: looking for a bogus 'xy' must not match 'ab' even with any-char regex
  run check_alias_in_file "$f" "xy" "bash"
  assert_failure
}
