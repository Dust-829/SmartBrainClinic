# 前端实施计划

更新时间：2026-07-07。

本文档用于维护智慧云脑诊疗平台前端专项计划，重点记录三端前端结构、路由边界、会话状态拆分、真实接口接入策略、阶段计划和当前执行切片。总业务范围以 `docs/项目规划.md` 为准。

## 1. 当前前端方向

前端已经明确转为“三端独立”方案：
- 患者端独立登录、独立首页、独立主链路。
- 医生端独立登录、独立工作台、独立业务流程。
- 管理员端独立登录、独立控制台、独立管理流程。

这里的独立，指产品体验、路由入口、会话状态和守卫边界独立；当前仍保持一个 `frontend/` 工程，不拆成三个仓库。

## 2. 建设原则

- 只接真实后端接口，不用大面积前端假业务填流程。
- 患者端继续优先推进，但结构必须按三端独立方式收口。
- 患者端移动端优先，医生端和管理员端桌面端优先。
- 三端可以共享请求层、基础组件、主题变量和工具函数，但不能再共享一个产品级角色切换入口。
- 患者端不展示后端内部编码，例如 `SJWK` 只用于接口参数，不直接给患者显示。
- AI 结果必须能区分来源，不能把规则兜底或 mock 伪装成真实大模型能力。
- 路由守卫和会话状态按端拆开，不允许跨端串用登录态。

## 3. 当前工程状态

已完成：
- Vue 3 + Vite 工程初始化。
- `Vue Router`、`Pinia`、`Axios`、`Element Plus` 接入。
- 三套基础布局已存在：
  - `frontend/src/layouts/PatientLayout.vue`
  - `frontend/src/layouts/DoctorLayout.vue`
  - `frontend/src/layouts/AdminLayout.vue`
- 公共请求层已存在：`frontend/src/api/http.ts`
- 患者端主流程状态已存在：`frontend/src/stores/patientFlow.ts`
- 产品级全局三端切换入口已移除，不再在 `App.vue` 顶部保留角色切换按钮。

当前遗留：
- 医生端工作台仍以占位骨架为主，未完成真实数据联动。
- 管理员端目前只有登录占位页和控制台骨架，尚未开始真实业务面联动。
- 患者链路已完成登录态拆分与守卫接管，但后续仍需要按小步持续回归验证。

最近已完成回顾：
- 已移除产品级全局三端切换入口，`App.vue` 不再承担角色切换职责。
- 已补齐 `patientSession`、`doctorSession`、`adminSession` 三套独立 session store，并统一挂到共享 `pinia` 实例。
- 已把患者登录页、注册页和患者端主要业务页的身份读取从 `patientFlow` 迁到 `patientSession`。
- 已清理 `patientFlow` 的剩余登录态兼容出口，使其回到纯业务 flow store。
- 已完成路由 `role` / `requiresAuth` meta、通用登录态判定工具和全局前置守卫。
- 已新增 `/doctor/login`、`/admin/login` 占位页，并把 `/doctor`、`/admin` 默认入口收口到各自登录页。
- 已显式收口医生业务首页为 `/doctor/workbench`，管理员首页为 `/admin/console`。
- 已把患者端默认入口切到首页，当前 `/patient` 为患者首页入口，`/patient/login` 为独立登录页。

## 4. 三端结构目标

### 4.1 患者端

当前路由：
- `/patient`
- `/patient/login`
- `/patient/register`
- `/patient/home`
- `/patient/departments`
- `/patient/triage`
- `/patient/doctors`
- `/patient/confirm-register`
- `/patient/payment`
- `/patient/queue`
- `/patient/registers`
- `/patient/profile`

患者端主链路：

```text
患者首页
-> 登录 / 注册建档
-> 返回患者首页
-> AI 问诊或按科室挂号
-> 医生推荐
-> 选择日期 / 午别 / 具体时间
-> 线上预挂号
-> 支付
-> 候诊状态
-> 历史挂号 / 个人中心
```

### 4.2 医生端

目标入口：
- `/doctor/login`
- `/doctor/workbench`
- `/doctor/queue`
- `/doctor/encounter/:registerId`
- `/doctor/records`

医生端最小闭环：

```text
医生登录
-> 工作台
-> 今日候诊列表
-> 接诊详情
-> 查看 AI 问诊摘要
-> 医生确认病历 / 检查 / 处方
```

### 4.3 管理员端

目标入口：
- `/admin/login`
- `/admin/console`
- `/admin/doctors`
- `/admin/schedules`
- `/admin/audit`

管理员端最小闭环：

```text
管理员登录
-> 控制台
-> 医生 / 科室查看
-> 排班生成与审批
-> AI 审计查看
```

## 5. 会话与守卫拆分目标

建议形成三套独立 session store：
- `patientSession`
- `doctorSession`
- `adminSession`

