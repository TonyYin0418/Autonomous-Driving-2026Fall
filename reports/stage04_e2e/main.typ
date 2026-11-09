// 版式参考《公网部署实验报告.typ》；本文件独立编译。
// 使用本机宋体、黑体和等宽字体。
#let song = ((name: "Times New Roman", covers: "latin-in-cjk"), "SimSun")
#let hei = ((name: "Times New Roman", covers: "latin-in-cjk"), "Noto Sans CJK SC")
#let mono = ("JetBrains Mono", "Noto Sans CJK SC")
#set document(title: "自动驾驶技术第四次实验报告", author: "尹玉文东", date: datetime(year: 2026, month: 11, day: 9))
#set page(
  paper: "a4",
  margin: (top: 2.4cm, bottom: 2.2cm, x: 2.5cm),
  numbering: "1",
  header: [
    #set text(font: song, size: 9pt)
    #grid(columns: (1fr, auto), [自动驾驶技术], [尹玉文东-2024302131025])
    #v(-0.5em)
    #line(length: 100%, stroke: 0.4pt)
  ],
)
#set text(font: song, size: 10.5pt, lang: "zh", region: "cn")
#set par(justify: true, leading: 0.82em, spacing: 0.8em,
  first-line-indent: (amount: 2em, all: true))
#set heading(numbering: "1.1")
#set raw(theme: none)
#set enum(indent: 1em)
#set list(indent: 1em, marker: [•])
#show strong: set text(font: hei, weight: "medium")
#show heading: set text(font: hei, weight: "medium")
#show heading: set par(first-line-indent: 0pt, justify: false)
#show heading.where(level: 1): it => {
  block(width: 100%, below: 0.8em, inset: (bottom: 0.35em),
    stroke: (bottom: 0.8pt))[
    #set text(size: 15pt)
    #if it.numbering != none { counter(heading).display(it.numbering); h(0.7em) }#it.body
  ]
}
#show heading.where(level: 2): set text(size: 12pt)
#show heading.where(level: 2): set block(above: 1.1em, below: 0.65em)
#show heading.where(level: 3): set text(size: 10.5pt)
#show heading.where(level: 3): set block(above: 0.8em, below: 0.5em)
#show raw: set text(font: mono, size: 0.85em)
#show raw.where(block: true): it => {
  set text(size: 7.7pt)
  set par(first-line-indent: 0pt, justify: false, leading: 0.5em)
  block(width: 100%, inset: (x: 8pt, y: 7pt), stroke: 0.5pt,
    breakable: true, it)
}
#set table(stroke: none, inset: (x: 5pt, y: 4.5pt), align: left + horizon)
#show table: set text(size: 9pt)
#show table: set par(first-line-indent: 0pt, justify: false, leading: 0.65em)
#show table.cell.where(y: 0): set text(font: hei, weight: "medium")
#let tbl(..cells) = table(
  table.hline(stroke: 1pt),
  ..cells,
  table.hline(stroke: 1pt),
)

#set figure(gap: 0.65em)
#show figure.caption: set text(size: 9pt)
#show figure.caption: set par(first-line-indent: 0pt, justify: false)
#show figure.where(kind: table): set figure.caption(position: top)
#let plot(file, caption, width: 100%) = figure(image("figures/" + file, width: width), caption: caption)
#let result = json("results/results.json")
#let fmt(value, digits: 6) = {
  let parts = str(calc.round(value, digits: digits)).split(".")
  parts.first() + "." + (parts.at(1, default: "") + "0" * digits).slice(0, digits)
}

