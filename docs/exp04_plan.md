# Exp04：端到端自动驾驶实验计划

2026-11-09：已完成独立环境配置、50 轮训练、模拟器运行和报告整理。
训练和验证合计 25.01 分钟，第 38 轮权重在 Lake Track 自动行驶 182.8 秒。
结果与运行命令见 `e2e_workflow/README.md`，提交附件位于 `submit/stage04/`。

## 实验内容

按课程指导书完成 NVIDIA CNN 转角预测模型的训练，接入 Udacity 一号赛道，
保存训练/验证损失曲线和自动驾驶画面，整理第四次实验报告及源码附件。

## 已有材料

- 指导书：`docs/端到端自动驾驶模型_实践指导文档.pdf`。
- 数据包：`data/udacity_assets/dataset.zip`，约 1.2 GB。
- 数据：32,443 行记录、97,329 张图片，包含两个赛道；CSV 无表头，图像路径使用 Windows 写法。
- 机器：WSL2、RTX 4060 8 GB，数据盘剩余约 226 GB。
- 代理：`http://127.0.0.1:17890`，已成功访问 GitHub 和 PyPI。
- 源码：<https://github.com/Zhenye-Na/e2e-learning-self-driving-cars>。

## 目录与环境

| 内容 | 位置 |
|---|---|
| 原始数据包 | `data/udacity_assets/dataset.zip` |
| 解压数据 | `data/udacity_e2e/dataset/` |
| 独立 Python 环境 | 数据盘 `envs/stage04/`，项目入口 `.venv-stage04` |
| 代码和运行说明 | `e2e_workflow/` |
| 权重、日志和回放 | 数据盘 `runs/stage04_e2e/YYYYMMDD_HHMMSS_nvidia_udacity/` |
| 报告 | `reports/stage04_e2e/` |
| 提交附件 | `submit/stage04/` |

`docs/` 保留指导材料和计划，数据与权重归入数据盘。

使用独立 Python 3.10 环境，通过 uv 安装：

- `torch==2.4.0+cu121`、`torchvision==0.19.0+cu121`。
- `numpy==1.26.4`、`opencv-python-headless==4.10.0.84`，以及 pandas、Pillow、matplotlib。
- 按指导书安装 `Flask-SocketIO==4.3.1`、`python-engineio==3.13.2`、`python-socketio==4.6.0`。
- Flask 配套先用 `Flask==2.0.3`、`Werkzeug==2.0.3`、`Jinja2==3.0.3`、`eventlet==0.36.1`，安装后检查通信。

使用 PyTorch wheel 自带的 CUDA runtime。下载时设置 17890 代理，
GitHub、PyPI 和 PyTorch 下载站使用代理，localhost 的模拟器连接直接访问。
Python 和依赖缓存继续放在数据盘。安装或下载卡住时，按已有约定交由用户处理。

## 实施步骤

1. **配置环境。** 创建 Stage04 环境，安装依赖，检查 PyTorch GPU 运算和通信模块导入。
2. **准备数据和代码。** 解压到数据盘，读取无表头 CSV，按文件名找到图片。
   固定随机种子，按 8:2 划分训练和验证，同一条记录的三路相机一起划分。
3. **修正课程代码。** 完成指导书要求的导入、resume、cv2 读图和 CHW 转换。
   训练和推理统一为 BGR、裁剪 `[65:-25]`、归一化 `x/127.5-1`、float32、`(3,70,320)`。
   修正梯度清零位置、损失统计和学习率调度；验证关闭随机翻转；推理启用 `model.eval()`。
4. **训练。** 初始 batch=32、workers=2、Adam 学习率 1e-4、weight decay 1e-5。
   先跑 5 轮，查看损失和每轮耗时，再继续到累计 50 轮。保存每轮损失、best 和 last 权重。
5. **接入模拟器。** 先启动 `drive.py`，再在模拟器进入一号赛道 AUTONOMOUS MODE。
   使用上游油门公式，目标速度设为 10，观察车辆行驶，保存截图或录像及转角、油门、速度日志。
6. **完成报告。** 使用 Typst，按《公网部署实验报告.typ》的版式写模型结构、代码修改、训练曲线和模拟器运行结果。
   源码 ZIP 与报告 PDF 放入 `submit/stage04/`，沿用前几次附件命名。

## 需要解决的问题

| 问题 | 处理方式 |
|---|---|
| 老版本 Socket.IO 与新版依赖不兼容 | 按指导书固定通信版本，同时固定 Flask 和 Werkzeug |
| CSV 使用 Windows 路径 | 取文件名，再与数据目录的 IMG 拼接 |
| 上游代码存在训练和推理问题 | 修正梯度清零、损失统计、CHW 转换和 eval 模式 |
| Windows 模拟器连接 WSL | 本机已启用 mirrored 网络，先用 localhost:4567 连接 |
| 直行样本较多，车辆可能过弯不好 | 先按课程训练；出现问题时再调整采样或训练轮数 |
| 训练时长 | 用前 5 轮的耗时估算并报告 |

## Windows 模拟器准备教程

模拟器是解压即用的程序。用户在 Windows 下载、解压和操作界面，Python 环境及模型在 WSL 中配置。

1. 下载指导书提供的 [Windows 模拟器 ZIP](https://s3-us-west-1.amazonaws.com/udacity-selfdrivingcar/Term1-Sim/term1-simulator-windows.zip)，约 107 MB。
2. 在 Windows 资源管理器中解压到例如 `D:\UdacitySimulator`。
   保留整个解压目录，包括 exe 旁边的资源文件夹。
3. 进入 `term1-simulator-windows` → `beta_simulator_windows`。
   本机已添加 `start_simulator.cmd`，双击该脚本启动模拟器。脚本使用窗口模式和 800×600 分辨率。
   它设置进程环境变量 `OPENSSL_ia32cap=:~0x20000000`，解决旧 OpenSSL 在本机 12 代 Intel CPU 上的启动崩溃。
4. 若显示设置窗口，选择 `800×600`、Fastest、Windowed，点击 **Play!**。
5. 在主菜单选择一号赛道 **Lake Track**。准备到这里即可，自动驾驶模式等模型服务启动后再点。
6. 训练完成后，由我在 WSL 启动 `drive.py`，随后你在模拟器点击 **AUTONOMOUS MODE**。
   车辆开始行驶，WSL 终端会输出转角、油门和速度。

无需安装 Unity 编辑器，也无需在 Windows 安装 Python、CUDA 或训练依赖。
连接使用本机 4567 端口，17890 代理用于下载。
