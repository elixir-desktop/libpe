#!/usr/bin/env bash
# Regenerate rcedit golden fixtures (Windows). Requires test/tools/rcedit.exe.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RCEDIT="${ROOT}/test/tools/rcedit.exe"
LOGO="${ROOT}/test/fixtures/logo.ico"
BASE="${ROOT}/test/fixtures/base/hello.exe"
OUT="${ROOT}/test/fixtures/golden/hello_rcedit.exe"
DUMP_DIR="${ROOT}/test/fixtures/dumps"

cp -f "$BASE" "$OUT"
"$RCEDIT" /I "$OUT" "$LOGO"
cd "$ROOT"
mix run test/fixtures/dump_golden.exs
echo "Regenerated $OUT and $DUMP_DIR/hello_rcedit.term"