#{
  set page(header: none, footer: none, numbering: none)
  set align(center)
  set par(first-line-indent: 0pt)
  v(3.2cm)
  text(font: hei, size: 20pt, [自动驾驶技术])
  v(1.1cm)
  text(font: hei, size: 24pt, [自动驾驶技术第四次实验报告])
  v(0.7cm)
  line(length: 14cm, stroke: 1pt)
  v(0.7cm)
  text(font: hei, size: 14pt, [端到端自动驾驶模型训练与模拟器运行])
  v(2.2cm)
  grid(
    columns: (3cm, 7cm), column-gutter: 0.6cm,
    row-gutter: 0.65cm, align: (right, left),
    text(font: hei, [姓名]), [尹玉文东],
    text(font: hei, [学号]), [2024302131025],
    text(font: hei, [学院]), [武汉大学计算机学院],
    text(font: hei, [专业]), [计算机科学与技术（雷军班）],
    text(font: hei, [指导老师]), [张红娟],
    text(font: hei, [日期]), [2026 年 11 月 9 日],
  )
  pagebreak()
}
#counter(page).update(1)
#show outline.entry: set text(size: 10.5pt)
#show outline.entry: set par(leading: 0.85em, first-line-indent: 0pt)
#show outline.entry: set block(above: 0.58em, below: 0.18em)
#show outline.entry.where(level: 1): it => {
  set text(font: hei, size: 11pt)
  block(above: 1.05em, below: 0.35em, it)
}
#outline(title: [目录], depth: 2, indent: 1.8em)
#pagebreak()

= 实验目的与内容

本次实验使用 NVIDIA CNN 学习“道路图像 → 方向盘转角”的映射，并将训练好的模型接入 Udacity 模拟器进行自动驾驶。训练数据来自教师提供的驾驶记录，模型及基础训练代码来自指导书指定的 #link("https://github.com/Zhenye-Na/e2e-learning-self-driving-cars")[Zhenye-Na/e2e-learning-self-driving-cars] 项目。

我按照指导书修正图像读取和张量排列，进一步调整三相机训练的梯度更新、损失统计、验证方式与断点恢复，完成 50 轮训练。随后将验证误差最小的模型接入 Lake Track，记录车辆转角、油门、车速和行驶画面。

= 环境与数据准备

== WSL 与 Windows 的运行分工

本机使用 Windows 和 WSL2 Ubuntu。数据处理、模型训练、验证及 Python 控制服务都在 WSL 中运行，训练通过 CUDA 使用 RTX 4060 显卡；Udacity 模拟器运行在 Windows 桌面。模拟器负责生成道路画面、模拟车辆运动，WSL 中的 Python 程序负责接收画面并计算控制量，两者通过本机网络通信。

本次单独建立 Python 3.10 环境，通过 uv 安装 PyTorch 和通信依赖。PyTorch 使用 cu121 版本及其自带的 CUDA runtime；Flask、Socket.IO 和 Engine.IO 按模拟器所用协议固定版本。主要配置见 @tab-env。

#figure(
  tbl(columns: (48mm, 1fr),
    [项目], [本次配置],
    table.hline(stroke: 0.5pt),
    [运行环境 / 显卡], [WSL2 Ubuntu / RTX 4060，8 GB],
    [Python], [3.10.21],
    [PyTorch / torchvision], [2.4.0+cu121 / 0.19.0+cu121],
    [NumPy / OpenCV], [1.26.4 / 4.10.0.84],
    [Flask / Werkzeug], [2.0.3 / 2.0.3],
    [python-socketio / python-engineio], [4.6.0 / 3.13.2],
    [Flask-SocketIO / eventlet], [4.3.1 / 0.36.1],
  ), caption: [实验环境配置],
) <tab-env>

安装后，我用一个 batch 完成 GPU 前向计算、损失计算、反向传播及参数更新，确认训练入口可以运行；再将模型切换为评估模式，对同一图像连续预测两次，检查结果一致。

== 数据组成与训练划分

教师数据包含两个赛道的 32,443 条驾驶记录，每条记录有中、左、右三路相机图像，以及同步的转角、油门、刹车和车速，共 97,329 张图片。其中一号赛道有 10,615 条记录，二号赛道有 21,828 条记录。本次使用图像作为输入、驾驶员转角作为监督标签。

我使用随机种子 20261109，将记录按 8:2 划分为 25,954 条训练数据和 6,489 条验证数据。同一时刻的三路图像随记录一起划分。训练阶段遍历三路相机，验证阶段同时统计三相机总体误差和中心相机误差。

#pagebreak()

== 图像处理与数据增强

原始转角主要集中在零值附近，直行记录较多，转弯记录分布在两侧，具体见 @fig-distribution。

#plot("steering_distribution.svg", [数据集中的方向盘转角分布], width: 83%) <fig-distribution>

