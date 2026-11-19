// 版式沿用第四次实验报告（main.typ），本文件独立编译。
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#let song = ((name: "Times New Roman", covers: "latin-in-cjk"), "Noto Serif CJK SC")
#let hei = ((name: "Times New Roman", covers: "latin-in-cjk"), "Noto Sans CJK SC")
#let mono = ("JetBrains Mono", "Noto Sans CJK SC")
#set document(title: "自动驾驶技术结题报告", author: "尹玉文东", date: datetime(year: 2026, month: 11, day: 18))
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
#set smartquote(enabled: false)
#set par(justify: true, leading: 0.82em, spacing: 0.8em,
  first-line-indent: (amount: 2em, all: true))
#set heading(numbering: "1.1")
#set raw(theme: none)
#set enum(indent: 1em)
#set list(indent: 1em, marker: [•])
#show strong: it => text(font: song, weight: "bold", it.body)
#show heading: set text(font: hei, weight: "bold")
#show heading: set par(first-line-indent: 0pt, justify: false)
#show heading.where(level: 1): it => {
  if it.numbering != none { pagebreak(weak: true) }
  block(width: 100%, below: 0.8em, inset: (bottom: 0.35em),
    stroke: (bottom: 0.8pt))[
    #set text(size: 15pt)
    #if it.numbering != none { counter(heading).display(it.numbering); h(0.7em) }#it.body
  ]
}
#show heading.where(level: 2): set text(size: 12pt)
#show heading.where(level: 2): set block(above: 1.1em, below: 0.65em)
#show heading.where(level: 3): set text(size: 10.5pt)
#show heading.where(level: 3): set block(above: 1.2em, below: 0.95em)
#show raw: set text(font: mono, size: 0.85em)
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
#show figure: set block(above: 1.1em, below: 1.1em)
#show figure.caption: set text(size: 9pt)
#show figure.caption: set par(first-line-indent: 0pt, justify: false)
#show figure.where(kind: table): set figure.caption(position: top)
// 文中引用跳转到参考文献条目
#let rl(n) = link(label("ref-" + str(n)), str(n))
#let refitem(n, body) = block(below: 0.5em, grid(columns: (2.4em, 1fr), [\[#n\]], body))
#let plot(file, caption, width: 100%) = figure(image("figures/" + file, width: width), caption: caption)
#let sub(file, label) = {
  set par(first-line-indent: 0pt)
  stack(spacing: 0.4em, image("figures/" + file, width: 100%),
    align(center, text(size: 9pt, label)))
}
// 题目对应说明
#let qnote(body) = {
  set par(first-line-indent: 0pt)
  block(below: 0.9em, text(size: 9pt, fill: luma(90), body))
}
// 流程图节点
#let box-node(pos, title, body: none, name: none, fill: none, width: auto) = node(pos,
  align(center, {
    text(font: song, weight: "bold", size: 8.5pt, title)
    if body != none { linebreak(); text(size: 7.5pt, body) }
  }),
  name: name, fill: fill, width: width, shape: rect)

#{
  set page(header: none, footer: none, numbering: none)
  set align(center)
  set par(first-line-indent: 0pt)
  v(6.2cm)
  text(font: hei, size: 24pt, [自动驾驶技术结题报告])
  v(0.7cm)
  line(length: 14cm, stroke: 1pt)
  v(1.7cm)
  text(font: hei, size: 14pt, [系统组成、环境感知与端到端驾驶的分析])
  v(7.2cm)
  grid(
    columns: (3cm, 7cm), column-gutter: 0.6cm,
    row-gutter: 0.65cm, align: (right, left),
    text(font: hei, [姓名]), [尹玉文东],
    text(font: hei, [学号]), [2024302131025],
    text(font: hei, [学院]), [武汉大学计算机学院],
    text(font: hei, [专业]), [计算机科学与技术（雷军班）],
    text(font: hei, [指导老师]), [张红娟],
    text(font: hei, [日期]), [2026 年 11 月 18 日],
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
#v(4.5em)


#heading(numbering: none)[前言]

本课程的四次实践依次覆盖了自动驾驶的各个环节。首先第一次实践读取 nuScenes 多传感器数据集，并训练 YOLO11n 模型，完成了前视图像的二维目标检测。第二次和第三次实践进一步扩展到了三维，分别用六路相机的 PETR 和激光雷达的 PointPillars 完成三维目标检测。第四次实践训练 NVIDIA CNN，从道路图像直接预测方向盘转角，并在 Udacity 模拟器中，进行了可视化的验证。

*此外，我还在前四次实验的已有模型上，补充了三组测试*，分别考察 YOLO11n 在夜间和雨天图像上的检测效果、端到端模型在图像变化下的转角预测，以及端到端模型的遮挡敏感度。

*四次实践的代码和记录在* #link("https://github.com/TonyYin0418/Autonomous-Driving-2026Fall")[github.com/TonyYin0418/Autonomous-Driving-2026Fall]。

= 自动驾驶系统组成与关键技术分析

== 系统组成与各模块的功能

模块化自动驾驶系统把驾驶任务拆成若干相对独立的子任务，每个模块有明确的输入和输出，前一个模块的结果作为后一个模块的输入。

整体来看，系统可以分为传感器、环境感知、定位、预测、规划决策、控制和线控执行几个部分，另外有高精地图和计算平台为各模块提供支撑。整体架构见 @fig-arch。

#figure(
  diagram(
    spacing: (10mm, 7mm),
    node-stroke: 0.6pt, node-inset: 5pt, node-corner-radius: 2pt,
    edge-stroke: 0.6pt, mark-scale: 70%,
    box-node((0, 0), [*传感器*], name: <sen>),
    box-node((0, 1), [*GNSS / IMU*], name: <gnss>),
    box-node((1, 0), [*环境感知*], body: [*（实践一二三）*], name: <per>, fill: luma(232)),
    box-node((1, 1), [*定位*], name: <loc>),
    box-node((1, 2), [*高精地图*], name: <map>),
    box-node((2, 0.5), [*预测*], name: <pred>),
    box-node((3, 0.5), [*规划决策*], name: <plan>),
    box-node((4, 0.5), [*控制*], name: <ctrl>),
    box-node((5, 0.5), [*线控底盘*], name: <act>),
    edge(<sen>, <per>, "-|>", label: text(size: 7pt)[图像 · 点云], label-side: left),
    edge(<gnss>, <loc>, "-|>"),
    edge(<sen>, <loc>, "-|>"),
    edge(<map>, <loc>, "-|>", label: text(size: 7pt)[地图匹配], label-side: left),
    edge(<per>, <pred>, "-|>", label: text(size: 7pt)[目标列表], label-side: left),
    edge(<loc>, <pred>, "-|>", label: text(size: 7pt)[自车位姿], label-side: right, label-pos: 0.6),
    edge(<pred>, <plan>, "-|>", label: text(size: 7pt)[未来轨迹], label-side: left),
    edge(<map>, (3, 2), <plan>, "-|>", label: text(size: 7pt)[车道与规则], label-pos: 0.3, label-side: left),
    edge(<plan>, <ctrl>, "-|>", label: text(size: 7pt)[规划轨迹], label-side: left),
    edge(<ctrl>, <act>, "-|>", label: text(size: 7pt)[控制指令], label-side: left),
    edge(<act>, (5, 1.4), (4, 1.4), <ctrl>, "--|>",
      label: text(size: 7pt)[车辆状态], label-side: left),
    edge(<sen>, (0, -0.85), (4, -0.85), <ctrl>, "--|>",
      label: text(size: 7pt)[*（实践四）*], label-side: left),
  ),
  caption: [模块化自动驾驶系统整体架构],
) <fig-arch>

下面按信息流动的顺序展开：

