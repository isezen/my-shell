# bats-support is a helper library providing common testing functions for bats
# This is a minimal implementation for basic functionality

# Load bats-assert if available
if [ -f "${BATS_TEST_DIRNAME}/bats-assert/load.bash" ]; then
  load "${BATS_TEST_DIRNAME}/bats-assert/load.bash"
fi