要求：
- 三端各自维护登录态、身份对象和默认落地页。
- 未登录访问业务页时，跳回本端登录页，而不是跳去别的端。
- `patientFlow` 只保留患者业务流程状态，不再兼管会话状态。
- 后续全局守卫按路由 `role` 和 `requiresAuth` 做判断。
- 当前患者端入口语义为：`/patient` 打开首页，`/patient/login` 打开登录页。

## 6. 真实接口接入边界

### 6.1 患者端

继续优先使用现有真实接口：
- `POST /api/v1/patient`
- `GET /api/v1/patient/card/{card_number}`
- `POST /api/v1/patient/triage`
- `GET /api/v1/patient/departments`
- `POST /api/v1/patient/recommend-doctors`
- `POST /api/v1/patient/online-register`
- `POST /api/v1/patient/online-register/pay`
- `GET /api/v1/patient/register/{uuid}`
- `GET /api/v1/patient/register/{register_uuid}/queue-status`
- `GET /api/v1/patient/{patient_uuid}/registers/detail`

### 6.2 医生端

医生端优先围绕真实挂号、候诊、病历、检查、处方相关接口搭建最小工作台，不补大面积假流程。

### 6.3 管理员端

管理员端优先围绕医生、科室、排班、审批、审计相关接口搭建控制台，不补大面积假流程。

## 7. 大阶段计划

### 阶段 0：工程初始化

已完成。

### 阶段 1：患者端主链路收口

进行中。

已完成：
- 登录
- 注册建档
- 首页
- 按科室挂号入口
- AI 问诊
- 医生推荐
- 挂号确认
- 支付
- 候诊状态
- 历史挂号
- 个人中心

待继续：
- 继续统一患者链路的加载、错误、空态与移动端细节。
- 在真实浏览器链路下补一次患者端受限路由回归检查。
- 保持患者链路稳定的前提下，开始医生端工作台真实数据盘点与联动。

### 阶段 2：医生端独立登录与最小工作台

目标：
- 独立医生登录页。
- 工作台首页。
- 真实候诊或挂号列表首屏。
- 医生接诊详情最小闭环。
当前状态：进行中。
阶段说明：独立登录入口和默认路由收口已完成，下一步进入工作台假数据与真实接口盘点。

### 阶段 3：管理员端独立登录与控制台

目标：
- 独立管理员登录页。
- 控制台首页。
- 排班、审批、审计的最小入口。
当前状态：进行中。
阶段说明：独立登录入口和控制台首页骨架已具备，真实业务面仍未展开。

### 阶段 4：三端入口与会话边界收口

目标：
- 三端都有独立入口。
- 三端都有独立默认首页。
- 路由守卫可独立工作。
- 不再依赖共享角色状态或共享产品入口。
当前状态：已完成。
阶段说明：session store 拆分、患者登录态迁移、meta/guard 落地、doctor/admin 独立登录入口与默认跳转均已收口完成。

### 阶段 5：医生端真实数据联动与演示收口

目标：
- 医生工作台接入真实数据。
- 补最小加载态、空态、错误态。
- 固化一条可重复演示路径。

## 8. 单轮执行切片

为避免一次对话改动过多，后续执行按“每轮只做一个最小子步”推进。每个子步都应满足：
- 修改范围收敛到同一条链路或同一类文件。
- 做完即停，并汇报改动文件、残留兼容点和最小验证结果。
- 没进入当前子步范围的 router、guard、doctor/admin 页面，不提前联动。

### 1. 拆 session store 骨架

#### 1.1 封装 sessionStorage 读写
目标：抽出通用会话存取工具，避免三端 store 各自重复写浏览器存储逻辑。
涉及文件：
- `frontend/src/stores/sessionStorage.ts`
交付标准：
- 能按 key 读取、写入、清除会话数据。
- 对空值和 JSON 解析失败有兜底处理。
当前状态：已完成。

#### 1.2 建立 Pinia 根实例导出
目标：统一状态挂载入口，为后续 session store 和守卫提供一致依赖。
涉及文件：
- `frontend/src/stores/pinia.ts`
交付标准：
- 前端统一复用同一个 `pinia` 实例。
当前状态：已完成。

#### 1.3 建立三端 session store 骨架
目标：拆出患者、医生、管理员三套会话容器，只负责登录态和身份信息。
涉及文件：
- `frontend/src/stores/patientSession.ts`
- `frontend/src/stores/doctorSession.ts`
- `frontend/src/stores/adminSession.ts`
交付标准：
- `patientSession` 至少管理 `patient`、`loginDraft`、`isLoggedIn`。
- `doctorSession`、`adminSession` 至少管理基础身份对象和 `isLoggedIn`。
- 都具备最小 `login` / `logout` 能力。
当前状态：已完成。

