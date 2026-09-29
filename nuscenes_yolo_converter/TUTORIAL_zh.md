# nuScenes二维目标检测标签转换

nuScenes主要面向自动驾驶三维感知任务，目标标注以三维包围框（3D Bounding Box）为主，而Ultralytics YOLO等常用二维目标检测网络需要图像平面上的二维矩形框。因此，在使用nuScenes开展YOLO二维目标检测实验之前，需要将三维目标标注变换到相机坐标系、投影到图像平面，并进一步转换为YOLO标签格式。

本课程提供完整的nuScenes→YOLO转换程序以及预先转换的数据集。学生可以直接使用课程数据训练模型，也可以自行运行转换程序，理解坐标变换、相机投影、目标筛选、数据降采样和训练集划分的完整流程。需要特别说明的是，本课程生成的二维框是三维框在图像平面上的投影包围框，并不是人工沿目标可见轮廓标注的紧致二维框。因此，在遮挡、截断、近距离目标或细长目标上，投影框与常规二维检测数据集中的人工框可能存在差异。本数据集适合用于学习自动驾驶数据处理及二维检测流程，但不应将其视为严格的人工二维标注基准。

## 4.1转换原理

nuScenes的`sample_annotation`给出了Global坐标系中的三维目标框，Camera图像则由安装在Ego车辆上的相机采集。要把三维框投影到图像，需要依次完成Global→Ego→Camera的坐标变换。转换程序从`ego_pose.json`读取车辆在全局坐标系中的位姿，从`calibrated_sensor.json`读取相机相对于车辆的外参以及相机内参，并按以下顺序处理每个目标框：

```text
nuScenes 3D Annotation（Global）
              │
              │ ego_pose的逆变换
              ▼
        3D Bounding Box（Ego）
              │
              │ calibrated_sensor的逆变换
              ▼
       3D Bounding Box（Camera）
              │
              │ box.corners()：取得8个角点
              ▼
         Camera坐标系三维角点
              │
              │ view_points() + Camera Intrinsic
              ▼
            图像平面投影点
              │
              │ 计算xmin、ymin、xmax、ymax并裁剪
              ▼
          2D Bounding Box（像素坐标）
              │
              │ 中心点/宽高归一化
              ▼
               YOLO Label
```

对Global→Ego变换，程序先减去Ego的平移，再乘以Ego旋转的逆；对Ego→Camera变换，再减去相机外参平移并乘以相机旋转的逆。`box.corners()`返回三维框的8个角点，`view_points()`使用相机内参把相机前方的三维点投影成二维像素坐标。所有有效投影点横、纵坐标的最小值和最大值构成二维矩形框，超出图像的部分被裁剪到图像边界。

nuScenes-devkit的高级接口（例如`nusc.get_sample_data()`）也能返回已转换至传感器坐标系的目标框；本课程程序为了让数据流和坐标变换过程更清楚，直接读取nuScenes JSON表并显式执行上述变换。两种方式所依据的坐标关系相同。

## 4.2目标筛选与关键参数

转换的核心不只是“投影”，还包括对标注质量和样本重复度的控制。本课程发布数据采用以下参数：

| 参数                            |    课程采用值 | 作用与选择依据                                                                                                     |
| ------------------------------- | ------------: | ------------------------------------------------------------------------------------------------------------------ |
| `--channels`                    |   `CAM_FRONT` | 仅使用车辆正前方相机，便于开展单相机二维目标检测。需要多相机数据时可显式传入其他Camera通道。                       |
| `--visibilities`                |         `3 4` | 只保留可见比例较高的目标，减少严重遮挡目标通过完整三维框投影后产生的大框、松框和歧义标签。                         |
| `--min-distance`                |       `1.0` m | 同一场景、同一相机中，车辆从上一张保留帧的Ego平面位置移动至少1 m才保留新帧，以减少停车或低速行驶造成的近重复图像。 |
| `--exclude-night`               |          开启 | 排除场景描述中带有`night`的场景，使课程基础实验集中在光照较稳定的日间图像上。                                      |
| `--min-width`                   |         10 px | 去除投影宽度过小、训练价值有限且容易受量化误差影响的目标。                                                         |
| `--min-height`                  |         10 px | 去除投影高度过小的目标。                                                                                           |
| `--min-area`                    |       100 px² | 对二维框面积设置下限，与宽高约束共同过滤极小框。                                                                   |
| `require_center_inside`         |          开启 | 要求三维框中心的投影位于图像内，避免只在图像边缘露出很小部分、但投影框异常大的目标。                               |
| `require_all_corners_in_front`  |          开启 | 要求三维框8个角点都位于相机近平面之前，避免目标穿过或位于相机后方时产生不稳定投影。                                |
| `require_fully_inside`          |          关闭 | 不要求完整投影框都在图像内部。边缘截断目标仍可用于YOLO，程序会把框裁剪到图像边界。                                 |
| `--train-ratio` / `--val-ratio` |   `0.7 / 0.1` | 训练、验证、测试比例为7:1:2，增加独立测试集比例，便于课程中的最终评估。                                            |
| `--seed`                        |          `42` | 固定场景划分顺序，使不同学生和不同机器上的结果可复现。                                                             |
| `--class-mode`                  | `detection10` | 使用nuScenes Detection任务的10个主要检测类别，而不是保留全部细粒度原始类别。                                       |

