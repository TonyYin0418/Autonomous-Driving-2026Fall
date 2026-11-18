"""Evaluate the One-North YOLO11n model under day/rain/night conditions.

Run from the repository root with the Stage01 environment:
  .venv-stage01/bin/python reports/final_report/scripts/yolo_conditions.py --out <run dir>
Small results are copied to reports/final_report/results/yolo_conditions.json.
"""
import argparse
import csv
import json
import os
from collections import defaultdict
from pathlib import Path

import numpy as np
from pyquaternion import Quaternion
from nuscenes.utils.data_classes import Box
from nuscenes.utils.geometry_utils import view_points

CLASS_NAMES = ["car", "truck", "bus", "trailer", "construction_vehicle",
               "pedestrian", "motorcycle", "bicycle", "traffic_cone", "barrier"]
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
WEIGHTS = "yolo_workflow/runs/checkpoints/20260916_092702_yolo11n_onenorth/weights/best.pt"
YOLO_DATA = Path("data/nuscenes_yolo_vis34")
META = Path("data/nuscenes/v1.0-trainval")


def stream(path, keep):
    """Yield top-level records of a nuScenes JSON array without loading the whole file."""
    block = []
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            if line.startswith("{"):
                block = [line]
            elif line.startswith("}"):
                block.append("}")
                text = "".join(block)
                if keep(text):
                    yield json.loads(text)
                block = []
            elif block:
                block.append(line)


def project_box(box, intrinsic, width, height):
    """Same filter as the course converter (default FilterConfig)."""
    corners = box.corners()
    if np.any(corners[2] <= 0.1):
        return None
    points = view_points(corners, intrinsic, normalize=True)[:2]
    x1, y1 = max(0.0, points[0].min()), max(0.0, points[1].min())
    x2, y2 = min(float(width), points[0].max()), min(float(height), points[1].max())
    w, h = x2 - x1, y2 - y1
    if w < 10 or h < 10 or w * h < 100:
        return None
    c = view_points(box.center.reshape(3, 1), intrinsic, normalize=True)[:2, 0]
    if not (0 <= c[0] <= width and 0 <= c[1] <= height):
        return None
    return x1, y1, x2, y2