+ *感知与定位*：传感器采集原始数据，*环境感知*把它们加工成对周围环境的描述，如目标、车道线和信号灯。*定位*则确定车辆自身在地图中的位置和姿态。
+ *预测*：根据感知和定位的结果，推断其他车辆和行人在未来几秒内可能的轨迹。
+ *规划决策*：通常分三层，全局路径规划在路网上找到从起点到终点的路线，行为决策确定当前是否需要跟车、变道或停车，局部轨迹规划再生成满足车辆动力学和舒适性要求的具体轨迹。
+ *控制与执行*：*控制*模块根据轨迹与实际状态的偏差计算转向和加减速指令，由*线控底盘*执行。

此外，*高精地图*为整个系统提供先验信息，其中记录了车道线、停止线、路口拓扑和限速等内容，既可以作为定位时的匹配参照，也能辅助规划模块判断哪些车道可以通行。

这几个模块会持续循环运行。车辆执行动作后，周围环境和自身状态随之变化，传感器采集到新的数据，整个链条再运行一次。

== 常用传感器及其特点

自动驾驶汽车常用的传感器有摄像头、激光雷达、毫米波雷达和超声波雷达，另外还有用于定位的 GNSS 和 IMU。这些传感器的测量原理不同、特点互补，主要特点见 @tab-sensors。

#figure(
  tbl(columns: (20mm, 1fr, 1fr, 30mm),
    [传感器], [优势], [局限], [典型用途],
    table.hline(stroke: 0.5pt),
    [摄像头], [语义丰富，能识别信号灯、标志和车道线，成本低], [不能直接测距，受夜间、逆光和雨雾影响大], [目标识别、车道线检测],
    [激光雷达], [直接得到三维点云，测距准，不依赖光照], [成本高，远处点云稀疏], [三维检测、定位建图],
    [毫米波雷达], [直接测出径向速度，能穿透雨雪雾], [点很少，难以分辨目标类别], [自适应巡航、盲区监测],
    [超声波雷达], [成本低，近距离可靠], [只能探测几米内的障碍物], [自动泊车],
  ), caption: [常用环境传感器的特点],
) <tab-sensors>

在第一次实践中，我试过把同一帧数据的激光雷达点和前向毫米波雷达点分别投影到前视图像上（@fig-sensors）。具体来说，落在图像范围内的激光雷达点有 2,983 个，车辆轮廓和路面都能看清。毫米波雷达点只有 48 个，集中在前方车辆和路侧物体附近，两者相差约 60 倍。

#figure(
  grid(columns: (1fr, 1fr), column-gutter: 6pt,
    sub("lidar_on_camera.png", [(a) 激光雷达点]),
    sub("radar_on_camera.png", [(b) 毫米波雷达点]),
  ),
  caption: [同一帧前视图像上的激光雷达与毫米波雷达投影对比],
) <fig-sensors>

因此，不同场景会选择不同的传感器组合。高速公路上的自适应巡航主要靠毫米波雷达测量前车的距离和速度，城市道路中的无人驾驶出租车则会同时搭载多个激光雷达、摄像头和毫米波雷达，以应对复杂的路口和行人。自动泊车距离近、速度低，用超声波雷达和环视摄像头就能完成。

在我的理解中，多传感器融合的意义在于互相补足。摄像头解决“是什么”的问题，激光雷达回答“在哪里、有多大”，毫米波雷达测量“速度多快”且在雨雾中仍能工作。

== 实际应用场景下的车辆控制全过程

以城区路口左转为例，整个过程可以分为四个阶段，见 @fig-leftturn。出发前，导航已经完成全局路径规划，确定车辆要在这个路口左转。至于何时变道、在哪里停车、何时起步，则由车上的系统在行驶中逐步决定。

#let stage(pos, title, body) = node(pos,
  align(center, {
    text(font: song, weight: "bold", size: 8.5pt, title)
    linebreak()
    text(size: 7.5pt, body)
  }), width: 32mm, shape: rect)
#figure(
  diagram(
    spacing: (5mm, 6mm),
    node-stroke: 0.6pt, node-inset: 5pt, node-corner-radius: 2pt,
    edge-stroke: 0.6pt, mark-scale: 70%,
    stage((0, 0), [① 接近路口], [感知 + 定位]),
    edge((0, 0), (1, 0), "-|>"),
    stage((1, 0), [② 变道停车], [预测 + 决策 \ 规划 + 控制]),
    edge((1, 0), (2, 0), "-|>"),
    stage((2, 0), [③ 绿灯让行], [感知 + 预测 \ 决策]),
    edge((2, 0), (3, 0), "-|>"),
    stage((3, 0), [④ 完成左转], [规划 + 控制]),
  ),
  caption: [城区路口左转的四个阶段],
) <fig-leftturn>

1. *接近路口。*摄像头识别出左转箭头和红灯，激光雷达和毫米波雷达测出周围车辆的位置与速度，感知模块据此输出目标列表。定位模块结合 GNSS、IMU 和高精地图，确定自车位于从左数第 2 条车道、距停止线约 100 m。

2. *变道停车。*预测模块判断左侧来车会先驶过变道位置，于是决策先让行，再变入左转车道，并在停止线前停车。轨迹规划会输出变道轨迹和减速曲线，控制模块按轨迹输出转向和制动指令。

3. *绿灯让行。*绿灯亮起后，感知发现对向有直行车辆，人行横道上还有行人。预测判断二者都会穿过自车的左转路线，决策选择在路口内等待。

4. *完成左转。*冲突消失后，规划生成左转轨迹，控制模块执行转向和加速，车辆驶出路口。

在这个左转的例子中，可以很明显看出模块之间的依赖关系。如果感知模块漏检一个行人，后面的预测和规划就无从考虑，导致一系列错误，误差会沿着链条向后传递。但其好处在于，模块化系统的每一步都能单独检查，问题容易定位。

= 自动驾驶环境感知算法与实践分析

== nuScenes 数据集的组成与作用

nuScenes 由 nuTonomy 发布，是第一个集成摄像头、激光雷达和毫米波雷达全套传感器的大规模自动驾驶数据集 \[#rl(1)\]，共包含 1000 个约 20 秒的驾驶场景，采集于美国波士顿和新加坡的城市道路，覆盖白天、夜间和雨天。

采集车装有 6 个摄像头（约 12 Hz，分辨率 $1600 times 900$）、1 个 32 线激光雷达（约 20 Hz）和 5 个毫米波雷达（约 13 Hz），另有 GPS 和 IMU 记录车辆位姿。关键帧以 2 Hz 的频率标注，共约 140 万个三维框，涉及 23 个目标类别，三维检测任务使用其中合并后的 10 个类别。

数据以关系表的形式组织，表之间通过 token 互相关联，主要关系见 @fig-schema。

#let snode(pos, name, body, n) = node(pos, align(center, {
    text(font: mono, size: 7.5pt, name); linebreak(); text(size: 7pt, body)
  }), name: n, width: 28mm, shape: rect)
#figure(
  diagram(
    spacing: (6mm, 5mm),
    node-stroke: 0.6pt, node-inset: 4pt, node-corner-radius: 2pt,
    edge-stroke: 0.6pt, mark-scale: 70%,
    snode((0, 1), [scene], [一段驾驶], <sc>),
    snode((1, 1), [sample], [关键帧], <sa>),
    snode((2, 1), [sample_data], [一次采集], <sd>),
    snode((3, 1), [samples/...], [图像或点云], <fi>),
    snode((2, 0), [calibrated_sensor], [内外参], <cs>),
    snode((3, 0), [ego_pose], [车辆位姿], <ep>),
    snode((1, 2), [sample_annotation], [三维框], <an>),
    snode((2, 2), [instance], [同一目标], <in>),
    snode((3, 2), [category], [类别], <ca>),
    edge(<sc>, <sa>, "-|>", label: text(size: 7pt)[约 40 个], label-side: left),
    edge(<sa>, <sd>, "-|>", label: text(size: 7pt)[12 路], label-side: left),
    edge(<sd>, <fi>, "-|>"),
    edge(<sd>, <cs>, "-|>"),
    edge(<sd>, <ep>, "-|>"),
    edge(<sa>, <an>, "-|>"),
    edge(<an>, <in>, "-|>"),
    edge(<in>, <ca>, "-|>"),
  ),
  caption: [nuScenes 主要数据表之间的关系],
) <fig-schema>

