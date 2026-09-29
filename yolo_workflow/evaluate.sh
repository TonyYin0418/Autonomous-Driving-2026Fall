#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
export UV_CACHE_DIR=/home/yin/data/autonomous_driving/cache/uv

training_run="20260916_092702_yolo11n_onenorth"
timestamp="$(date '+%Y%m%d_%H%M%S')"
run_name="${timestamp}_yolo11n_onenorth_test"

UV_PROJECT_ENVIRONMENT=.venv-stage01 uv run python yolo_workflow/evaluate.py \
  --model "runs/checkpoints/${training_run}/weights/best.pt" \
  --dataset-root data/nuscenes_yolo_vis34/singapore-onenorth \
  --splits test \
  --imgsz 640 \
  --batch 16 \
  --device 0 \
  --workers 16 \
  --project runs/evaluation \
  --name "$run_name"
