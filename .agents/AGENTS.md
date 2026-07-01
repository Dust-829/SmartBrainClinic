# AGENTS.md

本文档记录 SmartBrainClinic 仓库内 agent 协作时必须遵守的项目约束。后续 Codex、子 agent 或其他自动化接手时，先读本文，再读 `README.md`、`PRODUCT.md`、`docs/项目规划.md`、`docs/frontend-plan.md` 和 `docs/当前项目回顾.md`。

## 当前项目方向

- 当前真实实现是 Python FastAPI 微服务后端 + Vue 3 前端，不按早期 Java / Spring Boot 方向推进。
- 当前前端优先级固定为患者端主链路，暂不先铺医生端和管理员端业务页面。
- 患者端主链路为：登录 / 注册建档 -> 患者首页 -> 按科室挂号 -> 可选 AI 问诊 -> 医生推荐 -> 确认挂号 -> 支付 -> 候诊状态 -> 挂号记录。
- 只能接真实后端接口，不写大面积本地假业务。接口失败时显示错误、重试或空状态，不用假数据把页面填满。
- 脑科 / 神经外科门诊是当前固定演示主线，围绕头痛、恶心、视物模糊、疑似脑部占位等症状展开。

## 前端协作规则

- 患者端按移动端优先设计，保持蓝白医疗风格、圆角卡片、浅蓝提示条、底部导航和清晰中文文案。
- 首页不单独放“智能分诊”入口；智能分诊只作为“按科室挂号”流程里的可选辅助步骤。
- 从首页进入按科室挂号时，应弹出智能分诊提示；本次挂号流程已提示过或从 AI 问诊返回时，不再重复弹窗。
- 挂号页顶部提示条“不能确定科室？可使用智能分诊辅助推荐”应直接进入 `/patient/triage`，不再二次弹窗。
- 挂号到缴费成功链路统一使用 `PatientFlowHeader.vue`：左侧返回业务上一级，右侧一键回患者首页。
- 底部导航职责固定为：首页、挂号记录、消息、我的。第二项必须进入 `/patient/registers`，不是“去挂号”。
- 患者端不向患者展示内部编码，例如 `SJWK` 只能作为接口参数，界面展示“神经外科”。
- AI 结果必须标明来源，区分真实 LLM、规则、mock 和 fallback。不得把 mock/fallback 说成真实大模型输出。
- 全局角色切换按钮当前位于 `frontend/src/App.vue`，本阶段不要擅自移回单个页面。

## 真实接口边界

患者端第一阶段主要接口：

- `POST /api/v1/patient`：患者注册建档。
- `GET /api/v1/patient/card/{card_number}`：轻量登录查询已建档患者。
- `POST /api/v1/patient/triage`：AI 分诊。
- `GET /api/v1/patient/departments`：科室列表。
- `POST /api/v1/patient/recommend-doctors`：医生推荐。
- `GET /api/v1/patient/schedules?employee_uuid={uuid}`：医生可用排班。
- `POST /api/v1/patient/online-register`：线上预挂号锁号。
- `POST /api/v1/patient/online-register/pay`：线上支付模拟。
- `GET /api/v1/patient/register/{uuid}`：挂号详情。
- `GET /api/v1/patient/register/{register_uuid}/queue-status`：候诊状态。
- `GET /api/v1/patient/{patient_uuid}/registers/detail`：历史挂号详情。

## 工具与技能

- 项目已安装 `impeccable` 到 `.claude/skills/impeccable/`，UI / 前端 / 交互 / 视觉一致性任务应优先使用它。
- 使用方式：先运行 `node .claude/skills/impeccable/scripts/context.mjs --target frontend`，再结合 `PRODUCT.md` 和现有组件判断。
- 本仓库只放入当前项目确实需要的 skill。其他与本项目前端无关的学术、邮箱、文档类 skill 不放进仓库。
- Windows PowerShell 直接 `Get-Content` 中文 Markdown 可能显示乱码。判断文件内容时优先用 Node.js 按 UTF-8 读取。
- 当前已开启完整文件访问权限，`apply_patch` 可以正常修改文件。不要使用 `git reset --hard` 或 `git checkout --` 回退用户改动。
- `gh` 当前未安装，不能依赖 GitHub CLI 自动开 PR；如需推送，优先使用本地 `git push`。

## 文档维护

- 总项目计划维护在 `docs/项目规划.md`。
- 前端专项计划维护在 `docs/frontend-plan.md`。
- 当前阶段回顾维护在 `docs/当前项目回顾.md`。
- 开发问题统一记录在 `docs/问题记录.md`。
- 设计稿和概念图放在 `docs/assets/`。
- 修改设计、流程、工具约束或接口边界时，必须同步更新相关文档，并保留已完成进度记录。
