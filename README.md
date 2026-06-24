# SmartBrainClinic

智慧云脑诊疗平台项目仓库。

本项目面向门诊诊疗全链路，围绕患者端、医生端、管理端、医技端和药房端建立智能化诊疗平台。系统目标是在传统 HIS 业务基础上引入大语言模型、医学影像识别、智能医生推荐和智能排班能力，同时坚持医疗场景中的医生最终确认原则。

## 当前实现状态

当前仓库的主要实现已经转向 **Python FastAPI 微服务后端**。README 早期描述的 Java/Spring 微服务目录仍保留为占位，但不是当前主实现。

- 后端主目录：`backend/`
- 前端目录：`frontend/`，当前尚未初始化正式工程
- 旧服务占位目录：`services/`，当前仅保留 `.gitkeep`
- 需求与协作文档：`docs/`

## 业务范围

- 患者端：患者建档、AI 问诊、AI 分诊、医生推荐、挂号、候诊队列、历史挂号与异常通知。
- 医生端：叫号接诊、病历初稿、检查/检验/处置申请、门诊确诊、处方开立。
- 管理端：排班规则管理、排班申请审批、实际排班干预、医生评价与 AI 评估。
- 医技端：检查/检验申请接收、结果录入、医学影像 AI 辅助识别接口。
- 药房端：处方接收、发药、退药、库存扣减与恢复。
- 财务端：挂号缴费、检查/药品合并缴费、退费、账单查询。

## 技术栈

- 后端框架：FastAPI、Uvicorn、Pydantic v2
- 数据访问：SQLModel、SQLAlchemy Async、asyncpg
- 数据库：PostgreSQL、pgvector
- 异步消息：RabbitMQ、aio-pika、Outbox 模式
- 缓存/实时能力：Redis
- 服务发现：Nacos，带本地 fallback URL
- AI 编排：LangChain、LangGraph、OpenAI-compatible LLM API、向量嵌入检索
- 容器化：Docker、Docker Compose
- 前端规划：Vue 3、Element Plus、Pinia、Axios

## 后端微服务

| 服务 | 目录 | 默认端口 | 职责 |
| --- | --- | ---: | --- |
| Gateway | `backend/app/main.py` | 8000 | 统一入口，按 `/api/v1/{service}` 反向代理到子服务 |
| Auth | `backend/app/microservices/auth` | 8001 | 员工、科室、诊室、挂号级别、结算类别、医生向量检索 |
| Patient | `backend/app/microservices/patient` | 8002 | 患者、挂号、排班、AI 分诊、医生推荐、候诊队列 |
| Medical | `backend/app/microservices/medical` | 8003 | 病历、检查/检验/处置、诊断、AI 病历草稿、影像推理 |
| Pharmacy | `backend/app/microservices/pharmacy` | 8004 | 药品、处方、发药、退药、处方推荐 |
| Billing | `backend/app/microservices/billing` | 8005 | 缴费、退费、账单明细、支付事件 |

## 仓库结构

```text
SmartBrainClinic/
  backend/                      FastAPI 微服务后端
    app/
      common/                   公共配置、数据库、MQ、Nacos、AI embedding
      microservices/            auth/patient/medical/pharmacy/billing 服务
    docker-compose.yml          PostgreSQL、Redis、RabbitMQ、Nacos 与微服务编排
    requirements.txt            Python 依赖
    run_microservices.py        本地批量启动脚本
    verify_services.py          健康检查脚本
  docs/                         需求、规划、架构和协作文档
  frontend/                     前端工程占位
  services/                     早期 Java 服务规划占位目录
  database/                     数据库脚本占位目录
  scripts/                      项目辅助脚本占位目录
```

## 本地启动

### 1. 安装 Python 依赖

```powershell
cd backend
pip install -r requirements.txt
```

### 2. 配置环境变量

建议在 `backend/.env` 中配置数据库、RabbitMQ、Nacos 和 LLM 参数。不要把真实密钥提交到 Git。

关键变量包括：

```text
DB_HOST=localhost
DB_PORT=5432
DB_USER=lujuntong
DB_PASSWORD=
DB_NAME=his_db
REDIS_URL=redis://localhost:6379/0
RABBITMQ_URL=amqp://guest:guest@localhost:5672/
NACOS_SERVER_ADDR=127.0.0.1:8848
LLM_API_KEY=your-api-key
LLM_API_BASE=https://api.example.com/v1
LLM_MODEL=your-chat-model
LLM_EMBEDDING_MODEL=your-embedding-model
```

### 3. 启动基础设施

```powershell
cd backend
docker compose up -d postgres redis rabbitmq nacos
```

### 4. 启动微服务

```powershell
cd backend
python run_microservices.py
```

### 5. 验证服务

```powershell
cd backend
python verify_services.py
```

默认健康检查地址：

- Gateway: <http://localhost:8000/health>
- Auth: <http://localhost:8001/health>
- Patient: <http://localhost:8002/health>
- Medical: <http://localhost:8003/health>
- Pharmacy: <http://localhost:8004/health>
- Billing: <http://localhost:8005/health>

## 当前注意事项

- `backend/app/common/config.py` 中不应保留真实 LLM API Key，后续需要改为从环境变量读取并轮换已暴露密钥。
- Docker 环境下服务注册到 Nacos 时不能固定使用 `127.0.0.1`，否则容器间服务发现可能指向错误地址。
- `billing` 服务路由当前使用 `/api/v1/bill`，部分配置仍出现 `billing` 命名，需要后续统一。
- 当前缺少自动化测试，复杂流程应优先补挂号并发、缴费退费、库存扣减、Outbox 消息投递等测试。
- 前端尚未初始化，建议先实现最小闭环：建档 -> AI 分诊 -> 医生推荐 -> 挂号 -> 缴费 -> 候诊。

## 重要文档

- [需求文档](docs/智慧云脑诊疗平台_流程与需求文档.md)
- [项目规划](docs/项目规划.md)
- [后端架构说明](docs/后端架构说明.md)
- [GitHub 协作规范](docs/GitHub协作规范.md)
