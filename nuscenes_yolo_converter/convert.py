"""Convert nuScenes camera annotations to four location-wise YOLO datasets."""

from __future__ import annotations

import argparse
import csv
import json
import os
import random
import shutil
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Sequence, Tuple

import numpy as np
from pyquaternion import Quaternion

PROJECT_ROOT = Path(__file__).resolve().parent
MPL_CACHE_ROOT = PROJECT_ROOT / ".mpl-cache"
MPL_CACHE_ROOT.mkdir(parents=True, exist_ok=True)
os.environ.setdefault("MPLCONFIGDIR", str(MPL_CACHE_ROOT))

from nuscenes.utils.data_classes import Box
from nuscenes.utils.geometry_utils import view_points

LOCATIONS = {
    "boston-seaport",
    "singapore-hollandvillage",
    "singapore-onenorth",
    "singapore-queenstown",
}
CLASS_NAMES = [
    "car", "truck", "bus", "trailer", "construction_vehicle",
    "pedestrian", "motorcycle", "bicycle", "traffic_cone", "barrier",
]
CLASS_MAP = {
    "movable_object.barrier": "barrier", "vehicle.bicycle": "bicycle",
    "vehicle.bus.bendy": "bus", "vehicle.bus.rigid": "bus",
    "vehicle.car": "car", "vehicle.construction": "construction_vehicle",
    "vehicle.motorcycle": "motorcycle", "vehicle.trailer": "trailer",
    "vehicle.truck": "truck", "movable_object.trafficcone": "traffic_cone",
    "human.pedestrian.adult": "pedestrian", "human.pedestrian.child": "pedestrian",
    "human.pedestrian.construction_worker": "pedestrian",
    "human.pedestrian.police_officer": "pedestrian",
}


@dataclass(frozen=True)
class FilterConfig:
    near_plane: float = 0.1
    min_width: float = 10.0
    min_height: float = 10.0
    min_area: float = 100.0
    require_center_inside: bool = True
    require_all_corners_in_front: bool = True
    require_fully_inside: bool = False


def load_table(root: Path, version: str, name: str) -> List[dict]:
    path = root / version / f"{name}.json"
    if not path.is_file():
        raise FileNotFoundError(path)
    return json.loads(path.read_text(encoding="utf-8"))


def split_scenes(
    scenes: Sequence[dict], logs: Sequence[dict], seed: int,
    train_ratio: float, val_ratio: float, exclude_night: bool,
) -> Tuple[Dict[str, str], Dict[str, dict], dict]:
    """Split each location by log (or scene for very small locations)."""
    if train_ratio <= 0 or val_ratio <= 0 or train_ratio + val_ratio >= 1:
        raise ValueError("train_ratio and val_ratio must sum to less than 1")
    logs_by_token = {item["token"]: item for item in logs}
    active = [
        scene for scene in scenes
        if not (exclude_night and "night" in scene.get("description", "").lower())
    ]
    by_location: Dict[str, List[dict]] = defaultdict(list)
    for scene in active:
        location = logs_by_token[scene["log_token"]]["location"]
        if location not in LOCATIONS:
            raise ValueError(f"Unexpected location: {location}")
        by_location[location].append(scene)

    scene_split: Dict[str, str] = {}
    stats = {}
    for location in sorted(LOCATIONS):
        location_scenes = list(by_location[location])
        rng = random.Random(f"{seed}:{location}")
        rng.shuffle(location_scenes)
        val_count = max(1, round(len(location_scenes) * val_ratio))
        test_count = max(1, round(len(location_scenes) * (1 - train_ratio - val_ratio)))
        for index, scene in enumerate(location_scenes):
            scene_split[scene["token"]] = (
                "val" if index < val_count else
                "test" if index < val_count + test_count else "train"
            )
        stats[location] = {
            "scene_counts": dict(Counter(scene_split[s["token"]] for s in location_scenes)),
            "split_unit": "scene",
        }
    return scene_split, {s["token"]: s for s in active}, stats


