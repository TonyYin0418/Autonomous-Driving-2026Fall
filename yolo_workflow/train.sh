#!/usr/bin/env bash
set -euo pipefail

# Always run relative to the project root, regardless of the current directory.
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
export UV_CACHE_DIR=/home/yin/data/autonomous_driving/cache/uv

timestamp="$(date '+%Y%m%d_%H%M%S')"
run_name="${timestamp}_yolo11n_onenorth"

UV_PROJECT_ENVIRONMENT=.venv-stage01 uv run python yolo_workflow/train.py \
  --dataset-root data/nuscenes_yolo_vis34/singapore-onenorth \
  --model weights/yolo11n.pt \
  --epochs 50 \
  --batch 16 \
  --imgsz 640 \
  --workers 16 \
  --device 0 \
  --project runs/checkpoints \
  --name "$run_name"
