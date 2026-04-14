# CLAUDE.md

**MANDATORY: Read [`AGENTS.md`](AGENTS.md) before any action in this
repository.** It is the canonical, cross-tool guidance file. Everything
about project structure, build/test/lint commands, the `ll` family
architecture, baseline workflow, alias-sync rule, conventions, and
common gotchas lives there.

This file holds only Claude-Code-specific operational notes that do not
belong in `AGENTS.md`.

## Claude-Code-specific notes

### Fish-host bash wrapping (critical for the Bash tool)

The user's primary interactive shell is **fish**. When running multi-line
shell snippets via the Bash tool, **wrap them in `bash -c '...'` or
`zsh -c '...'`** — do not rely on fish-incompatible syntax (e.g. `[[ ]]`,
`$(...)` substitution patterns that fish parses differently, brace
expansion edge cases) being interpreted by the active shell.

```bash
# Correct
bash -c 'for f in *.sh; do shellcheck "$f"; done'

# Risky on a fish host
for f in *.sh; do shellcheck "$f"; done
```

### Tool preference

- **`Edit` / `Write` over `Bash`** for file modifications. Don't
  `sed -i` or `cat <<EOF >file` when an Edit will do.
- **`Grep` / `Glob` over `Bash` `find`/`grep`** — they're permission-
  scoped and faster.
- **`Read` over `Bash cat`** — better display, line numbers, range support.
- **Subagents** for open-ended exploration that would otherwise consume
  significant context.

### Validation workflow on this repo

After any non-trivial change, the standard checks are:

```bash
make baseline-check   # ll_linux + ll_macos byte-level regression lock
make test-bats        # 91 top-level + ll wrapper + baseline tests
make test-ll          # platform-aware ll suite
make lint             # ShellCheck + fish syntax
```

Linux-side validation requires Docker:

```bash
make test-act         # runs the Ubuntu CI job in a container via act
```

For everything else (Makefile targets, project structure, baseline
regeneration semantics, the `ll` parity contract, alias-sync, etc.),
see `AGENTS.md`.
