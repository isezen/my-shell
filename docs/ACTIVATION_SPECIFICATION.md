# Activation System Specification (Revised)

This document defines the expected behavior of the `my-shell` environment activation system. It is the reference for implementation and tests.

## 1. Overview

The activation system is conceptually similar to Python’s `venv`: it modifies the current shell environment to enable project-specific commands, configuration, and prompt indicators, and provides a clean way to revert those changes.

### 1.1 Core Purpose

- Provide access to commands in `scripts/` without the `./` prefix
- Automatically load shell-specific configuration files
- Visually indicate the environment (prompt prefix)
- Switch between Bash, Zsh, and Fish for testing
- Support quick iteration via `reactivate`

### 1.2 Supported Shells

- **Bash**: 4.0+
- **Zsh**: modern versions recommended (minimum version not enforced)
- **Fish**: 4.0+

### 1.3 Components

- **Shell-local activators**:
  - `env/activate.bash`
  - `env/activate.zsh`
  - `env/activate.fish`
- **Global switcher**:
  - `env/activate` (a Bash script)

> Note: The global switcher is implemented in Bash and cannot be sourced by Fish.

---

## 2. Activation Scenarios

### 2.1 Scenario A: Activation in Current Shell (Direct Source)

**Command:**
```bash
source env/activate.bash  # Bash
source env/activate.zsh   # Zsh
source env/activate.fish  # Fish
```

**Behavior:**
1. `MY_SHELL_ROOT` is set to the project root directory.
2. If `MY_SHELL_ACTIVATED` is already set, print `"my-shell environment is already activated"` and return (no-op).
3. Set `MY_SHELL_ACTIVATION_MODE=source`.
4. Save a PATH snapshot to `MY_SHELL_OLD_PATH` for exact restoration.
5. Prepend `"$MY_SHELL_ROOT/scripts/bin"` to `PATH`.
6. Source shell-specific config via single entrypoint:
   - Bash: `shell/bash/init.bash`
   - Zsh: `shell/zsh/init.zsh`
   - Fish: `shell/fish/init.fish`
7. Define `colortable`:
   - Bash/Zsh: alias calling the underlying script
   - Fish: function calling the underlying script
8. Add `(my-shell)` prefix to the prompt:
   - Bash/Zsh: modify `PS1` and store `MY_SHELL_OLD_PS1`
   - Fish: wrap `fish_prompt` using the strategy in Scenario 7.2
9. Define `deactivate` and `reactivate` functions.
10. Set `MY_SHELL_ACTIVATED=1`.
11. Print `"my-shell environment activated (<shell>)"`.

**Result:**
- Same shell session continues.
- Environment can be reverted by running `deactivate`.

---

### 2.2 Scenario B: Global Switcher Activation in Same Shell (Bash/Zsh Only)

**Command:**
```bash
./env/activate
./env/activate bash
./env/activate zsh
```

**Behavior:**
1. Global switcher detects the current shell.
2. **Check if already activated**: If `MY_SHELL_ACTIVATED` is set, print `"my-shell environment is already activated"` and exit (no-op). This prevents unnecessary re-activation and shell spawning.
3. If requested shell equals current shell and it is Bash or Zsh:
   - Execute `source "$MY_SHELL_ROOT/env/activate.<bash|zsh>"`.
4. Follow Scenario 2.1 behavior (activation mode remains `source`).

**Result:**
- Same process session continues.
- No shell replacement occurs.
- If already activated, no action is taken.

---

### 2.3 Scenario C: Fish Activation via Global Switcher (Exec-Activated Fish Session)

**Command:**
```bash
./env/activate
./env/activate fish
```

**Behavior:**
1. Global switcher detects the current shell as Fish (or the user requested Fish).
2. **Check if already activated**: If `MY_SHELL_ACTIVATED` is set, print `"my-shell environment is already activated"` and exit (no-op). This prevents unnecessary re-activation and shell spawning.
3. Because the global switcher is a Bash script and Fish cannot source it:
   - Determine project root in the global switcher:
     - `MY_SHELL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"`
   - Export before starting Fish:
     - `MY_SHELL_ROOT`
     - `MY_SHELL_ACTIVATION_MODE=exec`
     - `MY_SHELL_FISH_SPAWNED=1` (sentinel for an activation-started Fish session)
   - Prevent false `"my-shell environment is already activated"` in the new session:
     - use `env -u MY_SHELL_ACTIVATED ...`
   - Start Fish using an init file to ensure functions persist in the new interactive session:
     - Create a temporary init file that sources `activate.fish`
     - Use `fish --init-command` to source the init file before starting the interactive session
     - This ensures `deactivate` and other functions are available in the new Fish instance
     - Example: `exec env -u MY_SHELL_ACTIVATED fish --init-command "source '<init_file>'; rm -f '<init_file>'" -i`
