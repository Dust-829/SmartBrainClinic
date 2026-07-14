# Goal

实现管理员端药房工作台的真实业务闭环，并把现有表单式页面重构为驾驶舱 + 队列详情 + 库存操作的一体化工作台。

## Current behavior

- 管理员端药房页面已接入 `batch-import / listDrugs / listPrescriptions / dispense / return` 等基础接口。
- 前端仍主要依赖手工输入 `prescription_uuid` 触发发药和退药，缺少真实队列与详情联动。
- 后端缺少面向管理员工作台的聚合接口，患者/挂号/诊室上下文没有集中补齐。
- 批量入库仍会把重复 `drug_code` 等问题透传成通用异常，缺少逐项反馈。

## Proposed solution

- 在 `pharmacy service` 内新增管理员工作台聚合接口：
  - `GET /api/v1/pharmacy/admin/workbench/overview`
  - `GET /api/v1/pharmacy/admin/workbench/prescriptions`
  - `GET /api/v1/pharmacy/admin/workbench/prescriptions/{uuid}`
  - `GET /api/v1/pharmacy/admin/workbench/drugs`
- 新增库存调整接口：
  - `POST /api/v1/pharmacy/admin/workbench/drugs/{uuid}/stock-adjustments`
  - payload 固定为 `{ mode: "increase" | "set", quantity: number }`
- 保留并复用现有命令接口：
  - `PUT /api/v1/pharmacy/prescription/{uuid}/dispense`
  - `PUT /api/v1/pharmacy/prescription/{uuid}/return`
  - `POST /api/v1/pharmacy/drugs/batch-import`
- 改造批量入库逻辑：
  - 请求内重复 `drug_code` 前置校验
  - 库内已存在 `drug_code` 返回明确失败项
  - 返回结构改成 `successes + failures`
- 重写前端 `AdminPharmacyView.vue`：
  - Hero 指标区展示待发药、可退药、低库存、药品总数
  - 左侧处方队列支持 `待发药 / 可退药 / 全部` 切换
  - 右侧详情区展示单张处方的患者、挂号、诊室、药品明细和唯一主操作
  - 次级区域拆成低库存重点、库存总览、新药批量入库、已有药品补货/校正
  - 删除所有手输 UUID 的操作入口
- `frontend/src/api/admin.ts` 补齐工作台类型、分页结构、详情结构和库存调整调用，并为发药/退药带上 `Idempotency-Key`。

## Risks

- 工作台聚合依赖 `PatientClient.get_register()` 返回的挂号上下文字段；若下游字段缺失，只能展示真实空值，不能伪造。
- 当前测试环境缺少部分 Python 依赖时，后端 `pytest` 可能先失败在环境导入阶段，需要区分环境问题与业务回归。
- 批量入库返回结构调整后，前端必须同步切换到 `successes / failures`，否则会出现旧页面解析失败。

## Validation strategy

- 后端：
  - 新增 `backend/tests/test_pharmacy_admin_workbench.py`
  - 覆盖工作台概览、处方列表/详情、库存调整、批量入库校验
- 前端：
  - `npm run build`
  - 手工验证工作台刷新、队列切换、选中详情、发药/退药、库存筛选、批量入库、库存校正
- 集成：
  - 若本地微服务可运行，再补一条已缴费处方 -> 发药 -> 退药 -> 库存恢复的真实链路验证
