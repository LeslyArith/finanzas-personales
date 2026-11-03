#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="$ROOT_DIR/deploy/runtime"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_FILE="$RUNTIME_DIR/finanzas-personales-$STAMP.tar.gz"

mkdir -p "$RUNTIME_DIR"

tar \
  --exclude='.git' \
  --exclude='node_modules' \
  --exclude='vendor' \
  --exclude='deploy/runtime' \
  --exclude='.env' \
  -czf "$OUT_FILE" \
  -C "$ROOT_DIR" .

echo "PACKAGE_OK=$OUT_FILE"
