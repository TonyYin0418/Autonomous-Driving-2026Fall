"""NVIDIA CNN training, adapted from the course's third-party PyTorch code."""
import argparse
import csv
import json
import os
from pathlib import Path
import random
import time
import zipfile

import cv2
import numpy as np
import torch
from torch.utils.data import DataLoader

from model import NetworkNvidia
from RcCarDataset import TripletDataset
from utils import load_rows


def arguments():
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser()
    parser.add_argument('--dataroot', type=Path, default=root / 'data/udacity_e2e/dataset')
    parser.add_argument('--work-dir', type=Path, required=True)
    parser.add_argument('--epochs', type=int, default=50, help='total epochs, including resumed epochs')
    parser.add_argument('--resume', type=Path)
    parser.add_argument('--batch-size', type=int, default=32)
    parser.add_argument('--num-workers', type=int, default=2)
    parser.add_argument('--lr', type=float, default=1e-4)
    parser.add_argument('--weight-decay', type=float, default=1e-5)
    parser.add_argument('--seed', type=int, default=20261109)
    parser.add_argument('--image-archive', type=Path, default=root / 'data/udacity_assets/dataset.zip')
    return parser.parse_args()


def loader_worker(worker):
    cv2.setNumThreads(0)
    np.random.seed(torch.initial_seed() % 2**32)


def run_epoch(model, loader, device, optimizer=None):
    training = optimizer is not None
    model.train(training)
    squared = absolute = center_squared = center_absolute = 0.0
    count = center_count = 0
    with torch.set_grad_enabled(training):
        for batch, (images, angles) in enumerate(loader, 1):
            images = images.to(device, non_blocking=True)
            angles = angles.to(device, non_blocking=True)
            # One optimization step per camera, as in the upstream training loop.
            for camera in range(3):
                if training:
                    optimizer.zero_grad(set_to_none=True)
                outputs = model(images[:, camera].contiguous()).squeeze(1)
                error = outputs - angles[:, camera]
                loss = error.square().mean()
                if training:
                    loss.backward()
                    optimizer.step()
                squared += error.detach().square().sum().item()
                absolute += error.detach().abs().sum().item()
                count += error.numel()
                if camera == 0:
                    center_squared += error.detach().square().sum().item()
                    center_absolute += error.detach().abs().sum().item()
                    center_count += error.numel()
            if training and batch % 200 == 0:
                print(f'  training batch {batch}/{len(loader)} mse={squared / count:.6f}', flush=True)
    return {'mse': squared / count, 'mae': absolute / count,
            'center_mse': center_squared / center_count,
            'center_mae': center_absolute / center_count}


