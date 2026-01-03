# bats-assert - Common assertions for Bats
# This is a minimal implementation for basic assertions

# Assert that command succeeded
assert_success() {
  if [ "$status" -ne 0 ]; then
    {
      echo "command failed with exit status $status"
      echo "output: $output"
    } | flunk
  fi
}

# Assert that command failed
assert_failure() {
  if [ "$status" -eq 0 ]; then
    {
      echo "expected command to fail"
      echo "output: $output"
    } | flunk
  fi
}

# Assert output contains string
assert_output() {
  local expected
  if [ $# -eq 1 ]; then
    expected="$1"
  else
    if [ "$1" = "--partial" ]; then
      expected="$2"
      if [[ "$output" != *"$expected"* ]]; then
        {
          echo "output does not contain '$expected'"
          echo "output: $output"
        } | flunk
      fi
      return
    elif [ "$1" = "--regexp" ]; then
      expected="$2"
      if ! [[ "$output" =~ $expected ]]; then
        {
          echo "output does not match regexp '$expected'"
          echo "output: $output"
        } | flunk
      fi
      return
    fi
  fi
  
  if [ "$output" != "$expected" ]; then
    {
      echo "output differs"
      echo "expected: $expected"
      echo "actual: $output"
    } | flunk
  fi
}

# Flunk - print error and exit
flunk() {
  {
    if [ "$#" -eq 0 ]; then
      cat
    else
      echo "$@"
    fi
  } >&2
  return 1
}