原图大小为 $320 times 160$。我沿用指导书的裁剪范围，去掉上方 65 行和下方 25 行，使输入保留车辆前方的道路区域，得到 $320 times 70$ 的图像。像素经过 $x / 127.5 - 1$ 归一化后转换为 float32，三路相机的裁剪效果见 @fig-preprocess。

#plot("camera_preprocessing.svg", [三路相机原图与裁剪后的输入图像]) <fig-preprocess>

三路相机提供同一时刻的不同观察位置。左相机图像使用“原转角 +0.4”的标签，右相机使用“原转角 −0.4”的标签，让网络学习车辆偏离中心位置时的回正动作。每张训练图像以 0.5 的概率水平翻转，同时将对应转角取反，增加左右转向的训练样本。验证阶段使用原始朝向和固定标签。

== JPEG 缓存与读图速度

初次训练逐张读取数据盘上的 JPEG 小文件，读图等待较长。我将读取方式改为启动时从 ZIP 一次性读入全部 JPEG 压缩字节，训练时按 batch 在内存中解码，再执行裁剪和增强。这样保留了每轮随机翻转，同时把反复访问磁盘的工作集中到启动阶段。

缓存共 97,329 张图片，JPEG 压缩字节共 1141 MiB，首次加载耗时 19.5 秒。正式训练平均每轮用时 #fmt(result.mean_epoch_seconds, digits: 2) 秒。

#pagebreak()

= 模型与代码修改

== 转角回归网络

本次使用原项目的 `NetworkNvidia`，网络共有 559,419 个参数。每次输入一张 $3 times 70 times 320$ 的道路图像，经过五层卷积提取特征，再由四层全连接输出一个归一化转角，负值表示向左、正值表示向右。实际网络结构见 @tab-model。

#figure(
  tbl(columns: (24mm, 73mm, 1fr),
    [模块], [配置], [后续运算],
    table.hline(stroke: 0.5pt),
    [卷积 1], [$3 arrow.r 24$，$5 times 5$，stride 2], [ELU],
    [卷积 2], [$24 arrow.r 36$，$5 times 5$，stride 2], [ELU],
    [卷积 3], [$36 arrow.r 48$，$5 times 5$，stride 2], [ELU],
    [卷积 4], [$48 arrow.r 64$，$3 times 3$，stride 1], [ELU],
    [卷积 5], [$64 arrow.r 64$，$3 times 3$，stride 1], [Dropout，概率 0.5],
    [展平], [$64 times 2 times 33 = 4224$], [展平为向量],
    [全连接], [$4224 arrow.r 100 arrow.r 50 arrow.r 10 arrow.r 1$], [前两层后接 ELU],
  ), caption: [NVIDIA CNN 结构],
) <tab-model>

模型通过均方误差学习驾驶记录中的转角：

$ L = 1 / N sum_(i=1)^N (hat(s)_i - s_i)^2. $

其中 $s_i$ 为记录中的转角，$hat(s)_i$ 为预测转角，$N$ 为参与统计的图像数。训练时减小预测值与标签之间的平方差；运行时由网络输出转角，再结合当前车速计算油门。

== 统一颜色通道与张量排列

原项目的图像归一化结果仍按 HWC 排列，推理时直接用 `view` 改成网络输入形状。`view` 按原顺序重新解释数据，图像的三个颜色通道仍交错存放。我在训练和推理两端都增加 `transpose(2, 0, 1)`，将每个通道的数据排列到各自的平面，再送入卷积层。

训练读图改为 OpenCV，采用 BGR 通道顺序。模拟器发送的图像解码为 RGB 后，先转换成 BGR，再调用与训练相同的预处理函数。裁剪、归一化和维度转换集中在一个函数中：

```python
def preprocess(image_bgr):
    image = image_bgr[65:-25].astype(np.float32)
    return np.ascontiguousarray(
        (image / 127.5 - 1.0).transpose(2, 0, 1))
```

处理后，单张图像从 $(160, 320, 3)$ 变为 $(3, 70, 320)$。训练 batch 的输入形状为 $(32, 3, 70, 320)$，模拟器逐帧推理时的输入形状为 $(1, 3, 70, 320)$。

#pagebreak()

== 修正三相机的梯度更新与误差统计

