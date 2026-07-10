# AGENTS.md

本文档记录 SmartBrainClinic 仓库内 agent 协作约束。开始非 trivial 任务前，按顺序阅读：

1. `README.md`
2. `PRODUCT.md`
3. `docs/项目规划.md`
4. 与任务相关的 `docs/frontend-plan.md` 或 `docs/项目结构说明.md`

## 当前方向

- 当前真实实现是 Python FastAPI 微服务后端 + Vue 3 前端，不回退到早期 Java / Spring Boot 设定。
- 前端维持一个工程，通过 `/patient/*`、`/doctor/*`、`/admin/*` 组织三端。
- 根路由 `/` 是三端入口；患者端首页优先，医生端和管理员端登录优先。
- 三端使用独立 layout、session store 和路由守卫，不存在产品级全局角色切换器。
- 固定演示主线是脑科 / 神经外科门诊。
- 只能接真实接口；接口不足时显示加载、空、错误或明确边界，不写整面假业务。

## 前端规则

- 患者端移动优先，医生端和管理员端使用桌面工作台 / 后台结构。
- 患者端不展示 `SJWK`、排班 ID 等内部字段。
- AI 分诊是挂号流程中的可选辅助，不作为首页孤立入口。
- AI 输出必须区分真实模型、规则、mock 和 fallback；不得把兜底结果描述成真实模型结论。
- 医生端 AI 只提供建议，正式病历、诊断、处置和处方必须由医生确认。
- UI 任务优先使用已安装的 `impeccable` skill，并沿用现有组件和设计语言。

## 真实接口入口

患者端主链：

- `POST /api/v1/patient`
- `GET /api/v1/patient/card/{card_number}`
- `POST /api/v1/patient/triage`
- `GET /api/v1/patient/departments`
- `POST /api/v1/patient/recommend-doctors`
- `GET /api/v1/patient/schedules`
- `POST /api/v1/patient/online-register`
- `POST /api/v1/patient/online-register/pay`
- `GET /api/v1/patient/register/{uuid}`
- `GET /api/v1/patient/register/{register_uuid}/queue-status`
- `GET /api/v1/patient/{patient_uuid}/registers/detail`

医生端主链：

- `GET /api/v1/patient/doctor/{employee_uuid}/queue`
- `POST /api/v1/patient/doctor/{employee_uuid}/queue/call-next`
- `PUT /api/v1/patient/register/{register_uuid}/start-reception`
- Medical 病历、AI 助手、相似病历及检查 / 检验 / 处置接口

AI 上下文：

- `POST /api/v1/patient/triage` 支持 `session_uuid`
- 预挂号支持 `triage_session_uuid`
- `GET /api/v1/patient/register/{register_uuid}/ai-context`

## 修改与验证

- 先检查 entry point、caller、dependency、test 和类似实现，再修改。
- 优先复用现有 architecture，避免无关重构。
- 工作区可能包含其他未提交改动；不要回退、覆盖或顺带提交无关文件。
- 有意义的修改后运行相关测试、类型检查或构建；未验证的内容不能宣称完成。
- 不使用 `git reset --hard`、`git checkout --` 或 force push 回退用户改动。
- 除非用户明确要求，否则不要 push。

## Windows 注意事项

- 使用与当前 PowerShell 环境匹配的命令。
- 中文 Markdown 按 UTF-8 读取和写入。
- 不通过 PowerShell 到 Python stdin 的管道批量写中文文档。
- `apply_patch` 失败时先缩小补丁范围，不要循环执行同一失败操作。

## 文档维护

- `README.md`：技术基线、启动方式和入口。
- `docs/项目规划.md`：总体状态、差距和路线图。
- `docs/frontend-plan.md`：前端路由、页面和当前切片。
- `docs/项目结构说明.md`：代码导航。
- 数据库、演示数据和 GitHub 协作保留独立文档。
- 完成专项后把结论合并回主文档并删除专项文件，不再新增阶段回顾、问题流水账或长期保留临时计划文档。
- 修改路由、入口、会话或阶段状态时，同一轮同步对应主文档。