def project_box(
    box: Box, intrinsic: np.ndarray, image_size: Tuple[int, int], config: FilterConfig,
) -> Optional[Tuple[float, float, float, float]]:
    width, height = image_size
    corners = box.corners()
    depths = corners[2]
    if config.require_all_corners_in_front and np.any(depths <= config.near_plane):
        return None
    valid = depths > config.near_plane
    if not np.any(valid):
        return None
    points = view_points(corners[:, valid], intrinsic, normalize=True)[:2]
    x1, y1 = float(points[0].min()), float(points[1].min())
    x2, y2 = float(points[0].max()), float(points[1].max())
    if config.require_fully_inside and (x1 < 0 or y1 < 0 or x2 > width or y2 > height):
        return None
    bbox = (max(0.0, x1), max(0.0, y1), min(float(width), x2), min(float(height), y2))
    box_width, box_height = bbox[2] - bbox[0], bbox[3] - bbox[1]
    if box_width < config.min_width or box_height < config.min_height:
        return None
    if box_width * box_height < config.min_area:
        return None
    if config.require_center_inside:
        center = view_points(box.center.reshape(3, 1), intrinsic, normalize=True)[:2, 0]
        if not (0 <= center[0] <= width and 0 <= center[1] <= height):
            return None
    return bbox


def materialize(source: Path, destination: Path, mode: str) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    if mode == "copy":
        shutil.copy2(source, destination)
    elif mode == "symlink":
        destination.symlink_to(source)
    else:
        try:
            os.link(source, destination)
        except OSError:
            raise PermissionError("Hardlink creation failed; use --image-mode copy on this system")


