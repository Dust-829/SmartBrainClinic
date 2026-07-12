# 患者端动态就诊码实施计划

> 状态：待实施。范围为本项目院内使用的“动态就诊核验码”；不等同于国家医保码，也不宣称已接入医保便民服务。

## 1. Goal

为已登录患者提供一个可刷新、短时有效、服务端核验的二维码。导诊台或医生端扫描后，仅获得完成本次到院/接诊核验所需的最小信息，并留下审计记录。

## 2. Current behavior

- 患者首页和个人中心已有“就诊码”入口，但 `PatientProfileView.vue` 仅展示 `patientFlow.onlineRegister.qr_code_url`。
- 该字段由 `POST /api/v1/patient/online-register` 返回，当前内容是模拟微信支付 URL；它既不是二维码图片，也不能证明患者身份或挂号有效性。
- `Register` 已有关联患者、排班、诊室、就诊状态和时段的数据；已支付的 `REGISTERED` 和接诊中的 `RECEPTION` 状态足以作为首版可出示就诊码的业务依据。
- 患者、医生前端 session 均是浏览器本地状态；Patient Service 的现有挂号、候诊和接诊接口没有服务端调用方身份/归属校验。因此不得在该基础上直接把就诊码用于真实院内身份核验。

## 3. Proposed solution

### 3.1 产品边界与交互

1. 新增受保护路由 `/patient/visit-code`，首页和个人中心入口均跳转到此页；不再展示支付 URL。
2. 页面显示动态二维码、剩余有效期、患者姓名脱敏/门诊号、当前有效挂号的科室、医生、日期和时段；不显示身份证号、患者 UUID、挂号 UUID 或诊室内部 ID。
3. 有一条当日且状态为 `REGISTERED`/`RECEPTION` 的有效挂号时签发“本次就诊码”；没有有效挂号时显示明确空状态，并引导至挂号记录或挂号入口。
4. 二维码在到期前自动刷新，允许手动刷新；离开前台或网络失败时停止倒计时并展示重新获取操作。默认有效期建议 60 秒，作为配置项而不是前端常量。
5. 医生/导诊核验端首版采用“扫描或粘贴二维码内容 -> 服务端核验 -> 展示最小核验结果 -> 确认核验”的两步交互；成功后显示本次挂号、患者姓名脱敏、核验时间和状态，不返回完整病历。

### 3.2 服务端设计

1. 先补齐真实鉴权与授权中间件：患者只能签发本人凭证；医生/导诊员只能核验其授权范围内的挂号。认证主体从服务端 token/session 得到，不能信任请求体中的 `patient_uuid` 或 `employee_uuid`。
2. 新建 `visit_code` 表和迁移，建议字段：`id`、`uuid`、`patient_id`、`register_id`、`code_hash`、`issued_at`、`expires_at`、`redeemed_at`、`redeemed_by`、`revoked_at`、`purpose`、`created_at`。对 `code_hash` 建唯一索引，对 `(register_id, expires_at)` 建查询索引。
3. 签发时用加密安全随机数生成不透明 token；数据库只保存 hash。二维码 payload 只包含版本和 token（例如 `SBC:VC1:<opaque-token>`），不放可逆身份信息、URL 查询参数或签名密钥。
4. `POST /api/v1/patient/visit-codes`：从认证身份取得患者，锁定并校验其当日可用挂号，撤销该挂号仍有效的旧码，写入新码后返回 `payload`、`expires_at` 和已脱敏展示字段。
5. `POST /api/v1/staff/visit-code-verifications`：要求 staff 权限；校验格式、hash、有效期、撤销/已使用状态、挂号状态、核验者与诊室/医生归属。成功后以事务方式写入核验记录并使该码失效，返回最小核验结果；失败统一返回不可用提示，审计失败原因但不泄露患者是否存在。
6. 状态变化时主动撤销关联码：支付撤销/退号、挂号取消、接诊结束、患者登出或显式刷新。为保留扩展性，核验记录独立为 `visit_code_verification` 表（操作人、终端/来源、结果、失败原因码、时间），而非仅依赖 `redeemed_at`。
7. 为签发、核验和撤销添加结构化审计日志、限流、关联请求 ID 和异常告警；日志只记录 token 指纹或 code UUID，绝不记录原始二维码内容。