nuScenes的`visibility_token`描述目标在传感器视角中的可见程度，而不是目标是否处于Camera视场内。官方四档可见度的含义为：`1`表示可见比例0～40%，`2`表示40～60%，`3`表示60～80%，`4`表示80～100%。课程采用`3 4`，即只保留估计可见比例不低于60% 的目标。目标是否真正落入当前Camera图像，还要由相机坐标中的深度、中心位置和投影框范围继续判断。因此，`--visibilities 3 4`与Camera视场筛选是两个先后配合但含义不同的条件。

选择3、4档是课程数据质量与样本数量之间的折中。若同时保留1、2档，可以获得更多困难样本，但严重遮挡目标的完整三维框投影往往覆盖遮挡物或大片背景，不等同于目标当前可见部分的紧致二维框；对于入门二维检测实验，这会增加标签噪声。后续若研究遮挡鲁棒性，可改为 `--visibilities 1 2 3 4`重新生成数据，并对结果进行可视化抽查。

距离采样在每个“场景 + Camera通道”内独立执行，并按时间戳排序。程序先删除没有任何有效二维标注的图像，保留该组第一张有效图像，此后计算当前帧Ego位置与上一张已保留帧Ego位置在XY平面上的欧氏距离；距离达到1 m才保留当前帧。这里衡量的是车辆位移，不是目标运动距离，也不是相邻原始帧间距离。1 m可以明显减少车辆静止或缓慢移动时的重复画面，同时保留道路环境随行驶位置发生变化的样本。其局限是：车辆静止而行人或其他车辆明显运动时，部分有价值的时间变化帧也可能被删除。课程可将 `--min-distance`调小以保留更多帧，设为`0`则不进行距离降采样。

本次课程数据在上述条件下从30,162张候选图像中删除2,069张无有效标注图像，并因1 m距离采样删除6,591张近重复图像，最终保留21,502张图像和128,712个二维目标框。

## 4.3目标类别与YOLO标签

nuScenes原始标注包含更细的类别层级，例如不同类型的行人和公交车。本课程根据nuScenes Detection任务的类别映射关系将其归并为10类。类别ID由转换程序中的`CLASS_NAMES`顺序确定，课程当前版本如下：

| 类别ID | 类别名称               | 典型原始类别映射                                            |
| -----: | ---------------------- | ----------------------------------------------------------- |
|      0 | `car`                  | `vehicle.car`                                               |
|      1 | `truck`                | `vehicle.truck`                                             |
|      2 | `bus`                  | `vehicle.bus.bendy`、`vehicle.bus.rigid`                    |
|      3 | `trailer`              | `vehicle.trailer`                                           |
|      4 | `construction_vehicle` | `vehicle.construction`                                      |
|      5 | `pedestrian`           | adult、child、construction_worker、police_officer等行人子类 |
|      6 | `motorcycle`           | `vehicle.motorcycle`                                        |
|      7 | `bicycle`              | `vehicle.bicycle`                                           |
|      8 | `traffic_cone`         | `movable_object.trafficcone`                                |
|      9 | `barrier`              | `movable_object.barrier`                                    |

类别ID必须以生成数据集中的`data.yaml`和`classes.txt`为准，不能只根据类别名称自行重新编号。YOLO标签文件与图像同名，每个目标占一行：

```text
class_id x_center y_center width height
```

其中`x_center`和`width`除以图像宽度，`y_center`和`height`除以图像高度，所有几何值均归一化到0～1。例如：

```text
0 0.512400 0.603100 0.120500 0.184200
```

表示类别0（`car`）的二维框中心位于图像宽度的51.24% 和高度的60.31% 处，框宽、高分别约占图像宽、高的12.05% 和18.42%。YOLO不要求原始目标完整出现在图像中；本程序默认允许边缘截断目标，并把二维框裁剪至图像范围。如果实验需要只保留完整位于图像内的投影框，可增加 `--require-fully-inside`，但这通常会删除较多靠近图像边缘的有效目标。

## 4.4数据划分与转换程序

本课程不是把全部图像随机混合后再划分，而是先按照`location`生成四个互相独立的数据集：`boston-seaport`、`singapore-hollandvillage`、`singapore-onenorth`和`singapore-queenstown`。每个location内再以scene为最小单位，使用固定随机种子42划分train、val、test，比例为7:1:2。同一个scene的连续帧不会同时进入不同split，从而降低相邻画面泄漏导致评估结果虚高的风险。由于一个scene包含的有效帧数不同，最终图像数量比例会接近但不一定严格等于70%、10% 和20%。

本次转换结果如下：

