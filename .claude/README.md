# 项目级 Codex 技能说明

本目录用于保存 SmartBrainClinic 仓库内需要随项目一起协作的 Codex 技能和辅助脚本。

## 已安装技能

### impeccable

- 路径：`.claude/skills/impeccable/`
- 用途：患者端和后续医生端、管理员端的前端设计、交互审查、移动端适配、视觉一致性检查。
- 当前项目注册类型：`product`。
- 项目上下文来源：`PRODUCT.md`、`docs/frontend-plan.md`、`docs/项目规划.md`、现有 Vue 组件和主题样式。

## 使用规则

- 处理 UI / 前端 / 设计一致性任务时，先运行：

```bash
node .claude/skills/impeccable/scripts/context.mjs --target frontend
```

- 如果任务是具体页面，可以把 target 指到具体视图或组件，例如：

```bash
node .claude/skills/impeccable/scripts/context.mjs --target frontend/src/views/patient
```

- `impeccable` 不会替代项目约束。患者端仍然必须遵守真实接口优先、移动端优先、AI 来源透明、不展示内部编码等规则。
- 本仓库当前不安装与项目无关的技能，避免增加无关维护成本。
