# GitHub 协作规范

## 分支规则

- `main`：稳定主分支，只合并通过检查的代码。
- `develop`：日常集成分支。
- `feature/<模块名>-<功能名>`：功能开发分支，例如 `feature/frontend-registration`。
- `fix/<问题名>`：缺陷修复分支。

## 开发流程

1. 从 `develop` 拉取最新代码。
2. 新建自己的功能分支。
3. 完成开发后提交 commit。
4. 推送到 GitHub。
5. 创建 Pull Request，请至少一名组员 Review。
6. Review 通过后合并到 `develop`。
7. 阶段版本稳定后再由负责人合并到 `main`。

## Commit 规范

建议格式：

```text
<type>: <简短说明>
```

常用 `type`：

- `feat`：新增功能。
- `fix`：修复问题。
- `docs`：文档更新。
- `style`：样式或格式调整。
- `refactor`：重构。
- `test`：测试相关。
- `chore`：工程配置或杂项。

示例：

```text
feat: add outpatient registration page
docs: add github collaboration guide
```

## Pull Request 要求

- 标题清楚说明变更内容。
- 描述中写明改了什么、为什么改、如何验证。
- 不把无关改动混在同一个 PR 中。
- 涉及数据库结构调整时，同步提交 SQL 脚本和说明。
- 涉及医疗结论、AI 推荐、处方等功能时，必须保留医生确认机制。

## GitHub 仓库建议

- 建议创建私有仓库。
- 给老师或助教只读或维护者权限，按实际要求设置。
- 组员至少使用 `Write` 权限。
- 开启分支保护，限制直接推送 `main`。
- 后续可加入 GitHub Actions 做前端构建、后端测试和代码检查。

