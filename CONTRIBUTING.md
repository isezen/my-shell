# Contributing to my-shell

Thank you for your interest in contributing to my-shell! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Commit Message Guidelines](#commit-message-guidelines)

## Code of Conduct

- Be respectful and considerate
- Welcome newcomers and help them learn
- Focus on constructive feedback
- Respect different viewpoints and experiences

## Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Git** - Version control
- **ShellCheck** - Static analysis for shell scripts
  ```bash
  # macOS
  brew install shellcheck
  
  # Linux (Ubuntu/Debian)
  sudo apt-get install shellcheck
  ```
- **Fish Shell** - For fish script development and testing
  ```bash
  # macOS
  brew install fish
  
  # Linux (Ubuntu/Debian)
  sudo apt-get install fish
  ```
- **BATS** - Bash Automated Testing System
  ```bash
  # macOS
  brew install bats-core
  
  # Linux (Ubuntu/Debian)
  sudo apt-get install bats
  ```
- **pre-commit** (optional but recommended)
  ```bash
  pip install pre-commit
  ```

### Setting Up Your Development Environment

1. **Fork the repository** on GitHub

2. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/my-shell.git
   cd my-shell
   ```

3. **Add the upstream repository**:
   ```bash
   git remote add upstream https://github.com/isezen/my-shell.git
   ```

4. **Install pre-commit hooks** (recommended):
   ```bash
   make install-hooks
   # or
   pre-commit install
   ```

5. **Activate development environment** (optional but recommended):
   ```bash
   # Option 1: Use global switcher (works from any shell)
   ./env/activate          # Activate current shell
   ./env/activate bash     # Switch to bash and activate
   ./env/activate zsh      # Switch to zsh and activate
   ./env/activate fish     # Switch to fish and activate
   
   # Option 2: Source shell-specific script
   source env/activate.bash  # For bash
   source env/activate.zsh   # For zsh
   source env/activate.fish  # For fish
   
   # After making changes to alias.sh, bash.sh, or my_settings.fish:
   reactivate  # Reload files without deactivating
   ```

6. **Verify your setup**:
   ```bash
   make lint      # Check code quality
   make test-bats # Run tests
   ```

## Development Workflow

### Branch Strategy

We use **feature branches** for all changes:

1. **Create a feature branch** from `master`:
   ```bash
   git checkout master
   git pull upstream master
   git checkout -b feature/your-feature-name
   ```

2. **Naming conventions**:
   - `feature/description` - New features
   - `fix/description` - Bug fixes
   - `docs/description` - Documentation updates
   - `refactor/description` - Code refactoring

3. **Make your changes** and commit them

4. **Keep your branch up to date**:
   ```bash
   git fetch upstream
   git rebase upstream/master
   ```

5. **Push your branch**:
   ```bash
   git push origin feature/your-feature-name
   ```

### Making Changes

1. **Before you start coding**:
   - Check existing issues and pull requests
   - Create an issue if you're planning a significant change
   - Discuss major changes before implementing

2. **While coding**:
   - Follow the [coding standards](#coding-standards)
   - Write tests for new features
   - Keep commits focused and logical
   - Run `make lint` and `make test-bats` frequently

3. **Before committing**:
   ```bash
   make lint      # Check code quality
   make test-bats # Run all tests
   make test      # Run tests + linting
   ```

## Coding Standards

### Shell Script Standards

- **ShellCheck compliance**: All bash/sh scripts must pass ShellCheck
  ```bash
  make lint-bash
  ```

- **Fish script standards**: All fish scripts must pass syntax check
  ```bash
  make lint-fish
  ```

- **Code style**:
  - Use meaningful variable names
  - Add comments for complex logic
  - Keep functions focused and small
  - Follow existing code patterns

### File Organization

- Shell scripts (`.sh`) in the root directory
- Fish scripts (`.fish`) in the root directory
- Environment activation scripts in `env/` directory
- Test files in `tests/` directory
- Documentation in `docs/` directory

### Development Environment

For active development, you can use the environment activation system:

```bash
# Option 1: Use global switcher (recommended)
./env/activate          # Activate current shell
./env/activate bash     # Switch to bash
./env/activate zsh      # Switch to zsh
./env/activate fish     # Switch to fish

# Option 2: Source shell-specific script
source env/activate.bash  # For bash
source env/activate.zsh   # For zsh
source env/activate.fish  # For fish

# Make changes to alias.sh, bash.sh, or my_settings.fish
# Then reload without deactivating:
reactivate

# When done, deactivate
deactivate
```

This allows you to:
- Test changes immediately without restarting your shell session
- Switch between different shells easily
- Keep your development environment isolated

### Pre-commit Hooks

Pre-commit hooks automatically check your code before each commit:

- ShellCheck for bash/sh scripts
- Fish syntax check for fish scripts
- Trailing whitespace removal
- End of file fixes

To bypass hooks (not recommended):
```bash
git commit --no-verify
```

## Testing

### Test Requirements

**All new features must include tests.** This ensures:
- Code works as expected
- Regressions are caught early
- Documentation through examples

### Running Tests

```bash
# Run all BATS tests
make test-bats

# Run all tests (BATS + linting)
make test

# Run a specific test file
bats tests/alias.bats

# Run with verbose output
bats -v tests/alias.bats
```

### Writing Tests

1. **Create a test file** in `tests/` directory:
   ```bash
   tests/your_script.bats
   ```

2. **Follow the existing test structure**:
   ```bash
   #!/usr/bin/env bats
   
   load 'test_helper/bats-support/load'
   load 'test_helper/bats-assert/load'
   
   setup() {
     # Setup code here
   }
   
   @test "test description" {
     # Test code here
     run your_function
     assert_success
     assert_output --partial "expected output"
   }
   ```

3. **Test categories**:
   - **Loadability**: Script can be sourced without errors
   - **Functionality**: Functions work as expected
   - **Edge cases**: Handle errors and edge cases
   - **Options**: Command-line options work correctly

4. **See `tests/README.md`** for detailed testing guidelines

### Test Coverage

- Aim for high test coverage
- Test both success and failure cases
- Test edge cases and error conditions
- Update `tests/TEST_COVERAGE.md` when adding new tests

## Pull Request Process

### Before Submitting

1. **Ensure all tests pass**:
   ```bash
   make test
   ```

2. **Ensure code quality checks pass**:
   ```bash
   make lint
   ```

3. **Update documentation** if needed:
   - README.md
   - CHANGELOG.md
   - tests/TEST_COVERAGE.md

4. **Rebase on latest master**:
   ```bash
   git fetch upstream
   git rebase upstream/master
   ```

### Submitting a Pull Request

1. **Push your branch** to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create a Pull Request** on GitHub:
   - Use a clear, descriptive title
   - Describe what changes you made and why
   - Reference any related issues
   - Include screenshots if applicable

3. **PR Description Template**:
   ```markdown
   ## Description
   Brief description of changes
   
   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Documentation update
   - [ ] Refactoring
   
   ## Testing
   - [ ] Tests added/updated
   - [ ] All tests pass
   - [ ] Tested on Linux
   - [ ] Tested on macOS
   
   ## Checklist
   - [ ] Code follows style guidelines
   - [ ] Self-review completed
   - [ ] Comments added for complex code
   - [ ] Documentation updated
   - [ ] No new warnings generated
   - [ ] Tests added/updated
   - [ ] All tests pass locally
   ```

### Review Process

**All Pull Requests require review before merging.**

- Maintainers will review your PR
- Address any feedback or requested changes
- Keep discussions constructive and respectful
- Be patient - reviews may take time

### After Review

- Make requested changes
- Push updates to your branch (PR updates automatically)
- Respond to review comments
- Once approved, maintainers will merge your PR

## Commit Message Guidelines

We use **simple, descriptive commit messages**. Keep them clear and concise.

### Good Commit Messages

```
Add fish syntax check to pre-commit hooks
Fix ShellCheck warning in alias.sh line 50
Update README with installation instructions
Refactor dusd function for better error handling
```

### Commit Message Structure

- **First line**: Brief summary (50-72 characters)
- **Body** (optional): Detailed explanation if needed
- **Use imperative mood**: "Add" not "Added" or "Adds"

### Examples

```
Add test coverage for FindFiles function

Tests verify that FindFiles correctly searches for files
with the given pattern and handles edge cases like empty
directories and special characters.
```

```
Fix cd error handling in mcd function

Added error checking to prevent script continuation if
directory creation or navigation fails.
```

## Getting Help

- **Open an issue** for bugs or feature requests
- **Check existing issues** before creating new ones
- **Ask questions** in issue discussions
- **Review documentation** in `docs/` directory

## Additional Resources

- [ShellCheck Documentation](https://www.shellcheck.net/)
- [BATS Testing Framework](https://github.com/bats-core/bats-core)
- [Fish Shell Documentation](https://fishshell.com/docs/current/)
- [Git Best Practices](https://git-scm.com/book)

## Thank You!

Your contributions make this project better. Thank you for taking the time to contribute! 🎉

