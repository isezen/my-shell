#!/bin/bash
# my-shell bash initialization
# This file sources all bash configuration components

MY_SHELL_ROOT="${MY_SHELL_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

# Source components
source "$MY_SHELL_ROOT/shell/bash/env.bash"
source "$MY_SHELL_ROOT/shell/bash/aliases.bash"
source "$MY_SHELL_ROOT/shell/bash/prompt.bash"

