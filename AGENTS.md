# Repository Guidelines

## Project Structure & Module Organization
- `shell/` holds the per-shell configs (`bash|zsh|fish` subdirectories with `init.*`, `aliases.*`, `prompt.*`, `env.*` entry points).
- `scripts/bin/` is the executable surface (`ll`, `dus`, `dusf`, `dusf.`) while `scripts/dev/` contains helper tooling (`ll-compare`, `ls-compare`, `run-shellcheck`).
- `env/` houses the activation helpers (`activate`, `activate.*`) that bootstrap the dev environment from anywhere.
- `tests/` is a BATS-heavy suite (alias checks, platform-specific `ll` tests, scripts coverage) and `docs/` stores specs like `LL_SPECIFICATIONS.md`.
- `install.sh`, `Makefile`, `.shellcheckrc`, and `pre-commit` config tie the tooling together; update `README.md`/`CHANGELOG.md` when public behavior changes.

## Build, Test, and Development Commands
- `make help` — lists available targets.
- `make lint`, `make lint-bash`, `make lint-fish` — ShellCheck/fish syntax validation for the codebase.
- `make test` / `make test-bats` — run the full BATS suite; `make test-ll` auto-detects macOS vs. Linux wrappers, while `make test-ll-linux`, `make test-ll-macos`, `make test-ll-common` focus narrower scopes.
- `make alias-sync` — ensures `shell/aliases.yml` definitions are mirrored across `aliases.*`.
- `make format` / `make format-fish` — run `fish_indent` formatting on fish files, keeping style consistent.
- `make install-hooks` — installs the pre-commit hooks that gate commits.

## Coding Style & Naming Conventions
- Follow existing shell patterns: readable helper functions, short helper scripts, and two-space indentation for fish configs; keep behavior encapsulated and comment only when logic would otherwise be unclear.
- ShellCheck is the baseline lint (run via `make lint-bash` or `./scripts/dev/run-shellcheck`), and every fish file must pass `fish -n`.
- Executables live under `scripts/bin/`, dev helpers under `scripts/dev/`, and activation scripts under `env/`—keep names descriptive (e.g., `ll_linux`, `activate.zsh`).
- Use feature/prefix branch names (`feature/`, `fix/`, `docs/`, `refactor/`) for Git work and keep commits focused.

## Testing Guidelines
- Primary framework: [BATS](https://github.com/bats-core/bats-core). Tests live in `tests/`, with platform-specific subdirectories for `ll_linux/`, `ll_macos/`, and helper fixtures.
- Maintain at least 55 tests and update `tests/TEST_COVERAGE.md` plus the badge in `README.md` when adding new suites.
- Test files are `#!/usr/bin/env bats`, use helpers from `test_helper/`, and assert output/exit behavior (`run`, `assert_success`, `assert_output`).
- Alias sync is tested via `tests/alias-sync.bats`; run `make alias-sync` locally before submitting changes touching alias YAML or shell alias files.

## Commit & Pull Request Guidelines
- Commit messages are imperative and descriptive (`Fix history search edge cases`, not `Fixed…`). Keep the first line ≈50–72 characters and add a body when necessary.
- PRs should run `make test`, `make lint`, and `make alias-sync` locally before pushing; mention tests in the PR description.
- Use the provided PR template: describe the change, mark the change type, list testing performed, and check the checklist (style, docs, warnings, tests).
- Link issues, include screenshots when UI/behavior changes are visible, and keep discussions constructive during reviews.

## Environment & Configuration Tips
- Activate the repo’s shell environment before testing: `./env/activate` (bash/zsh/fish variations exist).
- When working on prompts or aliases, `reactivate` reloads the active shell without deactivating so you can iterate quickly.
- Keep pre-commit hooks installed (`make install-hooks` or `pre-commit install`) to ensure ShellCheck/fish linting, alias sync, and formatting run automatically.
