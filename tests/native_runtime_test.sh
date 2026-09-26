#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

runtime="${GZIM_NATIVE_BIN:-build/gzim}"
if [ ! -x "$runtime" ]; then
  echo "$runtime is missing; build src/gzim.nim first" >&2
  exit 1
fi
original_path="$PATH"

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

if command -v python3 >/dev/null 2>&1; then
  bridge_actual="$(PATH="$original_path" "$runtime" tests/native/python_bridge.gzim)"
  if [ "$bridge_actual" != "$(cat tests/native/python_bridge.expected)" ]; then
    echo "optional Python bridge output mismatch" >&2
    diff -u tests/native/python_bridge.expected <(printf '%s\n' "$bridge_actual")
    exit 1
  fi
fi

stdlib_actual="$("$runtime" tests/native/stdlib_next.gzim)"
if [ "$stdlib_actual" != "$(cat tests/native/stdlib_next.expected)" ]; then
  echo "native standard-library output mismatch" >&2
  diff -u tests/native/stdlib_next.expected <(printf '%s\n' "$stdlib_actual")
  exit 1
fi

echo "native runtime, diagnostics, and optional Python bridge passed"
