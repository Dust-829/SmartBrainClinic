# CT 伪影掩码模型运行目录

本目录保存 SmartBrainClinic 使用的本地 CT 伪影分割运行代码。它不依赖 `D:\work\NeuEduPython` 的源代码路径；模型运行时应使用 Conda 环境 `py3106`。

## 已迁入内容

- `model/attention_unet2d.py`：与 attention checkpoint 参数名兼容的网络定义。
- `inference.py`：权重校验、NIfTI / SimpleITK 推理和单序列 DICOM 读取。
- `service.py`：独立 FastAPI 推理进程；启动时加载一次模型，并以单并发执行 GPU 推理。
- `requirements.txt`：专用推理环境所需依赖版本。

模型权重不提交 Git，固定放在：

```text
backend/runtime/models/ct_artifact/attention_unet2d_best.pth
```

启动前可用 `CT_ARTIFACT_MODEL_WEIGHT` 覆盖该路径。运行时会校验权重 SHA-256，必须匹配 `8F61F71964621BB104CBF8CD72D4872FD257DFF8123CC9B9B0E17575E0D3FBE1`。

## 本地数据位置

请将后续本地数据复制到下列目录；这三个目录均被 Git 忽略：

```text
backend/runtime/data/ct_artifact/
├── input/          # 待推理的 NIfTI 或按“一目录一序列”组织的 DICOM
├── ground_truth/   # 可选：人工 mask，用于离线回归
└── output/         # 自动生成的 mask、预览图和任务输出
```

不要把 CQ500 原始数据复制进源代码目录、`frontend/`、数据库迁移目录或 Git 仓库。

## 启动本地推理服务

从 `backend/` 目录使用专用环境启动：

```powershell
& 'D:\develop\Anaconda\envs\py3106\python.exe' -m uvicorn model_services.ct_artifact.service:app --host 127.0.0.1 --port 8013
```

Medical 服务通过 `CT_ARTIFACT_SERVICE_URL` 访问该进程，默认值为 `http://127.0.0.1:8013`。提交任务时只传 `input/` 目录下的相对引用，例如：

```text
CQ500CT0 CQ500CT0/Unknown Study/CT 4cc sec 150cc D3D on
```

推理输出写入 `backend/runtime/data/ct_artifact/output/<task-uuid>/`，接口仅返回从 `output/` 开始的相对引用。

## 统一启动（推荐）

从 `backend/` 运行统一启动脚本时，CT 伪影推理仍会以独立进程运行，但会由脚本自动托管：

```powershell
cd backend
python run_microservices.py
```

脚本默认使用 `D:\develop\Anaconda\envs\py3106\python.exe` 启动 8013 端口，并等待 `/health` 最多 60 秒。若该环境的实际路径不同，可在启动前设置：

```powershell
$env:CT_ARTIFACT_PYTHON = 'D:\your-conda\envs\py3106\python.exe'
python run_microservices.py
```

CT 伪影推理服务不可用时，统一启动脚本会保留 Auth、Patient、Medical、Pharmacy、Billing 和 Gateway；此时仅影像分析不可用。可通过 `backend/logs/ctartifact.log` 查看模型加载或 CUDA 初始化原因。

仍可按上一节命令单独启动 8013，用于只排查模型服务。

## 当前边界

已完成独立 FastAPI 推理接口和 Medical 任务调用契约。数据库 migration、Medical 服务和本地推理进程需要按部署顺序实际启动后，任务才会在完整业务链路中执行。医生端页面将在后续切片接入。