原训练代码在进入三相机循环前清零一次梯度，随后分别对中、左、右相机反向传播和更新参数。PyTorch 的反向传播会累加梯度，这使后一个相机的更新带上前一个相机留下的梯度。

我保留每个相机 batch 分别更新一次的方式，将清零操作移到相机循环内部。一次更新按“清零梯度 → 前向计算 → 计算损失 → 反向传播 → 更新参数”执行，三路相机各完成一次：

```python
for camera in range(3):
    optimizer.zero_grad(set_to_none=True)
    outputs = model(images[:, camera].contiguous()).squeeze(1)
    error = outputs - angles[:, camera]
    loss = error.square().mean()
    loss.backward()
    optimizer.step()
```

原代码把三路相机的 batch 平均损失相加，再除以 batch 数。我改为累加每张图像的平方误差，并除以实际图像总数；最后一个 batch 也按其实际大小计入。报告曲线中的训练和验证 MSE 都使用这一口径，同时单独统计中心相机的 MSE、MAE，用于选择模拟器运行的权重。

== 固定验证过程与推理模式

原项目的训练集和验证集共用随机翻转增强。我将数据集分为训练和验证两种模式，训练保留随机翻转，验证使用固定朝向。验证时调用评估模式并关闭梯度计算，使每轮都在相同验证样本上计算误差。

推理程序加载权重后增加 `model.eval()`，使 Dropout 在推理时使用完整网络；前向计算放在 `torch.inference_mode()` 中执行。同一帧连续两次预测得到相同结果，随后使用这一设置接入模拟器。

== 调整训练入口与断点恢复

训练入口固定使用 NVIDIA 网络，并移除原项目中类名不匹配的 `NetworkLight` 导入。首次运行从随机初始化开始，续训时显式指定检查点。检查点保存模型参数、Adam 状态、学习率调度器、已完成轮数和随机数状态，加载后从下一轮继续训练。

我还将学习率调度移到每轮训练结束后。正式实验先完成 5 轮，检查损失下降及运行耗时，再恢复检查点继续到累计 50 轮，第 6 轮接续第 5 轮的参数与优化器状态。

#pagebreak()

= 训练过程与结果

== 训练设置

本次采用 Adam 优化器，batch size 为 32，DataLoader 使用 2 个读取进程。每个 batch 取 32 条驾驶记录，按中、左、右相机依次进行三次参数更新。初始学习率为 $10^(-4)$，weight decay 为 $10^(-5)$；第 30 轮结束后，学习率降为 $10^(-5)$，继续训练至第 50 轮。

每轮结束后使用全部验证数据计算误差，更新最新检查点，并在中心相机验证 MSE 下降时保存最优检查点。中心相机与模拟器运行时的观察视角一致，因此本次按这一指标选择运行模型。

== 损失变化与模型选择

@fig-loss 展示训练和验证 MSE 的变化。第 1 轮训练 MSE 为 0.180486，验证 MSE 为 0.161625；第 5 轮分别降至 0.132030 和 0.127629。到第 30 轮，训练 MSE 为 0.070524，验证 MSE 为 0.083069，下降速度逐渐减缓。

#plot("loss_curves.svg", [训练和三相机验证 MSE 随轮数的变化], width: 88%) <fig-loss>

降低学习率后，第 31 轮验证 MSE 降至 0.079642，第 50 轮为 #fmt(result.last_val_mse)。后期训练误差继续减小，验证曲线逐渐趋平。关键轮次的结果见 @tab-training。

