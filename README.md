# 自动驾驶技术课程实践

Stage01、Stage02、Stage03、Stage04 均已完成。提交附件统一放在项目根目录的
[`submit/`](submit/)，每个阶段各有一份源码 ZIP 和一份报告 PDF。

## 阶段与结果

| 阶段 | 实验 | 代码与运行说明 | 正式报告 | 提交附件 |
|---|---|---|---|---|
| Stage01 | nuScenes 多传感器处理、YOLO11n 与跨地区评估 | [DevKit](nuscenes_devkit/README.md)、[数据转换](nuscenes_yolo_converter/README.md)、下文命令 | [报告](reports/stage01_nuscenes_yolo/stage01_nuscenes_yolo_report.pdf) | [stage01](submit/stage01/) |
| Stage02 | PETR 六相机三维检测，20 轮训练及续训到 40 轮 | [PETR](petr_workflow/README.md) | [报告](reports/stage02_petr/stage02_petr_report.pdf) | [stage02](submit/stage02/) |
| Stage03 | PointPillars 单帧 LiDAR，1 轮微调及恢复到累计 5 轮 | [PointPillars](pointpillars_workflow/README.md) | [报告](reports/stage03_pointpillars/stage03_pointpillars_report.pdf) | [stage03](submit/stage03/) |
| Stage04 | NVIDIA CNN 转角预测，50 轮训练与 Udacity 模拟器 | [端到端模型](e2e_workflow/README.md) | [报告](reports/stage04_e2e/stage04_e2e_report.pdf) | [stage04](submit/stage04/) |

- Stage01：One-North 独立 test 集 mAP50 为 0.548、mAP50–95 为 0.288。
  跨地区 mAP50–95：Boston 0.071、Holland Village 0.275、One-North 0.288、Queenstown 0.259。
- Stage02：相同 81 帧 mini_val 上，第 20 轮 mAP 0.000102、NDS 0.02563；
  第 40 轮 mAP 0.000082、NDS 0.02280。继续训练未改善验证指标，报告保留预测偏差。
- Stage03：相同 81 帧 mini_val 上，基线 mAP 0.000061、NDS 0.02608；
  微调后 mAP 0.06138、NDS 0.11815。此为单帧、50×50 m 的教学设置，仍有误检与漏检。
- Stage04：50 轮训练和验证合计 25.01 分钟，末轮验证 MSE 0.078192。
  第 38 轮权重在 Lake Track 自动行驶 182.8 秒，平均速度 10.36 mph。

## 目录

```text
.
├── docs/                       # 课程指导材料、小型课程源码包和 Stage04 计划
├── nuscenes_devkit/             # Stage01：传感器检查、点云投影与框转换
├── nuscenes_yolo_converter/     # Stage01：课程数据转换与校验
├── yolo_workflow/               # Stage01：训练、评估、可视化与小型结果
├── petr_workflow/               # Stage02：课程入口、PETR 完整源码与环境清单
├── pointpillars_workflow/       # Stage03：课程入口、配置、环境与报告绘图
├── e2e_workflow/                # Stage04：转角预测、训练和模拟器通信
├── reports/                    # 按阶段保存报告源文件、PDF、图表和小型证据
│   ├── template/               # 公共 LaTeX 样式
│   └── stageXX_主题/
├── submit/                     # 可直接发送的附件
│   ├── stage01/
│   ├── stage02/
│   ├── stage03/
│   └── stage04/
├── data -> 数据盘/datasets     # 本地链接，不入 Git
├── .venv-stage01 -> 独立环境    # 本地链接，不入 Git
├── .venv-stage02 -> 独立环境
├── .venv-stage03 -> 独立环境
└── .venv-stage04 -> 独立环境
```

源码 ZIP 统一保存在 `submit/`；报告 PDF 在 `reports/` 保留正式版本，在
`submit/` 保留同内容的发送副本。附件命名为
`自动驾驶技术第X次实验+尹玉文东+2024302131025.zip` / `.pdf`。
后续阶段沿用 `submit/stageXX/`，不为每次打包新增说明文档。

## 环境与数据

本机为 WSL2 Ubuntu、RTX 4060（8 GB）。各阶段环境独立，Stage01 的根目录
`pyproject.toml` 和 `uv.lock` 不适用于 Stage02/03/04。

