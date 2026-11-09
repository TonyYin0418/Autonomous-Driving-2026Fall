"""Shared image preparation and course CSV loading."""
import csv
from pathlib import Path

import numpy as np


def preprocess(image_bgr):
    image = image_bgr[65:-25].astype(np.float32)
    return np.ascontiguousarray((image / 127.5 - 1.0).transpose(2, 0, 1))


def load_rows(root):
    with (Path(root) / 'driving_log.csv').open(newline='') as f:
        return list(csv.reader(f))


def image_path(root, recorded_path):
    return Path(root) / 'IMG' / recorded_path.strip().replace('\\', '/').split('/')[-1]
