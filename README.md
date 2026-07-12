# SmartBrainClinic

更新时间：2026-07-10。

智慧云脑诊疗平台是一个面向门诊流程的 AI 赋能 HIS / 无人医院实训项目。当前固定演示主线为脑科 / 神经外科门诊，覆盖患者建档、AI 分诊、医生推荐、挂号支付、候诊、医生接诊、检查检验、病历确认、处方与收费等环节。

## 技术基线

当前真实实现是 **Python FastAPI 微服务后端 + Vue 3 前端**，不是早期 Java / Spring Boot 方案。

| 模块 | 目录 / 端口 | 职责 |
| --- | --- | --- |
| Gateway | `backend/app/main.py` / 8000 | 统一 API 入口与服务转发 |
| Auth | `backend/app/microservices/auth` / 8001 | 科室、医生、诊室、挂号级别等基础资料 |
| Patient | `backend/app/microservices/patient` / 8002 | 患者、分诊、推荐、排班、挂号与候诊 |
| Medical | `backend/app/microservices/medical` / 8003 | 病历、检查、检验、处置和医生 AI 辅助 |
| Pharmacy | `backend/app/microservices/pharmacy` / 8004 | 药品、处方、发药与退药 |
| Billing | `backend/app/microservices/billing` / 8005 | 账单、缴费、退费与防重复收费 |
| Frontend | `frontend/` / 5173 | Vue 3、Vite、Pinia、Vue Router、Element Plus |

基础设施包括 PostgreSQL + pgvector、Redis、RabbitMQ、Nacos 和 Docker Compose。

## 当前产品状态

- 根路由 `/` 是三端入口页。
- 患者端 `/patient/*` 采用首页优先，已打通登录 / 建档、AI 分诊、选科、医生推荐、挂号、支付、候诊、挂号记录、个人中心和概念展示型就诊码。
- 医生端 `/doctor/*` 采用登录优先，已打通真实医生身份、今日候诊队列、挂号状态图表、开始 / 继续接诊、病历草稿确认、相似病例、AI 助手和检查 / 检验 / 处置开单。
- 管理员端 `/admin/*` 已有独立登录和控制台骨架，但登录仍是演示态，排班、审批和审计尚未接成真实管理闭环。
- 已提交：医生工作台挂号状态图表、接诊开单和病历确认等医生端主链能力已在当前分支提交。
- 本地待合并：AI 分诊会话与挂号绑定、Medical 草稿上下文、挂号历史 60 秒共享缓存和共享 `httpx.AsyncClient` 已在工作区实现，但不包含在本次文档提交中。
- 待验证：医生端直接展示 AI 分诊上下文、历史确认病历融合、结构化决策辅助，以及真实非空队列图表回归。

完整状态和下一步以 [项目规划](docs/项目规划.md) 为准。

状态口径：`已提交` 指已存在于当前 Git 分支的内容；`本地待合并` 指工作区可见但尚未提交的实现；`待验证` 指需要真实数据、浏览器或联调确认的项目。报告引用时应保留这一边界。

## 本地启动

### 1. 安装依赖

```powershell
cd backend
pip install -r requirements.txt

cd ..\frontend
npm install
```

如果 Windows 下读取 `requirements.txt` 遇到 GBK 编码错误，按文件中的版本逐项安装依赖，不要通过修改系统编码或删除依赖绕过。

### 2. 配置后端

在 `backend/.env` 中配置数据库、中间件和 AI 参数。不要把真实 API Key、Token 或密码提交到仓库。

常用变量：

```text
DB_HOST=localhost
DB_PORT=5432
DB_NAME=his_db
DB_USER=...
DB_PASSWORD=...

REDIS_URL=redis://localhost:6379/0
RABBITMQ_URL=amqp://guest:guest@localhost:5672/
NACOS_SERVER_ADDR=127.0.0.1:8848

LLM_API_KEY=...
LLM_API_BASE=...
LLM_MODEL=...
```

