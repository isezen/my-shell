# Test Suite

This directory contains BATS (Bash Automated Testing System) tests for the my-shell project.

## Test Files

- `alias.bats` - Tests for `shell/bash/aliases.bash` (aliases and functions)
- `bash.bats` - Tests for `shell/bash/prompt.bash` and `shell/bash/env.bash` (bash prompt and environment settings)
- `scripts_ll.bats` - Tests for `scripts/ll` (colorful long listing)
- `scripts_dus.bats` - Tests for `scripts/dus` (disk usage script)

## Running Tests

### Using Makefile (Recommended)

```bash
make test-bats    # Run only BATS tests
make test         # Run all tests (BATS + linting)
```

### Using BATS directly

```bash
# Run all tests
bats tests/*.bats

# Run a specific test file
bats tests/alias.bats

# Run with verbose output
bats -v tests/alias.bats
```

## Test Helper Libraries

The `test_helper/` directory contains minimal implementations of:
- `bats-support/load.bash` - Support functions
- `bats-assert/load.bash` - Assertion functions

These are minimal implementations. For full functionality, you can install the official libraries:

```bash
# Install bats-support and bats-assert (optional)
git clone https://github.com/bats-core/bats-support.git tests/test_helper/bats-support
git clone https://github.com/bats-core/bats-assert.git tests/test_helper/bats-assert
```

## Writing New Tests

When adding new tests:

1. Create a new `.bats` file in the `tests/` directory
2. Follow the existing test structure:
   ```bash
   #!/usr/bin/env bats
   
   load 'test_helper/bats-support/load'
   load 'test_helper/bats-assert/load'
   
   setup() {
     # Setup code here
   }
   
   @test "test description" {
     # Test code here
   }
   ```

3. Use BATS assertions:
   - `assert_success` - Check command succeeded
   - `assert_failure` - Check command failed
   - `assert_output --partial "text"` - Check output contains text
   - `[ condition ]` - Standard shell conditionals

## Notes

- Tests are designed to work on both macOS and Linux
- Some tests may be skipped if required tools are not available
- Tests use temporary directories that are cleaned up automatically