以一个 sample 为例。一个 *scene* 是约 20 秒的连续驾驶，按 2 Hz 取关键帧，大约包含 40 个 *sample*。每个 sample 的 data 字段里有 12 个 token，分别对应 6 路相机、1 个激光雷达和 5 个毫米波雷达。顺着其中 CAM_FRONT 的 token 找到 *sample_data*，就能得到这一时刻前视相机的图像文件。再通过这条 sample_data 关联的 *calibrated_sensor* 和 *ego_pose*，得到拍摄时的相机内外参和车辆位姿。@fig-mosaic 就是同一个 sample 下 6 路相机的 sample_data。

标注同样挂在 sample 上。每条 *sample_annotation* 是一个三维框，*instance* 把不同时刻的同一个目标串起来，再由 instance 指向 *category* 得到类别。图像、点云、标定、位姿和标注都能通过 token 找到彼此，点云投影到图像、三维框转换为二维框才得以实现。

#plot("camera_mosaic.jpg", [同一个 sample 下六路相机的图像], width: 92%) <fig-mosaic>

这个 nuScenes 数据集的作用主要体现在三方面。

*多传感器数据同步且标定完整。*视觉检测、激光雷达检测和多传感器融合可以在同一批场景上训练和比较，第二、三次实践正是在相同的验证帧上比较了 PETR 和 PointPillars。

*统一了评测指标。*三维检测的 mAP 按目标中心在地面上的距离（0.5、1、2、4 m 四个阈值）判断是否匹配，NDS 再把 mAP 与位置、尺寸、朝向、速度和属性五项误差合并为一个综合分数。用中心距离代替 IoU，是因为行人这类小目标的三维框稍有偏移，IoU 就会下降很多。

*场景差异明显。*新加坡车辆靠左行驶，波士顿靠右行驶，道路和天气也不同，这为研究模型的跨地区泛化提供了条件。第一次实践中，我就借助这个特性，额外补充完成了跨地区的实验。

== 二维与三维目标检测

=== 二维与三维检测的区别

*二维目标检测*在图像平面上定位目标，输出每个目标的类别和一个矩形框 $(x, y, w, h)$。*三维目标检测*在真实空间中定位目标，输出类别、中心坐标 $(x, y, z)$、长宽高和朝向角。

二者的根本区别在于是否需要深度信息。二维框只需要描述目标在画面中的位置，规划模块无法据此判断目标离车有多远。三维框多了深度，就直接给出目标在车体坐标系中的位置和大小。

第一次实践做数据转换时，我仔细看过这部分代码。把三维框转换成二维框，只需用相机参数投影 8 个角点，再取外接矩形。反过来，从二维框恢复三维框却缺少深度，同一个二维框既可能是远处的大车，也可能是近处的小车。

所以，三维检测要么借助激光雷达直接测距，要么让模型从多视角图像中推断深度。下面介绍四种方法，见 @fig-pipelines。

#let pipeline-rows = (
  ([YOLO], ([单张图像], [一次前向计算], [多尺度特征], [二维框与类别]), 1),
  ([PointPillars], ([激光雷达点云], [划分柱体并编码], [伪图像 + 二维卷积], [三维框]), 1),
  ([BEVFormer], ([多帧多相机图像], [图像特征], [鸟瞰图查询 \ + 时序融合], [三维框]), 2),
  ([PETR], ([多相机图像], [图像特征 \ + 三维位置编码], [目标查询解码], [三维框]), 1),
)
#let pipeline-items = {
  let items = ()
  for (y, row) in pipeline-rows.enumerate() {
    let (label, steps, hi) = row
    items.push(node((0, y), text(font: song, weight: "bold", size: 8.5pt, label), stroke: none, width: 20mm))
    for (i, body) in steps.enumerate() {
      items.push(node((i + 1, y), align(center, text(size: 7.5pt, body)),
        fill: if i == hi { luma(232) } else { none }, width: 28mm, shape: rect))
      if i > 0 { items.push(edge((i, y), (i + 1, y), "-|>")) }
    }
  }
  items
}
#figure(
  diagram(
    spacing: (4mm, 3.5mm),
    node-stroke: 0.6pt, node-inset: 4pt, node-corner-radius: 2pt,
    edge-stroke: 0.6pt, mark-scale: 70%,
    ..pipeline-items,
  ),
  caption: [四种检测方法的处理流程],
) <fig-pipelines>

=== YOLO