def write_dataset(root: Path, rows: List[dict], names: Sequence[str]) -> None:
    (root / "manifests").mkdir(parents=True, exist_ok=True)
    (root / "data.yaml").write_text(
        "path: .\ntrain: images/train\nval: images/val\ntest: images/test\nnames:\n"
        + "\n".join(f"  {i}: {json.dumps(name)}" for i, name in enumerate(names)) + "\n",
        encoding="utf-8",
    )
    (root / "classes.txt").write_text("\n".join(names) + "\n", encoding="utf-8")
    with (root / "manifest.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=["split", "location", "source_image", "output_image", "label_count"])
        writer.writeheader(); writer.writerows(rows)
    for split in ("train", "val", "test"):
        entries = [f"./../images/{split}/{Path(r['output_image']).name}" for r in rows if r["split"] == split]
        (root / "manifests" / f"{split}.txt").write_text("\n".join(sorted(entries)) + "\n", encoding="utf-8")


def sample_frames_by_distance(
    frames: Sequence[dict], min_distance: float,
) -> Tuple[List[dict], dict]:
    """Remove empty frames and retain frames at least min_distance metres apart.

    Sampling is performed independently for each scene and camera channel in
    timestamp order. Distance is measured in the XY ego-position plane from
    the last retained frame.
    """
    if min_distance < 0:
        raise ValueError("min_distance must be non-negative")

    nonempty_frames = [frame for frame in frames if frame["labels"]]
    grouped_frames: Dict[Tuple[str, str], List[dict]] = defaultdict(list)
    for frame in nonempty_frames:
        grouped_frames[(frame["scene_token"], frame["channel"])].append(frame)

    retained: List[dict] = []
    for group in grouped_frames.values():
        last_position: Optional[np.ndarray] = None
        for frame in sorted(group, key=lambda item: item["timestamp"]):
            position = frame["ego_position"]
            if last_position is None or np.linalg.norm(position[:2] - last_position[:2]) >= min_distance:
                retained.append(frame)
                last_position = position

    retained.sort(key=lambda frame: (frame["location"], frame["scene_token"], frame["timestamp"]))
    stats = {
        "input_frames": len(frames),
        "empty_frames_removed": len(frames) - len(nonempty_frames),
        "distance_frames_removed": len(nonempty_frames) - len(retained),
        "retained_frames": len(retained),
        "min_distance_m": min_distance,
        "retained_boxes": sum(len(frame["labels"]) for frame in retained),
        "by_location_split": {},
    }
    location_split_counts: Dict[str, Counter] = defaultdict(Counter)
    for frame in retained:
        location_split_counts[frame["location"]][frame["split"]] += 1
    stats["by_location_split"] = {
        location: dict(counts) for location, counts in sorted(location_split_counts.items())
    }
    return retained, stats


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dataroot", type=Path, required=True)
    parser.add_argument("--version", default="v1.0-trainval")
    parser.add_argument("--output", type=Path, default=PROJECT_ROOT / "output" / "nuscenes_yolo")
    parser.add_argument("--channels", nargs="+", default=["CAM_FRONT"])
    parser.add_argument("--train-ratio", type=float, default=0.7)
    parser.add_argument("--val-ratio", type=float, default=0.1)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--exclude-night", action=argparse.BooleanOptionalAction, default=False)
    parser.add_argument("--visibilities", nargs="+", default=["1", "2", "3", "4"])
    parser.add_argument("--image-mode", choices=("hardlink", "copy", "symlink"), default="hardlink")
    parser.add_argument("--overwrite", action="store_true")
    parser.add_argument("--class-mode", choices=("detection10", "all23"), default="detection10")
    parser.add_argument("--min-width", type=float, default=10.0)
    parser.add_argument("--min-height", type=float, default=10.0)
    parser.add_argument("--min-area", type=float, default=100.0)
    parser.add_argument("--no-require-center-inside", dest="center", action="store_false")
    parser.add_argument("--no-require-all-corners-in-front", dest="all_front", action="store_false")
    parser.add_argument("--require-fully-inside", action="store_true")
    parser.add_argument("--min-distance", type=float, default=1.0, help="Minimum ego XY distance in metres between retained frames")
    parser.add_argument("--dry-run", action="store_true", help="Print sampling statistics without writing output")
    args = parser.parse_args()

    dataroot = args.dataroot.expanduser().resolve()
    output = args.output.expanduser().resolve()
    scenes = load_table(dataroot, args.version, "scene")
    logs = load_table(dataroot, args.version, "log")
    scene_split, selected_scenes, location_stats = split_scenes(
        scenes, logs, args.seed, args.train_ratio, args.val_ratio, args.exclude_night
    )
    samples = {r["token"]: r for r in load_table(dataroot, args.version, "sample") if r["scene_token"] in selected_scenes}
    sample_data = load_table(dataroot, args.version, "sample_data")
    calibrated = {r["token"]: r for r in load_table(dataroot, args.version, "calibrated_sensor")}
    poses = {r["token"]: r for r in load_table(dataroot, args.version, "ego_pose")}
    categories = load_table(dataroot, args.version, "category")
    instances = {r["token"]: r for r in load_table(dataroot, args.version, "instance")}
    category_names = {r["token"]: r["name"] for r in categories}
    instance_categories = {k: category_names[v["category_token"]] for k, v in instances.items()}
    names = CLASS_NAMES if args.class_mode == "detection10" else [r["name"] for r in categories]
    class_ids = {name: i for i, name in enumerate(names)}
    frames = []; by_sample = defaultdict(list); logs_by_token = {r["token"]: r for r in logs}
    for record in sample_data:
        if not record.get("is_key_frame") or record["sample_token"] not in samples:
            continue
        if not any(record["filename"].startswith(f"samples/{c}/") for c in args.channels):
            continue
        sample = samples[record["sample_token"]]
        location = logs_by_token[selected_scenes[sample["scene_token"]]["log_token"]]["location"]
        frame = {
            "record": record,
            "location": location,
            "split": scene_split[sample["scene_token"]],
            "scene_token": sample["scene_token"],
            "channel": Path(record["filename"]).parts[1],
            "timestamp": int(record["timestamp"]),
            "ego_position": np.asarray(poses[record["ego_pose_token"]]["translation"], dtype=float),
            "source": dataroot / record["filename"],
            "labels": [],
        }
        frames.append(frame); by_sample[record["sample_token"]].append(frame)
    config = FilterConfig(
        min_width=args.min_width,
        min_height=args.min_height,
        min_area=args.min_area,
        require_center_inside=args.center,
        require_all_corners_in_front=args.all_front,
        require_fully_inside=args.require_fully_inside,
    )
    visibility = set(args.visibilities)
    annotations = load_table(dataroot, args.version, "sample_annotation")
    for annotation in annotations:
        if annotation["sample_token"] not in by_sample or annotation.get("visibility_token") not in visibility:
            continue
        raw_name = instance_categories[annotation["instance_token"]]
        mapped = raw_name if args.class_mode == "all23" else CLASS_MAP.get(raw_name)
        if mapped not in class_ids:
            continue
        for frame in by_sample[annotation["sample_token"]]:
            record = frame["record"]; cs = calibrated[record["calibrated_sensor_token"]]; pose = poses[record["ego_pose_token"]]
            box = Box(annotation["translation"], annotation["size"], Quaternion(annotation["rotation"]))
            box.translate(-np.asarray(pose["translation"])); box.rotate(Quaternion(pose["rotation"]).inverse)
            box.translate(-np.asarray(cs["translation"])); box.rotate(Quaternion(cs["rotation"]).inverse)
            bbox = project_box(box, np.asarray(cs["camera_intrinsic"]), (record["width"], record["height"]), config)
            if bbox is not None:
                x1, y1, x2, y2 = bbox; w, h = record["width"], record["height"]
                frame["labels"].append((class_ids[mapped], (x1+x2)/(2*w), (y1+y2)/(2*h), (x2-x1)/w, (y2-y1)/h))
    frames, sampling_stats = sample_frames_by_distance(frames, args.min_distance)
    if args.dry_run:
        print(json.dumps(sampling_stats, ensure_ascii=False, indent=2))
        return
    if output.exists() and any(output.iterdir()):
        if not args.overwrite: raise FileExistsError(f"Output directory is not empty: {output}")
        shutil.rmtree(output)
    output.mkdir(parents=True, exist_ok=True)
    rows_by_location = defaultdict(list)
    for frame in frames:
        root = output / frame["location"]; split = frame["split"]; name = Path(frame["record"]["filename"]).name
        image_path = root / "images" / split / name; label_path = root / "labels" / split / f"{Path(name).stem}.txt"
        materialize(frame["source"], image_path, args.image_mode)
        label_path.parent.mkdir(parents=True, exist_ok=True)
        label_path.write_text("\n".join("%d %.6f %.6f %.6f %.6f" % item for item in frame["labels"]) + ("\n" if frame["labels"] else ""), encoding="utf-8")
        rows_by_location[frame["location"]].append({"split": split, "location": frame["location"], "source_image": str(frame["source"]), "output_image": f"images/{split}/{name}", "label_count": len(frame["labels"])})
    for location in sorted(LOCATIONS):
        root = output / location; write_dataset(root, rows_by_location[location], names)
        (root / "conversion_summary.json").write_text(json.dumps({"location": location, "class_names": names, "seed": args.seed, "split_ratios": {"train": args.train_ratio, "val": args.val_ratio, "test": 1-args.train_ratio-args.val_ratio}, "frame_counts": dict(Counter(r["split"] for r in rows_by_location[location])), "data_yaml": "data.yaml"}, indent=2), encoding="utf-8")
    (output / "conversion_summary.json").write_text(json.dumps({"dataroot": str(dataroot), "locations": location_stats, "datasets": {l: f"{l}/data.yaml" for l in sorted(LOCATIONS)}, "class_names": names, "frames": len(frames), "sampling": sampling_stats}, indent=2), encoding="utf-8")
    print(json.dumps({"output": str(output), "frames": len(frames), "datasets": sorted(LOCATIONS)}, indent=2))


if __name__ == "__main__":
    main()
