#!/usr/bin/env bash
# Pre-commit hook script to check that all aliases in shell/aliases.yml
# are present in all shell-specific aliases.* files
# Uses file parsing instead of environment validation
#
# Usage: check-aliases.sh [-v|--verbose]
#   -v, --verbose  Show detailed output including matched lines

set -euo pipefail

# Parse command line arguments
VERBOSE=false
if [[ $# -gt 0 ]]; then
    case "$1" in
        -v|--verbose)
            VERBOSE=true
            ;;
        -h|--help)
            echo "Usage: $0 [-v|--verbose]"
            echo "  -v, --verbose  Show detailed output including matched lines"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Use -h or --help for usage information" >&2
            exit 1
            ;;
    esac
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ALIASES_YML="${PROJECT_ROOT}/shell/aliases.yml"
SHELL_DIR="${PROJECT_ROOT}/shell"

# Check if aliases.yml exists
if [[ ! -f "${ALIASES_YML}" ]]; then
    echo -e "${RED}Error: ${ALIASES_YML} not found${NC}" >&2
    exit 1
fi

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
    done < "${ALIASES_YML}"
    
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
            # Use -q for quiet mode unless verbose is enabled
            local grep_flags="-F"
            if [[ "$VERBOSE" != "true" ]]; then
                grep_flags="-qF"
            fi
            
            if grep $grep_flags "alias ${alias_name}=" "$file" 2>/dev/null || \
               grep $grep_flags "alias \"${alias_name}\"=" "$file" 2>/dev/null || \
               grep $grep_flags "alias '${alias_name}'=" "$file" 2>/dev/null || \
               grep $grep_flags "${alias_name}()" "$file" 2>/dev/null || \
               grep $grep_flags "${alias_name} (" "$file" 2>/dev/null || \
               grep $grep_flags "function ${alias_name}()" "$file" 2>/dev/null || \
               grep $grep_flags "function ${alias_name} {" "$file" 2>/dev/null; then
                return 0
            fi
            return 1
            ;;
        fish)
            # Check for: function name
            local grep_flags="-F"
            if [[ "$VERBOSE" != "true" ]]; then
                grep_flags="-qF"
            fi
            if grep $grep_flags "function ${alias_name}" "$file" 2>/dev/null; then
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

if [[ ${#alias_names[@]} -eq 0 ]]; then
    echo -e "${YELLOW}Warning: No aliases found in ${ALIASES_YML}${NC}" >&2
    exit 0
fi

# Check each shell file
bash_file="${SHELL_DIR}/bash/aliases.bash"
fish_file="${SHELL_DIR}/fish/aliases.fish"
zsh_file="${SHELL_DIR}/zsh/aliases.zsh"

missing_aliases=()
errors=0

# Check bash
if [[ ! -f "$bash_file" ]]; then
    echo -e "${RED}Error: ${bash_file} not found${NC}" >&2
    exit 1
fi

if [[ "$VERBOSE" == "true" ]]; then
    echo "Checking aliases in bash..." >&2
fi
for i in $(seq 0 $((${#alias_names[@]} - 1))); do
    alias_name="${alias_names[$i]}"
    alias_shell="${alias_shells[$i]}"
    
    # Check if this alias should be checked for bash
    if ! should_check_alias "$alias_shell" "bash"; then
        continue
    fi
    
    # Check if alias exists in file
    if ! check_alias_in_file "$bash_file" "$alias_name" "bash"; then
        missing_aliases+=("bash:${alias_name}")
        errors=$((errors + 1))
    fi
done

# Check zsh
if [[ ! -f "$zsh_file" ]]; then
    echo -e "${RED}Error: ${zsh_file} not found${NC}" >&2
    exit 1
fi

if [[ "$VERBOSE" == "true" ]]; then
    echo "Checking aliases in zsh..." >&2
fi
for i in $(seq 0 $((${#alias_names[@]} - 1))); do
    alias_name="${alias_names[$i]}"
    alias_shell="${alias_shells[$i]}"
    
    # Check if this alias should be checked for zsh
    if ! should_check_alias "$alias_shell" "zsh"; then
        continue
    fi
    
    # Check if alias exists in file
    if ! check_alias_in_file "$zsh_file" "$alias_name" "zsh"; then
        missing_aliases+=("zsh:${alias_name}")
        errors=$((errors + 1))
    fi
done

# Check fish
if [[ ! -f "$fish_file" ]]; then
    echo -e "${RED}Error: ${fish_file} not found${NC}" >&2
    exit 1
fi

if [[ "$VERBOSE" == "true" ]]; then
    echo "Checking aliases in fish..." >&2
fi
for i in $(seq 0 $((${#alias_names[@]} - 1))); do
    alias_name="${alias_names[$i]}"
    alias_shell="${alias_shells[$i]}"
    
    # Check if this alias should be checked for fish
    if ! should_check_alias "$alias_shell" "fish"; then
        continue
    fi
    
    # Check if alias exists in file
    if ! check_alias_in_file "$fish_file" "$alias_name" "fish"; then
        missing_aliases+=("fish:${alias_name}")
        errors=$((errors + 1))
    fi
done

# Report results
if [[ $errors -gt 0 ]]; then
    echo -e "${RED}Error: Missing aliases detected!${NC}" >&2
    echo -e "${RED}The following aliases are missing from shell files:${NC}" >&2
    echo "" >&2
    
    for missing in "${missing_aliases[@]}"; do
        shell="${missing%%:*}"
        alias_name="${missing#*:}"
        echo -e "${RED}  - ${shell}: missing '${alias_name}'${NC}" >&2
    done
    
    echo "" >&2
    echo -e "${YELLOW}Please ensure all aliases in ${ALIASES_YML} are present in all shell-specific aliases.* files.${NC}" >&2
    exit 1
fi

echo -e "${GREEN}✓ All aliases are synchronized across all shell files${NC}"
exit 0
