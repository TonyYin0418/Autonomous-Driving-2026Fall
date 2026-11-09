#!/usr/bin/env bash
set -euo pipefail
STAGE04_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
STAGE04_DISK="${STAGE04_DISK:-/home/yin/data/autonomous_driving}"
export HTTP_PROXY="${HTTP_PROXY:-http://127.0.0.1:17890}"
export HTTPS_PROXY="$HTTP_PROXY" http_proxy="$HTTP_PROXY" https_proxy="$HTTP_PROXY"
export NO_PROXY=localhost,127.0.0.1,::1
export no_proxy="$NO_PROXY"
export UV_CACHE_DIR="$STAGE04_DISK/cache/uv"
export UV_PYTHON_INSTALL_DIR="$STAGE04_DISK/python"
export UV_HTTP_TIMEOUT=60 UV_HTTP_RETRIES=0
uv python install 3.10
if [[ ! -x "$STAGE04_DISK/envs/stage04/bin/python" ]]; then
  uv venv --no-project --python 3.10 "$STAGE04_DISK/envs/stage04"
fi
if [[ ! -e "$STAGE04_ROOT/.venv-stage04" ]]; then
  ln -s "$STAGE04_DISK/envs/stage04" "$STAGE04_ROOT/.venv-stage04"
fi
uv pip install --python "$STAGE04_ROOT/.venv-stage04/bin/python" \
  'torch==2.4.0+cu121' 'torchvision==0.19.0+cu121' \
  --index-url https://download.pytorch.org/whl/cu121
uv pip install --python "$STAGE04_ROOT/.venv-stage04/bin/python" \
  -r "$STAGE04_ROOT/e2e_workflow/environment/requirements-linux.txt"
