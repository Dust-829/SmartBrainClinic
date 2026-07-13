# CT 伪影掩码模型运行目录

本目录保存 SmartBrainClinic 使用的本机 CT 伪影分割运行代码。它不依赖
`D:\work\NeuEduPython` 的源码路径；模型运行时应使用 Conda 环境 `py3106`。

## 已迁入内容

- `model/attention_unet2d.py`：与 attention checkpoint 参数名兼容的网络定义。
- `inference.py`：权重校验、NIfTI / SimpleITK 推理和单序列 DICOM 读取。
- `requirements.txt`：专用推理环境所需依赖版本。

模型权重不提交 Git，固定放在：

```text
backend/runtime/models/ct_artifact/attention_unet2d_best.pth
```

启动前可用 `CT_ARTIFACT_MODEL_WEIGHT` 覆盖该路径。运行时会校验权重 SHA-256，
必须匹配 `8F61F71964621BB104CBF8CD72D4872FD257DFF8123CC9B9B0E17575E0D3FBE1`。

## 为你预留的数据位置

请将后续本地数据复制到下列目录；这三个目录均被 Git 忽略：

```text
backend/runtime/data/ct_artifact/
├─ input/          # 待推理的 NIfTI 或按“一个目录一个序列”组织的 DICOM
├─ ground_truth/   # 可选：人工 mask，用于离线回归
└─ output/         # 自动生成的 mask、预览图和任务输出
```

不要把 CQ500 原始数据复制进源码目录、`frontend/`、数据库迁移目录或 Git 仓库。

## 当前边界

本次只完成模型运行集迁移和本地数据目录预留。FastAPI 推理接口、Medical 服务调用、
任务状态和医生端页面将在后续切片接入。