#### 1.4 让 patientFlow 先退化为兼容层
目标：先让 `patientFlow` 内部转接 `patientSession`，不一次性重写所有患者页。
涉及文件：
- `frontend/src/stores/patientFlow.ts`
交付标准：
- `patientFlow` 内部不再自行持有患者登录态来源。
- 外部旧页面暂时还能通过 `patientFlow` 工作。
当前状态：已完成。

### 2. 患者端登录态从 patientFlow 挪出去

#### 2.1 登录页和注册页直连 patientSession
目标：从登录入口先切，让登录、注册动作直接读写 `patientSession`。
涉及文件：
- `frontend/src/views/patient/PatientLoginView.vue`
- `frontend/src/views/patient/PatientRegisterView.vue`
交付标准：
- 页面初始化直接读取 `session.loginDraft`。
- 登录成功、注册成功直接调用 `session.login(...)`。
- 跳转注册或“已注册请登录”直接调用 `session.setLoginDraft(...)`。
当前状态：已完成。

#### 2.2 患者业务页面直接读取 patientSession 身份
目标：把首页、分诊、挂号、支付、排队、个人中心等页面对“当前患者是谁”的读取，从 `patientFlow` 切到 `patientSession`。
涉及文件：
- `frontend/src/views/patient/PatientHomeView.vue`
- `frontend/src/views/patient/PatientTriageView.vue`
- `frontend/src/views/patient/PatientDoctorsView.vue`
- `frontend/src/views/patient/PatientConfirmRegisterView.vue`
- `frontend/src/views/patient/PatientPaymentView.vue`
- `frontend/src/views/patient/PatientQueueView.vue`
- `frontend/src/views/patient/PatientRegistersView.vue`
- `frontend/src/views/patient/PatientProfileView.vue`
交付标准：
- 页面直接从 `patientSession` 读取患者身份、登录态或登录草稿。
- `patientFlow` 只继续承载分诊、医生推荐、号源、支付、候诊等业务流状态。
当前状态：已完成。

#### 2.3 清理 patientFlow 剩余登录态兼容出口
目标：在患者页都切完后，删除 `patientFlow` 里多余的登录态兼容接口。
涉及文件：
- `frontend/src/stores/patientFlow.ts`
交付标准：
- 不再把 `patient`、`loginDraft`、`isLoggedIn` 作为对外推荐出口。
- 移除 `setPatient`、`setLoginDraft` 等仅服务兼容层的方法。
当前状态：已完成。

### 3. 路由 meta 和通用守卫

#### 3.1 为三端路由补 meta
目标：明确每条路由属于哪个端，以及是否需要登录。
涉及文件：
- `frontend/src/router/index.ts`
交付标准：
- `patient`、`doctor`、`admin` 路由组具备 `role` 标记。
- 需要登录的业务页具备 `requiresAuth` 标记。
当前状态：已完成。

#### 3.2 抽通用登录态判定工具
目标：减少守卫内硬编码判断，让三端登录态读取方式可复用。
涉及文件：
- `frontend/src/router/` 下新增工具文件，或 `frontend/src/stores/` 下新增通用判定模块。
交付标准：
- 能统一按 `role` 读取对应 session store。
- 能返回“是否已登录”和“未登录应跳去哪里”。
当前状态：已完成。

#### 3.3 增加全局前置守卫
目标：正式接管跨页访问边界，防止未登录直接进入三端业务页。
涉及文件：
- `frontend/src/router/index.ts`
交付标准：
- 患者未登录访问受限页时跳回患者登录入口。
- 医生、管理员后续可跳到各自登录页。
- 不允许跨端复用另一端的登录态直接放行。
当前状态：已完成。

#### 3.4 做患者链路最小回归验证
目标：确认守卫加上后，不把患者现有链路打断。
涉及文件：
- 以验证为主，不强调新增文件。
交付标准：
- 患者登录、注册、首页、挂号主链路跳转保持可用。
- 至少通过 `vue-tsc --noEmit`，必要时补一次构建验证。
当前状态：已完成。

### 4. 新增 doctor/admin 登录占位入口

#### 4.1 新增 `/doctor/login` 占位页
目标：先把医生端入口从业务页直出改成独立登录入口。
涉及文件：
- `frontend/src/views/doctor/DoctorLoginView.vue`
- `frontend/src/router/index.ts`
交付标准：
- 可访问独立医生登录页。
- 先允许占位登录，不要求真实鉴权闭环。
当前状态：已完成。

#### 4.2 新增 `/admin/login` 占位页
目标：让管理员端也拥有独立入口，避免继续共享旧的 staff 入口语义。
涉及文件：
- `frontend/src/views/admin/AdminLoginView.vue`
- `frontend/src/router/index.ts`
交付标准：
- 可访问独立管理员登录页。
- 页面结构和入口命名与医生端一致。
当前状态：已完成。