#figure(
  tbl(columns: (27mm, 1fr, 1fr, 1.15fr),
    [轮数], [训练 MSE], [三相机验证 MSE], [中心相机验证 MSE],
    table.hline(stroke: 0.5pt),
    [5], [0.132030], [0.127629], [0.091127],
    [30], [0.070524], [0.083069], [0.078683],
    [38（最优）], [0.062749], [0.078465], [#fmt(result.best_center_mse)],
    [50], [#fmt(result.last_train_mse)], [#fmt(result.last_val_mse)], [0.074586],
  ), caption: [关键轮次的训练与验证指标],
) <tab-training>

中心相机验证 MSE 的最小值出现在第 #result.best_epoch 轮，为 #fmt(result.best_center_mse)，对应 MAE 为 #fmt(result.best_center_mae)，RMSE 为 #fmt(result.best_center_rmse)。第 50 轮的中心相机 MSE 为 0.074586，因此模拟器加载第 38 轮的最优权重。50 轮训练与轮末验证合计耗时 #fmt(result.total_training_seconds / 60, digits: 2) 分钟。

#pagebreak()

= 模拟器运行

== 处理 Windows 模拟器闪退

模拟器在 Windows 中运行，配置为 Fastest 画质、$800 times 600$ 分辨率和窗口模式。初次启动时，点击 Play! 后程序直接退出。我检查 Windows 崩溃记录及 Unity 日志，定位到程序自带的旧 OpenSSL SHA 指令代码。

本机使用第 12 代 Intel 处理器。我在启动脚本中加入以下设置，屏蔽旧 OpenSSL 的对应指令优化，再启动模拟器：

```bat
set "OPENSSL_ia32cap=:~0x20000000"
start "" "beta_simulator.exe" -screen-width 800 -screen-height 600 -screen-fullscreen 0
```

通过脚本启动后，模拟器成功进入主菜单，随后选择一号赛道 Lake Track 进行自动驾驶。

== WSL 控制服务与闭环运行

我先在 WSL 中加载第 38 轮权重，启动 `drive.py`，服务监听 4567 端口。WSL 使用 mirrored 网络模式，Windows 模拟器通过 localhost 连接。随后在模拟器中点击 AUTONOMOUS MODE，服务开始接收图像与车速并返回转角和油门。

每帧的处理顺序为：解码相机图像，转换颜色通道，裁剪与归一化，送入 NVIDIA CNN 预测转角，计算油门，再将两个控制量发回模拟器。车辆按控制量运动后，模拟器产生下一帧，持续进行这一循环。训练使用 GPU，逐帧推理使用 WSL 中的 CPU。

油门沿用原项目实际启用的公式：

$ t = 1.2 - hat(s)^2 - (v / 10)^2. $

其中 $hat(s)$ 为预测转角，$v$ 为当前车速，目标速度参数设为 10。车辆起步时油门较大，随着车速上升逐渐减小；转角绝对值增大时，转角平方项进一步减小油门。输出的转角和油门都裁剪到 $[-1, 1]$。程序逐帧记录转角、油门、速度和处理耗时。

#plot("driving_signals.svg", [自动驾驶过程中的转角、油门和车速], width: 75%) <fig-signals>

#pagebreak()

== 行驶结果与信号分析

本次在 Lake Track 自动行驶 #fmt(result.driving.seconds, digits: 1) 秒，共记录 29,479 帧遥测，平均车速为 #fmt(result.driving.mean_speed, digits: 2) mph，单帧图像处理和预测平均耗时为 #fmt(result.driving.mean_inference_ms, digits: 2) 毫秒。

从 @fig-signals 可以看到，车辆起步后车速很快上升，随后主要保持在 10 mph 附近，油门随之降到较低水平。转角随道路变化在零值两侧调整，记录中的范围为 −0.570 至 0.646；转角变化较大的时段，油门也相应降低。相机画面覆盖了弯道和湖边路段，见 @fig-frames，实际自动驾驶界面见 @fig-window。

#plot("driving_frames.svg", [行驶过程中的相机画面]) <fig-frames>

#plot("driving_window.png", [Windows 模拟器自动驾驶界面], width: 78%) <fig-window>

= 实验总结

本次完成了从三相机驾驶数据训练 NVIDIA CNN，到在 Udacity 模拟器中逐帧控制车辆的实验。模型训练 50 轮，第 38 轮的中心相机验证 MSE 最小，为 #fmt(result.best_center_mse)；加载该权重后，车辆在 Lake Track 自动行驶 #fmt(result.driving.seconds, digits: 1) 秒，平均车速为 #fmt(result.driving.mean_speed, digits: 2) mph。

实现中，我将训练与推理统一为相同的 BGR 图像和 CHW 张量，逐相机清零梯度，按图像数统计损失，并分别设置训练、验证和推理模式。JPEG 缓存缩短了读图等待，断点恢复接续了两阶段训练，启动脚本解决了 Windows 模拟器闪退。
