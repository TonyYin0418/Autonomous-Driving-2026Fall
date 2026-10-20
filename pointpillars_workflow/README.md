# 第三次实践：PointPillars 单帧 LiDAR 检测

2026-10-19 已完成课程全部实验及报告。正式报告与证据在
`reports/stage03_pointpillars/`；源码 ZIP 和提交 PDF 统一在根目录 `submit/stage03/`。
训练获得用户确认后执行。

## 实验结果

| 项目 | 公开权重基线 | 检测头微调 5 轮 |
|---|---:|---:|
| mini_val 帧数 | 81 | 81 |
| NDS | 0.026076699 | 0.118147172 |
| mAP | 0.000060735 | 0.061377287 |
| 模型构建、推理及评估（秒，不含绘图） | 19.139 | 10.521 |

第 1 轮和恢复后的四轮训练审计分别计时 24.165 / 63.526 秒，包含轮末验证，合计
87.691 秒。两次均有 6/6 个检测头参数张量发生更新，所有模型参数有限。最终模型含
4,928,678 个参数，其中检测头参数 113,190 个。与公开权重比较，检测头外的参数
没有改变，63 个 BatchNorm 缓冲张量随训练更新。

累计 1615 次迭代，实际优化器更新 1612 次；AMP 记录 3 次溢出并跳过对应更新。
平均训练损失逐轮为 2.8699、2.6914、2.5897、2.5064、2.4596。验证效果主要来自
部分车辆，仍有误检、漏检及类别差异。上述数值属于单帧、50×50 m 的 mini 教学设置。

## 代码来源及本地修改

教师提供的 `docs/PointPillarsCourse.rar` 包含 10 个 Python 脚本及
`requirements-course.txt`；模型与算子来自 MMDetection3D 1.4.0。本次新增或调整：

- `environment/install_linux.sh`、`requirements-linux.txt`：独立 Linux 安装入口。
  `requirements-lock-linux.txt` 保存实际版本；原课程依赖清单保留。
- `run.sh`：从独立解释器启动课程脚本，设置 WSL 驱动及绘图缓存目录。
- `course_common.py`、`download_weights.py`：适配项目数据和模型资产路径。
- `check_environment.py`：增加真实 CUDA 体素化与旋转框 NMS 检查。
- `preprocess.py`：将仅统计每帧首个目标的类别计数改为统计全部有效类别标注，
  不影响生成的训练标注。
- `test.py`：记录模型构建、推理及评估耗时和峰值已分配显存。
- `course_visualization.py`、`plot_training.py`：输出 PDF/SVG 与 300 dpi PNG，
  使用固定颜色并删除图内重复标题。
- `prepare_report.py`：拼接连续损失、核对预测和索引顺序、绘制含真值的 BEV 对照，
  保存可随报告独立查看的证据文件。教师原始绘图只显示预测框。

训练、检测范围、batch、AMP、优化器和随机种子沿用课程设置。模型参数冻结不阻止
训练态 BatchNorm 更新运行统计。

## 环境与数据

| 用途 | 路径 |
|---|---|
| 独立 Python 环境 | `.venv-stage03` → `/home/yin/data/autonomous_driving/envs/stage03/` |
| 单帧数据与教师源索引 | `data/nuscenes_pointpillars_mini/`（相对仓库根目录） |
| 官方权重和完整配置 | `data/pointpillars_assets/` |
| 运行输出 | 本目录 `outputs` → 数据盘 `runs/stage03_pointpillars/` |
| 正式报告与证据 | `reports/stage03_pointpillars/` |
| 源码 ZIP 与提交 PDF | `submit/stage03/` |

Python 3.9.25、Torch 2.0.1+cu118、MMCV 2.1.0、MMEngine 0.10.7、MMDetection 3.2.0、
MMDetection3D 1.4.0，GPU RTX 4060 8 GB。安装期间官方站点连接超时，已按用户要求
暂停，由用户手动完成；最终环境及 CUDA 算子均已验证。不混用 stage01/02 依赖，
不对根目录的 stage01 `pyproject.toml` 执行 stage03 的 `uv sync`。

