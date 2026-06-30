# 前端实施计划

本文档用于指导智慧云脑诊疗平台前端建设，范围只覆盖当前真实后端能力可支撑的页面与交互，不提前引入大量假数据或未落地业务。

更新时间：2026-06-29。

## 1. 当前判断

当前项目适合开始做前端，但前端必须围绕现有 FastAPI 微服务接口来设计。

已具备的基础：

- 后端 6 个微服务已能启动并访问
- 患者、挂号、分诊、医生推荐、排队、病历、检查检验、处方、财务、排班等接口已经存在
- Gateway 已统一暴露网关入口，适合前端统一走网关调用

当前约束：

- `frontend/` 目录还是空的，前端工程需要从 0 初始化
- 登录鉴权体系还不完整，第一版不能把登录当成前置阻塞项
- 医学影像目前还是 `image_path + ai_tumor_prob + check_result` 的演示级能力，不是完整 DICOM 工作站
- 统计看板类接口还不够完整，管理员端第一版要先做业务管理，不先做复杂 BI

因此，前端第一阶段应以“最小可演示闭环”为目标，而不是一开始铺满所有角色和所有页面。

## 2. 前端目标

前端第一轮目标是完成三个端的最小可演示版本：

1. 患者端：手机端优先
2. 医生端：电脑端双栏工作台
3. 管理员端：电脑端管理后台

建设原则：

- 只接真实后端接口
- 先做主业务闭环，再补细节和视觉
- 页面风格必须区分患者端、医生端、管理员端
- 公共请求层、状态层、基础组件只写一套，不重复造轮子

## 3. 技术方案

建议采用一个统一的 Vue 3 前端工程，不拆成三个独立项目。

技术栈：

- Vue 3
- Vite
- Vue Router
- Pinia
- Axios
- Element Plus

工程结构建议：

```text
frontend/
  src/
    api/                按微服务拆分接口调用
    stores/             Pinia 状态管理
    router/             路由与角色入口
    layouts/            三套布局：patient / doctor / admin
    views/
      patient/          患者端页面
      doctor/           医生端页面
      admin/            管理员端页面
    components/
      common/           公共组件
      patient/          患者端专用组件
      doctor/           医生端专用组件
      admin/            管理员端专用组件
    utils/              请求、枚举、格式化工具
    styles/             全局样式与主题变量
```

这样做的原因：

- 三个端界面可以明显不同
- 公共 API、错误处理、状态枚举、加载逻辑可以统一复用
- 便于后续加医技端、药房端、财务端，而不推倒重来

## 4. 三端功能边界

### 4.1 患者端

定位：移动端体验优先，承担患者自主操作链路。

第一版页面：

- 患者首页 / 角色入口
- 注册建档页
- AI 问诊页
- 分诊结果页
- 医生推荐页
- 挂号确认页
- 在线支付页
- 候诊状态页
- 历史挂号页
- 检查检验结果页

第一版核心目标：

让“张三注册 -> AI 问诊 -> 医生推荐 -> 线上挂号 -> 支付 -> 查看排队状态”跑通。

### 4.2 医生端

定位：答辩核心工作台，电脑端双栏界面。

界面结构：

- 左侧：传统 HIS 业务区
- 右侧：AI 辅助区

第一版页面模块：

- 今日候诊队列
- 叫号 / 开始接诊 / 结束就诊
- AI 病历草稿查看
- 医生确认病历
- AI 医生辅助问答
- 相似病历召回
- 检查开立
- 检验开立
- 检查结果查看
- 检验数字报告查看
- AI 处方推荐
- 处方确认

第一版核心目标：

让“华佗叫号 -> 接诊 -> 审核病历 -> 开检查检验 -> 看结果 -> 开处方”跑通。

### 4.3 管理员端

定位：演示管理能力，不追求第一版就做复杂可视化。

第一版页面模块：

- 医生与科室基础信息查看
- 排班生成
- AI 排班微调
- 排班申请审批
- 排班规则干预
- 实际排班应急调整
- AI 审计日志查看

第一版核心目标：

让管理员能够查看排班、审批排班申请、强制干预规则，并查看 AI 审计记录。

## 5. 前后端接口映射

### 5.1 患者端对应接口

- `POST /api/v1/patient`：患者注册建档
- `POST /api/v1/patient/triage`：AI 分诊
- `GET /api/v1/patient/departments`：科室列表
- `POST /api/v1/patient/recommend-doctors`：智能医生推荐
- `POST /api/v1/patient/online-register`：线上预挂号锁源
- `POST /api/v1/patient/online-register/pay`：线上支付模拟
- `GET /api/v1/patient/register/{uuid}`：挂号详情
- `GET /api/v1/patient/register/{register_uuid}/queue-status`：排队状态
- `GET /api/v1/patient/{patient_uuid}/registers/detail`：历史挂号详情
- `GET /api/v1/medical/check/{uuid}`：检查结果
- `GET /api/v1/medical/inspection/{uuid}`：检验结果

### 5.2 医生端对应接口

