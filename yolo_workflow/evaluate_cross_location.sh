#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
export UV_CACHE_DIR=/home/yin/data/autonomous_driving/cache/uv

timestamp="$(date '+%Y%m%d_%H%M%S')"
run_name="${timestamp}_yolo11n_onenorth_cross_location"

UV_PROJECT_ENVIRONMENT=.venv-stage01 uv run python yolo_workflow/evaluate_cross_location.py \
  --model runs/checkpoints/20260916_092702_yolo11n_onenorth/weights/best.pt \
  --datasets-root data/nuscenes_yolo_vis34 \
  --name "$run_name" \
  --imgsz 640 \
  --batch 16 \
  --device 0 \
  --workers 16
