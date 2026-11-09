"""Create course report figures from saved training and driving results."""
import argparse
import csv
import json
from pathlib import Path
import shutil

import cv2
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np

from utils import image_path, load_rows


def save_figure(fig, path):
    fig.tight_layout()
    for extension in ('pdf', 'svg', 'png'):
        fig.savefig(path.with_suffix('.' + extension), dpi=300, bbox_inches='tight')
    plt.close(fig)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--work-dir', type=Path, required=True)
    parser.add_argument('--drive-dir', type=Path)
    args = parser.parse_args()
    report = Path(__file__).resolve().parents[1] / 'reports/stage04_e2e'
    figures, results = report / 'figures', report / 'results'
    figures.mkdir(parents=True, exist_ok=True)
    results.mkdir(exist_ok=True)
    plt.rcParams.update({'font.size': 10, 'axes.spines.top': False, 'axes.spines.right': False,
                         'font.family': 'DejaVu Sans'})
    metrics = np.genfromtxt(args.work_dir / 'metrics.csv', delimiter=',', names=True)
    metrics = np.atleast_1d(metrics)
    fig, ax = plt.subplots(figsize=(6.4, 3.4))
    ax.plot(metrics['epoch'], metrics['train_mse'], color='#0072B2', label='Training')
    ax.plot(metrics['epoch'], metrics['val_mse'], color='#D55E00', label='Validation')
    ax.set(xlabel='Epoch', ylabel='MSE')
    ax.legend(frameon=False)
    save_figure(fig, figures / 'loss_curves')
    config = json.loads((args.work_dir / 'config.json').read_text())
    rows = load_rows(config['dataroot'])
    angles = np.array([float(r[3]) for r in rows])
    fig, ax = plt.subplots(figsize=(6.4, 3.1))
    ax.hist(angles, bins=41, color='#0072B2', edgecolor='white', linewidth=0.3)
    ax.set(xlabel='Steering angle', ylabel='Frames')
    save_figure(fig, figures / 'steering_distribution')
    row = next(r for r in rows if abs(float(r[3])) > 0.15 and 'track1data' in r[0])
    fig, axes = plt.subplots(2, 3, figsize=(9, 3.5))
    for camera, label in enumerate(('Center', 'Left', 'Right')):
        image = cv2.imread(str(image_path(config['dataroot'], row[camera])))[:, :, ::-1]
        axes[0, camera].imshow(image)
        axes[1, camera].imshow(image[65:-25])
        axes[0, camera].set_title(label, fontsize=10)
        axes[0, camera].axis('off')
        axes[1, camera].axis('off')
    save_figure(fig, figures / 'camera_preprocessing')
    for name in ('metrics.csv', 'config.json', 'summary.json'):
        shutil.copy2(args.work_dir / name, results / name)
    if (results / 'driving_window.png').exists():
        shutil.copy2(results / 'driving_window.png', figures / 'driving_window.png')
    best = metrics[int(np.argmin(metrics['val_center_mse']))]
    summary = {'epochs': int(metrics[-1]['epoch']), 'best_epoch': int(best['epoch']),
               'best_center_mse': float(best['val_center_mse']),
               'best_center_rmse': float(np.sqrt(best['val_center_mse'])),
               'best_center_mae': float(best['val_center_mae']),
               'last_train_mse': float(metrics[-1]['train_mse']),
               'last_val_mse': float(metrics[-1]['val_mse']),
               'total_training_seconds': float(metrics['seconds'].sum()),
               'mean_epoch_seconds': float(metrics['seconds'].mean()),
               'peak_gpu_mb': float(metrics['peak_gpu_mb'].max()),
               'rows': len(rows), 'train_rows': config['train_rows'], 'val_rows': config['val_rows']}
    if args.drive_dir:
        telemetry_path = args.drive_dir / 'telemetry.csv'
        with telemetry_path.open() as f:
            telemetry = list(csv.DictReader(f))
        if telemetry:
            from datetime import datetime
            start = datetime.fromisoformat(telemetry[0]['time'])
            seconds = np.array([(datetime.fromisoformat(r['time']) - start).total_seconds() for r in telemetry])
            fig, axes = plt.subplots(3, 1, figsize=(6.4, 5), sharex=True)
            for ax, field, label, color in zip(axes, ('steering', 'throttle', 'speed'),
                                             ('Steering', 'Throttle', 'Speed'),
                                             ('#0072B2', '#D55E00', '#009E73')):
                ax.plot(seconds, [float(r[field]) for r in telemetry], color=color, linewidth=0.8)
                ax.set_ylabel(label)
            axes[-1].set_xlabel('Time (s)')
            save_figure(fig, figures / 'driving_signals')
            summary['driving'] = {'frames': len(telemetry), 'seconds': float(seconds[-1]),
                'mean_speed': float(np.mean([float(r['speed']) for r in telemetry])),
                'mean_inference_ms': float(np.mean([float(r['inference_ms']) for r in telemetry]))}
            shutil.copy2(telemetry_path, results / 'telemetry.csv')
            frames = sorted((args.drive_dir / 'frames').glob('*.jpg'))
            if frames:
                fig, axes = plt.subplots(1, 3, figsize=(9, 2.1))
                for ax, index in zip(axes, np.linspace(0, len(frames)-1, 3, dtype=int)):
                    ax.imshow(plt.imread(frames[index]))
                    ax.axis('off')
                save_figure(fig, figures / 'driving_frames')
    (results / 'results.json').write_text(json.dumps(summary, indent=2))
    print(json.dumps(summary, indent=2))


if __name__ == '__main__':
    main()
