# nuScenes DevKit inspection

读取一个完整 sample 的六路相机、顶置 LiDAR 和五路 Radar，并生成 DevKit 使用日志和三张报告用图片：

```bash
UV_CACHE_DIR=/home/yin/data/autonomous_driving/cache/uv UV_PROJECT_ENVIRONMENT=.venv-stage01 uv run python nuscenes_devkit/inspect_sample.py
```

默认选择第一个 scene 的第一个 sample。日志记录 12 路传感器文件和五路 Radar 点数；
结果目录包含 `devkit.log`、六路相机拼图、前视相机标注图和 LiDAR 俯视图。
需要更换样本时使用 `--scene-index` 和
`--sample-index`。结果保存在 `nuscenes_devkit/runs/`。

## LiDAR/Radar 与相机叠加、3D 转 2D

```bash
UV_CACHE_DIR=/home/yin/data/autonomous_driving/cache/uv UV_PROJECT_ENVIRONMENT=.venv-stage01 uv run python nuscenes_devkit/project_lidar_camera.py
```

该脚本调用 DevKit 将 `LIDAR_TOP` 和 `RADAR_FRONT` 分别投影到 `CAM_FRONT`，
并将相机坐标系中的 3D 标注框绘制为 3D 投影框和 2D 矩形框。结果同样保存在
`nuscenes_devkit/runs/`。当前课程数据只保存关键帧，其他四路 Radar 的文件也已通过
`inspect_sample.py` 读取；它们在前视相机中的可见范围很小，因此叠加图使用前向 Radar。
两张点云叠加图同时保存为 PDF、SVG、300 dpi PNG 和 JPG。
