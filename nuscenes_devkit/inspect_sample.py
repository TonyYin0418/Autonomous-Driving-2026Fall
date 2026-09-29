"""用 nuScenes DevKit 读取一个样本并生成报告用图片。"""

from __future__ import annotations

import argparse
import os
from datetime import datetime
from pathlib import Path

os.environ.setdefault("MPLCONFIGDIR", "/tmp/autonomous-driving-matplotlib")

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from PIL import Image, ImageDraw, ImageFont
from nuscenes.nuscenes import NuScenes
from nuscenes.utils.data_classes import RadarPointCloud


PROJECT_ROOT = Path(__file__).resolve().parents[1]
CAMERAS = (
    "CAM_FRONT_LEFT",
    "CAM_FRONT",
    "CAM_FRONT_RIGHT",
    "CAM_BACK_LEFT",
    "CAM_BACK",
    "CAM_BACK_RIGHT",
)
RADARS = (
    "RADAR_FRONT",
    "RADAR_FRONT_LEFT",
    "RADAR_FRONT_RIGHT",
    "RADAR_BACK_LEFT",
    "RADAR_BACK_RIGHT",
)
SENSORS = (*CAMERAS, "LIDAR_TOP", *RADARS)


def get_sample(nusc: NuScenes, scene: dict, sample_index: int) -> dict:
    token = scene["first_sample_token"]
    for _ in range(sample_index):
        sample = nusc.get("sample", token)
        if not sample["next"]:
            raise IndexError("sample-index 超出当前 scene 范围")
        token = sample["next"]
    return nusc.get("sample", token)


def save_camera_mosaic(nusc: NuScenes, sample: dict, output: Path) -> None:
    tile_width, tile_height, label_height = 800, 450, 35
    canvas = Image.new("RGB", (tile_width * 3, (tile_height + label_height) * 2), "white")
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.load_default(size=22)

    for index, channel in enumerate(CAMERAS):
        image_path = nusc.get_sample_data_path(sample["data"][channel])
        with Image.open(image_path) as image:
            image = image.convert("RGB")
            image.thumbnail((tile_width, tile_height))
            column, row = index % 3, index // 3
            x = column * tile_width + (tile_width - image.width) // 2
            y = row * (tile_height + label_height) + label_height
            canvas.paste(image, (x, y))
            draw.text(
                (column * tile_width + 10, row * (tile_height + label_height) + 5),
                channel,
                fill="black",
                font=font,
            )

    canvas.save(output, quality=92)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scene-index", type=int, default=0)
    parser.add_argument("--sample-index", type=int, default=0)
    args = parser.parse_args()

    dataroot = (PROJECT_ROOT / "data/nuscenes").resolve()
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_dir = Path(__file__).resolve().parent / "runs" / f"{timestamp}_devkit_sample"
    output_dir.mkdir(parents=True)
    log_lines: list[str] = []

    def log(message: str) -> None:
        print(message)
        log_lines.append(message)

    log(f"数据目录: {dataroot}")
    nusc = NuScenes(version="v1.0-trainval", dataroot=str(dataroot), verbose=False)
    log(f"场景数量: {len(nusc.scene)}")
    log(f"样本数量: {len(nusc.sample)}")
    log(f"标注数量: {len(nusc.sample_annotation)}")

    scene = nusc.scene[args.scene_index]
    sample = get_sample(nusc, scene, args.sample_index)
    log(f"示例场景: {scene['name']}")
    log(f"场景描述: {scene['description']}")
    log(f"示例 sample token: {sample['token']}")
    log(f"当前 sample 目标数量: {len(sample['anns'])}")

    log("传感器数据:")
    for channel in SENSORS:
        path = Path(nusc.get_sample_data_path(sample["data"][channel]))
        log(f"  {channel}: {path} (存在={path.is_file()})")
        if channel in RADARS and path.is_file():
            log(f"    Radar 点数: {RadarPointCloud.from_file(str(path)).points.shape[1]}")

    save_camera_mosaic(nusc, sample, output_dir / "camera_mosaic.jpg")
    nusc.render_sample_data(
        sample["data"]["CAM_FRONT"],
        out_path=str(output_dir / "cam_front_boxes.jpg"),
        verbose=False,
    )
    plt.close("all")
    nusc.render_sample_data(
        sample["data"]["LIDAR_TOP"],
        nsweeps=1,
        out_path=str(output_dir / "lidar_top.png"),
        verbose=False,
    )
    plt.close("all")

    log("已生成: camera_mosaic.jpg（六路相机）")
    log("已生成: cam_front_boxes.jpg（前视相机与3D标注框）")
    log("已生成: lidar_top.png（LiDAR俯视图）")
    (output_dir / "devkit.log").write_text("\n".join(log_lines) + "\n", encoding="utf-8")
    print(f"结果目录: {output_dir}")


if __name__ == "__main__":
    main()
