"""Report the exact software, GPU and supplied-data state used by the course."""
from __future__ import annotations

import argparse
import platform
import subprocess
import sys
from pathlib import Path

import mmcv
import mmdet
import mmdet3d
import mmengine
import numpy as np
import torch
from mmcv.ops import Voxelization, nms_rotated

from course_common import COURSE_ROOT, data_root_from_arg, save_json


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--data-root', default=None)
    args = parser.parse_args()
    root = data_root_from_arg(args.data_root)
    # Import success alone does not prove that the installed wheel has usable CUDA ops.
    cuda_ops = {}
    if torch.cuda.is_available():
        points = torch.tensor([[0., 0., 0., 1.], [0.1, 0.1, 0.1, 0.5],
                               [1., 1., 0., 0.3]], device='cuda')
        voxelize = Voxelization(voxel_size=[0.25, 0.25, 8],
                               point_cloud_range=[-25, -25, -5, 25, 25, 3],
                               max_num_points=20, max_voxels=8000)
        voxels, _, counts = voxelize(points)
        cuda_ops['voxelization'] = voxels.is_cuda and int(counts.sum()) == 3
        boxes = torch.tensor([[0., 0., 2., 2., 0.], [0., 0., 2., 2., 0.],
                              [5., 5., 2., 2., 0.]], device='cuda')
        _, kept = nms_rotated(boxes, torch.tensor([0.9, 0.8, 0.7], device='cuda'), 0.5)
        cuda_ops['nms_rotated'] = kept.tolist() == [0, 2]
        if not all(cuda_ops.values()):
            raise RuntimeError(f'CUDA operator checks failed: {cuda_ops}')
    gpu_query = 'unavailable'
    try:
        gpu_query = subprocess.check_output(
            ['nvidia-smi', '--query-gpu=name,driver_version,memory.total',
             '--format=csv,noheader'], text=True, encoding='utf-8').strip()
    except Exception as exc:  # nvidia-smi may not be on PATH in a student PC.
        gpu_query = f'unavailable: {exc}'
    report = dict(
        python=sys.version, platform=platform.platform(),
        torch=torch.__version__, torch_cuda=torch.version.cuda,
        cuda_available=torch.cuda.is_available(), cuda_ops=cuda_ops,
        gpu=torch.cuda.get_device_name(0) if torch.cuda.is_available() else None,
        gpu_query=gpu_query, numpy=np.__version__, mmcv=mmcv.__version__,
        mmengine=mmengine.__version__, mmdet=mmdet.__version__,
        mmdet3d=mmdet3d.__version__, data_root=str(root),
        v1_mini_exists=(root / 'v1.0-mini').is_dir(),
        keyframe_bins=len(list((root / 'samples' / 'LIDAR_TOP').glob('*.bin'))),
        sweep_bins=len(list((root / 'sweeps' / 'LIDAR_TOP').glob('*.bin'))))
    output = COURSE_ROOT / 'outputs' / 'environment.json'
    save_json(output, report)
    print('ENVIRONMENT_OK' if report['cuda_available'] and report['v1_mini_exists']
          and len(cuda_ops) == 2 and all(cuda_ops.values())
          else 'ENVIRONMENT_CHECK_FAILED')
    for key, value in report.items():
        print(f'{key}={value}')
    print(f'wrote={output}')


if __name__ == '__main__':
    main()