### 3. 初始化数据库与基础设施

```powershell
cd backend
docker compose up -d postgres redis rabbitmq nacos
```

空库需要先导入 `backend/his_db_backup.sql`，再按文件名顺序执行 `backend/migrations/*.sql`。

演示数据建议：执行 `backend/scripts/seed_full_demo_data.sql`。
该脚本提供中文患者、医生、排班、病历、医技、处方和收费的关联样例；不要再与旧最小样例脚本混用。

### 4. 启动服务

Windows 本地建议分别启动，便于查看每个服务日志：

```powershell
cd backend
python -X utf8 -m uvicorn app.main:app --host 0.0.0.0 --port 8000
python -X utf8 -m uvicorn app.microservices.auth.main:app --host 0.0.0.0 --port 8001
python -X utf8 -m uvicorn app.microservices.patient.main:app --host 0.0.0.0 --port 8002
python -X utf8 -m uvicorn app.microservices.medical.main:app --host 0.0.0.0 --port 8003
python -X utf8 -m uvicorn app.microservices.pharmacy.main:app --host 0.0.0.0 --port 8004
python -X utf8 -m uvicorn app.microservices.billing.main:app --host 0.0.0.0 --port 8005
```

```powershell
cd frontend
npm run dev
```

入口：

- 前端：<http://localhost:5173>
- Gateway：<http://localhost:8000/health>
- Swagger：`http://localhost:8000/docs` 至 `http://localhost:8005/docs`

## 验证

```powershell
cd frontend
npm run build
```

```powershell
cd backend
python -m pytest tests
```

根据改动范围优先运行相关测试；未执行的验证必须在交付说明中明确指出。

## 已知边界

- 医学影像仍包含 Mock 推理，不应描述为真实影像模型已经完成。
- 管理员端仍是骨架，不应描述为真实后台闭环。
- AI 能力依赖有效模型配置；mock、fallback 和规则结果必须明确标识来源。
- `20260708_01_create_ai_conversation_tables.sql` 必须在目标数据库执行后，会话链路才能完整使用。
- 当前本地医生今日队列可能为空，非空图表场景需要在存在真实当日挂号时补验。

## 文档导航

- [项目规划](docs/项目规划.md)：当前状态、差距、优先级和阶段路线。
- [前端实施计划](docs/frontend-plan.md)：三端路由、页面、状态和前端执行切片。
- [项目结构说明](docs/项目结构说明.md)：仓库、前后端模块和关键入口导航。
- [数据库表结构说明](docs/数据库表结构说明.md)：当前数据库关系和业务表说明。
- [全链路演示数据清单](docs/全链路演示数据清单.md)：全链路演示数据的范围、账号和执行前提。
- [GitHub 协作规范](docs/GitHub协作规范.md)：分支、提交和 PR 约定。

## 历史与报告留档

以下文档保留项目逐步完善的证据，用于阶段汇报、答辩报告和问题复盘；其中的状态以文档标注日期为准，当前实现仍以“文档导航”中的主文档为准。

- [当前项目回顾](docs/当前项目回顾.md)：2026-07-07 阶段快照与当时的下一步建议。
- [问题记录](docs/问题记录.md)：问题现象、原因、处理方式和后续注意项。
- [设计图留档](docs/设计图留档.md)：医生端和患者端关键界面设计图及其适用范围。
- [AI 分诊与病历增强方案](docs/AI分诊与病历增强方案.md)：AI 会话和病历上下文增强的专项设计。
- [患者端就诊码概念展示计划](docs/patient-visit-code-plan.md)：患者端静态二维码展示的范围、交互和验收策略。
- [医生工作台挂号可视化改版计划 v2](docs/doctor-workbench-registration-visual-plan-v2.md)：设计图、数据口径、实施过程和验收记录。
- [历史专项计划](PLAN.md)：医生工作台可视化改造的原始实施计划。