4. `env/activate.fish` runs (Scenario 2.1 behavior, but the mode remains `exec`).

**Important Notes:**
- This is not "same process session"; the global switcher replaces the current process with Fish (`exec`).
- `MY_SHELL_FISH_SPAWNED=1` marks that this Fish session was started by the activation system.
- The spec does not assume a particular "parent shell" exists after an `exec`. If there is a parent (e.g., a terminal/launcher shell), `exit` will return control to it.
- **Function persistence**: Functions defined in `activate.fish` (including `deactivate`) must be available in the new Fish interactive session. This is achieved by using an init file that sources `activate.fish` before the interactive session starts.

**Result:**
- An activation-started Fish interactive session runs with the environment active.
- All functions (including `deactivate`) are available in the new session.
- If already activated, no action is taken.

---

### 2.4 Scenario D: Shell Switching via Global Switcher (Switch Mode)

**Command:**
```bash
./env/activate bash
./env/activate zsh
./env/activate fish
```

**Behavior:**
1. Global switcher determines:
   - `MY_SHELL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"`
2. If requested shell differs from current shell:
   - Set `MY_SHELL_SWITCHED_FROM=<current shell>`
   - Set `MY_SHELL_ACTIVATION_MODE=switch`
   - Create a temporary directory for switch artifacts; store path in `MY_SHELL_TMPDIR`
3. Start the requested shell with a temporary startup file that:
   - exports `MY_SHELL_SWITCHED_FROM`, `MY_SHELL_ACTIVATION_MODE`, `MY_SHELL_ROOT`, `MY_SHELL_TMPDIR`
   - sources the corresponding activator via **absolute path**
   - prevents inheritance of `MY_SHELL_ACTIVATED` using `env -u MY_SHELL_ACTIVATED`

**Shell-specific switch commands:**
- **Bash**:
  - `exec env -u MY_SHELL_ACTIVATED bash --rcfile <temp_rcfile> -i`
  - `<temp_rcfile>` sources `"$MY_SHELL_ROOT/env/activate.bash"`
- **Zsh**:
  - `exec env -u MY_SHELL_ACTIVATED ZDOTDIR=<temp_dir> zsh -i`
  - `<temp_dir>/.zshrc` sources `"$MY_SHELL_ROOT/env/activate.zsh"`
- **Fish**:
  - `exec env -u MY_SHELL_ACTIVATED fish -c "set -gx MY_SHELL_SWITCHED_FROM '...'; set -gx MY_SHELL_ACTIVATION_MODE 'switch'; set -gx MY_SHELL_ROOT '...'; set -gx MY_SHELL_TMPDIR '...'; set -gx MY_SHELL_FISH_SPAWNED 1; source '$MY_SHELL_ROOT/env/activate.fish'; exec fish -i"`

**Result:**
- User lands in the requested shell with the environment active.
- Running `deactivate` returns to the original shell (see Scenario 3.2).

---

## 3. Deactivation Scenarios

### 3.1 Scenario A: Normal Deactivation (No Switch Return)

**Command:**
```bash
deactivate
```

**Behavior:**
1. If `MY_SHELL_ACTIVATED` is not set, print `"my-shell environment is not activated"` and return.
2. Restore PATH to `MY_SHELL_OLD_PATH` (exact snapshot).
   - Any PATH changes made while active are discarded.
3. Restore prompt:
   - Bash/Zsh: restore `PS1` from `MY_SHELL_OLD_PS1`
   - Fish: restore `fish_prompt` per Scenario 7.2
4. Remove shell-local `colortable` definition.
5. Remove `deactivate` and `reactivate` functions.
6. Unset activation variables:
   - `MY_SHELL_ACTIVATED`
   - `MY_SHELL_ACTIVATION_MODE`
   - `MY_SHELL_ROOT`
   - `MY_SHELL_OLD_PATH`
   - `MY_SHELL_OLD_PS1` (Bash/Zsh)
   - `MY_SHELL_FISH_SPAWNED` (Fish, if set)
7. Print `"- my-shell environment deactivated"`.
8. Print `"- Bye..."`

