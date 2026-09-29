"""Validate structure, labels, and geographic split of a converted dataset."""

from __future__ import annotations

import argparse
import csv
import json
from collections import Counter
from pathlib import Path

IMAGE_SUFFIXES = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


def validate_dataset(dataset_root: Path) -> dict:
    dataset_root = dataset_root.expanduser().resolve()
    summary_path = dataset_root / "conversion_summary.json"
    manifest_path = dataset_root / "manifest.csv"
    yaml_path = dataset_root / "data.yaml"
    for required in (summary_path, manifest_path, yaml_path):
        if not required.is_file():
            raise FileNotFoundError(f"Missing required file: {required}")

    summary = json.loads(summary_path.read_text(encoding="utf-8"))
    class_names = summary.get("class_names")
    if class_names is None:
        class_names = [
            line.strip()
            for line in (dataset_root / "classes.txt").read_text(encoding="utf-8").splitlines()
            if line.strip()
        ]
    class_count = len(class_names)
    split_counts = {}
    label_counts: Counter = Counter()
    errors = []

    for split in ("train", "val", "test"):
        image_dir = dataset_root / "images" / split
        label_dir = dataset_root / "labels" / split
        images = sorted(path for path in image_dir.iterdir() if path.suffix.lower() in IMAGE_SUFFIXES)
        labels = sorted(label_dir.glob("*.txt"))
        image_stems = {path.stem for path in images}
        label_stems = {path.stem for path in labels}
        if image_stems != label_stems:
            errors.append(
                f"{split}: unmatched stems; images_only={len(image_stems - label_stems)}, "
                f"labels_only={len(label_stems - image_stems)}"
            )

        for label_path in labels:
            for line_number, line in enumerate(
                label_path.read_text(encoding="utf-8").splitlines(), start=1
            ):
                fields = line.split()
                if len(fields) != 5:
                    errors.append(f"{label_path}:{line_number}: expected 5 fields")
                    continue
                try:
                    class_id = int(fields[0])
                    values = [float(value) for value in fields[1:]]
                except ValueError:
                    errors.append(f"{label_path}:{line_number}: non-numeric label")
                    continue
                if not 0 <= class_id < class_count:
                    errors.append(f"{label_path}:{line_number}: invalid class id {class_id}")
                if any(not 0.0 <= value <= 1.0 for value in values):
                    errors.append(f"{label_path}:{line_number}: coordinate outside [0, 1]")
                if values[2] <= 0.0 or values[3] <= 0.0:
                    errors.append(f"{label_path}:{line_number}: non-positive box size")
                label_counts[split] += 1

        split_counts[split] = {"images": len(images), "labels": len(labels)}

    manifest_counts: Counter = Counter()
    with manifest_path.open("r", newline="", encoding="utf-8-sig") as handle:
        for row in csv.DictReader(handle):
            split = row["split"]
            manifest_counts[split] += 1

    for split in ("train", "val", "test"):
        if manifest_counts[split] != split_counts[split]["images"]:
            errors.append(
                f"{split}: manifest={manifest_counts[split]}, "
                f"images={split_counts[split]['images']}"
            )

    result = {
        "dataset_root": str(dataset_root),
        "valid": not errors,
        "split_counts": split_counts,
        "box_counts": dict(label_counts),
        "errors": errors[:100],
        "error_count": len(errors),
    }
    if errors:
        raise ValueError(json.dumps(result, ensure_ascii=False, indent=2))
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("dataset_root", type=Path)
    args = parser.parse_args()
    print(json.dumps(validate_dataset(args.dataset_root), ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
