#!/usr/bin/env bash
set -euo pipefail
STAGE04_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${LD_LIBRARY_PATH:-}"
export MPLCONFIGDIR="$STAGE04_ROOT/.mpl-cache"
export PYTHONUNBUFFERED=1
export OMP_NUM_THREADS=4
exec "$STAGE04_ROOT/.venv-stage04/bin/python" "$STAGE04_ROOT/e2e_workflow/$@"