**Result:**
- The current shell continues (no shell switching behavior is triggered).

---

### 3.2 Scenario B: Deactivation After Shell Switching (Return to Original Shell)

**Command:**
```bash
deactivate
```

**Precondition:**
- `MY_SHELL_SWITCHED_FROM` is set.

**Behavior:**
1. Perform Scenario 3.1 deactivation steps.
2. Capture `MY_SHELL_SWITCHED_FROM` into a local variable and unset it.
3. Clean up temporary artifacts:
   - If `MY_SHELL_TMPDIR` is set: remove it (best-effort, recursive) and unset `MY_SHELL_TMPDIR`.
   - **Best-effort cleanup**: Attempts to remove the temporary directory recursively. If removal fails (e.g., permissions, file locks), the operation continues without error. This prevents cleanup failures from blocking deactivation. Temporary files may accumulate in rare cases but do not affect functionality.
4. Print `"Returning to <shell> shell..."`.
5. `exec <shell>`.

**Result:**
- Control transfers to the original shell program.

---

### 3.3 Scenario C: Fish Deactivation for Activation-Started Fish Sessions (Exec Mode)

**Command:**
```bash
deactivate
```

**Preconditions:**
- Current shell is Fish.
- `MY_SHELL_ACTIVATION_MODE=exec` and/or `MY_SHELL_FISH_SPAWNED=1` is set.

**Behavior:**
1. If `MY_SHELL_SWITCHED_FROM` is set, use Scenario 3.2 (return to original shell) instead.
2. Perform Scenario 3.1 deactivation steps.
3. If `MY_SHELL_FISH_SPAWNED=1` is set:
   - Exit Fish using `exit`.
   - The session returns control to whatever launched this Fish instance (if any).

**Result:**
- If the Fish session was started by activation (`MY_SHELL_FISH_SPAWNED=1`), `deactivate` ends the Fish session after cleanup.
- If not, Fish remains open after cleanup.

> No logic relies on `$SHLVL`. `$SHLVL` may be informative but is not a decision input.

---

## 4. Reactivation

### 4.1 Scenario: Reload Files Without Deactivation

**Command:**
```bash
reactivate
```

**Behavior:**
1. If `MY_SHELL_ACTIVATED` is not set, print `"my-shell environment is not activated"` and return.
2. Print `"Reloading my-shell environment files..."`.
3. Re-source shell-specific files via single entrypoint:
   - Bash: `shell/bash/init.bash`
   - Zsh: `shell/zsh/init.zsh`
   - Fish: `shell/fish/init.fish`
4. Re-define `colortable`.
5. Ensure prompt prefix is present.
6. Print `"my-shell environment reloaded"`.

**Result:**
- Environment remains active.
- Changes in sourced files take effect.

---

## 5. Environment Variables

### 5.1 Variables

| Variable | Description | Example |
|---|---|---|
| `MY_SHELL_ROOT` | Project root directory | `/Users/user/proj/my-shell` |
| `MY_SHELL_ACTIVATED` | Activation status (`1` when active) | `1` |
| `MY_SHELL_ACTIVATION_MODE` | `source`, `switch`, `exec` | `source` |
| `MY_SHELL_OLD_PATH` | PATH snapshot for restoration | `/usr/bin:/bin:...` |
| `MY_SHELL_OLD_PS1` | Original PS1 (Bash/Zsh) | `\u@\h \w $ ` |
| `MY_SHELL_SWITCHED_FROM` | Original shell name for return | `fish` |
| `MY_SHELL_FISH_SPAWNED` | Sentinel: activation-started Fish session | `1` |
| `MY_SHELL_TMPDIR` | Temp directory for switch artifacts | `/tmp/tmp.XXXXXX` |

### 5.2 Export and Cleanup

- Bash/Zsh: export via `export`.
- Fish: export via `set -gx`.
- All variables are unset during `deactivate` (plus switch artifacts cleanup when applicable).

### 5.3 Inheritance Rules

- `MY_SHELL_ACTIVATED` is explicitly **removed** when starting a new shell via switch/exec using `env -u MY_SHELL_ACTIVATED`.
- `MY_SHELL_ROOT`, `MY_SHELL_SWITCHED_FROM`, `MY_SHELL_ACTIVATION_MODE`, `MY_SHELL_TMPDIR` are intentionally passed to the child shell to guide activation and deactivation.
- `MY_SHELL_OLD_PATH` and `MY_SHELL_OLD_PS1` are captured fresh in the target shell during activation.