def write_subset(root, items):
    """items: list of (image_path, label_lines)."""
    (root / "images").mkdir(parents=True, exist_ok=True)
    (root / "labels").mkdir(parents=True, exist_ok=True)
    for image, lines in items:
        link = root / "images" / image.name
        if not link.exists():
            link.symlink_to(image.resolve())
        (root / "labels" / f"{image.stem}.txt").write_text("".join(lines), encoding="utf-8")
    yaml = "path: {}\ntrain: images\nval: images\nnames:\n".format(root.resolve())
    yaml += "".join(f"  {i}: {n}\n" for i, n in enumerate(CLASS_NAMES))
    (root / "data.yaml").write_text(yaml, encoding="utf-8")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    out = args.out
    out.mkdir(parents=True, exist_ok=True)

    scenes = {s["token"]: s for s in json.loads((META / "scene.json").read_text())}
    logs = {l["token"]: l for l in json.loads((META / "log.json").read_text())}
    sample_scene = {s["token"]: s["scene_token"] for s in json.loads((META / "sample.json").read_text())}

    def condition(scene):
        d = scene["description"].lower()
        return "night" if "night" in d else ("rain" if "rain" in d else "day")

    # CAM_FRONT key frames of every scene
    cam = {}
    for r in stream(META / "sample_data.json",
                    lambda t: '"is_key_frame": true' in t and "samples/CAM_FRONT/" in t):
        cam[Path(r["filename"]).name] = r
    print("CAM_FRONT key frames:", len(cam), flush=True)

    def info(name):
        scene = scenes[sample_scene[cam[name]["sample_token"]]]
        return scene, logs[scene["log_token"]]["location"], condition(scene)

    subsets = defaultdict(list)
    # 1) teacher test splits, split by scene condition
    for location in ("boston-seaport", "singapore-hollandvillage", "singapore-queenstown", "singapore-onenorth"):
        base = YOLO_DATA / location
        for image in sorted((base / "images" / "test").iterdir()):
            _, _, cond = info(image.name)
            label = base / "labels" / "test" / f"{image.stem}.txt"
            lines = label.read_text().splitlines(keepends=True) if label.exists() else []
            key = {"boston-seaport": "boston", "singapore-onenorth": "onenorth"}.get(location, "sg_hv_qt")
            subsets[f"{key}_{cond}"].append((image, lines))

    # 2) night scenes (excluded from the course data): convert like the course converter
    night_samples = {tok for tok, sc in sample_scene.items() if condition(scenes[sc]) == "night"}
    night_cam = {n: r for n, r in cam.items() if r["sample_token"] in night_samples}
    pose_tokens = {r["ego_pose_token"] for r in night_cam.values()}
    poses = {r["token"]: r for r in stream(META / "ego_pose.json",
             lambda t: t[t.index('"token": "') + 10:t.index('"token": "') + 42] in pose_tokens)}
    calib = {r["token"]: r for r in json.loads((META / "calibrated_sensor.json").read_text())}
    cats = {c["token"]: c["name"] for c in json.loads((META / "category.json").read_text())}
    inst = {i["token"]: cats[i["category_token"]] for i in json.loads((META / "instance.json").read_text())}
    anns = defaultdict(list)
    for a in stream(META / "sample_annotation.json",
                    lambda t: t[t.index('"sample_token": "') + 17:t.index('"sample_token": "') + 49] in night_samples):
        if a["visibility_token"] in ("3", "4") and CLASS_MAP.get(inst[a["instance_token"]]):
            anns[a["sample_token"]].append(a)
    by_scene = defaultdict(list)
    for name, r in night_cam.items():
        by_scene[sample_scene[r["sample_token"]]].append((r["timestamp"], name, r))
    night_items = []
    for scene_token, frames in by_scene.items():
        last = None
        for _, name, r in sorted(frames):
            pose, cs = poses[r["ego_pose_token"]], calib[r["calibrated_sensor_token"]]
            lines = []
            for a in anns[r["sample_token"]]:
                box = Box(a["translation"], a["size"], Quaternion(a["rotation"]))
                box.translate(-np.asarray(pose["translation"])); box.rotate(Quaternion(pose["rotation"]).inverse)
                box.translate(-np.asarray(cs["translation"])); box.rotate(Quaternion(cs["rotation"]).inverse)
                bb = project_box(box, np.asarray(cs["camera_intrinsic"]), r["width"], r["height"])
                if bb:
                    x1, y1, x2, y2 = bb; w, h = r["width"], r["height"]
                    cls = CLASS_NAMES.index(CLASS_MAP[inst[a["instance_token"]]])
                    lines.append("%d %.6f %.6f %.6f %.6f\n" % (cls, (x1 + x2) / 2 / w, (y1 + y2) / 2 / h, (x2 - x1) / w, (y2 - y1) / h))
            pos = np.asarray(pose["translation"][:2])
            if not lines or (last is not None and np.linalg.norm(pos - last) < 1.0):
                continue
            last = pos
            night_items.append((Path("data/nuscenes") / r["filename"], lines))
    subsets["sg_hv_qt_night"] = night_items

    rows = []
    from ultralytics import YOLO
    model = YOLO(WEIGHTS)
    for key in sorted(subsets):
        items = subsets[key]
        if not items:
            continue
        root = out / "datasets" / key
        write_subset(root, items)
        m = model.val(data=str(root / "data.yaml"), split="val", imgsz=640, batch=16, device=0,
                      workers=4, conf=0.001, iou=0.7, plots=False, verbose=False,
                      project=str(out / "val"), name=key, exist_ok=True)
        row = {"subset": key, "images": len(items), "boxes": sum(len(l) for _, l in items),
               "precision": float(m.box.mp), "recall": float(m.box.mr),
               "mAP50": float(m.box.map50), "mAP50-95": float(m.box.map)}
        rows.append(row); print(row, flush=True)
    (out / "summary.json").write_text(json.dumps(rows, indent=2), encoding="utf-8")
    with (out / "summary.csv").open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)

    # example predictions for the report
    examples = out / "examples"; examples.mkdir(exist_ok=True)
    for key in ("sg_hv_qt_night", "boston_rain", "boston_day"):
        items = subsets.get(key, [])
        if not items:
            continue
        for image, lines in items[len(items) // 3: len(items) // 3 + 6]:
            res = model.predict(str(image), conf=0.25, imgsz=640, device=0, verbose=False)[0]
            import cv2
            pred = res.plot(line_width=2, font_size=14)
            gt = cv2.imread(str(image))
            h, w = gt.shape[:2]
            for line in lines:
                c, xc, yc, bw, bh = map(float, line.split())
                p1 = (int((xc - bw / 2) * w), int((yc - bh / 2) * h)); p2 = (int((xc + bw / 2) * w), int((yc + bh / 2) * h))
                cv2.rectangle(gt, p1, p2, (80, 200, 80), 3)
                cv2.putText(gt, CLASS_NAMES[int(c)], (p1[0], max(20, p1[1] - 6)), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (80, 200, 80), 2)
            cv2.imwrite(str(examples / f"{key}__{image.stem}__gt.jpg"), gt)
            cv2.imwrite(str(examples / f"{key}__{image.stem}__pred.jpg"), pred)


if __name__ == "__main__":
    os.environ.setdefault("YOLO_VERBOSE", "False")
    main()