def main():
    args = arguments()
    random.seed(args.seed)
    np.random.seed(args.seed)
    torch.manual_seed(args.seed)
    torch.set_num_threads(4)
    cv2.setNumThreads(0)
    torch.backends.cudnn.benchmark = True
    device = torch.device('cuda')
    rows = load_rows(args.dataroot)
    print('Loading JPEG byte cache from data archive ...', flush=True)
    begin = time.perf_counter()
    with zipfile.ZipFile(args.image_archive) as archive:
        image_cache = {Path(name).name: archive.read(name) for name in archive.namelist()
                       if name.startswith('dataset/IMG/') and name.endswith('.jpg')}
    print(f'JPEG cache: {len(image_cache)} images, {sum(map(len, image_cache.values())) / 1024**2:.0f} MiB, '
          f'{time.perf_counter() - begin:.1f} seconds', flush=True)
    indices = torch.randperm(len(rows), generator=torch.Generator().manual_seed(args.seed)).tolist()
    cut = int(0.8 * len(rows))
    train_ids, val_ids = indices[:cut], indices[cut:]
    args.work_dir.mkdir(parents=True, exist_ok=True)
    (args.work_dir / 'split.json').write_text(json.dumps({'seed': args.seed, 'train': train_ids, 'val': val_ids}))
    config = {key: str(value) if isinstance(value, Path) else value for key, value in vars(args).items()}
    config.update(train_rows=len(train_ids), val_rows=len(val_ids), torch=torch.__version__,
                  device=torch.cuda.get_device_name(), camera_correction=0.4)
    (args.work_dir / 'config.json').write_text(json.dumps(config, indent=2))
    kwargs = dict(batch_size=args.batch_size, num_workers=args.num_workers, pin_memory=True,
                  persistent_workers=args.num_workers > 0, worker_init_fn=loader_worker)
    trainloader = DataLoader(TripletDataset(args.dataroot, [rows[i] for i in train_ids], True, image_cache), shuffle=True, **kwargs)
    valloader = DataLoader(TripletDataset(args.dataroot, [rows[i] for i in val_ids], False, image_cache), shuffle=False, **kwargs)
    model = NetworkNvidia().to(device)
    optimizer = torch.optim.Adam(model.parameters(), lr=args.lr, weight_decay=args.weight_decay)
    scheduler = torch.optim.lr_scheduler.MultiStepLR(optimizer, milestones=[30, 50], gamma=0.1)
    start, best = 0, float('inf')
    if args.resume:
        checkpoint = torch.load(args.resume, map_location=device, weights_only=False)
        model.load_state_dict(checkpoint['state_dict'])
        optimizer.load_state_dict(checkpoint['optimizer'])
        scheduler.load_state_dict(checkpoint['scheduler'])
        start, best = checkpoint['epoch'], checkpoint['best_mse']
        torch.set_rng_state(checkpoint['torch_rng'].cpu())
        torch.cuda.set_rng_state(checkpoint['cuda_rng'].cpu())
        random.setstate(checkpoint['python_rng'])
        np.random.set_state(checkpoint['numpy_rng'])
    elif (args.work_dir / 'last.h5').exists():
        raise FileExistsError('Use --resume or a new work directory')
    print(json.dumps(config), flush=True)
    print('PARAMETERS', sum(p.numel() for p in model.parameters()), flush=True)
    columns = ['epoch', 'lr', 'train_mse', 'val_mse', 'val_center_mse', 'val_center_mae', 'seconds', 'peak_gpu_mb']
    metrics_path = args.work_dir / 'metrics.csv'
    with metrics_path.open('a' if start else 'w', newline='', buffering=1) as handle:
        writer = csv.DictWriter(handle, fieldnames=columns)
        if start == 0:
            writer.writeheader()
        for epoch in range(start + 1, args.epochs + 1):
            begin = time.perf_counter()
            torch.cuda.reset_peak_memory_stats()
            lr = optimizer.param_groups[0]['lr']
            train = run_epoch(model, trainloader, device, optimizer)
            val = run_epoch(model, valloader, device)
            torch.cuda.synchronize()
            row = dict(epoch=epoch, lr=lr, train_mse=train['mse'], val_mse=val['mse'],
                       val_center_mse=val['center_mse'], val_center_mae=val['center_mae'],
                       seconds=time.perf_counter() - begin,
                       peak_gpu_mb=torch.cuda.max_memory_allocated() / 1024**2)
            writer.writerow(row)
            print(json.dumps(row), flush=True)
            scheduler.step()
            improved = val['center_mse'] < best
            best = min(best, val['center_mse'])
            state = dict(epoch=epoch, state_dict=model.state_dict(), optimizer=optimizer.state_dict(),
                         scheduler=scheduler.state_dict(), best_mse=best, config=config,
                         torch_rng=torch.get_rng_state(), cuda_rng=torch.cuda.get_rng_state(),
                         python_rng=random.getstate(), numpy_rng=np.random.get_state())
            torch.save(state, args.work_dir / 'last.h5')
            if improved:
                torch.save(state, args.work_dir / 'best.h5')
            if epoch % 5 == 0:
                torch.save(state, args.work_dir / f'model-{epoch}.h5')
    (args.work_dir / 'summary.json').write_text(json.dumps({'epochs': args.epochs, 'best_center_mse': best}, indent=2))


if __name__ == '__main__':
    main()