---

## 6. Functions and Commands

### 6.1 `deactivate`

- Deactivates the environment.
- **Availability**: The `deactivate` function must be available in all activation scenarios, including exec-activated Fish sessions (Scenario 2.3). In Fish exec-activation, functions must persist in the new interactive session using init files.
- If `MY_SHELL_SWITCHED_FROM` is set: returns to the original shell (Scenario 3.2).
- If in Fish and `MY_SHELL_FISH_SPAWNED=1`: exits Fish after cleanup (Scenario 3.3).
- Otherwise: standard deactivation (Scenario 3.1).

### 6.2 `reactivate`

- Reloads configuration without leaving the active environment.

### 6.3 `colortable`

- Displays the color table by invoking `colortable.sh` (or equivalent).
- Bash/Zsh: alias
- Fish: function

---

## 7. Shell-Specific Behaviors

### 7.1 Bash / Zsh

- Source-based activation works directly.
- Prompt modification uses `PS1` (store/restore via `MY_SHELL_OLD_PS1`).

### 7.2 Fish Prompt Strategy (Function Copying)

**Activation:**
1. Backup the current prompt:
   - `functions -c fish_prompt __my_shell_old_fish_prompt`
2. Define `__my_shell_prompt_prefix` function:
   ```fish
   function __my_shell_prompt_prefix
       echo -n "(my-shell) "
   end
   ```
   - This function outputs the `(my-shell)` prefix without a newline.
3. Replace `fish_prompt` to call:
   - `__my_shell_prompt_prefix`
   - then `__my_shell_old_fish_prompt`

**Deactivation:**
1. Restore original prompt:
   - `functions -c __my_shell_old_fish_prompt fish_prompt`
2. Remove backup and helper:
   - `functions -e __my_shell_old_fish_prompt`
   - `functions -e __my_shell_prompt_prefix`
   - This ensures no orphaned functions remain after deactivation.

---

## 8. Limitations and Constraints

### 8.1 Repeated Activation

- Re-sourcing an activator in the same shell after activation prints `"my-shell environment is already activated"` and returns.
- **Global switcher behavior**: If `MY_SHELL_ACTIVATED` is already set when running `./env/activate`, the global switcher must check this condition **before** attempting any activation or shell spawning. It should print `"my-shell environment is already activated"` and exit without starting a new shell or re-sourcing activators. This applies to all shells (Bash, Zsh, and Fish).
- Switch/exec flows avoid inheriting `MY_SHELL_ACTIVATED` to prevent false positives.

### 8.2 Nested Activation

- Not supported. (An activation-started Fish session is not treated as “nested activation”; it is a process/session management requirement.)

### 8.3 Temporary Artifacts

- Switch mode uses temp artifacts stored under `MY_SHELL_TMPDIR`.
- Cleanup is best-effort during `deactivate` before returning to the original shell.
- **Best-effort cleanup**: Attempts to remove the temporary directory recursively. If removal fails (e.g., permissions, file locks), the operation continues without error. This prevents cleanup failures from blocking deactivation. Temporary files may accumulate in rare cases but do not affect functionality.

---

## 9. Test Scenarios

> **Note**: The following test scenarios are documented for reference but are **not currently implemented**.

1. Direct activation (Bash/Zsh/Fish) — Scenario 2.1
2. Global switcher activation same shell (Bash/Zsh) — Scenario 2.2
3. Global switcher Fish exec-activation — Scenario 2.3
4. Shell switching (Bash↔Zsh↔Fish) — Scenario 2.4
5. Repeated activation no-op (direct source) — prints message and returns
6. **Repeated activation no-op (global switcher)** — when `MY_SHELL_ACTIVATED` is set, `./env/activate` must check before activation and exit without spawning new shell
7. **Fish exec-activation function persistence** — `deactivate` function must be available in exec-activated Fish session
8. Normal deactivation — Scenario 3.1
9. Deactivation return to original shell — Scenario 3.2
10. Fish deactivation exits activation-started Fish session — Scenario 3.3
11. Reactivation — Scenario 4.1
12. PATH snapshot restoration behavior
13. Prompt prefix add/remove correctness
14. Fish prompt backup/restore and helper cleanup
15. `env -u MY_SHELL_ACTIVATED` prevents false positives
16. Temp artifact cleanup via `MY_SHELL_TMPDIR`
17. Absolute path sourcing for all activators
