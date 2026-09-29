"""演示 LiDAR/Radar 与相机叠加，以及 3D 标注框到 2D 框的转换。"""

from __future__ import annotations

import argparse
import os
import sys
from datetime import datetime
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT))
os.environ.setdefault("MPLCONFIGDIR", "/tmp/autonomous-driving-matplotlib")

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from PIL import Image, ImageDraw
from nuscenes.nuscenes import NuScenes
from nuscenes.utils.geometry_utils import BoxVisibility

from nuscenes_yolo_converter.convert import FilterConfig, project_box


def get_sample(nusc: NuScenes, scene_index: int, sample_index: int) -> tuple[dict, dict]:
    scene = nusc.scene[scene_index]
    token = scene["first_sample_token"]
    for _ in range(sample_index):
        sample = nusc.get("sample", token)
        if not sample["next"]:
            raise IndexError("sample-index 超出当前 scene 范围")
        token = sample["next"]
    return scene, nusc.get("sample", token)


def save_pointcloud_projection(
    nusc: NuScenes, point_token: str, camera_token: str, output: Path,
    channel: str,
) -> int:
    points, depth, image = nusc.explorer.map_pointcloud_to_image(point_token, camera_token)
    fig, ax = plt.subplots(figsize=(16, 9))
    ax.imshow(image)
    if channel == "LIDAR_TOP":
        scatter = ax.scatter(points[0], points[1], c=depth, s=3, cmap="viridis")
        fig.colorbar(scatter, ax=ax, label="Depth (m)")
    else:
        ax.scatter(
            points[0], points[1], color="#E69F00", s=35,
            edgecolors="black", linewidths=0.35,
        )
    ax.axis("off")
    fig.tight_layout()
    fig.savefig(output, dpi=150, bbox_inches="tight")
    fig.savefig(output.with_suffix(".pdf"), bbox_inches="tight")
    fig.savefig(output.with_suffix(".svg"), bbox_inches="tight")
    fig.savefig(output.with_suffix(".png"), dpi=300, bbox_inches="tight")
    plt.close(fig)
    return points.shape[1]


def save_box_projections(
    nusc: NuScenes, camera_token: str, output_3d: Path, output_2d: Path
) -> tuple[int, int]:
    image_path, boxes, intrinsic = nusc.get_sample_data(
        camera_token, box_vis_level=BoxVisibility.ANY
    )
    intrinsic_array = np.asarray(intrinsic)

    with Image.open(image_path) as source:
        image = source.convert("RGB")
        width, height = image.size

        fig, ax = plt.subplots(figsize=(16, 9))
        ax.imshow(image)
        for box in boxes:
            box.render(ax, view=intrinsic_array, normalize=True)
        ax.set_xlim(0, width)
        ax.set_ylim(height, 0)
        ax.set_title("3D boxes projected onto CAM_FRONT")
        ax.axis("off")
        fig.tight_layout()
        fig.savefig(output_3d, dpi=150, bbox_inches="tight")
        plt.close(fig)

        image_2d = image.copy()

    draw = ImageDraw.Draw(image_2d)
    config = FilterConfig()
    projected_count = 0
    for box in boxes:
        bbox = project_box(box, intrinsic_array, (width, height), config)
        if bbox is None:
            continue
        draw.rectangle(bbox, outline="red", width=4)
        draw.text((bbox[0] + 4, bbox[1] + 4), box.name, fill="red")
        projected_count += 1
    image_2d.save(output_2d, quality=95)
    return len(boxes), projected_count


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scene-index", type=int, default=189)
    parser.add_argument("--sample-index", type=int, default=19)
    args = parser.parse_args()

    dataroot = (PROJECT_ROOT / "data/nuscenes").resolve()
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_dir = Path(__file__).resolve().parent / "runs" / f"{timestamp}_lidar_camera"
    output_dir.mkdir(parents=True)
    log_lines: list[str] = []

    def log(message: str) -> None:
        print(message)
        log_lines.append(message)

    nusc = NuScenes(version="v1.0-trainval", dataroot=str(dataroot), verbose=False)
    scene, sample = get_sample(nusc, args.scene_index, args.sample_index)
    lidar_token = sample["data"]["LIDAR_TOP"]
    radar_token = sample["data"]["RADAR_FRONT"]
    camera_token = sample["data"]["CAM_FRONT"]

    camera_data = nusc.get("sample_data", camera_token)
    camera_calibration = nusc.get(
        "calibrated_sensor", camera_data["calibrated_sensor_token"]
    )
    lidar_data = nusc.get("sample_data", lidar_token)
    lidar_calibration = nusc.get(
        "calibrated_sensor", lidar_data["calibrated_sensor_token"]
    )

    log(f"场景: {scene['name']}")
    log(f"sample token: {sample['token']}")
    log("坐标变换: Point Sensor → Ego → Global → Ego → Camera → Image")
    log(f"相机内参: {camera_calibration['camera_intrinsic']}")
    log(f"CAM_FRONT 外参平移: {camera_calibration['translation']}")
    log(f"LIDAR_TOP 外参平移: {lidar_calibration['translation']}")

    lidar_count = save_pointcloud_projection(
        nusc, lidar_token, camera_token, output_dir / "lidar_on_camera.jpg", "LIDAR_TOP"
    )
    radar_count = save_pointcloud_projection(
        nusc, radar_token, camera_token, output_dir / "radar_on_camera.jpg", "RADAR_FRONT"
    )
    box_count, bbox_count = save_box_projections(
        nusc,
        camera_token,
        output_dir / "boxes_3d_on_camera.jpg",
        output_dir / "boxes_2d_on_camera.jpg",
    )

    log(f"map_pointcloud_to_image(): 投影 {lidar_count} 个 LiDAR 点")
    log(f"map_pointcloud_to_image(): 投影 {radar_count} 个 Radar 点")
    log(f"get_sample_data(): 获得 {box_count} 个相机坐标系 3D 框")
    log(f"project_box(): 生成 {bbox_count} 个 2D 包围框")
    log("已生成: lidar_on_camera.jpg")
    log("已生成: radar_on_camera.jpg")
    log("已生成: boxes_3d_on_camera.jpg")
    log("已生成: boxes_2d_on_camera.jpg")
    (output_dir / "fusion.log").write_text("\n".join(log_lines) + "\n", encoding="utf-8")
    print(f"结果目录: {output_dir}")


if __name__ == "__main__":
    main()
