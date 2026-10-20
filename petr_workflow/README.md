# 第二次实践：PETR 六相机三维目标检测

本目录包含教师课程包中的预处理、训练、测试入口，以及它们依赖的
`PETR-official/` 完整源码、插件、继承配置和许可证。不要只复制三个入口脚本。
入口与教学配置已适配本项目的数据目录；环境检查脚本用于验证本机依赖和 CUDA 算子。

## 环境与数据

本次使用 Python 3.8.19、PyTorch 1.13.1+cu117、torchvision 0.14.1+cu117、
MMCV 1.7.0、MMDetection 2.28.2、MMDetection3D 1.0.0rc6。
Linux 依赖见 `environment/requirements-linux.txt`；课程提供的 Windows 清单和
版本约束也保留在 `environment/` 中。运行时使用本目录附带的 MMDetection3D 源码。
新机器需先准备匹配的独立环境，不能直接复用 Stage01 或 Stage03 环境。

解压后的目录关系为：

```text
项目根目录/
├── petr_workflow/
│   ├── preprocess.py
│   ├── train.py
│   ├── test.py
│   ├── PETR-official/
│   └── environment/
├── data/
│   ├── nuscenes_mini/
│   │   ├── samples/        # 六路相机关键帧
│   │   ├── maps/
│   │   └── v1.0-mini/      # 官方 mini 元数据
│   └── petr_assets/
│       └── resnet50_msra-5891d200.pth
└── reports/stage02_petr/figures/
```

原始数据、预训练权重、训练权重和 Python 环境需另行准备，未放入源码包。
预处理会重新生成索引；本实验不读取 LiDAR 点云和历史 sweeps。

## 运行方法

以下命令从解压后的项目根目录执行。先激活准备好的 Stage02 环境；WSL 下设置
驱动库路径，原生 Linux 按实际驱动路径配置。

```bash
export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${LD_LIBRARY_PATH:-}"
python petr_workflow/environment/check_environment.py
python petr_workflow/preprocess.py
python petr_workflow/train.py --epochs 20 --work-dir outputs/run20
python petr_workflow/test.py --checkpoint outputs/run20/epoch_20.pth
python petr_workflow/train.py --epochs 40 \
  --resume-from outputs/run20/epoch_20.pth --work-dir outputs/resume40
python petr_workflow/test.py --checkpoint outputs/resume40/epoch_40.pth
```

`--work-dir`、`--checkpoint` 的相对路径从 `petr_workflow/` 起算。
训练目录必须为空或不存在；源码包附带的历史结果目录应保留，复现实验使用新的目录。
`--epochs 40` 表示恢复后累计训练到第 40 轮。

## 已完成实验与随包结果

323 帧训练、81 帧验证，按官方场景划分，无样本交集，每帧六路相机。
仅 ResNet50 骨干使用公开预训练参数，检测头从随机参数开始训练。

| 实验 | `outputs/` 下的目录 | mAP | NDS |
|---|---|---:|---:|
| 20 轮 | `20260928_180737_petr_mini_r50` | 0.000102 | 0.02563 |
| 恢复到 40 轮 | `20260928_194716_petr_mini_r50_resume40` | 0.000082 | 0.02280 |

源码包保留这两次运行的文本日志、JSON 日志、实际配置、指标摘要和可视化说明；
报告使用的损失曲线、六相机图及 BEV 图位于 `reports/stage02_petr/figures/`。
完整权重和逐帧预测不随源码包发送。

两个模型的验证指标均很低，续训未改善结果；报告如实展示预测偏差。
恢复训练同时改变了目标总轮数和学习率计划，因此不能视为严格控制学习率的轮数消融。
正式 PDF 为单独的邮件附件 `stage02_petr_report.pdf`。
