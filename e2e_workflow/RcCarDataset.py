"""Three-camera dataset adapted from Zhenye-Na's course implementation."""
import cv2
import numpy as np
import torch
from torch.utils.data import Dataset

from utils import image_path, preprocess


class TripletDataset(Dataset):
    def __init__(self, root, rows, training=False, image_cache=None):
        self.root, self.rows, self.training = root, rows, training
        self.image_cache = image_cache

    def __len__(self):
        return len(self.rows)

    def __getitem__(self, index):
        row = self.rows[index]
        images, angles = [], []
        for camera, correction in enumerate((0.0, 0.4, -0.4)):
            path = image_path(self.root, row[camera])
            if self.image_cache is None:
                image = cv2.imread(str(path))
            else:
                image = cv2.imdecode(np.frombuffer(self.image_cache[path.name], dtype=np.uint8), cv2.IMREAD_COLOR)
            if image is None:
                raise FileNotFoundError(path)
            angle = float(row[3]) + correction
            if self.training and np.random.random() < 0.5:
                image = cv2.flip(image, 1)
                angle = -angle
            images.append(preprocess(image))
            angles.append(angle)
        return torch.from_numpy(np.stack(images)), torch.tensor(angles, dtype=torch.float32)
