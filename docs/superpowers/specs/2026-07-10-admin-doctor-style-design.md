# 管理员端视觉统一到医生端风格设计说明

## Goal

在不改变管理员端现有信息架构、功能行为、字段语义和路由结构的前提下，将全部管理员端前端界面统一为医生端当前使用的视觉语言与交互外观。

本次目标是“shared skin”式改造，而不是页面重构：

- 不新增或删除管理员端页面
- 不调整页面内的业务字段和功能流程
- 不修改数据加载、提交、审批、查询等业务逻辑
- 不改变现有路由、按钮行为、表单语义和接口调用
- 只改 layout、spacing、color、surface、button/input/list/card 等视觉与交互外观

## Current Behavior

管理员端当前已有完整页面集合：

- `AdminLoginView.vue`
- `AdminDashboardView.vue`
- `AdminAccountsView.vue`
- `AdminSchedulesView.vue`
- `AdminApprovalsView.vue`
- `AdminAuditView.vue`
- `AdminBillingView.vue`
- `AdminAnalyticsView.vue`
- `AdminPharmacyView.vue`
- `AdminDoctorsView.vue`
- `AdminDepartmentsView.vue`
- `AdminRoomsView.vue`
- `AdminConsoleView.vue`

当前问题不是功能缺失，而是视觉系统不统一：

- `AdminLayout.vue` 使用深色侧栏和偏独立的管理员端品牌表达，与医生端浅色侧栏骨架不一致
- 多个管理员页面各自维护一套 `hero` 配色，存在 indigo / blue / amber / purple 等分散色系
- 各页面本地 `scoped style` 中重复定义 form、list、empty、button、card 等模式
- 医生端已形成较稳定的视觉语言：teal 主色、浅色背景、白色 surface、统一 hero、统一 card 半径与边框、统一状态块与列表块

这导致管理员端虽然功能可用，但整体体验不像同一产品线。

## Design Thesis

管理员端保留“后台工作台”定位，但视觉上完全并入医生端语言：用同样的 teal 主色、同样的浅背景和卡片语法，把管理员页面从“每页单独设计”收敛成“一套统一骨架下的不同工作面板”。

签名动作只有一个：所有管理员页统一使用医生端式 hero + workspace + panel 结构，不再让每页拥有独立品牌色和局部视觉规则。

## Proposed Solution

### 1. 统一 layout 层

重做 `AdminLayout.vue` 的视觉表达，使其与 `DoctorLayout.vue` 同源：

- 整体页面背景改为医生端同系浅色底
- 侧栏从深色改为白色 surface + 淡边框
- 侧栏品牌区、导航、身份卡的 spacing、radius、边框和按钮样式对齐医生端
- 主内容区标题区不再单独维持当前管理员端 header 风格，而是提供更轻的壳层，让具体页面 hero 自己承担页面识别
- 保留管理员端导航项、文案、登录保护和 banner 逻辑

### 2. 抽管理员端共享视觉皮肤

新增一层管理员端共享样式文件，负责承载医生端视觉语言在管理员端的落地。该层只提供视觉 class，不承载业务逻辑。

预期覆盖的模式：

- 页面根容器：`admin-skin-page`
- hero：`admin-skin-hero`
- hero 指标组：`admin-skin-metrics`
- 工作区网格：`admin-skin-grid`
- 表单：`admin-skin-form`
- 工具栏：`admin-skin-toolbar`
- 列表：`admin-skin-list`
- 条目卡片：`admin-skin-item`
- 结果块 / 状态块：`admin-skin-state`
- empty state：`admin-skin-empty`
- 主按钮 / 次按钮：`admin-skin-button`
- tag / badge：`admin-skin-badge`

同时补一组管理员端 token，但其语义直接继承医生端审美方向：

- 主色：teal / slate
- 背景：浅灰蓝
- surface：白色
- muted 文本：slate
- radius：14 / 16 / 18
- border：浅蓝灰
- focus ring：teal

### 3. 页面逐个迁移到共享皮肤

对管理员端 13 个页面逐个做“样式替换，不改结构”：

- 保留原 template 的字段、SectionCard 组织方式、按钮位置和逻辑分支
- 只把原本页面内散落的本地视觉规则替换为共享 class
- 删除或压缩每页重复的样式定义，避免后续再次分叉

