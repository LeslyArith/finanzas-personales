#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

./deploy/package.sh
LATEST="$(ls -1t deploy/runtime/finanzas-personales-*.tar.gz | head -n1)"
python3 ./deploy/verify.py "$LATEST"

echo "DEPLOY_PRECHECK_OK=1"
echo "NEXT_STEP=transport_to_server_manually"
