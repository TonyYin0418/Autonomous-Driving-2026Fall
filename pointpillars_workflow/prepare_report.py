"""Build report figures and small evidence files from completed course runs."""
from __future__ import annotations

import argparse
import hashlib
import json
import pickle
import shutil
from pathlib import Path

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
import numpy as np

from course_common import COURSE_ROOT, CLASSES, data_root_from_arg, save_json
from course_visualization import _as_numpy, _box_lines


def read_json(path):
    return json.loads(path.read_text(encoding='utf-8'))


def predictions(sample):
    pred = sample['pred_instances_3d'] if isinstance(sample, dict) else sample.pred_instances_3d
    if isinstance(pred, dict):
        return (_as_numpy(pred['bboxes_3d'].tensor),
                _as_numpy(pred['scores_3d']), _as_numpy(pred['labels_3d']))
    return (_as_numpy(pred.bboxes_3d.tensor), _as_numpy(pred.scores_3d),
            _as_numpy(pred.labels_3d))


def save_figure(fig, destination):
    for extension in ['.pdf', '.svg', '.png']:
        fig.savefig(destination.with_suffix(extension), dpi=300, bbox_inches='tight')
    plt.close(fig)


def draw_bev(ax, points, sample, info, threshold, ground_truth=True):
    keep = (np.abs(points[:, 0]) <= 25) & (np.abs(points[:, 1]) <= 25)
    ax.scatter(points[keep, 0], points[keep, 1], s=0.3, c='0.45', alpha=0.45,
               rasterized=True)
    if ground_truth:
        for instance in info['instances']:
            if instance['bbox_label_3d'] < 0 or instance['num_lidar_pts'] <= 0:
                continue
            box = instance['bbox_3d']
            if abs(box[0]) <= 25 and abs(box[1]) <= 25:
                corners = _box_lines(box)
                ax.plot(*corners.T, color='#0072B2', linestyle='--', linewidth=1.1)
    boxes, scores, labels = predictions(sample)
    for box, score, label in zip(boxes, scores, labels):
        if score < threshold:
            continue
        corners = _box_lines(box)
        ax.plot(*corners.T, color='#D55E00', linewidth=1.1)
    ax.plot(0, 0, '+', color='black', markersize=5)
    ax.set(xlim=(-25, 25), ylim=(-25, 25), xlabel='x / m', ylabel='y / m')
    ax.set_aspect('equal')
    ax.set_xticks([-20, -10, 0, 10, 20])
    ax.set_yticks([-20, -10, 0, 10, 20])
    ax.grid(alpha=0.15)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ['baseline', 'finetuned', 'run1', 'run5']:
        parser.add_argument('--' + name, type=Path, required=True)
    parser.add_argument('--report-dir', type=Path,
                        default=COURSE_ROOT.parent / 'reports/stage03_pointpillars')
    args = parser.parse_args()
    report = args.report_dir.resolve()
    figures = report / 'figures'
    evidence = report / 'results'
    figures.mkdir(parents=True, exist_ok=True)
    evidence.mkdir(exist_ok=True)
    plt.rcParams.update({'font.size': 10, 'axes.labelsize': 10,
                         'xtick.labelsize': 9, 'ytick.labelsize': 9,
                         'legend.fontsize': 9, 'svg.fonttype': 'none'})

    # Preserve evidence with no dependency on the runtime outputs symlink.
    for name in ['baseline', 'finetuned', 'run1', 'run5']:
        source = getattr(args, name).resolve()
        target = evidence / name
        target.mkdir(exist_ok=True)
        for filename in ['metrics_summary.json', 'test_meta.json', 'training_audit.json',
                         'run_meta.json', 'loss_history.json', 'resolved_config.py',
                         'console.log', 'loss.png', 'loss.pdf', 'loss.svg']:
            if (source / filename).is_file():
                shutil.copy2(source / filename, target / filename)
    for filename in ['environment.json', 'data_audit.json', 'checkpoint_audit.json',
                     'comparison.json']:
        shutil.copy2(COURSE_ROOT / 'outputs' / filename, evidence / filename)
    shutil.copy2(COURSE_ROOT / 'data_infos/manifest.json', evidence / 'manifest.json')

    history = (read_json(args.run1 / 'loss_history.json')['points'] +
               read_json(args.run5 / 'loss_history.json')['points'])
    iterations = np.array([item['iteration'] for item in history]) + 1
    loss = np.array([item['loss'] for item in history])
    assert np.array_equal(iterations, np.arange(1, 1616)) and np.isfinite(loss).all()
    fig, ax = plt.subplots(figsize=(7.2, 3.3))
    ax.plot(iterations, loss, color='#56B4E9', alpha=0.35, linewidth=0.5,
            label='Per iteration')
    window = 50
    ax.plot(iterations[window - 1:], np.convolve(loss, np.ones(window) / window, 'valid'),
            color='#0072B2', linewidth=1.5, label='50-iteration moving average')
    ax.axvline(323.5, linestyle='--', color='#666666', linewidth=1)
    ax.text(340, max(loss) * 0.88, 'Resume from epoch 1', fontsize=9)
    ax.set(xlabel='Training iteration', ylabel='Training loss', xlim=(1, 1615))
    ax.spines[['top', 'right']].set_visible(False)
    ax.grid(axis='y', alpha=0.2)
    ax.legend(frameon=False, loc='upper right')
    save_figure(fig, figures / 'training_loss')

    with (args.baseline / 'predictions.pkl').open('rb') as f:
        baseline = pickle.load(f)
    with (args.finetuned / 'predictions.pkl').open('rb') as f:
        finetuned = pickle.load(f)
    with (COURSE_ROOT / 'data_infos/val.pkl').open('rb') as f:
        infos = pickle.load(f)['data_list']
    assert len(baseline) == len(finetuned) == len(infos) == 81
    # Bind prediction order to the validation records before any GT overlay.
    for model_samples in [baseline, finetuned]:
        for index, sample in enumerate(model_samples):
            meta = sample if isinstance(sample, dict) else sample.metainfo
            assert int(meta['sample_idx']) == int(infos[index]['sample_idx'])
            assert Path(meta['lidar_path']).name == infos[index]['lidar_points']['lidar_path']
    root = data_root_from_arg(None)
    points = {i: np.fromfile(root / 'samples/LIDAR_TOP' /
                            infos[i]['lidar_points']['lidar_path'], dtype=np.float32).reshape(-1, 5)
              for i in [0, 40, 80]}
    handles = [Line2D([], [], color='#0072B2', linestyle='--', label='Ground truth'),
               Line2D([], [], color='#D55E00', label='Prediction')]
    fig, axes = plt.subplots(1, 2, figsize=(9, 4.2))
    for ax, sample in zip(axes, [baseline[0], finetuned[0]]):
        draw_bev(ax, points[0], sample, infos[0], 0.30)
    fig.legend(handles=handles, loc='upper center', ncol=2, frameon=False,
               bbox_to_anchor=(0.5, 1.06))
    fig.tight_layout()
    save_figure(fig, figures / 'baseline_vs_finetuned')

    fig, axes = plt.subplots(1, 3, figsize=(12, 4))
    for ax, index in zip(axes, [0, 40, 80]):
        draw_bev(ax, points[index], finetuned[index], infos[index], 0.30)
    fig.legend(handles=handles, loc='upper center', ncol=2, frameon=False,
               bbox_to_anchor=(0.5, 1.06))
    fig.tight_layout()
    save_figure(fig, figures / 'fixed_samples')

    fig, axes = plt.subplots(1, 2, figsize=(9, 4.2))
    for ax, threshold in zip(axes, [0.10, 0.30]):
        draw_bev(ax, points[0], finetuned[0], infos[0], threshold, ground_truth=False)
    fig.tight_layout()
    save_figure(fig, figures / 'threshold_comparison')

    samples_json = json.loads((root / 'v1.0-mini/sample.json').read_text())
    scenes = {x['token']: x['name'] for x in json.loads((root / 'v1.0-mini/scene.json').read_text())}
    sample_scenes = {x['token']: scenes[x['scene_token']] for x in samples_json}
    selected = []
    for index in [0, 40, 80]:
        bboxes, bscores, _ = predictions(baseline[index])
        fboxes, fscores, _ = predictions(finetuned[index])
        selected.append(dict(validation_index=index, sample_token=infos[index]['token'],
                             scene=sample_scenes[infos[index]['token']],
                             baseline_thr010=int((bscores >= .1).sum()),
                             baseline_thr030=int((bscores >= .3).sum()),
                             finetuned_thr010=int((fscores >= .1).sum()),
                             finetuned_thr030=int((fscores >= .3).sum())))
    bm = read_json(args.baseline / 'metrics_summary.json')
    fm = read_json(args.finetuned / 'metrics_summary.json')
    class_ap = {name: {kind: float(np.mean([value for key, value in metrics.items()
                  if '/' + name + '_AP_dist_' in key]))
                  for kind, metrics in [('baseline', bm), ('finetuned', fm)]}
                for name in CLASSES}
    epoch_loss = [float(np.mean(loss[e * 323:(e + 1) * 323])) for e in range(5)]
    weight = args.run5 / 'epoch_5.pth'
    summary = dict(runs={name: getattr(args, name).resolve().name
                         for name in ['baseline', 'finetuned', 'run1', 'run5']},
                   epoch_mean_loss=epoch_loss, selected_samples=selected,
                   class_ap_from_rounded_distance_metrics=class_ap,
                   final_checkpoint_sha256=hashlib.sha256(weight.read_bytes()).hexdigest(),
                   final_checkpoint_bytes=weight.stat().st_size)
    save_json(evidence / 'report_summary.json', summary)
    # Preserve teacher-required PNGs separately from the report's GT overlays.
    for source_dir, target_name in [('visualizations', 'finetuned_thr010'),
                                     ('visualizations_thr030', 'finetuned_thr030')]:
        target = figures / target_name
        target.mkdir(exist_ok=True)
        for path in (args.finetuned / source_dir).glob('*'):
            if path.suffix in ['.png', '.pdf', '.svg', '.json']:
                shutil.copy2(path, target / path.name)
    print(json.dumps(summary, indent=2, ensure_ascii=False))
    print('REPORT_ASSETS_OK', report)


if __name__ == '__main__':
    main()
