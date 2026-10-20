# PETR 环境说明

本目录保存依赖清单和检查脚本，不包含现成 Python 环境。
运行方法和数据目录见上级 `README.md`。

- 本次 Linux 实验使用 Python 3.8.19、Torch 1.13.1+cu117、
  torchvision 0.14.1+cu117、MMCV 1.7.0；其余依赖见 `requirements-linux.txt`。
- `requirements-win.txt` 和 `requirements-lock.txt` 为课程包提供的清单，保留供参考。
- `check_environment.py` 检查依赖、PETR 插件及 DCNv2 的 GPU 前向和反向运算。

MMCV 使用与 Torch/CUDA 匹配的 `mmcv-full` 1.7.0；
MMDetection3D 使用随包 `PETR-official/mmdetection3d/` 中的 1.0.0rc6 源码。