| Location                   |      Train |       Val |      Test |       合计 |
| -------------------------- | ---------: | --------: | --------: | ---------: |
| `boston-seaport`           |      9,420 |     1,402 |     2,709 |     13,531 |
| `singapore-hollandvillage` |        365 |        56 |        88 |        509 |
| `singapore-onenorth`       |      3,634 |       461 |     1,015 |      5,110 |
| `singapore-queenstown`     |      1,661 |       205 |       486 |      2,352 |
| **总计**                   | **15,080** | **2,124** | **4,298** | **21,502** |

转换程序位于课程代码仓库的`nuscenes_yolo_converter`目录。程序依赖通过pip安装的`nuscenes-devkit`，不依赖本地修改版devkit。Linux环境下可在项目根目录执行：

```bash
conda activate yolo
python nuscenes_yolo_converter/convert.py \
  --dataroot /data/nuscenes \
  --output nuscenes_yolo_converter/output/nuscenes_yolo_vis34 \
  --channels CAM_FRONT \
  --visibilities 3 4 \
  --exclude-night \
  --min-distance 1.0 \
  --train-ratio 0.7 \
  --val-ratio 0.1 \
  --seed 42 \
  --class-mode detection10 \
  --image-mode copy \
  --overwrite
```

`--dataroot`指向nuScenes根目录，该目录下应包含`samples/`、`sweeps/`、`maps/`和`v1.0-trainval/`等内容。`--output`指定转换结果位置；`--overwrite`会删除并重新创建非空输出目录，应确认目标路径无误后再使用。`--image-mode copy`会生成独立图像副本，兼容性最好但占用额外磁盘空间；同一文件系统中也可尝试`hardlink`以节省空间，Linux下可用`symlink`，但移动数据集或改变源数据路径时需注意链接有效性。

在正式写入之前，建议先使用 `--dry-run`统计筛选后的样本数量。该模式不会创建或覆盖输出数据：

```bash
python nuscenes_yolo_converter/convert.py \
  --dataroot /data/nuscenes \
  --channels CAM_FRONT \
  --visibilities 3 4 \
  --exclude-night \
  --min-distance 1.0 \
  --train-ratio 0.7 \
  --val-ratio 0.1 \
  --seed 42 \
  --dry-run
```

课程发布仓库地址：**【此处填写GitHub/Gitee链接】**。转换后数据集下载地址：**【此处填写课程云盘链接】**。

## 4.5转换后的数据集结构

转换程序为每个location生成一个可以独立移动和使用的Ultralytics YOLO数据集。以`boston-seaport`为例：

```text
nuscenes_yolo_vis34/
├── conversion_summary.json
├── boston-seaport/
│   ├── data.yaml
│   ├── classes.txt
│   ├── conversion_summary.json
│   ├── manifest.csv
│   ├── manifests/
│   │   ├── train.txt
│   │   ├── val.txt
│   │   └── test.txt
│   ├── images/
│   │   ├── train/
│   │   ├── val/
│   │   └── test/
│   └── labels/
│       ├── train/
│       ├── val/
│       └── test/
├── singapore-hollandvillage/
├── singapore-onenorth/
└── singapore-queenstown/
```

`images/`与`labels/`下的图像和标签通过文件主名一一对应；`data.yaml`定义相对数据路径和类别名称，可以直接传给Ultralytics YOLO；`classes.txt`保存按ID排列的类别名称；`manifest.csv`记录split、location、源图像、输出图像和标签数量，便于追溯；`conversion_summary.json`保存转换参数及统计信息。数据集内部使用相对路径，因此整个location目录移动到其他机器后无需修改内部清单。`manifest.csv`中的`source_image`仅作为来源追溯信息记录原始绝对路径，不参与YOLO训练。

## 4.6转换结果检查与实践要求

数据生成后应先检查完整性和可视化结果，再开始模型训练。完整性检查包括：每个split的图像数与标签文件数是否一致、同名图像是否能找到对应标签、标签每行是否恰好包含5列、类别ID是否处于0～9、归一化坐标是否位于合理范围，以及`data.yaml`是否能从数据集根目录正确解析train、val、test路径。可使用课程提供的校验程序检查单个location：

```bash
python nuscenes_yolo_converter/validate.py \
  nuscenes_yolo_converter/output/nuscenes_yolo_vis34/boston-seaport
```

还应随机抽取若干图像，把YOLO标签重新绘制到原图上，重点观察类别是否正确、投影框是否覆盖目标、边缘框是否被正确裁剪、是否出现异常大框或极小框。遮挡目标的投影框可能包含较多背景，`barrier`、`trailer`等长条或组合目标也可能与视觉直觉不同，这不一定表示程序错误，应结合原始三维标注、可见度等级和目标类别定义判断。

本节不要求学生重新实现nuScenes的全部坐标系统，但需要能够说明`ego_pose`、`calibrated_sensor`、`box.corners()`和`view_points()`在转换中的作用，理解`visibility_token`与Camera视场筛选的区别，理解为什么按scene而不是按单张图像划分数据，并能够解释1 m距离采样对样本重复度及运动目标覆盖率的影响。完成转换和检查后，即可使用任意一个location的`data.yaml`进入YOLO训练、验证和测试阶段。
