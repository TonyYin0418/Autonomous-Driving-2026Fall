"""Occlusion-sensitivity maps for the Stage04 NVIDIA CNN.

Run from e2e_workflow/ after e2e_probe.py, writing into the same output directory:
  PYTHONPATH=. ../.venv-stage04/bin/python ../reports/final_report/scripts/e2e_sensitivity.py --out <probe dir>
"""
import argparse, json
from pathlib import Path
import cv2, numpy as np, torch
from model import NetworkNvidia
from utils import image_path, load_rows, preprocess

DATA = Path("../data/udacity_e2e/dataset")
CKPT = Path("outputs/20261109_193500_nvidia_udacity/best.h5")
SPLIT = Path("outputs/20261109_193500_nvidia_udacity/split.json")

p = argparse.ArgumentParser(); p.add_argument("--out", type=Path, required=True); args = p.parse_args()
device = torch.device("cuda")
model = NetworkNvidia(); model.load_state_dict(torch.load(CKPT, map_location="cpu", weights_only=False)["state_dict"])
model.to(device).eval()
rows = load_rows(DATA); val = json.loads(SPLIT.read_text())["val"]
imgs = {i: cv2.imread(str(image_path(DATA, rows[i][0]))) for i in val[:3000]}
with torch.inference_mode():
    ids = list(imgs)
    pred = np.concatenate([model(torch.from_numpy(np.stack([preprocess(imgs[i]) for i in ids[s:s+256]])).to(device)).squeeze(1).cpu().numpy() for s in range(0, len(ids), 256)])
lab = np.array([float(rows[i][3]) for i in ids])
ok = np.abs(pred - lab) < 0.03
picks = {}
for tag, target in (("left", -0.35), ("straight", 0.0), ("right", 0.35)):
    cand = np.where(ok)[0]
    picks[tag] = ids[int(cand[np.argmin(np.abs(lab[cand] - target))])]
meta = {}
P, STEP = 20, 4
for tag, i in picks.items():
    im = imgs[i]; crop = im[65:-25]
    base = preprocess(im)
    variants, pos = [], []
    for y in range(0, 70 - P + 1, STEP):
        for x in range(0, 320 - P + 1, STEP):
            v = base.copy(); v[:, y:y+P, x:x+P] = 0.0  # mid-gray after normalisation
            variants.append(v); pos.append((y, x))
    with torch.inference_mode():
        b = model(torch.from_numpy(base)[None].to(device)).item()
        out = np.concatenate([model(torch.from_numpy(np.stack(variants[s:s+512])).to(device)).squeeze(1).cpu().numpy() for s in range(0, len(variants), 512)])
    acc = np.zeros((70, 320)); cnt = np.zeros((70, 320))
    for (y, x), o in zip(pos, out):
        acc[y:y+P, x:x+P] += abs(o - b); cnt[y:y+P, x:x+P] += 1
    sens = acc / np.maximum(cnt, 1)
    np.save(args.out / f"sensitivity_{tag}.npy", sens)
    cv2.imwrite(str(args.out / f"sensitivity_{tag}_input.png"), crop)
    meta[tag] = {"row": int(i), "label": float(rows[i][3]), "pred": b, "max_change": float(sens.max()), "image": rows[i][0].split("\\")[-1]}
(args.out / "sensitivity.json").write_text(json.dumps(meta, indent=2)); print(json.dumps(meta, indent=2))
