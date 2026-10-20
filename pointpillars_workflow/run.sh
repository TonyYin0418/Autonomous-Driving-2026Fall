#!/usr/bin/env bash
# Run a course command with the isolated environment and WSL CUDA driver path.
set -euo pipefail
STAGE03_WORKFLOW="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export LD_LIBRARY_PATH="/usr/lib/wsl/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export MPLCONFIGDIR="$STAGE03_WORKFLOW/../.mpl-cache"
export PYTHONUTF8=1
cd "$STAGE03_WORKFLOW"
exec ../.venv-stage03/bin/python "$@"
