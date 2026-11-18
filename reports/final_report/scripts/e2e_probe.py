"""Probe the Stage04 NVIDIA CNN: input perturbations, a pasted pedestrian and saliency maps.

Run from e2e_workflow/ with the Stage04 environment:
  PYTHONPATH=. ../.venv-stage04/bin/python ../reports/final_report/scripts/e2e_probe.py \
      --out outputs/<YYYYMMDD_HHMMSS>_nvidia_udacity_probe
Small results are copied to reports/final_report/results/e2e_perturbation.json.
"""
import argparse
import json
from pathlib import Path

import cv2
import numpy as np
import torch

from model import NetworkNvidia
from utils import image_path, load_rows, preprocess

DATA = Path("../data/udacity_e2e/dataset")
CKPT = Path("outputs/20261109_193500_nvidia_udacity/best.h5")
SPLIT = Path("outputs/20261109_193500_nvidia_udacity/split.json")
YOLO_TEST = Path("../data/nuscenes_yolo_vis34/singapore-onenorth")


def rain(img, rng):
    out = img.astype(np.float32)
    layer = np.zeros(img.shape[:2], np.float32)
    for _ in range(250):
        x, y = rng.integers(0, img.shape[1]), rng.integers(0, img.shape[0])
        cv2.line(layer, (int(x), int(y)), (int(x) + 2, int(y) + 10), 1.0, 1)
    layer = cv2.GaussianBlur(layer, (3, 3), 0)
    out = out * 0.85 + layer[..., None] * 90
    for _ in range(12):  # lens droplets: local blur discs
        x, y, r = rng.integers(20, 300), rng.integers(70, 150), rng.integers(6, 14)
        mask = np.zeros(img.shape[:2], np.uint8)
        cv2.circle(mask, (int(x), int(y)), int(r), 1, -1)
        blurred = cv2.GaussianBlur(out, (15, 15), 0)
        out[mask > 0] = blurred[mask > 0]
    return np.clip(out, 0, 255).astype(np.uint8)


def shadow(img, rng):
    out = img.astype(np.float32)
    x1, x2 = sorted(rng.integers(0, 320, 2))
    poly = np.array([[x1, 65], [x2, 65], [min(319, x2 + 60), 135], [max(0, x1 - 60), 135]], np.int32)
    mask = np.zeros(img.shape[:2], np.uint8)
    cv2.fillPoly(mask, [poly], 1)
    out[mask > 0] *= 0.4
    return out.astype(np.uint8)


def occlude(img, rng):
    out = img.copy()
    x, y = int(rng.integers(80, 220)), int(rng.integers(75, 110))
    out[y:y + 25, x:x + 40] = 0
    return out


def load_pedestrian():
    """Largest pedestrian crop from the One-North test images (YOLO class 5)."""
    best = None
    for label in sorted((YOLO_TEST / "labels" / "test").glob("*.txt")):
        for line in label.read_text().splitlines():
            c, xc, yc, w, h = map(float, line.split())
            if int(c) == 5 and h > 0.25 and w / h < 0.6 and (best is None or h > best[0][4]):
                best = ((c, xc, yc, w, h), label.stem)
    (c, xc, yc, w, h), stem = best
    img = cv2.imread(str(YOLO_TEST / "images" / "test" / f"{stem}.jpg"))
    H, W = img.shape[:2]
    x1, y1, x2, y2 = int((xc - w / 2) * W), int((yc - h / 2) * H), int((xc + w / 2) * W), int((yc + h / 2) * H)
    return img[y1:y2, x1:x2], stem