### 3.3 前端与依赖

1. 在 `frontend/src/api/patient.ts` 增加 `createVisitCode()` 和严格的响应类型；新增 `visitCode` 临时状态，不把 token 持久化到 Pinia/sessionStorage。
2. 新增 `PatientVisitCodeView.vue`，复用患者端 design tokens 和移动端页面结构。使用成熟的本地 QR renderer 生成 canvas/SVG；新增依赖前先确认其维护状态、包体积和许可证。
3. 新增 staff 端核验组件/页面，优先支持受控扫码枪文本输入；若需要手机摄像头扫描，再单独评估摄像头权限、HTTPS 和扫码库，避免首版把硬件兼容性与核心核验逻辑耦合。
4. 支付页的 `qr_code_url` 明确仅用于模拟支付，不复用于就诊码；清除 `PatientProfileView.vue` 中的支付 URL 图片弹窗。

## 4. Delivery slices

1. **安全前置**：梳理 Gateway/Auth 的实际认证模型，补充患者和 staff token、角色与资源归属校验；为既有高风险挂号/接诊接口补回归测试。
2. **数据与领域服务**：添加迁移、实体、token hash、签发/撤销/核验服务、审计表与状态转换钩子。
3. **API 与测试**：提供签发、核验接口；覆盖所有权、过期、重放、取消/退号、并发双扫、跨医生/诊室核验和不泄露存在性的失败响应。
4. **患者端**：实现独立动态就诊码页、倒计时刷新、空/加载/错误状态，替换现有支付二维码复用。
5. **staff 核验端**：实现输入/扫码枪核验流程、最小结果展示和审计反馈；摄像头扫描作为可选后续切片。
6. **联调与上线控制**：使用当日真实挂号完成端到端演练，配置有效期、限流和密钥轮换；在审计、权限和重放测试未通过前保持功能关闭。

## 5. Risks

- 目前的演示登录与接口信任客户端 UUID 的模式不具备生产级访问控制；若跳过安全前置，二维码会扩大越权读取与冒用风险。
- 把患者号、身份证号或挂号 UUID 直接编码进二维码会造成截图泄露和重放风险；必须使用随机不透明 token、短时有效和服务端核验。
- 一次成功核验即失效最能防重放，但会影响多节点反复出示；首版以“单次到院/接诊核验”限定用途，未来多场景需单独引入一次性 challenge 或按用途的凭证策略。
- “国家医保码/医保电子凭证”涉及合作渠道接入、规范和资质，不能用本项目自建码替代或冒充。

## 6. Validation strategy

- 后端：新增单元、服务和 API 集成测试，重点验证 token 不落日志、不能跨患者签发、不能跨 staff 范围核验、过期/撤销/重放均失败，以及并发双扫只有一次成功。
- 前端：`npm run build`、常见 360--430px 宽度回归、屏幕阅读器标签和键盘焦点检查；二维码刷新不能造成页面跳动或泄露 token 到持久化存储。
- 联调：完成“登录患者 -> 支付成功 -> 出示码 -> staff 核验 -> 码失效 -> 队列/接诊继续”的真实数据演练，并检查审计记录完整性。
- 安全评审：依据 OWASP 的认证与二维码劫持风险检查 token 生命周期、认证/授权、TLS、日志脱敏、速率限制和异常响应。

## 7. Reference material

- [国家医疗保障局：医保便民服务国家标准](https://www.nhsa.gov.cn/art/2025/8/12/art_14_17556.html)：后续医保便民服务对接的合规边界参考，不适用于替代本项目自建院内码。
- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)：认证、会话与 token 生命周期要求。
- [OWASP QRLJacking](https://owasp.org/www-community/attacks/Qrljacking)：二维码被替换、截图和诱导扫描的风险背景。
- [ONC SAFER：Patient Identification](https://www.healthit.gov/sites/default/files/playbook/pdf/6-patient-identification-final.pdf)：在关键医疗流程使用条码/二维码核验患者身份的实施思路。
