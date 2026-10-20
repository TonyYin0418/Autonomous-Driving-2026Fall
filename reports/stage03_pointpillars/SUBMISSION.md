# Stage03 提交清单

## 交付文件

| 文件 | 内容 |
|---|---|
| `stage03_pointpillars_report.pdf` | 正式实验报告 |
| 根目录 `submit/stage03/` 下的 ZIP | 本阶段源码、环境清单、模型独立配置、报告 LaTeX 及排版所需 PDF 图 |
| `stage03_pointpillars_results.zip` | 最终 `epoch_5.pth`、单帧索引、清单、训练日志与审计、前后指标、预测图及阈值重绘图 |
| `SHA256SUMS` | 上述文件的 SHA256，另列最终检查点哈希 |

发送附件统一位于项目根目录的 `submit/stage03/`，文件名为
`自动驾驶技术第三次实验+尹玉文东+2024302131025.pdf` 和同名 `.zip`。
报告目录保留正式 PDF，源码 ZIP 只在 `submit/` 保存。

结果包实际保存在数据盘
`/home/yin/data/autonomous_driving/runs/stage03_pointpillars/submission/`，本目录的同名文件是
软链接。发送提交材料时复制软链接指向的 ZIP 文件内容即可。原始数据、环境和公开预训练
权重不放入代码包；最终自己训练的权重包含在结果包中。

源代码包与结果包使用相同的项目相对路径，可解压到同一目录。结果包中的最终权重路径为：

```text
pointpillars_workflow/outputs/20261019_203712_pointpillars_mini_run5/epoch_5.pth
```

该权重 20,968,725 字节，SHA256：

```text
ae8d2698a36ca9280d32a606d129cc76aeb4042b3c61533142b33dbe9ad1388a
```

代码包还包含教师提供的 MMDetection3D 1.4.0 源码压缩包（约 620 KiB），供安装脚本使用；
其余大型教师材料和原始 LiDAR 不重复打包。数据及解释器路径设置见工作目录 README。

## 对应课程要求的证据

| 课程要求 | 本地文件或结果包内的位置 |
|---|---|
| 323/81、无交集、单关键帧 | `pointpillars_workflow/data_infos/manifest.json` |
| 真实一轮训练 | `outputs/20261019_203612_pointpillars_mini_run1/training_audit.json` |
| 第 1 轮损失图 | 上述目录 `loss.png`（另有 PDF/SVG） |
| 恢复到累计 5 轮 | `outputs/20261019_203712_pointpillars_mini_run5/console.log`，记录恢复 epoch=1、iter=323 |
| 最终模型、续训审计及损失图 | 上述 run5 目录的 `epoch_5.pth`、`training_audit.json`、`loss.png` |
| 公开权重基线指标 | `outputs/20261019_203330_pointpillars_mini_baseline/metrics_summary.json` |
| 最终权重验证指标 | `outputs/20261019_203834_pointpillars_mini_finetuned/metrics_summary.json` |
| BEV 检测图 | 上述 finetuned 目录 `visualizations/`，预测前三帧，阈值 0.10 |
| 阈值 0.30 重绘 | 上述 finetuned 目录 `visualizations_thr030/`，同一份预测、相同前三帧 |
| 前后指标比较 | `pointpillars_workflow/outputs/comparison.json` |
| GPU 算子与环境 | `pointpillars_workflow/outputs/environment.json` |
| 检查点参数及 AMP 审核 | `pointpillars_workflow/outputs/checkpoint_audit.json` |

表内简写 `outputs/...` 均从 `pointpillars_workflow/` 起算。
报告的 `results/` 同时保留小型证据副本，`figures/` 保留全部报告图的 PDF/SVG/300 dpi PNG。
报告额外的蓝色虚线为真值叠加，教师原始绘图仅显示预测框。

## 实测结果

- 基线：NDS 0.026076699，mAP 0.000060735。
- 微调 5 轮：NDS 0.118147172，mAP 0.061377287。
- 第 1 轮及恢复训练审计时间共 87.691 秒，含两次轮末验证。
- 检测头参数张量两次均更新 6/6；模型参数全部有限，非检测头参数未改变。
- AMP 跳过 3 次溢出更新，1615 次迭代中实际优化器更新 1612 次；BN 运行统计有更新。

此为单帧、50×50 m 教学设置，结果仍有误检、漏检及类别差异。
