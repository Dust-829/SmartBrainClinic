# SmartBrainClinic AI 分诊与 AI 病历增强方案

> 专项设计留档。本文保留方案提出时的设计和假设；已落地状态与后续差距以 [项目规划.md](./项目规划.md) 为准。

更新时间：2026-07-15。状态说明：会话模型、挂号关联、`ai-context` 查询、Medical 草稿消费，以及患者端性别/年龄快照注入真实 LLM 分诊上下文均已在本地工作区完成实现；尚待执行数据库迁移并完成医生端只读展示验收。本文中的长期设计不等同于已发布能力。

## Summary

当前仓库已经具备这些基础能力：患者端 `AI triage`、医生端 `AI 病历草稿`、`相似病历召回`、`AI 医生助手`、以及 `ai_audit_log` 审计表；但现状仍有三个关键缺口：

- 医疗侧 AI 病历草稿仍然把 `register.symptoms` 同时当作症状摘要、对话原文和单次挂号输入来使用，模型上下文与业务字段耦合过深。
- 医生端还没有一个结构化的“决策辅助”输出层，现有 AI 助手主要是自由问答，不适合稳定生成风险提醒、补问建议、检查建议。

这次方案按当前约定的方向收口为：

- 保留全量长期 AI 档案，但长期病史只在医生侧 AI 中复用。
- 患者端只自动调用基础档案信息，不自动把既往病史塞回患者分诊对话。
- 首期范围做到三件事：`自动读患者基本信息 -> AI 分诊留痕 -> 医生端 AI 病历草稿 + 结构化决策辅助`。

## Key Changes

### 1. 用独立 AI 会话库替代 `register.symptoms` 过载

新增共享数据模型，放在现有 `common` 能力层，供 Patient 和 Medical 两个微服务共用：

- `ai_conversation_session`
  - `uuid`
  - `surface`：`patient_triage` / `doctor_assistant` / `doctor_decision_support`
  - `module_name`
  - `patient_uuid`
  - `register_uuid`（患者挂号前可为空，挂号成功后回填）
  - `employee_uuid`
  - `status`：`draft` / `linked` / `completed` / `abandoned`
  - `profile_snapshot_json`：本次 AI 实际看到的患者基础信息快照
  - `latest_result_json`：最新结构化结果
  - `summary_text`
  - `source` / `model` / `validated`
  - `created_at` / `updated_at`
- `ai_conversation_message`
  - `uuid`
  - `session_uuid`
  - `turn_index`
  - `role`
  - `content`
  - `created_at`

保留 `register.symptoms`，但角色改为“单次挂号可读摘要文本”，不再存完整对话 JSON。旧数据和旧流程继续兼容；新流程优先读 AI 会话表，缺失时再回退到 `register.symptoms`。

### 2. 患者端 AI 分诊改成“自动读档案 + 会话持久化”

扩展 `POST /api/v1/patient/triage`：

- 请求改为：
  - `patient_uuid?: UUID`
  - `session_uuid?: UUID`
  - `messages: TriageMessage[]`
  - `use_profile_defaults?: boolean`，默认 `true`
- 响应新增：
  - `session_uuid`

行为固定如下：

- 已登录且拿到 `patient_uuid` 时，后端读取 `Patient.gender / birthdate`，生成仅含性别和计算年龄的 `profile_snapshot_json` 注入 triage prompt；姓名、身份证号和住址不会发送给模型。
- 若基础档案已完整，AI 不再重复询问年龄和性别；只追问缺失信息或症状细节。
- 患者端不注入既往病史；既往病史只留给医生侧 AI 使用。
- 每轮分诊都写入 `ai_conversation_session` 和 `ai_conversation_message`，并把结构化 triage 结果同步到 `latest_result_json`。
- `POST /api/v1/patient/online-register` 新增 `triage_session_uuid?: UUID`，挂号成功后把该会话与 `register_uuid` 关联。
- 新增内部读取接口 `GET /api/v1/patient/register/{register_uuid}/ai-context`，返回本次分诊摘要、原始对话和档案快照，供 Medical 服务与医生端使用。

前端改动固定如下：

- [frontend/src/views/patient/PatientTriageView.vue](D:/work/SmartBrainClinic/frontend/src/views/patient/PatientTriageView.vue) 顶部继续显示患者卡片，但文案改成“已自动使用档案信息：性别/年龄”。
- `patientApi.triage()` 传 `patient_uuid` 和 `session_uuid`，并在 `patientFlow` 中持久化 `triage_session_uuid`。
- [frontend/src/views/patient/PatientRegisterConfirmView.vue](D:/work/SmartBrainClinic/frontend/src/views/patient/PatientRegisterConfirmView.vue) 挂号时连同 `triage_session_uuid` 一起提交。

### 3. 医生端 AI 病历草稿改成“当前分诊 + 既往确认病历”双来源

Medical 服务中，病历草稿生成链路调整为：

