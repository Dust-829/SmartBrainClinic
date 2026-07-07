# SmartBrainClinic

智慧云脑诊疗平台项目仓库。

项目当前以门诊场景为主，围绕患者端、医生端、管理员端、医技端、药房端和财务端构建 AI 赋能的诊疗闭环。主业务主线固定为脑科 / 神经外科门诊，重点展示 AI 问诊、AI 分诊、医生推荐、检查检验、脑部 CT / MRI 影像辅助、处方审核和缴费发药。

## 当前实现

当前仓库的主实现已经确定为 **Python FastAPI 微服务后端**，不是 Java / Spring Boot。

- 后端主目录：`backend/`
- 前端目录：`frontend/`，当前已是可运行的 Vue 3 + Vite 工程，患者端第一阶段主链路已落地，且已移除产品级全局角色切换入口
- 文档目录：`docs/`
- 旧 `services/` 目录仅为早期占位，不是当前运行实现

## 技术栈

- 后端：FastAPI、Uvicorn、Pydantic v2
- 数据访问：SQLModel、SQLAlchemy Async、asyncpg
- 数据库：PostgreSQL、pgvector
- 中间件：Redis、RabbitMQ、Nacos
- AI 编排：LangChain、LangGraph、OpenAI-compatible API
- 前端规划：Vue 3、Pinia、Axios、Element Plus

## 微服务

| 服务 | 目录 | 端口 | 职责 |
| --- | --- | ---: | --- |
| Gateway | `backend/app/main.py` | 8000 | 统一入口，按 `/api/v1/{service}` 转发 |
| Auth | `backend/app/microservices/auth` | 8001 | 医生、科室、诊室、挂号级别、结算类别 |
| Patient | `backend/app/microservices/patient` | 8002 | 患者建档、AI 分诊、医生推荐、挂号、排班、候诊队列 |
| Medical | `backend/app/microservices/medical` | 8003 | 病历、检查、检验、处置、影像辅助、医生 AI 助手 |
| Pharmacy | `backend/app/microservices/pharmacy` | 8004 | 处方推荐、发药、退药、库存 |
| Billing | `backend/app/microservices/billing` | 8005 | 缴费、退费、账单、退款保护 |

## 最近状态

截至 2026-07-06，当前本地已完成这些验证：

- `ai-trust-hardening` 分支已合并到本地 `main`
- Docker 基础设施已可启动：PostgreSQL、Redis、RabbitMQ、Nacos
- 数据库备份已导入，`backend/migrations/` 已全部执行
- 6 个微服务的 `/health` 和 `/docs` 均可访问
- 前端已明确按 `/patient/*`、`/doctor/*`、`/admin/*` 组织三套路由入口，且不再保留顶部全局角色切换按钮
- 新增测试中，至少以下两组已通过：
  - `backend/tests/test_billing_refund_guard.py`
  - `backend/tests/test_patient_auxiliary_workflows.py`

## 数据库初始化

当前本地运行依赖两部分：

1. 导入基础库和演示数据：`backend/his_db_backup.sql`
2. 执行增量迁移：`backend/migrations/*.sql`

如果是第一次在空库上启动，建议先启动 PostgreSQL 容器，再导入 `his_db_backup.sql`，最后执行 `backend/migrations/` 下的 SQL。

## 本地启动

### 1. 安装依赖

```powershell
cd backend
pip install -r requirements.txt
```

### 2. 配置环境变量

建议创建 `backend/.env`，至少包含以下内容：

```text
DB_HOST=localhost
DB_PORT=5432
DB_NAME=his_db
DB_USER=lujuntong
DB_PASSWORD=his_password

REDIS_URL=redis://localhost:6379/0
RABBITMQ_URL=amqp://guest:guest@localhost:5672/
NACOS_SERVER_ADDR=127.0.0.1:8848
SERVICE_HOST=127.0.0.1

APP_ENV=development
APP_DEBUG=true
AI_ALLOW_MOCK_FALLBACK=true
```

其他 AI 相关参数可按需继续补充：

```text
LLM_API_KEY=your-api-key
LLM_API_BASE=https://api.example.com/v1
LLM_MODEL=your-chat-model
LLM_EMBEDDING_MODEL=your-embedding-model
ADMIN_API_TOKEN=your-admin-token
AI_AUDIT_ADMIN_TOKEN=your-ai-audit-token
```

### 3. 启动基础设施

```powershell
cd backend
docker compose up -d postgres redis rabbitmq nacos
```

### 4. 启动微服务

Windows 本地推荐直接按服务启动，避免 `run_microservices.py` 的控制台编码问题：

```powershell
cd backend
python -X utf8 -m uvicorn app.main:app --host 0.0.0.0 --port 8000
python -X utf8 -m uvicorn app.microservices.auth.main:app --host 0.0.0.0 --port 8001
python -X utf8 -m uvicorn app.microservices.patient.main:app --host 0.0.0.0 --port 8002
python -X utf8 -m uvicorn app.microservices.medical.main:app --host 0.0.0.0 --port 8003
python -X utf8 -m uvicorn app.microservices.pharmacy.main:app --host 0.0.0.0 --port 8004
python -X utf8 -m uvicorn app.microservices.billing.main:app --host 0.0.0.0 --port 8005
```

### 5. 验证服务

- Gateway：<http://localhost:8000/health>
- Auth：<http://localhost:8001/health>
- Patient：<http://localhost:8002/health>
- Medical：<http://localhost:8003/health>
- Pharmacy：<http://localhost:8004/health>
- Billing：<http://localhost:8005/health>

Swagger 文档入口：

- <http://localhost:8000/docs>
- <http://localhost:8001/docs>
- <http://localhost:8002/docs>
- <http://localhost:8003/docs>
- <http://localhost:8004/docs>
- <http://localhost:8005/docs>

## 当前注意事项

- `backend/app/common/config.py` 里仍有硬编码的 LLM Key 默认值，后续应移出代码并轮换。
- `run_microservices.py` 和 `verify_services.py` 在 Windows 下存在 emoji / GBK 编码问题。
- 医学影像当前仍是 Mock 推理，不应对外描述为真实深度学习模型已完成。
- 前端阶段 0 已完成，当前重点进入患者端主链路联调。

## 重要文档

- [项目规划](docs/项目规划.md)
- [项目结构说明](docs/项目结构说明.md)
- [GitHub 协作规范](docs/GitHub协作规范.md)