| 阶段 | Python | PyTorch | 主要依赖 | 本地解释器 |
|---|---|---|---|---|
| Stage01 | 3.12 | 见 `uv.lock` | Ultralytics、nuScenes DevKit | `.venv-stage01/bin/python` |
| Stage02 | 3.8.19 | 1.13.1+cu117 | MMCV 1.7.0、MMDetection 2.28.2、MMDetection3D 1.0.0rc6 | `.venv-stage02/bin/python` |
| Stage03 | 3.9.25 | 2.0.1+cu118 | MMCV 2.1.0、MMEngine 0.10.7、MMDetection3D 1.4.0 | `.venv-stage03/bin/python` |
| Stage04 | 3.10.21 | 2.4.0+cu121 | OpenCV 4.10、python-socketio 4.6、python-engineio 3.13 | `.venv-stage04/bin/python` |

数据盘根目录为 `/home/yin/data/autonomous_driving/`：环境在 `envs/stageXX/`，
原始数据和教师资产在 `datasets/`，缓存位于 `cache/`。项目内 `data` 指向 `datasets/`。

| 项目相对路径 | 内容 |
|---|---|
| `data/nuscenes/` | trainval 元数据、六路相机、LiDAR 和五路 Radar 关键帧 |
| `data/nuscenes_yolo_vis34/` | 按四个采集地点划分的 YOLO 数据 |
| `data/nuscenes_mini/` | PETR 的 mini 元数据、六路相机和生成索引 |
| `data/petr_assets/` | ResNet50 公开预训练权重 |
| `data/nuscenes_pointpillars_mini/` | 复用的 mini 元数据、404 帧 LiDAR 及教师源索引 |
| `data/pointpillars_assets/` | 官方 PointPillars 权重、配置及依赖源码 |
| `data/udacity_assets/dataset.zip` | Stage04 教师原始数据包 |
| `data/udacity_e2e/dataset/` | Stage04 三相机图像与驾驶记录 |

数据、权重及依赖二进制包直接归档到数据盘，`docs/` 不保留副本或软链接。
Stage03 的原始 `checkpoints.zip`、`checkpoints_thirdparty.rar` 位于
`data/pointpillars_assets/`，三个教师 PKL 索引位于 `data/nuscenes_pointpillars_mini/`。

本项目没有保存历史 sweeps。Stage02/03 使用官方 8/2 场景划分，分别为 323 帧训练、
81 帧验证；不将相邻帧随机拆分。新机器需另行准备数据与模型权重，代码包不包含这些文件。

## 运行入口

以下命令从项目根目录执行；训练会创建新的运行结果，请先准备对应数据与环境。

Stage01 使用 `uv`：

```bash
export UV_CACHE_DIR=/home/yin/data/autonomous_driving/cache/uv
UV_PROJECT_ENVIRONMENT=.venv-stage01 uv sync
UV_PROJECT_ENVIRONMENT=.venv-stage01 uv run python nuscenes_devkit/inspect_sample.py
UV_PROJECT_ENVIRONMENT=.venv-stage01 uv run python nuscenes_devkit/project_lidar_camera.py
bash yolo_workflow/train.sh
bash yolo_workflow/evaluate.sh
bash yolo_workflow/predict.sh
bash yolo_workflow/evaluate_cross_location.sh
```

Stage02/03 的环境检查入口：

```bash
env LD_LIBRARY_PATH="/usr/lib/wsl/lib:${LD_LIBRARY_PATH:-}" \
  .venv-stage02/bin/python petr_workflow/environment/check_environment.py
bash pointpillars_workflow/run.sh check_environment.py
```

预处理、训练、恢复和评估命令分别见 [PETR 说明](petr_workflow/README.md) 与
[PointPillars 说明](pointpillars_workflow/README.md)。Stage03 的安装入口为
`pointpillars_workflow/environment/install_linux.sh`；配置环境或下载卡住时停止，
交由用户手动处理。新的正式训练开始前需说明估算耗时并确认。

## 结果与版本管理

- `reports/` 保留报告、图表及 Stage03 训练审计、指标等小型证据；编译方法见
  [报告说明](reports/README.md)，写作要求见 [写作准则](reports/WRITING_GUIDELINES.md)。
- PETR 完整运行记录在本地 `petr_workflow/outputs/`；PointPillars 的 `outputs` 链接到
  数据盘 `runs/stage03_pointpillars/`。检查点、原始数据、Python 环境及缓存不加入后续提交。
  Stage01 历史中已存在的权重保留在历史中，当前目录的权重仅在本地保存。
- Stage03 含最终权重的结果 ZIP 单独保存在数据盘，详见
  [已有交付清单](reports/stage03_pointpillars/SUBMISSION.md)，不放入源码附件或 Git。
- 提交按各阶段的实验实现、结果报告、提交附件组织，标题使用 `type(scope): 中文说明`，
  正文统一说明内容、结果和验证。作者日期依据原提交、实验日志和操作记录，重整历史的
  提交日期使用当前时间；协作约定见 [AGENT.md](AGENT.md)。