- `register_consumer.py` 不再直接把 `register.symptoms` 当唯一来源。
- 生成草稿时按顺序取上下文：
  1. `Patient` 基础档案快照
  2. 当前挂号关联的 triage transcript
  3. 当前挂号 triage summary
  4. 患者历史已确认 `medical_record`
- `medical_record` 继续是医生最终确认的正式病历；AI 草稿只改生成来源，不改确认流程。
- `dialog_vector` 的生成来源改为“医生确认后的正式病历正文”，不是患者原始聊天，从而保持相似病历召回质量稳定。

### 4. 医生端新增结构化 AI 决策辅助层

新增 `POST /api/v1/medical/record/decision-support`，请求：

- `register_uuid: UUID`
- `patient_uuid: UUID`
- `draft_fields`
  - `present`
  - `history`
  - `physique`
  - `diagnosis`
- `top_k?: number`

返回固定结构：

- `risk_flags[]`：需要优先排除的风险点
- `missing_questions[]`：还应继续追问的问题
- `suggested_checks[]`：建议优先开的检查/检验，带理由
- `similar_case_refs[]`：相似病例引用，带 `record_uuid` 和相似度
- `disclaimer`：明确“仅供医生参考，最终由医生确认”

`POST /api/v1/medical/record/ai-assistant` 同时补充 `register_uuid?: UUID`，有该值时自动把“当前 triage transcript + 当前 encounter 草稿 + 历史确认病历”一起注入助手上下文。

前端落点固定如下：

- [frontend/src/views/doctor/DoctorEncounterView.vue](D:/work/SmartBrainClinic/frontend/src/views/doctor/DoctorEncounterView.vue) 左侧主工作区不变，仍以病历与开单为主。
- 右侧辅助区调整为三个块：
  - `AI 风险提醒 / 补问建议`
  - `AI 检查建议 / 相似病例依据`
  - `自由问答 AI 助手`
- 现有“相似病历召回”和“AI 医生助手”复用，不新开独立页面。
- 医生确认病历仍然是唯一生效动作，AI 任何建议都不能直接写回正式诊断或处置。

### 5. 这套底座顺带支持的后续 AI 场景

本次不实现，但表结构与接口直接兼容后续扩展：

- 患者复诊前预问诊
- 检查/检验结果 AI 解释与复诊提醒
- 出院/门诊后随访建议草稿
- 管理员侧 AI 质量与安全审计看板
- 医生个人病例知识回顾与教学案例沉淀

## Public APIs / Types

需要明确变更的接口与类型：

- `TriageRequest`
  - 由 `messages` 扩展为 `patient_uuid? + session_uuid? + messages + use_profile_defaults?`
- `TriageResult`
  - 新增 `session_uuid`
- `OnlineRegisterCreate`
  - 新增 `triage_session_uuid?`
- 新增 `GET /api/v1/patient/register/{register_uuid}/ai-context`
- 新增 `POST /api/v1/medical/record/decision-support`
- `AIAssistantRequest`
  - 新增 `register_uuid?`
- 前端 `patientFlow` store
  - 新增 `triageSessionUuid`
- 共享 infra
  - 新增 `ai_conversation` 读写 helper，供 patient/medical 共用
  - `ai_audit_log` 继续只做脱敏审计，不承担全文会话留存职责

## Test Plan

必须覆盖这些场景：

- 已登录患者进入 AI 分诊时，年龄/性别不再被重复追问；未登录或档案缺失时，AI 仍能补问。
- 分诊多轮对话会持续写入 `ai_conversation_session/message`，并返回稳定的 `session_uuid`。
- 挂号成功后，`triage_session_uuid` 能正确关联到 `register_uuid`。
- Medical 异步草稿生成在新数据存在时优先读 triage transcript；只有旧数据时才回退到 `register.symptoms`。
- 医生打开 `/doctor/encounter/:registerId` 时，能同时看到当前挂号摘要、AI 草稿、决策辅助和相似病例引用。
- `decision-support` 输出必须保持结构化，不允许直接返回大段不可解析自由文本。
- 医生确认病历后，正式病历写回成功，相似病历向量仍基于正式确认内容生成。
- `ai_audit_log` 继续写入脱敏摘要，全文对话只存 `ai_conversation_*`，两者内容边界清晰。
- 回归路径至少验证：
  - 登录 -> AI 分诊 -> 医生推荐 -> 挂号 -> 支付 -> 草稿生成
  - 医生登录 -> 接诊详情 -> 看 AI 建议 -> 开单 -> 确认病历

## Assumptions

- 患者端历史病史不自动注入分诊，只自动注入基础档案；这是当前默认策略。
- 医生侧历史上下文只使用“历史已确认病历 + 本次 triage transcript + 患者基础档案快照”，不直接把未确认旧草稿当事实。
- 不新增独立 AI 微服务；继续沿用现有 FastAPI 微服务结构，在 `common` 中补共享 AI 会话基础能力。
- `pgvector` 继续只服务正式病历召回；患者原始聊天不直接进入相似病例召回向量库。
- 全部 AI 输出继续遵守现有项目规则：`AI 给建议，医生审核后生效`。