YOLO 是单阶段的二维检测器 \[#rl(5)\]。整张图像输入卷积网络后，网络提取出几种不同分辨率的特征图：分辨率高的特征图负责小目标，分辨率低的负责大目标。特征图上的每个位置都会同时预测三件事：这里是否有目标、目标属于哪一类、目标框的位置和大小。YOLO11 不再预设锚框，直接预测该位置到目标框四条边的距离。最后用非极大值抑制去掉重叠的框，得到检测结果。

- *优势*：只需一次前向计算就能得到全部目标，速度快，适合实时运行和车端部署。
- *不足*：只输出二维框，远处的小目标占的像素少，容易漏检。第一次实践中远处行人和自行车漏检较多，正是这个原因。

=== PointPillars

PointPillars 以激光雷达点云为输入 \[#rl(2)\]，核心思路是把三维点云变成一张“图像”，再借用成熟的二维检测网络。具体分三步：

+ 在俯视平面上把空间划分为网格，同一网格内、从地面到高处的所有点组成一个竖直的柱体（pillar）。
+ 用一个小型点特征网络处理每个柱体里的点，把它们汇总成一个固定长度的特征向量。
+ 按网格位置把这些特征向量排成一张伪图像，用二维卷积网络提取特征，检测头再输出三维框的中心、长宽高和朝向。

- *优势*：只用二维卷积，速度快，而且激光雷达直接测距，三维位置准确。
- *不足*：依赖成本较高的激光雷达。远处点云稀疏，竖直方向又被压缩进一个柱体，行人等细小目标的细节容易丢失。第三次实践微调后，pedestrian 的 AP 仍接近零。

=== BEVFormer

BEVFormer 以多相机图像为输入 \[#rl(4)\]，先构建一张车辆周围的鸟瞰图（BEV）特征，再在鸟瞰图上检测目标。

鸟瞰图被划分为网格，每个网格对应一个查询。对每个查询，网络在该位置取几个不同的高度，把这些三维点投影到相机图像上，只到投影落在的那几个视图中采样特征，这一步称为空间交叉注意力。随后，时序自注意力把上一时刻的鸟瞰图特征按自车运动对齐后融合进来。得到鸟瞰图特征后，检测头输出三维框。

- *优势*：各视角统一到同一张鸟瞰图上，便于和激光雷达融合，也方便下游规划使用。利用历史帧后，速度估计更准，被遮挡的目标也更容易补全。
- *不足*：计算量和显存占用大，深度仍要靠网络从图像中学习，需要大量数据。

=== PETR

PETR 同样以多相机图像为输入 \[#rl(3)\]，但不构建鸟瞰图，做法是让图像特征直接带上三维位置信息。

核心是三维位置编码。对图像特征图上的每个像素，沿相机视线在一组深度上取点，再用相机内外参把这些点转换到统一的车体坐标系，编码后加到图像特征上。这样，每个像素的特征都“知道”自己可能对应空间中的哪些位置。之后，一组目标查询（课程配置中为 100 个）通过 Transformer 解码器与六路相机的特征交互，每个查询直接输出一个三维框，不需要非极大值抑制。

- *优势*：结构简洁，不需要构建稠密的鸟瞰图，计算量相对较小。
- *不足*：深度完全由网络隐式学习，对数据量的依赖很大。原版只用当前帧，速度估计也较弱。第二次实践只有 323 帧训练数据，效果很差，与这一点直接相关。

== 视觉与激光雷达检测结果的比较

三次感知实践的结果见 @tab-practice。

#figure(
  tbl(columns: (14mm, 34mm, 20mm, 18mm, 1fr, 1fr),
    [实践], [方法], [传感器], [任务], [mAP], [NDS],
    table.hline(stroke: 0.5pt),
    [第一次], [YOLO11n], [前视相机], [二维检测], [0.288（mAP50–95）], [—],
    [第二次], [PETR，第 20 轮], [六路相机], [三维检测], [0.000102], [0.0256],
    [], [PETR，第 40 轮], [六路相机], [三维检测], [0.000082], [0.0228],
    [第三次], [PointPillars，微调前], [激光雷达], [三维检测], [0.000061], [0.0261],
    [], [PointPillars，微调后], [激光雷达], [三维检测], [0.0614], [0.1181],
  ), caption: [三次感知实践的检测结果],
) <tab-practice>

对于二维检测，YOLO 在 One-North 测试集上对车辆的检测比较稳定，car、truck 和 bus 在混淆矩阵中的正确率都在 80% 左右，远处的小行人、自行车，以及交通锥、隔离栏等小目标漏检较多。

对于三维检测，PETR 和 PointPillars 在同一组验证帧上的 mAP 相差两个数量级以上。从俯视图看（@fig-3d），PETR 的预测框大多偏离真实目标，续训到 40 轮后整体移到了另一侧。PointPillars 微调后，已有部分车辆的预测框与真实框基本重合，但仍有误检和漏检。

#figure(
  grid(columns: (0.62fr, 0.62fr, 1.76fr), column-gutter: 5pt, align: bottom,
    sub("petr20_scene0103_bev.png", [(a) PETR 第 20 轮]),
    sub("petr40_scene0103_bev.png", [(b) PETR 第 40 轮]),
    sub("pointpillars_fixed_samples.svg", [(c) PointPillars 微调后的三帧]),
  ),
  caption: [视觉与激光雷达三维检测结果的俯视图],
) <fig-3d>

如果只看这组数字，很容易得出“激光雷达远好于摄像头”的结论。但两次实验的起点并不相同：PointPillars 用的是官方训练好的完整模型，PETR 只有图像骨干网络的预训练权重，检测部分从零开始。两者的训练条件见 @tab-confound。

#figure(
  tbl(columns: (26mm, 1fr, 1fr),
    [对比项], [PETR（第二次实践）], [PointPillars（第三次实践）],
    table.hline(stroke: 0.5pt),
    [预训练内容], [只有 ResNet50 图像骨干], [完整检测模型（含检测头）],
    [检测头的起点], [随机初始化], [已在完整 nuScenes 上训练（约 2.8 万帧）],
    [本次训练数据], [323 帧], [323 帧],
    [本次训练方式], [整个网络训练 20 轮，续训至 40 轮], [冻结骨干，只微调检测头 5 轮],
    [输入设置], [图像缩小到 $192 times 512$], [单帧点云，$50 times 50$ m 范围],
  ), caption: [两次三维检测实践的训练条件],
) <tab-confound>

最关键的是前两行的差异。PointPillars 的检测头已经在约 2.8 万帧完整数据上学会了检测，PETR 的检测头则要用 323 帧从零学起，可用的数据相差近百倍。两个模型自身的变化也说明了这一点。PointPillars 不训练时 NDS 只有 0.026，与 PETR 相当，只微调检测头 5 轮就升到 0.118。PETR 续训到第 40 轮，训练损失仍在下降，验证指标却低于第 20 轮，这就是数据不足导致的过拟合。

*发现这个问题后，我查阅了三种方法的原论文*，对比它们在完整 nuScenes 测试集上的结果，见 @tab-paper。在数据充足时，两种纯视觉方法的指标都超过了 PointPillars，与本次实践的结果正好相反。

#figure(
  tbl(columns: (30mm, 30mm, 28mm, 1fr, 1fr),
    [方法], [传感器], [骨干网络], [mAP], [NDS],
    table.hline(stroke: 0.5pt),
    [PointPillars \[#rl(1)\]], [激光雷达], [—], [30.5%], [45.3%],
    [PETR \[#rl(3)\]], [六路相机], [VoVNet-99], [44.1%], [50.4%],
    [BEVFormer \[#rl(4)\]], [六路相机（多帧）], [VoVNet-99], [48.1%], [56.9%],
  ), caption: [原论文在完整 nuScenes 测试集上的结果],
) <tab-paper>

我也估算了在本地补做这项对比的代价。第二次实践中，PETR 在课程配置下每个训练样本约需 0.34 s，完整训练集约 2.8 万个样本，训练一轮约 2.7 小时，按原论文训练 24 轮需要两天半以上。换成原论文的输入分辨率，显存占用和训练时间还会成倍增加，本机 8 GB 显存的显卡难以承担。

*虽然本次实践无法在同等条件下比较，但结合原理和论文数据，仍然可以得到一个判断。*激光雷达直接测得距离，三维定位的难度低，数据少时更容易学好。纯视觉方法要从图像中推断深度，依赖大规模数据、更强的骨干网络和多帧信息，数据充足时可以追上甚至超过 PointPillars。不过论文中的对比也不完全对等，两种视觉方法用了更大的骨干网络，而 PointPillars 是较早的激光雷达方法，之后的 CenterPoint 等激光雷达方法精度仍明显更高。所以两类方法谁更好，取决于数据规模和方法本身，不能由一次课程实验下结论。

== 复杂道路环境下的问题与改进思路

=== 实践中发现的问题

我在四次实践中发现的问题主要有三点。

*第一，模型跨城市的泛化性不足*，换一个城市效果就会变差。第一次实践中，我用 One-North 训练的 YOLO 模型测试了其余三个地区。新加坡另外两个地区的 mAP50–95 与 One-North 接近，波士顿则降到 0.071，召回率不到 0.2。原因可能是波士顿的测试图像中有大量雨天画面，而且车辆靠右行驶，道路、建筑和车型都与新加坡不同。

*第二，夜间和雨天的影响更大。为了把光照、天气的影响和地区差异分开，我额外补充了一组测试。*我按照 nuScenes 提供的场景描述，把各地区测试集分为雨天和非雨天两组，再用课程转换程序的规则，把 99 个夜间场景转换成 2,768 张带标签的图像，用同一个模型评估（@fig-conditions）。新加坡另外两个地区白天的 mAP50–95 为 0.257，到了夜间只有 0.010，召回率约 3%。波士顿雨天比非雨天又低了约三分之一。这说明光照变化对纯视觉检测的影响比换一个城市更大，换到波士顿时召回率还能保留白天的四成左右，到了夜间只剩约 6%。

#plot("yolo_conditions.svg", [YOLO11n 在不同光照和天气条件下的测试结果], width: 88%) <fig-conditions>

从 @fig-night-rain 的例子看，夜间画面中的车辆只剩尾灯和模糊的轮廓，模型一个也没有检出。雨天画面中，模型检出了近处的汽车和两个行人，左侧人行道上的一排行人和远处的目标都被漏掉了。

#figure(
  grid(columns: (1fr, 1fr), column-gutter: 6pt, row-gutter: 6pt,
    sub("yolo_rain_gt.jpg", [(a) 波士顿雨天，真实标签]),
    sub("yolo_rain_pred.jpg", [(b) 波士顿雨天，模型预测]),
    sub("yolo_night_gt.jpg", [(c) 新加坡夜间，真实标签]),
    sub("yolo_night_pred.jpg", [(d) 新加坡夜间，模型预测（无检出）]),
  ),
  caption: [雨天与夜间的检测示例],
) <fig-night-rain>

*第三，远处、被遮挡和少见的目标容易漏检。*YOLO 对远处的行人和自行车漏检较多。第三次实践微调后，只有 car 和 bus 的 AP 明显提升，工程车辆、拖车等样本很少的类别仍未被检出。激光雷达点云随距离迅速变稀，第三次实践为了在本机运行，还只检测了 50 m 范围内的目标。

这些问题在日常出行中也很常见。夜间对向车灯的眩光、隧道出入口的明暗突变、从违停车辆后面突然走出的行人，对人类驾驶员同样是难点，对只用摄像头的模型就更难了。

=== 相关研究中的结论

*为了确认这些问题是否普遍，我查阅了两篇专门研究感知鲁棒性的论文。*

第一篇是 Dong 等人发表在 CVPR 2023 的 _Benchmarking Robustness of 3D Object Detection to Common Corruptions_ \[#rl(11)\]。作者针对激光雷达和相机输入设计了 27 种常见的数据损坏，分为天气、传感器、运动、目标和传感器对齐五大类，例如雨雪雾、点云缺失、运动模糊和传感器之间的时间不同步。作者把这些损坏合成到 KITTI、nuScenes 和 Waymo 上，建立了 KITTI-C、nuScenes-C、Waymo-C 三个基准，测试了 24 个三维检测模型。论文的主要结论有三条。运动类损坏对所有模型的影响最大，激光雷达模型和融合模型在部分运动类损坏下的性能下降超过 50%。激光雷达与相机融合的模型整体更稳健。纯视觉模型对图像损坏极其敏感，作者据此认为激光雷达点云不可或缺。

第二篇是 Xie 等人的 _RoboBEV: Towards Robust Bird's Eye View Perception under Corruptions_ \[#rl(12)\]，专门研究纯视觉 BEV 模型。作者在 nuScenes 上模拟了三类共 8 种损坏，包括变亮、变暗、雾、雪四种恶劣环境，运动模糊和颜色量化两种图像失真，以及某路相机失效、某些帧丢失两种相机故障，每种损坏分为三个强度。评价指标之一是 mRR，即损坏条件下的 NDS 占原始 NDS 的比例。@tab-robobev 摘录了论文中与本课程相关的两个模型。

#figure(
  tbl(columns: (26mm, 16mm, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
    [模型], [原始 NDS], [变暗], [雪], [运动模糊], [相机失效], [雾], [变亮],
    table.hline(stroke: 0.5pt),
    [BEVFormer-Base], [0.517], [48.6%], [35.9%], [52.1%], [61.0%], [78.6%], [80.9%],
    [PETR-R50], [0.367], [42.9%], [38.7%], [62.7%], [63.3%], [78.5%], [77.5%],
  ), caption: [RoboBEV 中两个模型在各类损坏下保留的性能（mRR）\[#rl(12)\]],
) <tab-robobev>

可以看到，变暗和下雪对这两个纯视觉模型的影响最大，PETR 在变暗条件下只保留了约四成的性能。论文还发现，原始精度相近的模型在损坏下表现差别很大，预训练和不依赖显式深度估计的鸟瞰图转换方式能提升鲁棒性，融合更长的历史帧则有助于应对相机失效和丢帧。

两篇论文与我的观察是一致的。我的夜间测试中，YOLO 的 mAP50–95 只保留了白天的约 4%，虽然指标和模型都不同，但都说明光照变暗是纯视觉感知最难应对的情况之一。

=== 改进思路

结合实践和调研，我认为最值得做的有三点。

*第一，多传感器融合。*补充测试中，摄像头模型在夜间几乎失效，而激光雷达和毫米波雷达主动发射信号，不受光照影响，上面的研究也说明融合模型更稳健 \[#rl(11)\]。BEVFusion 等方法把相机和激光雷达的特征都转换到鸟瞰图上再融合 \[#rl(10)\]，比只在最后合并检测框保留了更多信息。对成本敏感的车型，即使只有摄像头和毫米波雷达，雷达也能在夜间提供前方目标的距离和速度。

*第二，针对困难场景补充数据。*我的模型在夜间失效，最直接的原因是训练数据里没有夜间图像。nuScenes 本身就有 99 个夜间场景，把其中一部分加入训练或用来微调，再配合降低亮度、模拟雨滴等数据增强，就能有针对性地补上这块短板。实际系统中，这一步通常由数据闭环完成，车队自动收集模型表现不好的片段，标注后用于下一轮训练。

*第三，利用时序信息。*第二、三次实践都只用了当前帧，被遮挡的目标在这一帧里就无从检测。BEVFormer 融合历史鸟瞰图特征后，速度估计和低可见度目标的召回率都有提升 \[#rl(4)\]，RoboBEV 也发现更长的时序信息有助于提升鲁棒性 \[#rl(12)\]。

= 规划决策与端到端自动驾驶综合分析

== 定位、路径规划与驾驶决策

=== 定位

*定位*解决“车在哪里”的问题，实时估计车辆的位置、速度和姿态。常用的定位源各有长处和短板：

- *GNSS*：提供全局位置，RTK 差分后可达厘米级，但在隧道、高架桥下和高楼之间，信号会被遮挡或反射。
- *IMU*：更新频率高、不受外界干扰，但误差会随积分不断累积。
- *轮速计*：可以估计行驶距离，但车轮打滑时会失真。
- *激光雷达或视觉 SLAM*：把当前观测与地图对齐来校正位置，但在重复结构、空旷场景中容易匹配失败。

没有哪一种定位源永远可靠，所以实际系统会用卡尔曼滤波或因子图优化把它们融合起来，同时给出定位结果的可信程度。nuScenes 每帧数据附带的 ego_pose 就是这一过程的结果，第一次实践正是依靠 ego_pose，才把不同时刻、不同传感器的数据统一到同一个坐标系下。

=== 路径规划

路径规划分为两层：

- *全局路径规划*：基于道路地图，寻找从起点到终点的路线，更新频率较低。常用 Dijkstra 和 A\* 等图搜索算法，A\* 在已知代价之外加入到终点距离的估计，比 Dijkstra 搜索得更快。RRT 等采样算法适合高维空间，但路径不够平滑。
- *局部轨迹规划*：以全局路线为参考，根据实时感知结果，生成未来几秒内可执行的轨迹，包含位置和速度，并且高频更新。

=== 驾驶决策与控制

*驾驶决策*决定当前应采取的动作，例如跟车、变道、在路口停车或让行。传统方法常用有限状态机，人工设计状态之间的转换条件。遇到行人和非机动车意图不明时，决策应偏向保守。

*控制*模块执行规划结果。纵向控制调节油门和制动，常用 PID 控制器，横向控制调节方向盘，常用纯跟踪和模型预测控制（MPC）。第四次实践的油门公式 $t = 1.2 - hat(s)^2 - (v slash 10)^2$ 就是一个简单的纵向控制器，车速接近 10 mph 或转角较大时，油门会自动减小。

== 端到端自动驾驶与模块化系统的区别

=== 什么是端到端自动驾驶

*端到端自动驾驶*用一个整体训练的神经网络，从传感器输入直接得到驾驶输出。输出可以是方向盘转角和油门，也可以是一段规划轨迹。网络中间没有人为规定的接口，驾驶表现通过模仿人类驾驶数据或在仿真中试错来整体优化。

NVIDIA 在 2016 年发表的工作是早期的代表 \[#rl(6)\]，第四次实践复现的就是这一网络，输入一张道路图像，输出一个方向盘转角。@fig-e2e 把这一网络和模块化系统、一般的端到端系统放在一起对比。

#figure(
  diagram(
    spacing: (5mm, 3.6mm),
    node-stroke: 0.6pt, node-inset: 4.5pt, node-corner-radius: 2pt,
    edge-stroke: 0.6pt, mark-scale: 70%,
    node((0, 0), text(font: song, weight: "bold", size: 8.5pt)[模块化], stroke: none),
    box-node((1, 0), [传感器], name: <a0>),
    box-node((2, 0), [感知], name: <a1>),
    box-node((3, 0), [定位 · 预测], name: <a2>),
    box-node((4, 0), [规划决策], name: <a3>),
    box-node((5, 0), [控制], name: <a4>),
    box-node((6, 0), [车辆], name: <a5>),
    edge(<a0>, <a1>, "-|>"),
    edge(<a1>, <a2>, "-|>", label: text(size: 7pt)[目标列表], label-side: left),
    edge(<a2>, <a3>, "-|>", label: text(size: 7pt)[位姿 · 轨迹], label-side: left),
    edge(<a3>, <a4>, "-|>", label: text(size: 7pt)[规划轨迹], label-side: left),
    edge(<a4>, <a5>, "-|>", label: text(size: 7pt)[控制量], label-side: left),
    node((0, 1.5), text(font: song, weight: "bold", size: 8.5pt)[端到端], stroke: none),
    box-node((1, 1.5), [传感器], name: <b0>),
    node(enclose: ((2, 1.5), (4, 1.5)), align(center)[#text(font: song, weight: "bold", size: 8.5pt)[统一的神经网络]], name: <b1>, fill: luma(232)),
    box-node((5, 1.5), [轨迹 / 控制量], name: <b2>),
    box-node((6, 1.5), [车辆], name: <b3>),
    edge(<b0>, <b1>, "-|>"),
    edge(<b1>, <b2>, "-|>"),
    edge(<b2>, <b3>, "-|>"),
    node((0, 3.0), text(font: song, weight: "bold", size: 8.5pt)[实践四], stroke: none),
    box-node((1, 3.0), [中心相机], name: <c0>),
    node(enclose: ((2, 3.0), (4, 3.0)), align(center)[#text(font: song, weight: "bold", size: 8.5pt)[NVIDIA CNN]], name: <c1>),
    box-node((5, 3.0), [转角], name: <c2>),
    box-node((6, 3.0), [模拟器], name: <c3>),
    edge(<c0>, <c1>, "-|>"),
    edge(<c1>, <c2>, "-|>"),
    edge(<c2>, <c3>, "-|>"),
  ),
  caption: [模块化与端到端自动驾驶的架构对比],
) <fig-e2e>

近几年的端到端系统大多输出未来几秒的轨迹，按生成轨迹的方式大致可以分为三类：

- *基于查询*：网络中设置一组查询向量，分别提取周围车辆、地图等信息，最后汇总输出轨迹，代表工作是 UniAD \[#rl(8)\] 和 VAD。
- *基于自回归*：像语言模型逐字生成句子一样，逐个时间点生成轨迹，常与视觉语言模型结合。
- *基于扩散模型*：从一条随机的“噪声轨迹”出发，逐步修正成合理的轨迹，可以给出多种可能的结果。

=== 与模块化系统的比较

下面从系统架构、工作原理和应用特点三个角度比较两者，主要区别汇总在 @tab-compare 中。

#figure(
  tbl(columns: (18mm, 22mm, 1fr, 1fr),
    [角度], [对比项], [模块化系统], [端到端系统],
    table.hline(stroke: 0.5pt),
    table.cell(rowspan: 2)[系统架构], [组成], [感知、定位、预测、规划、控制等多个模块串联], [一个网络从传感器输入直接到驾驶输出],
    [模块接口], [人工定义，如目标列表、预测轨迹], [网络内部自行学习],
    table.hline(stroke: 0.3pt),
    table.cell(rowspan: 2)[工作原理], [优化方式], [各模块分别优化自己的指标], [以最终驾驶效果整体优化],
    [决策依据], [人工规则和优化算法], [从人类驾驶数据中学习],
    table.hline(stroke: 0.3pt),
    table.cell(rowspan: 2)[应用特点], [解释与验证], [可以逐个模块检查和验证], [难以解释，需要额外的安全兜底],
    [应对新场景], [需要人工新增规则], [需要补充训练数据],
  ), caption: [模块化系统与端到端系统的比较],
) <tab-compare>

*从系统架构看*，模块化系统由多个模块串联而成，模块之间传递的是人工定义的中间结果，比如检测框列表和预测轨迹。端到端系统只有一个网络，中间表示由网络自己学习，原始图像中的信息可以一直传到决策环节。代价是中间结果不再直观，信息在接口处丢失的问题也换成了“看不见网络内部”的问题。

*从工作原理看*，模块化系统的各个模块分别训练、分别优化，规划和决策主要依靠人工规则和优化算法。端到端系统以最终的驾驶效果为目标整体训练，驾驶行为是从大量人类驾驶数据中学出来的，第四次实践就是用人类驾驶时记录的转角作为监督信号。

*从应用特点看*，模块化系统出了问题可以逐个模块排查，也便于按模块做安全验证，因此限定区域内的无人驾驶出租车仍以模块化为主。端到端系统更容易随数据规模提升性能，遇到新场景时补充数据就行，不必再人工写规则，但决策过程难以解释和验证，实际产品通常还要保留规则化的安全兜底。

=== 结合实践的体会

结合第四次实践和补充测试，我有三点体会。

*第一，模仿学习会遇到分布偏移。*网络学的是人类在正常行驶时的操作，训练数据里的车大多位于车道中央。一旦模型自己开车，转角的一点误差就会让车偏离中心，看到训练时没见过的画面，误差可能越积越大。

第四次实践给左右相机图像分别加上 +0.4 和 −0.4 的转角修正，相当于告诉模型“车偏到这里时应该往回打方向”。我查阅资料时发现，这与模仿学习中 DAgger 方法“为模型自己会遇到的状态补充正确标签”的思路一致 \[#rl(7)\]。

训练数据的分布还会带来“惯性问题”。数据中直行和匀速的样本很多，模型容易倾向于保持当前状态。第四次实践的转角标签同样集中在零附近，补充测试中选取的两个急转弯帧，标签为 ±1.0，模型的预测只有 −0.48 和 +0.14，明显偏向直行。

*第二，开环指标不能代表闭环表现。*开环评测只看录好的数据，比较模型预测和人类操作差多少，并不真正控制车辆。闭环评测则让模型在仿真环境中真正开车，环境会随车辆动作变化。

第四次实践训练到第 38 轮时，验证 MSE 已基本不再下降（@fig-loss），这只说明模型在固定图像上预测得有多准。真正的检验是模拟器中的闭环运行，加载第 38 轮权重后，车辆在 Lake Track 连续行驶了 182.8 秒。我在查阅资料时还看到一项研究 \[#rl(9)\]，在 nuScenes 上仅利用自车速度等状态信息，就能取得接近的开环规划分数，这也是 NAVSIM、CARLA 等闭环评测越来越受重视的原因。

#plot("loss_curves.svg", [第四次实践的训练与验证 MSE], width: 72%) <fig-loss>

*第三，端到端模型对输入变化很敏感，而且很难看出依据。为了验证这一点，我额外做了两组测试。*

第一组在全部 6,489 张中心相机验证图像上，施加降低亮度、路面阴影、局部遮挡、模拟雨滴和模糊等变化，比较转角预测的变化（@fig-perturb）。路面上加一块阴影，预测转角平均改变 0.24，七成图像的变化超过 0.1，已经与模型本身 0.20 的平均误差相当。训练数据来自光照固定的模拟赛道，模型没见过阴影和昏暗的画面，这与 YOLO 在夜间失效是同一类问题。

#figure(
  stack(spacing: 6pt,
    grid(columns: (1fr,) * 5, column-gutter: 3pt,
      sub("e2e_example_original.png", [原图]),
      sub("e2e_example_dark_0.5.png", [亮度 ×0.5]),
      sub("e2e_example_shadow.png", [路面阴影]),
      sub("e2e_example_occlusion.png", [局部遮挡]),
      sub("e2e_example_rain.png", [模拟雨天]),
    ),
    image("figures/e2e_perturbation.svg", width: 90%),
  ),
  caption: [端到端模型在图像变化下的转角预测变化],
) <fig-perturb>

第二组是遮挡敏感度分析，用一个灰色方块依次遮住图像的不同位置，看转角预测变化多大（@fig-sensitivity）。转弯时，敏感区域主要在车道线和道路边缘附近，说明模型确实学到了沿车道行驶的线索。但这种分析只能事后解释单张图像，不像模块化系统那样可以直接检查检测框和车道线，这就是端到端模型“黑盒不可解释”的问题。

#plot("e2e_sensitivity.svg", [端到端模型的遮挡敏感度], width: 86%) <fig-sensitivity>

=== 工业界的做法

*为了了解实际系统怎么做，我查阅了几家公司的公开资料和相关论文*，发现它们的路线并不相同。

#plot("uniad_pipeline.png", [UniAD 的整体结构 \[#rl(8)\]]) <fig-uniad>


UniAD 是学术界最有代表性的工作 \[#rl(8)\]，获得了 CVPR 2023 最佳论文奖。UniAD 以多相机图像为输入，先得到鸟瞰图特征，再依次接上跟踪（TrackFormer）、在线建图（MapFormer）、运动预测（MotionFormer）、占用预测（OccFormer）和规划（Planner）五个模块，结构见 @fig-uniad。图中的 Track Q、Map Q 等是各模块的查询，B 表示鸟瞰图特征，模块之间通过查询传递信息。这些模块之间传递的是查询向量，没有检测框这样的人工中间结果，整个网络以规划为最终目标联合训练。UniAD 的思路介于模块化和端到端之间，保留了可以检查的中间结果，又能整体优化。

特斯拉走的是更彻底的端到端路线。从 FSD V12 开始，城市道路驾驶改由一个端到端神经网络完成，取代了原先 30 多万行手写的 C++ 规则代码，网络从数百万段驾驶视频中学习，直接输出转向和加减速等控制 \[#rl(15)\]。不过这套系统目前仍属于需要驾驶员监督的辅助驾驶。

理想汽车采用“端到端模型 + 视觉语言模型”的双系统方案，于 2024 年 10 月全量推送 \[#rl(16), #rl(17)\]。端到端模型相当于快速反应的“系统 1”，负责大部分常规驾驶。视觉语言模型相当于慢思考的“系统 2”，参数量约 22 亿，用来理解 ETC 车道、公交车道、潮汐车道等需要结合语义的复杂场景，再把判断交给端到端模型。

从这三个例子可以看出，实际系统多在模块化和端到端之间寻找平衡，越接近量产，越需要可解释的中间结果和安全兜底。

== 行人横穿马路场景分析

假设车辆以 40 km/h 在城市道路上行驶，前方有行人从路边走出，准备横穿马路。@fig-ped 对比了两种系统的处理方式。

#let pnode(pos, title, body: none, name: none, fill: none, width: 26mm) = node(pos,
  align(center, {
    text(font: song, weight: "bold", size: 8pt, title)
    if body != none { linebreak(); text(size: 7pt, body) }
  }), name: name, fill: fill, width: width, shape: rect)
#figure(
  diagram(
    spacing: (4mm, 7mm),
    node-stroke: 0.6pt, node-inset: 4pt, node-corner-radius: 2pt,
    edge-stroke: 0.6pt, mark-scale: 70%,
    node((0, 0), text(font: song, weight: "bold", size: 8.5pt)[模块化], stroke: none, width: 14mm),
    pnode((1, 0), [感知], body: [检测与跟踪], name: <m1>),
    pnode((2, 0), [预测], body: [行人轨迹], name: <m2>),
    pnode((3, 0), [决策与规划], body: [让行减速], name: <m3>),
    pnode((4, 0), [控制], body: [制动], name: <m4>),
    edge(<m1>, <m2>, "-|>"), edge(<m2>, <m3>, "-|>"), edge(<m3>, <m4>, "-|>"),
    edge(<m1>, (1, -0.75), (4, -0.75), <m4>, "--|>", label: text(size: 7pt)[AEB 兜底], label-side: left),
    node((0, 1), text(font: song, weight: "bold", size: 8.5pt)[端到端], stroke: none, width: 14mm),
    pnode((1, 1), [多帧图像], name: <e1>),
    node(enclose: ((2, 1), (3, 1)), align(center, text(font: song, weight: "bold", size: 8pt)[端到端网络]), name: <e2>, fill: luma(235), shape: rect),
    pnode((4, 1), [减速轨迹], name: <e3>),
    edge(<e1>, <e2>, "-|>"), edge(<e2>, <e3>, "-|>"),
  ),
  caption: [两种系统处理行人横穿的方式],
) <fig-ped>

=== 模块化系统

模块化系统按以下顺序处理：

+ *感知*：摄像头识别出行人，激光雷达给出位置和轮廓，毫米波雷达测得相对速度，系统再在连续多帧中跟踪行人的运动方向。
+ *定位*：确定自车所在车道和与人行横道的距离，把行人位置转换到同一坐标系中。
+ *预测与决策*：预测行人未来几秒会进入自车车道，决策让行，规划生成在冲突点前停下的减速曲线。
+ *控制*：把减速度要求转换为制动指令，由线控底盘执行。

除了这条主链路，大多数车辆还配有独立的自动紧急制动（AEB）系统，在主系统来不及反应时作为最后一道保护。

这个场景的关键是时间。*为了直观说明延迟的影响，我按简化的匀减速模型估算了停车距离*（@fig-stop）。在 40 km/h 时，0.5 s 的系统延迟对应约 16 m 的停车距离，1.5 s 的人类反应时间则需要约 27 m。车速升到 60 km/h，两者分别增加到约 31 m 和 48 m。第四次实践中模型单帧推理只需约 2.4 ms，但那只是一路低分辨率图像和一个小网络，真实系统要处理多路相机和激光雷达，延迟控制难得多。

#plot("stopping_distance.svg", [不同车速下的停车距离估算，系统延迟取 0.5 s，人类反应时间取 1.5 s，减速度取 6 m/s²], width: 80%) <fig-stop>

=== 端到端系统

工业界的端到端系统通常以多路相机的连续多帧图像为输入，输出包含速度信息的轨迹。行人横穿是城市驾驶中很常见的场景，人类驾驶数据里有大量减速让行的示范，网络可以直接学会“看到有人要过马路就减速”，不必先输出检测框、再由规则决定减速。实际系统通常还保留基于规则的安全层和 AEB，在网络输出明显不安全时进行干预。

要做到这一点，网络必须看到连续多帧图像来判断行人的运动方向，训练数据中也要有大量行人交互的场景。像孩子从停放车辆之间突然跑出这类数据难以覆盖的情况，仍要依靠规则化的安全机制兜底。

== 对自动驾驶发展现状、问题与方向的认识

=== 从身边看到的现状

自动驾驶已经实实在在地出现在城市道路上。武汉是百度萝卜快跑运营规模最大的城市之一，市民可以在服务区域内乘坐没有安全员的无人驾驶出租车。我去过北京亦庄，那里是全国首个高级别自动驾驶示范区，多家企业的车辆在公开道路上测试和运营。

量产乘用车上的智能驾驶则是另一种情况。自适应巡航、车道保持和城市领航辅助（NOA）已经很常见，但都需要驾驶员全程监控。我试驾小米 YU7 时也感到，这款车的智能驾驶功能尚不够成熟，仍有改进空间。

=== 调研中的认识

按照 SAE J3016 标准，自动驾驶分为 L0 到 L5 六个等级，核心区别是驾驶责任由谁承担。L0 到 L2 属于辅助驾驶，由驾驶员负责。L3 及以上属于自动驾驶，系统在设计运行范围内负责。身边的两类产品正好对应两条路线，无人驾驶出租车是限定区域内的 L4，乘用车上的功能仍是 L2。

*下面是我了解的行业发展现状。*

*运营规模。*据新华网报道，截至 2025 年 11 月，萝卜快跑每周的全无人驾驶订单已超过 25 万单，累计服务超过 1700 万次 \[#rl(13)\]。限定区域内的 L4 已经从示范走向规模化运营，开始需要考虑单车成本和盈利。

*安全表现。*Waymo 在 2025 年发表的研究中，把 5670 万英里的全无人驾驶里程与同区域人类驾驶员的基准对比 \[#rl(18)\]。无论责任在哪一方，涉及行人受伤的碰撞减少了 92%，疑似重伤及以上的碰撞减少了 85%。这说明在限定区域、充分验证的条件下，L4 系统已经可以比人类驾驶员更安全。

*法规。*北京市自动驾驶汽车条例于 2025 年 4 月 1 日起施行 \[#rl(19)\]，支持 L3 及以上自动驾驶汽车用于个人乘用车、出租车、公交等出行服务，同时要求试点企业配备安全员和平台安全监控人员，并对数据安全和事故处置作出规定。法规开始为 L3 及以上车辆上路提供依据，但责任认定仍是讨论的焦点。

*验证方法。*RAND 的研究估算，要以 80% 的置信度证明自动驾驶的致死率比人类低 20%，需要约 110 亿英里的测试，即使 100 辆车不间断行驶也要 500 多年 \[#rl(14)\]。Waymo 的 5670 万英里在其中只占很小一部分，所以仅靠道路里程无法证明安全，仿真测试和针对性的场景测试必不可少。这也是世界模型受到关注的原因之一，世界模型可以生成真实世界中很难采集的危险场景。

=== 我的看法

我认为当前最突出的问题是*长尾场景和分布外泛化*。

*这个问题指的是什么。*驾驶中遇到的场景分布很不均匀。直行、跟车、等红灯这类常见场景占了绝大部分里程，而施工改道、路面散落物、逆行车辆、突然冲出的行人等情况，单独看每一种都很少出现，但种类非常多，合在一起并不罕见。这条分布曲线的“尾巴”很长，所以称为长尾。分布外泛化说的是另一面，模型主要在常见场景上训练，遇到与训练数据分布不同的输入时，表现会明显下降，而且往往不会提示自己没有把握。

*这个问题为什么难。*长尾场景很难靠采集数据来覆盖，前面 RAND 的估算说明，仅靠道路里程去证明安全需要上百亿英里，而长尾中的很多情况在这么长的里程里也只出现寥寥几次。基于学习的模型擅长在见过的情况之间插值，却不擅长外推，端到端模型又难以解释，出错前很难察觉。

应对这个问题，目前主要有三个思路。一是用数据闭环有针对性地收集困难场景，再借助仿真和世界模型生成真实世界中难以采集的危险情况。二是让系统能够识别自己没有把握的时刻，在这种情况下主动减速、降级运行或请求接管，并在端到端模型之外保留可验证的规则化安全机制。三是借助车路云协同，让路侧设备补充单车看不到的信息。短期内，限定区域的无人驾驶会继续扩大范围，乘用车的辅助驾驶会继续进步，而在任何道路、任何天气下完全替代人类驾驶，还有相当长的路要走。

= 课程总结

作为一门 1 学分的跨专业选修课，这门课让我第一次完整地了解了自动驾驶的技术链条，也让我把计算机专业中学到的深度学习和工程调试能力，用在了真实的自动驾驶数据集和模拟器上。

四次实践并不是每次都得到了理想的结果，PETR 的检测指标很低，PointPillars 也有明显的误检和漏检。但正是这些不理想的结果，让我去分析数据、预训练和评测方式对模型的影响，也更理解了实际系统为什么需要大规模的数据和严格的测试。

感谢张红娟老师精心设计的理论课和四次实践，也感谢助教在环境配置和实验过程中的耐心解答，让我在有限的课时里学有所获。

#heading(numbering: none)[参考文献]

#set par(first-line-indent: 0pt, justify: false)
#set text(size: 9.5pt)

#refitem(1)[H. Caesar et al. nuScenes: A Multimodal Dataset for Autonomous Driving. CVPR, 2020.] <ref-1>

#refitem(2)[A. H. Lang et al. PointPillars: Fast Encoders for Object Detection from Point Clouds. CVPR, 2019.] <ref-2>

#refitem(3)[Y. Liu et al. PETR: Position Embedding Transformation for Multi-View 3D Object Detection. ECCV, 2022.] <ref-3>

#refitem(4)[Z. Li et al. BEVFormer: Learning Bird's-Eye-View Representation from Multi-Camera Images via Spatiotemporal Transformers. ECCV, 2022.] <ref-4>

#refitem(5)[Ultralytics. Ultralytics YOLO Documentation. https://docs.ultralytics.com/.] <ref-5>

#refitem(6)[M. Bojarski et al. End to End Learning for Self-Driving Cars. arXiv:1604.07316, 2016.] <ref-6>

#refitem(7)[S. Ross, G. Gordon, D. Bagnell. A Reduction of Imitation Learning and Structured Prediction to No-Regret Online Learning. AISTATS, 2011.] <ref-7>

#refitem(8)[Y. Hu et al. Planning-Oriented Autonomous Driving. CVPR, 2023.] <ref-8>

#refitem(9)[Z. Li et al. Is Ego Status All You Need for Open-Loop End-to-End Autonomous Driving? CVPR, 2024.] <ref-9>

#refitem(10)[Z. Liu et al. BEVFusion: Multi-Task Multi-Sensor Fusion with Unified Bird's-Eye View Representation. ICRA, 2023.] <ref-10>

#refitem(11)[Y. Dong et al. Benchmarking Robustness of 3D Object Detection to Common Corruptions. CVPR, 2023.] <ref-11>

#refitem(12)[S. Xie et al. RoboBEV: Towards Robust Bird's Eye View Perception under Corruptions. arXiv:2304.06719, 2023.] <ref-12>

#refitem(13)[新华网. 萝卜快跑周全无人订单超 25 万，累计服务超 1700 万次. 2025-11-14.] <ref-13>

#refitem(14)[N. Kalra, S. M. Paddock. Driving to Safety: How Many Miles of Driving Would It Take to Demonstrate Autonomous Vehicle Reliability? RAND Corporation, 2016.] <ref-14>

#refitem(15)[Tesla. FSD (Supervised) v12 Release Notes. 2024.] <ref-15>

#refitem(16)[理想汽车. 理想汽车 2024 年 10 月交付数据公告. 2024-11-01.] <ref-16>

#refitem(17)[虎嗅. 理想加入“端到端”竞赛. 2024.] <ref-17>

#refitem(18)[Waymo. New Study: Waymo is Reducing Serious Crashes and Making Streets Safer for Those Most at Risk. 2025.] <ref-18>

#refitem(19)[北京市人民代表大会常务委员会. 北京市自动驾驶汽车条例. 2024-12-31 通过，2025-04-01 施行.] <ref-19>