仓库和源码 ZIP 均附带 `checkpoints/official_pointpillars_config.py` 与
`environment/mmdet3d-1.4.0.tar.gz`，均来自教师提供的资产。前者为独立模型配置，
后者为约 620 KiB 的依赖源码，不含模型权重。安装脚本默认使用项目的
`data/pointpillars_assets/`，也可通过 `STAGE03_ASSETS` 指定其他存放目录。

mini 元数据、地图和 404 帧点云通过软链接复用已有数据。原始文件按每点五列读取，
模型使用 x/y/z/intensity 四维。全部点云可读且输入有限；8 个训练场景 / 323 帧、
2 个验证场景 / 81 帧，无 token 交集。预处理移除 3940 条历史 sweeps 引用，
实际没有读取 sweeps；额外的 `nuscenes_dbinfos_train.pkl` 不参与本实验。

完整官方权重在两个教师压缩包中相同，其 SHA256 为：

```text
f19d00a38e6b775f38a45a9a3ca3ecaec20a5585a3caf44622423e2d5f75d5d0
```

## 复现命令

以下命令从仓库根目录执行；`run.sh` 进入工作目录，因此 `outputs/...` 相对此目录。
新机器先创建独立 Python 3.9 环境和 `.venv-stage03` 入口，并设置好上述数据及资产路径。
准备环境后执行：

```bash
bash pointpillars_workflow/environment/install_linux.sh
bash pointpillars_workflow/run.sh check_environment.py
bash pointpillars_workflow/run.sh download_weights.py
bash pointpillars_workflow/run.sh preprocess.py
```

实际运行目录：

| 描述 | `outputs/` 下的名称 |
|---|---|
| baseline | `20261019_203330_pointpillars_mini_baseline` |
| run1 | `20261019_203612_pointpillars_mini_run1` |
| run5 | `20261019_203712_pointpillars_mini_run5` |
| finetuned | `20261019_203834_pointpillars_mini_finetuned` |

```bash
bash pointpillars_workflow/run.sh test.py \
  --checkpoint checkpoints/pointpillars_nuscenes_official.pth \
  --output-dir outputs/20261019_203330_pointpillars_mini_baseline \
  --vis-count 3 --score-thr 0.10
bash pointpillars_workflow/run.sh train.py --epochs 1 --amp \
  --work-dir outputs/20261019_203612_pointpillars_mini_run1
bash pointpillars_workflow/run.sh train.py --epochs 5 --amp \
  --resume-from outputs/20261019_203612_pointpillars_mini_run1/epoch_1.pth \
  --work-dir outputs/20261019_203712_pointpillars_mini_run5
bash pointpillars_workflow/run.sh test.py \
  --checkpoint outputs/20261019_203712_pointpillars_mini_run5/epoch_5.pth \
  --output-dir outputs/20261019_203834_pointpillars_mini_finetuned \
  --vis-count 3 --score-thr 0.10
```

上述是已完成的运行记录；重新运行时为结果目录换新的时间戳，避免覆盖。
使用课程 `plot_training.py --work-dir ...` 生成每次训练的损失图，使用
`compare_results.py --baseline ... --finetuned ... --run1 ... --run5 ... --output ...`
生成比较 JSON。

阈值重绘直接调用 `course_visualization.render_predictions`，保存到独立目录
`finetuned/visualizations_thr030/`，未覆盖 0.10 原图或重新计算指标。
课堂要求的前三帧预测图在 `finetuned/visualizations/`，框数分别为 64/51/86；
0.30 下分别为 9/5/4。报告另按位置固定选取验证索引 0/40/80，覆盖两个场景，
对应 0.10 框数 64/130/71、0.30 框数 9/22/19。

报告素材由以下命令生成：

```bash
bash pointpillars_workflow/run.sh prepare_report.py \
  --baseline outputs/20261019_203330_pointpillars_mini_baseline \
  --finetuned outputs/20261019_203834_pointpillars_mini_finetuned \
  --run1 outputs/20261019_203612_pointpillars_mini_run1 \
  --run5 outputs/20261019_203712_pointpillars_mini_run5
```

`outputs/` 保留完整预测、检查点、框架日志、训练审计和清单；
`reports/stage03_pointpillars/results/` 保存相应的小型证据副本，报告 PDF 和图表
不依赖数据盘即可查看。提交清单和 SHA256 见该报告目录的 `SUBMISSION.md`。