#### 4.3 staff 入口改为跳转独立登录页
目标：把现有 staff 侧入口收口到 `/doctor/login`、`/admin/login`。
涉及文件：
- `frontend/src/router/index.ts`
- 可能涉及现有医生端、管理员端入口页或布局文件。
交付标准：
- 不再默认用 `/doctor` 直接承载业务页首屏。
- doctor/admin 的入口语义和患者端明显分离。
当前状态：已完成。

### 5. 医生端工作台联动真实数据

#### 5.1 盘点医生端假数据入口与真实接口
目标：先确认当前工作台哪些内容是静态占位，哪些能直接接已有后端接口。
涉及文件：
- `frontend/src/views/doctor/DoctorWorkbenchView.vue`
- 相关医生端 API 文件。
交付标准：
- 列清真实可接接口、仍缺的接口、需要保留占位的区域。
盘点结论：
- 当前 `DoctorWorkbenchView.vue` 全量为静态占位，没有任何真实 API 调用。
- 人工业务区里的候诊列表 `queueItems` 是本轮最适合先替换的假数据块；后端已存在 `GET /api/v1/patient/doctor/{employee_uuid}/queue`，返回 `register_uuid`、`patient_uuid`、`patient_name`、`patient_case_number`、`gender`、`symptoms`、`visit_state`、`visit_state_text`、`visit_date`、`time_range`、`clinic_room_name`，可直接支撑“今日候诊列表”首屏。
- 候诊状态推进也已有后端接口：`PUT /api/v1/patient/register/{uuid}/state`、`PUT /api/v1/patient/register/{uuid}/start-reception`、`PUT /api/v1/patient/register/{uuid}/finish`，后续可接“叫号 / 开始接诊 / 结束接诊”一类操作。
- AI 辅助区已有可复用真实接口：`POST /api/v1/medical/record/ai-assistant`、`POST /api/v1/medical/record/search-similar`、`GET /api/v1/medical/record/draft/{register_uuid}`、`PUT /api/v1/medical/record/draft/{register_uuid}/confirm`，分别对应 AI 问答、相似病历召回、AI 病历草稿读取与医生确认。
- 检查检验处置相关接口已存在：`POST /api/v1/medical/check`、`POST /api/v1/medical/inspection`、`POST /api/v1/medical/disposal`，以及对应详情和状态更新接口，可支撑后续“开单”和结果查看。
- 处方推荐接口已存在：`POST /api/v1/pharmacy/recommend-prescription`，入参为 `register_uuid`，适合放到 AI 辅助区后续联动。
- 当前仍缺的是前端医生端专用 API 封装文件、工作台与 `doctorSession` 的身份串联，以及基于 `register_uuid` 的接诊详情页实际承载页面；这些属于 `5.2` 及以后范围，不在本步实现。
当前建议：
- 下一最小步优先做 `5.2 接入医生登录态到工作台`，先让工作台拿到 `doctorSession.staffCode / 身份信息`，再决定如何映射到后端 `employee_uuid`。
当前状态：已完成。

#### 5.2 接入医生登录态到工作台
目标：让医生工作台至少能读取本端 session，而不是无身份上下文运行。
涉及文件：
- `frontend/src/stores/doctorSession.ts`
- `frontend/src/views/doctor/DoctorWorkbenchView.vue`
- 可能涉及医生端布局文件。
交付标准：
- 登录后的医生身份可在工作台读取。
- 未登录状态下的渲染逻辑和后续守卫方案一致。
当前状态：待执行。

#### 5.3 工作台首屏切到真实数据
目标：优先把最关键的一块列表从静态数据切到真实接口，例如今日候诊、挂号队列或待接诊列表。
涉及文件：
- `frontend/src/views/doctor/DoctorWorkbenchView.vue`
- 医生端相关 API 文件。
交付标准：
- 至少一块核心列表改为真实接口返回。
- 明确字段映射，不再只是静态卡片展示。
当前状态：待执行。

#### 5.4 补加载态、空态、错误态并做最小回归验证
目标：不把真实接口联动停留在“能请求到数据”，而是补最基础页面稳定性。
涉及文件：
- 以上医生端工作台相关文件。
交付标准：
- 具备最小加载态、空态、错误态。
- 至少通过 `vue-tsc --noEmit`，必要时补一次构建验证。
当前状态：待执行。

## 9. 当前建议起点

如果继续按小步推进，下一轮最合适的切片是：`5.1 盘点医生端假数据入口与真实接口`。

## 10. 文档维护规则

- 总体产品边界、阶段方向维护在 `docs/项目规划.md`。
- 前端页面、路由、状态拆分和执行切片维护在本文档。
- 问题台账统一维护在 `docs/问题记录.md`。
- 每完成一个执行切片，就在本文档更新对应子步的状态，不把进度只留在对话里。
