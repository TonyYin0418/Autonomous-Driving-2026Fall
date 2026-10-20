#!/usr/bin/env bash
# Install the separate stage03 environment; stop at the first failed command.
set -euo pipefail

STAGE03_PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
STAGE03_PYTHON="$STAGE03_PROJECT_ROOT/.venv-stage03/bin/python"
STAGE03_ASSETS="${STAGE03_ASSETS:-$STAGE03_PROJECT_ROOT/data/pointpillars_assets}"
export UV_CACHE_DIR="${UV_CACHE_DIR:-/home/yin/data/autonomous_driving/cache/uv}"
export UV_HTTP_TIMEOUT="${UV_HTTP_TIMEOUT:-60}"
export UV_HTTP_RETRIES=0

if [[ ! -x "$STAGE03_PYTHON" ]]; then
    echo "Missing stage03 Python: $STAGE03_PYTHON" >&2
    exit 1
fi

"$STAGE03_PYTHON" --version

uv pip install --python "$STAGE03_PYTHON" \
    'torch==2.0.1+cu118' 'torchvision==0.15.2+cu118' 'numpy==1.24.4' \
    --index-url https://download.pytorch.org/whl/cu118

# Require a wheel: do not fall back to compiling MMCV CUDA extensions.
uv pip install --python "$STAGE03_PYTHON" 'mmcv==2.1.0' \
    --no-deps --only-binary=mmcv \
    --find-links https://download.openmmlab.com/mmcv/dist/cu118/torch2.0/index.html

uv pip install --python "$STAGE03_PYTHON" \
    -r "$STAGE03_PROJECT_ROOT/pointpillars_workflow/environment/requirements-linux.txt"

# Use the teacher-supplied MMDetection3D source distribution.
mkdir -p "$STAGE03_ASSETS"
if [[ -f "$STAGE03_PROJECT_ROOT/docs/checkpoints_thirdparty.rar" ]]; then
    bsdtar -xOf "$STAGE03_PROJECT_ROOT/docs/checkpoints_thirdparty.rar" \
        third_party/mmdet3d-1.4.0.tar.gz > "$STAGE03_ASSETS/mmdet3d-1.4.0.tar.gz"
else
    # The source submission ZIP includes this small source archive directly.
    cp "$STAGE03_PROJECT_ROOT/pointpillars_workflow/environment/mmdet3d-1.4.0.tar.gz" \
        "$STAGE03_ASSETS/mmdet3d-1.4.0.tar.gz"
fi
uv pip install --python "$STAGE03_PYTHON" --no-deps --no-build-isolation \
    "$STAGE03_ASSETS/mmdet3d-1.4.0.tar.gz" 'lyft-dataset-sdk==0.0.8'

"$STAGE03_PYTHON" - <<'PY'
import torch, torchvision, mmcv, mmengine, mmdet, mmdet3d
for module in [torch, torchvision, mmcv, mmengine, mmdet, mmdet3d]:
    print(f'{module.__name__}={module.__version__}')
print('INSTALL_IMPORTS_OK; CUDA operator checks are a separate next step.')
PY