迁移方式按页面类型分组：

#### A. 登录与仪表盘

- `AdminLoginView.vue`
- `AdminDashboardView.vue`

这两页最直接体现第一印象，优先统一到医生端 hero 和 card 风格。

#### B. 列表 / 审批 / 分析页

- `AdminApprovalsView.vue`
- `AdminAnalyticsView.vue`
- `AdminAuditView.vue`
- `AdminBillingView.vue`
- `AdminDashboardView.vue`

这类页面主要统一：

- hero 风格
- 列表条目卡片
- empty state
- badge / status 色块

#### C. 表单工作台页

- `AdminSchedulesView.vue`
- `AdminPharmacyView.vue`
- `AdminConsoleView.vue`
- `AdminDoctorsView.vue`
- `AdminDepartmentsView.vue`
- `AdminRoomsView.vue`
- `AdminAccountsView.vue`

这类页面主要统一：

- form label / input / textarea / select
- 工具栏按钮
- 双列工作区
- 结果区 / 反馈区
- 弹窗 footer 按钮

### 4. 保持 SectionCard 为基础容器

`SectionCard.vue` 已经是共用容器，不引入新的 card 组件体系。若需要，只做小幅 token 化增强，让管理员端和医生端都能受益：

- header spacing
- body spacing
- radius / border / background

前提是变更不会破坏 patient / doctor 已有显示。

## Implementation Boundaries

以下内容明确不在本次范围：

- 不把管理员页面改成医生端的业务结构
- 不把多个管理员页面合并
- 不新增动画库、UI kit 或 icon 包
- 不引入新的状态管理层
- 不改 API 请求、参数、错误处理语义
- 不动非管理员端页面的业务结构

## Risks

### 1. `scoped style` 分散，迁移时容易漏样式

管理员页面几乎都自带大段 `scoped style`。如果共享样式命名不完整，可能出现部分按钮、列表或空状态仍沿用旧风格。

应对：

- 先定义共享模式清单
- 再逐页比对 `hero / form / list / empty / result / dialog`

### 2. `SectionCard` 是跨角色共用组件

如果直接修改过重，可能影响 patient / doctor 页面现有显示。

应对：

- 优先通过管理员端页面 class 覆盖
- 只有在确认收益大且影响可控时才调整 `SectionCard` 默认样式

### 3. Element Plus 弹窗与表单控件存在默认样式渗透

`el-dialog`、`el-skeleton` 等组件可能仍表现为框架默认观感。

应对：

- 在管理员端共享样式中补充必要的 `.admin-layout` 或页面级 Element Plus 覆盖
- 避免做全局无差别覆盖

## Validation Strategy

### 静态验证

- 运行 `npm run build`
- 确认 TypeScript 与 Vue SFC 编译通过

### 结构验证

逐项检查以下页面仍可进入且无模板错误：

- `/admin/login`
- `/admin/dashboard`
- `/admin/accounts`
- `/admin/schedules`
- `/admin/approvals`
- `/admin/audit`
- `/admin/pharmacy`
- `/admin/billing`
- `/admin/analytics`

以及额外的：

- `/admin/doctors`
- `/admin/departments`
- `/admin/rooms`
- `/admin/console`

### 视觉验证

人工检查以下一致性：

- 所有管理员页面 hero 是否统一为医生端同系视觉
- 所有主要按钮是否统一为同一主色与圆角体系
- 所有输入框、textarea、select 是否统一边框与 focus ring
- 所有 list / card / empty state 是否统一 surface 与边框语法
- 移动端断点下 sidebar、hero、双列工作区是否仍可读

## Recommended Execution Order

1. 先改 `AdminLayout.vue`
2. 新增管理员端共享皮肤样式文件
3. 先迁移 `AdminLoginView.vue` 与 `AdminDashboardView.vue`
4. 再迁移其余管理员页面
5. 最后运行构建验证并做视觉回查

## Success Criteria

完成后，用户应感受到：

- 管理员端与医生端属于同一产品视觉体系
- 即使不看路由，仅凭界面也能识别出共用的设计语言
- 管理员端功能和页面结构保持原样，但视觉不再割裂
