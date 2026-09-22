# 自动驾驶课程

本仓库用于完成自动驾驶课程中的 nuScenes 数据处理、视觉 YOLO 以及后续感知任务。
课程任务 PDF 统一保存在 `docs/`，目录结构会随课程要求逐步调整。

## 环境

项目使用 `uv` 和 Python 3.12，不使用 Conda。PyTorch wheel 自带 CUDA runtime 与
cuDNN；本机 NVIDIA 驱动支持 CUDA 13.1，因此
无需额外安装完整 CUDA Toolkit。

```bash
export UV_CACHE_DIR="$PWD/.uv-cache"
uv sync
source .venv/bin/activate
```

VS Code 的 Python 解释器选择 `.venv/bin/python`。

## 当前状态

- 本地 GPU 为 NVIDIA GeForce RTX 4060（8 GB）。
- `nuscenes_yolo_converter/`：老师提供的 nuScenes 转 YOLO 代码。
- `yolo_workflow/`：老师提供的 YOLO 训练、评估和可视化代码。
- `data`：指向机械盘 `/home/yin/data/autonomous_driving/datasets` 的软链接。
- nuScenes 原始数据和转换后的四个 YOLO 地区数据集均已完整解压。
- 下载压缩包已在核对解压结果后删除，外部备份由用户自行保留。

## 数据目录

```text
data/
├── nuscenes/
│   ├── maps/
│   ├── samples/
│   └── v1.0-trainval/
└── nuscenes_yolo_vis34/
```

数据解压后，常用路径为：

- 原始 nuScenes：`data/nuscenes`
- Boston YOLO 数据：`data/nuscenes_yolo_vis34/boston-seaport`
- 其他地区数据位于同一目录下。

原始数据包含六路相机与一路顶置 LiDAR，各 40,157 个文件。转换后的 YOLO 数据共
21,502 对图片与标签，按四个采集地点分别划分为 train、val 和 test。

## YOLO 训练

`yolo_workflow/train.sh` 使用 Singapore One North 数据集正式训练 YOLO11n：

```bash
./yolo_workflow/train.sh
```

结果目录使用 `YYYYMMDD_HHMMSS_yolo11n_onenorth` 格式。时间戳前缀保证运行记录
按名称自然排序，模型和数据集后缀保持固定；特殊实验才更改后缀。

当前正式训练 `20260916_092702_yolo11n_onenorth` 已完成 50 epochs。验证集最佳结果
出现在第 38 轮：mAP50 为 0.547，mAP50-95 为 0.279。

独立 test 集评估已完成：Precision 为 0.686、Recall 为 0.505、mAP50 为 0.548、
mAP50-95 为 0.288。另已保存 50 张 test 集预测图，结果分别位于：

- `yolo_workflow/runs/evaluation/20260916_095228_yolo11n_onenorth_test_val_test/`
- `yolo_workflow/runs/visualization/20260916_095324_yolo11n_onenorth_test/`

使用最佳权重评估独立 test 集：

```bash
./yolo_workflow/evaluate.sh
```

保存 50 张 test 集预测结果：

```bash
./yolo_workflow/predict.sh
```
