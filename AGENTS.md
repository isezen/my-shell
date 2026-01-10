# Repository Guidelines

## Project Structure & Module Organization
- `shell/` stores per-shell entry points and reuseable alias definitions across `bash/`, `zsh/`, and `fish/` subfolders; update both the shell-specific scripts and `aliases.*` when you touch shared aliases.
- `scripts/bin/` is the user-facing surface (`ll`, `ll_linux`, `ll_macos`, `llfish`, etc.), while `scripts/dev/` hosts helpers that the tests or maintainers use (`ll-compare`, `run-shellcheck`, `ll-compare` fixtures).
- `env/` contains activation helpers (`activate`, `activate.bash`, `activate.fish`) so any terminal can reach the same tooling; don’t forget to refresh the environment after changing those scripts.
- `tests/` is primarily a BATS suite with fixtures under `tests/ll_linux/`, `tests/ll_macos/`, and `tests/alias-sync/`; keep docs/news in `docs/`, `README.md`, and `CHANGELOG.md` aligned with public behaviors.

## Build, Test, and Development Commands
- `make help` — prints available targets so you know what’s maintained.
- `make lint`, `make lint-bash`, `make lint-fish` — run ShellCheck (or `fish -n`) across the relevant sources before a PR.
- `make test` (or `make test-bats`) — executes the entire BATS suite; for platform-specific runs use `make test-ll`, `make test-ll-linux`, or `make test-ll-macos`.
- `make alias-sync` — keeps `shell/aliases.yml` and generated alias files in sync; rerun after editing `aliases.yml`.
- `scripts/dev/ll-compare --show-ansi --only=50 ll_macos ll_linux` — reproduces the single ll test that spots ANSI/coloring regressions for symlink rendering changes.

## Coding Style & Naming Conventions
- Favor readable helper functions, short scripts, and well-scoped responsibilities; when a helper is reused across linux/macos, keep it in `scripts/dev/` and reference it from both wrappers.
- Shell files should stick to two-space indentation for `if`, `for`, and `case` blocks, avoid needless subshells, and use descriptive names (`ll_macos`, `batch_push_rows`, `render_rows_awk`).
- Annotate non-obvious logic with concise comments (e.g., why `stat -f` uses `%N`), and keep inline quoting consistent: use `printf '%s' "$var"` when expanding user input, `"$@"` when forwarding arguments, and `DELIM=$'\037'` when working with record separators.
- Keep executable helpers under `scripts/bin/`, dev helpers under `scripts/dev/`, configuration under `env/`, and docs in `docs/` or `README.md`.

## Testing Guidelines
- The suite is BATS-based. Tests name directories/fixtures in `tests/ll_*` and call helpers from `tests/test_helper/`. Add new tests adjacent to existing ones (`tests/ll_macos/case-*`) when extending behavior.
- When editing fast-path logic, rerun `scripts/dev/ll-compare --show-ansi --only=50 ll_macos ll_linux` to confirm ANSI parity before broader test runs; the script is the authoritative comparison between the two `ll` implementations.
- Alias sync is validated by `tests/alias-sync.bats`; run `make alias-sync` before touching alias sources and commit the generated files.
- Any new test should update `tests/TEST_COVERAGE.md` and the badge in `README.md`.

## Commit & Pull Request Guidelines
- Use imperative, descriptive commit messages (“Fix ll_macos broken symlink coloring”) with a 50–72 character summary and optional body.
- PRs run `make test`, `make lint`, and `make alias-sync` locally; mention these commands in the PR description and include the results.
- Fill the repository’s PR template, describe the change’s scope, select the correct change type, and note the registers (style/docs/tests) you touched.
- Link related issues, add screenshots for visual changes, and keep discussions professional.

## Environment & Configuration Tips
- Source `./env/activate` (or `./env/activate.fish`) to get consistent PATHs, `shellcheck`, and lint hooks before running scripts.
- Re-run `./env/activate` (or its `reactivate` helper) after editing aliases or tools so your shell keeps in sync.
- Install pre-commit hooks via `make install-hooks` (or `pre-commit install`) to automatically run ShellCheck/fish linting and enforce formatting before commits.
