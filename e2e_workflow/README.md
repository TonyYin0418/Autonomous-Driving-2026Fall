# 第四次实践：端到端自动驾驶

按照课程指导书训练 NVIDIA CNN，并接入 Windows Udacity 模拟器。
模型代码来自 [Zhenye-Na/e2e-learning-self-driving-cars](https://github.com/Zhenye-Na/e2e-learning-self-driving-cars)，
提交 `ef999ee49acc443e284dbf2c38afc8ae47fd31c8`，保留原 MIT 许可证。
`model.py` 使用原版 NetworkNvidia；数据读取、训练和推理脚本按课程流程适配本机目录。

## 实验结果

已完成累计 50 轮训练，训练和轮末验证合计 25.01 分钟。

| 轮数 | 训练 MSE | 三相机验证 MSE | 中心相机验证 MSE |
|---|---:|---:|---:|
| 5 | 0.132030 | 0.127629 | 0.091127 |
| 38（best） | 0.062749 | 0.078465 | 0.074244 |
| 50 | 0.060597 | 0.078192 | 0.074586 |

best.h5 对应第 38 轮，中心相机 MAE 为 0.199994。
训练运行目录为 `outputs/20261109_193500_nvidia_udacity/`，
最终模拟器运行目录为 `outputs/20261109_200600_nvidia_udacity_drive/`。
该目录保存 telemetry.csv、相机帧、窗口录制帧和 simulator.mp4。
第 38 轮权重在 Lake Track 自动行驶 182.8 秒，记录 29,479 帧遥测，
平均速度 10.36 mph，图像处理和预测平均耗时 2.63 ms。
正式报告在 `reports/stage04_e2e/stage04_e2e_report.pdf`，提交附件在 `submit/stage04/`。

## 环境和数据

独立 Python 3.10.21、PyTorch 2.4.0+cu121、torchvision 0.19.0+cu121。
依赖版本保存在 `environment/requirements-lock-linux.txt`。

- 环境：`.venv-stage04`，指向数据盘 `envs/stage04/`。
- 数据：`data/udacity_e2e/dataset/`，IMG 和 driving_log.csv 同级。
- 输出：`e2e_workflow/outputs`，指向数据盘 `runs/stage04_e2e/`。
- CSV 共 32,443 行，按随机种子 20261109 划分为 25,954 行训练、6,489 行验证。
- 三相机训练，左右相机转角修正 ±0.4，训练随机水平翻转。
- 图像使用 BGR，裁剪为 320×70，归一化到 [-1,1] 并转换为 CHW。
- 训练从原始 ZIP 预读 JPEG 字节到内存，缓存约 1.14 GiB，按 batch 解码。

新机器从项目根目录执行 `bash e2e_workflow/environment/install_linux.sh` 创建环境。
安装脚本使用 17890 代理，Python 和缓存保存在数据盘。

## 训练与推理

从项目根目录运行，`--epochs` 为累计训练轮数：

```bash
bash e2e_workflow/run.sh main.py --epochs 5 \
  --work-dir e2e_workflow/outputs/20261109_193500_nvidia_udacity
bash e2e_workflow/run.sh main.py --epochs 50 \
  --work-dir e2e_workflow/outputs/20261109_193500_nvidia_udacity \
  --resume e2e_workflow/outputs/20261109_193500_nvidia_udacity/last.h5
```

默认 batch=32、workers=2、Adam 学习率 1e-4、weight decay 1e-5。
每轮写入 metrics.csv，保存 best.h5 和 last.h5，每五轮另存 model-N.h5。
best 按中心相机验证 MSE 选择。训练和验证损失均按三相机图片数计算。

训练后启动模型服务，再进入模拟器 AUTONOMOUS MODE：

```bash
bash e2e_workflow/run.sh drive.py \
  e2e_workflow/outputs/20261109_193500_nvidia_udacity/best.h5 \
  --output e2e_workflow/outputs/YYYYMMDD_HHMMSS_nvidia_udacity_drive
```

每次使用新的输出目录。服务监听 4567 端口，目标速度为 10，油门使用上游公式
`1.2-steering²-(speed/10)²`。遥测写入 telemetry.csv，每十帧保存一张相机图像。

本机 Windows 模拟器位于
`D:\Users\yin\Documents\Repos\term1-simulator-windows\beta_simulator_windows`。
通过同目录 `start_simulator.cmd` 启动，脚本设置
`OPENSSL_ia32cap=:~0x20000000`，解决 12 代 Intel CPU 上旧 OpenSSL 的启动崩溃。

## 代码修改

- 移除未使用的 NetworkLight 导入，首次训练默认从头开始；续训显式传入检查点路径。
- 使用 cv2 和跨平台文件名解析，共用训练、推理预处理。
- 每次相机更新前清零梯度，轮末更新学习率，保存并恢复优化器和调度器状态。
- 验证关闭随机翻转，按图片数统计 MSE；推理使用 eval 和 inference_mode。
- 保存每轮指标和最优权重，推理记录转角、油门、速度和耗时。

报告图表入口为 `prepare_report.py --work-dir ... --drive-dir ...`，
输出 PDF/SVG 和 300 dpi PNG 到 `reports/stage04_e2e/figures/`。
`capture_simulator.ps1` 可在 Windows 截取模拟器窗口，使用 `-Seconds` 指定连续录制时长。

## 报告编译

报告使用 Typst 0.15.1，封面、目录、页眉、标题和表格样式参考《公网部署实验报告.typ》。
正文位于 `reports/stage04_e2e/main.typ`，从 `results/results.json` 读取指标。
从项目根目录运行：

```bash
typst compile reports/stage04_e2e/main.typ \
  reports/stage04_e2e/stage04_e2e_report.pdf
```

字体使用 Times New Roman、SimSun、Noto Sans CJK SC 和 JetBrains Mono。
源码 ZIP 包含报告正文、SVG 图表、模拟器截图、结果日志和 Python 代码。
