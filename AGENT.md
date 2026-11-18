# 协作约定

- 开始新任务时先读 `README.md`、本文件和 `docs/` 中对应的课程材料，再核对已有代码、
  数据与运行结果。Stage01、Stage02、Stage03、Stage04 均已完成，入口和报告路径见根 README。
- 第一次实践课已完成：nuScenes DevKit 数据读取，LiDAR/Radar 与相机叠加，3D 框转 2D
  框，YOLO11n 训练、测试及跨地区评估。正式报告在
  `reports/stage01_nuscenes_yolo/`，构建产物只保留正式 PDF。
- 第一次实践使用 `uv` 管理 Python 3.12 环境。PETR 教程指定 Python 3.8、Torch 1.13.1
  和 MMCV 1.x，需单独核对兼容环境，勿直接复用第一次实践的依赖。
- 第一次实践采用 PyTorch wheel 自带的 CUDA runtime 和 cuDNN，不重复安装系统级 CUDA。
- 保持项目简单，目录、配置和代码只在实际需要时创建，不提前搭建复杂工程骨架。
- 课程作业以跑通指导书要求为目标。计划、进度说明和报告使用直接写法，省略防御性限定、
  免责说明和额外验收要求；围绕实际操作与结果展开。
- 报告具体说明改了什么、为何修改及运行结果，写清 WSL 训练和推理与 Windows 模拟器的
  分工。目录管理、路径字符串处理和提交文件位置放在 README，正文引用相关源码包内
  脚本时使用文件名或简短相对路径。
- 检查和诊断代码默认使用一次性命令，不把临时测试脚本留在仓库中。
- 数据保存在 `/home/yin/data/autonomous_driving/datasets`，项目内 `data` 是指向它的
  软链接；代码和小型结果保存在仓库。第一次实践已有 nuScenes trainval 元数据、六路
  相机、LIDAR_TOP、五路 Radar 关键帧和四个地区的 YOLO 数据，未保存 sweeps。
- `docs/` 中新拷入的数据、权重和依赖二进制包只是临时导入；整理后移到数据盘，
  不在 `docs/` 保留副本或软链接。指导 PDF 和小型课程源码包保留在 `docs/`。
- 未经明确要求，不下载或解压大型数据集，不移动大文件到项目所在磁盘。
- 每完成一个阶段，及时更新 `README.md` 中的进度、运行方法和必要路径。
- 提交附件统一放在根目录 `submit/stageXX/`，与 `reports/` 平级。每阶段只保留源码 ZIP
  和报告 PDF，命名为 `自动驾驶技术第X次实验+尹玉文东+2024302131025.zip` / `.pdf`。
  源码 ZIP 不在 `reports/` 重复保存；优先更新已有 README，不为打包新增说明文档。
- Git 提交按阶段和里程碑拆分，标题统一为 `type(scope): 中文说明`，正文用“内容、结果、
  验证”三项描述；各阶段按实验实现、结果报告、提交附件组织。作者日期以原提交、日志和
  文件记录为依据，历史重整的提交日期使用当前时间；新增整理也使用当前日期。
  用户已于 2026-11-17 要求统一全部历史的标题、正文和里程碑粒度。
- `nuscenes_yolo_converter/` 与 `yolo_workflow/` 的基础转换、训练和评估代码来自课程；
  `nuscenes_devkit/` 中的检查与可视化脚本，以及 `evaluate_cross_location.py` 是第一次
  实践补写的。报告中如实交代代码来源，并说明每次运行使用的脚本。
- 每阶段单独组织报告，遵循 `reports/WRITING_GUIDELINES.md`。Stage01—03 使用
  `reports/template/course-report.sty`；Stage04 按用户指定的《公网部署实验报告.typ》
  版式编写 `main.typ`。正文只保留能帮助读者理解操作与结果的说明；对课程
  提供的代码简述作用，对自己编写的关键处理适当展示代码。不要为了显得严谨而补充重复
  解释、无根据的原因推测或机械排比。
- 训练运行目录统一使用 `YYYYMMDD_HHMMSS_<固定描述>`；时间戳放在最前，常规实验
  保持模型与数据集后缀不变，只有特殊实验才增加或调整后缀。
- 报告图使用简洁、色盲友好的论文配色与统一字号，避免图内冗余标题，并同时保存
  PDF/SVG 矢量格式和高分辨率 PNG，供报告排版。
- 第三次实践 PointPillars 已完成。代码在 `pointpillars_workflow/`，报告在
  `reports/stage03_pointpillars/`，数据根目录为 `data/nuscenes_pointpillars_mini/`。
  独立 `.venv-stage03` 使用 Python 3.9.25、Torch 2.0.1+cu118、MMCV 2.1.0、
  MMDetection3D 1.4.0；通过 `run.sh` 启动。单帧 323/81 划分、AMP 检测头微调，
  已从第 1 轮恢复至累计第 5 轮，NDS 0.118147、mAP 0.061377。用户要求下载或
  环境配置卡住时停止并交由用户手动处理；本次正式训练已获得明确确认。
- 第四次实践已完成 NVIDIA CNN 50 轮训练与 Udacity 模拟器运行。代码在 `e2e_workflow/`，
  报告在 `reports/stage04_e2e/`，附件在 `submit/stage04/`。独立 `.venv-stage04` 使用
  Python 3.10.21、Torch 2.4.0+cu121，默认下载代理为 `http://127.0.0.1:17890`。
  模拟器使用第 38 轮 best.h5，在 Lake Track 自动行驶 182.8 秒。
  Windows 端通过 start_simulator.cmd 设置 OPENSSL_ia32cap，解决旧程序在本机的启动崩溃。
- 结题报告已完成，正文在 `reports/final_report/main.typ`，附件在 `submit/final/`。三组补充测试
  只做推理，结果保存在 `reports/final_report/results/`，中间版本在 `history/`。写作上少用分号和
  排比句，课外调研要写明“我查阅了……”，额外做的测试要明确说明是补充测试。
