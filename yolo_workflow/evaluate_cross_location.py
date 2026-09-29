"""Evaluate one trained model on all four nuScenes locations."""

from __future__ import annotations

import argparse
import csv
import json
import os
from pathlib import Path

from common import configure_runtime, workflow_path


LOCATIONS = (
    "boston-seaport",
    "singapore-hollandvillage",
    "singapore-onenorth",
    "singapore-queenstown",
)


def save_comparison_plot(rows: list[dict], output_dir: Path) -> None:
    """Save a compact, publication-ready comparison in raster and vector formats."""
    import matplotlib.pyplot as plt

    plt.rcParams.update(
        {
            "font.family": "sans-serif",
            "font.size": 9,
            "axes.labelsize": 9,
            "xtick.labelsize": 8,
            "ytick.labelsize": 8,
            "legend.fontsize": 8,
            "pdf.fonttype": 42,
            "ps.fonttype": 42,
        }
    )
    labels = ["Boston", "Holland Village", "One-North", "Queenstown"]
    x = list(range(len(rows)))
    width = 0.34
    colors = ("#4C78A8", "#F58518")  # colorblind-friendly blue and orange

    fig, ax = plt.subplots(figsize=(7.2, 3.5))
    bars_50 = ax.bar(
        [i - width / 2 for i in x],
        [row["mAP50"] for row in rows],
        width,
        label=r"mAP$_{50}$",
        color=colors[0],
    )
    bars_5095 = ax.bar(
        [i + width / 2 for i in x],
        [row["mAP50-95"] for row in rows],
        width,
        label=r"mAP$_{50:95}$",
        color=colors[1],
    )
    for bars in (bars_50, bars_5095):
        ax.bar_label(bars, fmt="%.3f", padding=2, fontsize=7)

    ax.set_xticks(x, labels)
    ax.set_ylabel("Detection performance")
    ax.set_ylim(0, 0.62)
    ax.set_axisbelow(True)
    ax.grid(axis="y", color="#D9D9D9", linewidth=0.6)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.legend(frameon=False, ncols=2, loc="upper left")
    fig.tight_layout()
    for suffix in ("pdf", "svg"):
        fig.savefig(output_dir / f"comparison.{suffix}", bbox_inches="tight")
    fig.savefig(output_dir / "comparison.png", dpi=300, bbox_inches="tight")
    plt.close(fig)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model", type=Path, required=True)
    parser.add_argument("--datasets-root", type=Path, required=True)
    parser.add_argument("--name", required=True)
    parser.add_argument("--imgsz", type=int, default=640)
    parser.add_argument("--batch", type=int, default=16)
    parser.add_argument("--device", default="0")
    parser.add_argument("--workers", type=int, default=16)
    parser.add_argument("--project", type=Path, default=Path("runs/cross_location"))
    return parser


def main() -> None:
    args = build_parser().parse_args()
    configure_runtime()

    from ultralytics import YOLO

    model_path = workflow_path(args.model)
    datasets_root = args.datasets_root.expanduser().resolve()
    output_dir = workflow_path(args.project) / args.name
    output_dir.mkdir(parents=True)
    model = YOLO(str(model_path))
    rows = []

    for location in LOCATIONS:
        data_yaml = datasets_root / location / "data.yaml"
        print(f"\n===== {location} =====")
        os.chdir(data_yaml.parent)
        metrics = model.val(
            data=str(data_yaml),
            split="test",
            imgsz=args.imgsz,
            batch=args.batch,
            device=args.device,
            workers=args.workers,
            conf=0.001,
            iou=0.7,
            plots=True,
            project=str(output_dir),
            name=location,
            exist_ok=True,
        )
        rows.append(
            {
                "location": location,
                "images": sum(1 for path in (data_yaml.parent / "images/test").iterdir() if path.is_file()),
                "precision": float(metrics.box.mp),
                "recall": float(metrics.box.mr),
                "mAP50": float(metrics.box.map50),
                "mAP50-95": float(metrics.box.map),
            }
        )

    with (output_dir / "summary.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)
    (output_dir / "summary.json").write_text(
        json.dumps({"model": str(model_path), "split": "test", "results": rows}, indent=2),
        encoding="utf-8",
    )

    save_comparison_plot(rows, output_dir)

    print("\nCross-location summary:")
    for row in rows:
        print(row)
    print(f"Results saved to {output_dir}")


if __name__ == "__main__":
    main()