- `GET /api/v1/patient/doctor/{employee_uuid}/queue`：医生今日候诊队列
- `POST /api/v1/patient/doctor/{employee_uuid}/queue/call-next`：叫下一位
- `PUT /api/v1/patient/register/{uuid}/start-reception`：开始接诊
- `PUT /api/v1/patient/register/{uuid}/finish`：结束就诊
- `GET /api/v1/medical/record/draft/{register_uuid}`：获取 AI 病历草稿
- `PUT /api/v1/medical/record/draft/{register_uuid}/confirm`：医生确认病历草稿
- `POST /api/v1/medical/record/ai-assistant`：AI 医生辅助问答
- `POST /api/v1/medical/record/search-similar`：相似病历召回
- `POST /api/v1/medical/check`：开立检查
- `POST /api/v1/medical/inspection`：开立检验
- `POST /api/v1/medical/disposal`：开立处置
- `GET /api/v1/medical/check/{uuid}`：查看检查详情
- `GET /api/v1/medical/inspection/{uuid}`：查看检验详情
- `GET /api/v1/medical/record/{register_uuid}`：查看完整病历
- `POST /api/v1/pharmacy/recommend-prescription`：AI 处方推荐
- `POST /api/v1/pharmacy/prescription`：开立处方

### 5.3 管理员端对应接口

- `GET /api/v1/auth/doctors`：医生列表
- `GET /api/v1/auth/doctors/by-dept-code/{code}`：按科室查询医生
- `POST /api/v1/patient/schedule/generate`：批量生成排班
- `POST /api/v1/patient/ai-schedule`：AI 排班微调
- `GET /api/v1/patient/admin/scheduling-applications`：待审批排班申请
- `POST /api/v1/patient/admin/scheduling-applications/{uuid}/approve`：审批通过
- `POST /api/v1/patient/admin/scheduling-applications/{uuid}/reject`：审批拒绝
- `POST /api/v1/patient/admin/scheduling-rules`：干预排班规则
- `PUT /api/v1/patient/admin/scheduling-actuals`：应急调整实际排班
- `GET /api/v1/patient/admin/ai-audits`：查看 AI 审计日志

## 6. 分阶段实施计划

### 阶段 0：前端工程初始化

目标：把前端基建搭起来。

任务：

- 初始化 Vue 3 + Vite 工程
- 接入 Vue Router、Pinia、Axios、Element Plus
- 配置统一 API 请求层
- 配置环境变量和网关地址
- 建立三套基础布局：患者端、医生端、管理员端
- 建立公共样式、主题变量、通用页面容器

交付标准：

- 前端工程可启动
- 路由和状态管理可用
- 三套角色布局可切换

### 阶段 1：患者端主链路

目标：先做最容易形成完整体验的一端。

任务：

- 完成患者注册建档页
- 完成 AI 问诊页
- 完成分诊结果展示
- 完成医生推荐列表
- 完成挂号确认与支付页面
- 完成候诊状态页面
- 完成历史挂号和结果查看入口

交付标准：

- 患者端可基于真实接口完成问诊、挂号、支付、候诊
- 页面具备移动端观感
- 不依赖本地假数据演示主链路

### 阶段 2：医生端工作台

目标：完成答辩最核心的医生端。

任务：

- 完成医生候诊队列页
- 完成叫号、开始接诊、结束就诊操作
- 完成病历草稿查看与确认页
- 完成 AI 辅助问答侧栏
- 完成相似病历召回面板
- 完成检查检验开立页
- 完成检查结果、检验数字报告、影像结果展示区
- 完成 AI 处方推荐与处方确认页

交付标准：

- 医生端双栏布局明确
- 可以用真实挂号单完成接诊、病历确认、检查开立、处方开立
- AI 信息和人工确认信息界面上明显区分

### 阶段 3：管理员端基础后台

目标：完成管理闭环。

任务：

- 完成医生与科室查看页
- 完成排班生成页
- 完成 AI 排班调优页
- 完成排班申请审批页
- 完成排班规则干预页
- 完成 AI 审计日志页

交付标准：

- 管理员端有独立后台布局
- 可以完成排班审批与规则干预
- 可以查询 AI 审计信息

### 阶段 4：联调与体验补强

目标：收口演示体验。

任务：

- 统一接口错误提示和空状态
- 统一状态枚举、标签色、业务状态流转展示
- 补移动端适配细节
- 补医生端工作流切换体验
- 收敛重复组件与重复请求逻辑
- 固定演示数据与演示路径

交付标准：

- 三端流程切换顺畅
- 关键页面没有明显断链
- 演示路径稳定可复现

## 7. 实施顺序建议

建议严格按下面顺序推进：

1. 阶段 0：前端工程初始化
2. 阶段 1：患者端主链路
3. 阶段 2：医生端工作台
4. 阶段 3：管理员端基础后台
5. 阶段 4：联调与体验补强

不建议一开始同时铺三个端。

原因：

- 当前后端链路最清晰的是患者挂号和医生接诊主线
- 同时铺三端会产生大量空页面和重复组件
- 先把患者端和医生端做通，后面管理员端接入会更稳

## 8. 当前必须接受的产品边界

前端第一版需要按真实情况收口：

- 登录先做演示身份切换，不等待完整 RBAC 完成
- 支付先做模拟支付流程，不包装成真实支付网关
- 医学影像先展示图片路径、结果描述、AI 概率，不实现完整 DICOM 浏览器
- 管理员端先做管理页和审批页，不先做复杂统计大屏
- 药房端、财务端、医技端先不单独立项成完整前端，后续视进度扩展

## 9. 第一轮交付建议

第一轮建议交付以下内容：

- 前端工程初始化完成
- 三套布局搭建完成
- 患者端主链路打通
- 医生端最小工作台打通
- 管理员端排班审批页打通

完成这一步后，项目就会从“后端原型”进入“可演示系统”状态。

## 10. 后续执行建议

从执行角度看，最合理的下一步不是先画所有页面，而是马上开始：

1. 初始化前端工程
2. 搭角色路由和三套布局
3. 先做患者端主链路
4. 患者端跑通后切医生端

这样推进，返工会最少，闭环也最容易尽快出现。
