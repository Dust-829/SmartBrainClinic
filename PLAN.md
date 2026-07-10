# PLAN

## Goal

在不改变管理员端现有信息架构、功能行为、字段语义和路由结构的前提下，将管理员端全部前端页面统一到医生端当前的视觉语言与交互外观，并通过前端构建验证改造结果。

## Current Behavior

- 管理员端已有完整页面集合与路由，业务逻辑已可运行。
- `frontend/src/layouts/AdminLayout.vue` 仍采用深色侧栏和独立后台风格，与医生端 `DoctorLayout.vue` 的浅色工作台骨架不一致。
- 多个管理员页面分别维护自己的 `hero` 配色、按钮样式、表单样式、列表卡片与 empty state，存在明显视觉分叉。
- 管理员端页面主要依赖 `SectionCard.vue` 作为基础容器，但页面内部的大量 `scoped style` 仍是各写各的。
- 项目没有现成的前端单元测试框架，当前最可靠的自动化验证手段是 `npm run build`。

## Proposed Solution

- 重做 `AdminLayout.vue` 的视觉层，使其在骨架、间距、侧栏、身份卡和主内容区上与医生端同源。
- 新增管理员端共享皮肤样式文件，集中定义 hero、grid、form、toolbar、list、item、state、empty、button、badge 等视觉模式。
- 按“只换皮、不改结构”的原则，逐页迁移管理员端 13 个页面，将局部散落样式收敛到共享皮肤层。
- 尽量保留 `SectionCard.vue` 现有职责，优先通过管理员端 class 覆盖；仅在确认不会影响 patient / doctor 页面时，才做小幅通用增强。
- 最终通过 `npm run build` 验证所有 Vue / TypeScript / 样式改造仍可编译通过。

## Risks

- 管理员端页面大量使用 `scoped style`，迁移过程中容易遗漏局部按钮、表单或状态块样式。
- `SectionCard.vue` 是跨角色共用组件，若改动过重，可能影响患者端和医生端现有界面。
- Element Plus 组件默认观感可能与共享皮肤不完全一致，需要做有边界的管理员端局部覆盖。
- 本次没有浏览器自动化视觉回归，移动端与断点行为需要依赖人工样式审查和构建后抽样检查。

## Validation Strategy

- 运行 `npm run build`，确认 `vue-tsc --noEmit` 与 `vite build` 均成功。
- 核对管理员端核心文件是否只发生视觉层改动，没有新增业务逻辑改写。
- 检查共享皮肤是否覆盖登录页、仪表盘、审批/分析页、表单工作台页的主要视觉模式。
- 在最终汇报中明确说明未覆盖的可视化人工验证风险。
