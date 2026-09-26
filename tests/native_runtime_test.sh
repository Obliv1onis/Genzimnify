#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

runtime="${GZIM_NATIVE_BIN:-build/gzim}"
if [ ! -x "$runtime" ]; then
  echo "$runtime is missing; build src/gzim.nim first" >&2
  exit 1
fi

tmp="$(mktemp -d "${TMPDIR:-/tmp}/genzimnify-native.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

# If the runtime accidentally falls back to Python, this shim makes the test
# fail and leaves evidence behind.
mkdir -p "$tmp/bin"
printf '#!/bin/sh\necho called > "%s"\nexit 97\n' "$tmp/python-called" > "$tmp/bin/python3"
chmod +x "$tmp/bin/python3"

actual="$(PATH="$tmp/bin:$PATH" "$runtime" tests/native/main.gzim hello "$tmp/output.txt")"
if [ "$actual" != "$(cat tests/native/expected.txt)" ]; then
  echo "native runtime integration output mismatch" >&2
  diff -u tests/native/expected.txt <(printf '%s\n' "$actual")
  exit 1
fi
if [ -e "$tmp/python-called" ]; then
  echo "native runtime attempted to invoke python3" >&2
  exit 1
fi

if error_output="$("$runtime" tests/native/runtime_error.gzim 2>&1)"; then
  echo "runtime error case unexpectedly passed" >&2
  exit 1
fi
if [[ "$error_output" != *"runtime_error.gzim:4:"* ]] ||
   [[ "$error_output" != *"multiple values for argument 'value'"* ]]; then
  echo "runtime error did not include the expected location and message" >&2
  echo "$error_output" >&2
  exit 1
fi

echo "native runtime integration and diagnostics passed without Python"