def paste(img, person, height=34):
    out = img.copy()
    scale = height / person.shape[0]
    p = cv2.resize(person, (max(1, int(person.shape[1] * scale)), height))
    x, y = 160 - p.shape[1] // 2, 122 - height  # feet on the road ahead
    out[y:y + height, x:x + p.shape[1]] = p
    return out


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=False)
    device = torch.device("cuda")
    model = NetworkNvidia()
    ckpt = torch.load(CKPT, map_location="cpu", weights_only=False)
    model.load_state_dict(ckpt["state_dict"]); model.to(device).eval()
    rows = load_rows(DATA)
    val = json.loads(SPLIT.read_text())["val"]
    person, person_src = load_pedestrian()
    cv2.imwrite(str(args.out / "pedestrian_crop.jpg"), person)

    conditions = {
        "original": lambda im, r: im,
        "dark_0.5": lambda im, r: (im * 0.5).astype(np.uint8),
        "dark_0.25": lambda im, r: (im * 0.25).astype(np.uint8),
        "blur": lambda im, r: cv2.GaussianBlur(im, (9, 9), 0),
        "rain": rain,
        "shadow": shadow,
        "occlusion": occlude,
        "pedestrian": lambda im, r: paste(im, person),
    }
    labels = np.array([float(rows[i][3]) for i in val], np.float32)
    preds = {}
    examples = {}
    with torch.inference_mode():
        for name, fn in conditions.items():
            rng = np.random.default_rng(20261118)
            out = []
            for start in range(0, len(val), 256):
                batch = []
                for i in val[start:start + 256]:
                    im = cv2.imread(str(image_path(DATA, rows[i][0])))
                    im = fn(im, rng)
                    if i == val[0]:
                        examples[name] = im
                    batch.append(preprocess(im))
                x = torch.from_numpy(np.stack(batch)).to(device)
                out.append(model(x).squeeze(1).float().cpu().numpy())
            preds[name] = np.concatenate(out)
    base = preds["original"]
    summary = []
    for name, p in preds.items():
        err = p - labels
        delta = np.abs(p - base)
        summary.append({"condition": name, "mse": float((err ** 2).mean()), "mae": float(np.abs(err).mean()),
                        "mean_abs_change": float(delta.mean()), "p95_abs_change": float(np.percentile(delta, 95)),
                        "frac_change_gt_0.1": float((delta > 0.1).mean())})
        print(summary[-1], flush=True)
    (args.out / "perturbation.json").write_text(json.dumps(
        {"checkpoint": str(CKPT), "epoch": ckpt["epoch"], "val_images": len(val), "camera": "center",
         "pedestrian_source": person_src, "results": summary}, indent=2))
    for name, im in examples.items():
        cv2.imwrite(str(args.out / f"example_{name}.png"), im)

    # saliency (SmoothGrad) on a few validation frames: straight, left, right
    order = np.argsort(labels)
    picks = {"left": val[int(order[len(order) // 50])], "straight": val[int(np.argmin(np.abs(labels)))],
             "right": val[int(order[-len(order) // 50])]}
    picks["pedestrian"] = picks["straight"]
    sal_meta = {}
    for tag, i in picks.items():
        im = cv2.imread(str(image_path(DATA, rows[i][0])))
        if tag == "pedestrian":
            im = paste(im, person)
        x0 = torch.from_numpy(preprocess(im))[None].to(device)
        grads = torch.zeros_like(x0)
        for _ in range(32):
            x = (x0 + 0.1 * torch.randn_like(x0)).requires_grad_(True)
            model(x).sum().backward()
            grads += x.grad.abs()
        sal = grads[0].mean(0).cpu().numpy()
        sal = cv2.GaussianBlur(sal, (0, 0), 2)
        sal = (sal - sal.min()) / (sal.max() - sal.min() + 1e-8)
        crop = im[65:-25]
        heat = cv2.applyColorMap((sal * 255).astype(np.uint8), cv2.COLORMAP_INFERNO)
        overlay = cv2.addWeighted(crop, 0.55, heat, 0.45, 0)
        cv2.imwrite(str(args.out / f"saliency_{tag}_input.png"), crop)
        cv2.imwrite(str(args.out / f"saliency_{tag}.png"), overlay)
        with torch.inference_mode():
            sal_meta[tag] = {"row": int(i), "label": float(rows[i][3]), "pred": float(model(x0).item())}
    (args.out / "saliency.json").write_text(json.dumps(sal_meta, indent=2))


if __name__ == "__main__":
    main()
