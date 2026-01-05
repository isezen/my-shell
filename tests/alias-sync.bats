#!/usr/bin/env bats
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
    
    # Check if we're leaving the section (next top-level key)
    if [[ "$in_section" == true ]] && [[ "$line" =~ ^[a-zA-Z_]+: ]]; then
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

# Function to check if alias exists in file (file parsing)
check_alias_in_file() {
  local file="$1"
  local alias_name="$2"
  local shell_type="$3"
  
  case "$shell_type" in
    bash|zsh)
      # Check for: alias name= or name() or function name() or function name {
      # Use -F for literal string matching to avoid regex escaping issues
      if grep -qF "alias ${alias_name}=" "$file" 2>/dev/null || \
         grep -qF "alias \"${alias_name}\"=" "$file" 2>/dev/null || \
         grep -qF "alias '${alias_name}'=" "$file" 2>/dev/null || \
         grep -qF "${alias_name}()" "$file" 2>/dev/null || \
         grep -qF "${alias_name} (" "$file" 2>/dev/null || \
         grep -qF "function ${alias_name}()" "$file" 2>/dev/null || \
         grep -qF "function ${alias_name} {" "$file" 2>/dev/null; then
        return 0
      fi
      return 1
      ;;
    fish)
      # Check for: function name
      if grep -qF "function ${alias_name}" "$file" 2>/dev/null; then
        return 0
      fi
      return 1
      ;;
    *)
      return 1
      ;;
  esac
}

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

