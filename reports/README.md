# 实践课报告

| 阶段 | 报告目录 | 正式 PDF |
|---|---|---|
| Stage01 | `stage01_nuscenes_yolo/` | [第一次实验](stage01_nuscenes_yolo/stage01_nuscenes_yolo_report.pdf) |
| Stage02 | `stage02_petr/` | [第二次实验](stage02_petr/stage02_petr_report.pdf) |
| Stage03 | `stage03_pointpillars/` | [第三次实验](stage03_pointpillars/stage03_pointpillars_report.pdf) |
| Stage04 | `stage04_e2e/` | [第四次实验](stage04_e2e/stage04_e2e_report.pdf) |
| 结题报告 | `final_report/` | [结题报告](final_report/final_report.pdf) |

Stage01—03 的 `main.tex`、Stage04 的 `main.typ` 为报告正文，`figures/` 保留排版图表。
LaTeX 公共样式位于 `template/course-report.sty`，Stage04 按《公网部署实验报告.typ》排版，
样式定义包含在 `main.typ` 中。写作与绘图要求见
[WRITING_GUIDELINES.md](WRITING_GUIDELINES.md)。Stage03 的 `results/` 保留指标、
日志和训练审计，已有交付说明见该阶段的 `SUBMISSION.md`。结题报告的 `results/` 保留三组补充测试的
指标，`scripts/` 保留在 WSL 上运行的测试脚本，`history/` 按时间保存修改过程中的各版正文。

## 提交附件

附件统一放在项目根目录的 [`submit/`](../submit/)，与 `reports/` 平级，
按 `stage01/`、`stage02/`、`stage03/`、`stage04/` 分目录。每个阶段只放源码 ZIP 和正式 PDF 副本，
命名为 `自动驾驶技术第X次实验+尹玉文东+2024302131025.zip` / `.pdf`。
源码 ZIP 不在报告目录重复保存；后续阶段沿用此结构。

## 编译

结题报告同样使用 Typst 0.15.1，正文和加粗为思源宋体（Noto Serif CJK SC），标题为思源黑体，
首次编译会下载 `fletcher` 绘图包：

```bash
typst compile reports/final_report/main.typ \
  reports/final_report/final_report.pdf
```

Stage04 使用 Typst 0.15.1，从项目根目录编译：

```bash
typst compile reports/stage04_e2e/main.typ \
  reports/stage04_e2e/stage04_e2e_report.pdf
```

正文从 `results/results.json` 读取指标，使用 `figures/` 中的 SVG 和 PNG。
字体为 Times New Roman、SimSun、Noto Sans CJK SC 和 JetBrains Mono。

Stage01—03 需要 XeLaTeX、`latexmk` 和供 `minted` 使用的 `pygmentize`。
从对应报告目录运行，将 `stageXX_主题_report` 替换为该阶段 PDF 的文件名（不含扩展名）：

```bash
latexmk -xelatex -shell-escape \
  -jobname=stageXX_主题_report -outdir=build main.tex
```

检查生成的 PDF 后，复制到该报告目录和 `submit/stageXX/` 的正式文件路径。
`build/` 只用于编译，可在更新正式 PDF 后删除，不纳入 Git。
