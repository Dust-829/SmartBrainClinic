# SmartBrainClinic

智慧云脑诊疗平台项目仓库。

本项目面向门诊诊疗全链路，围绕患者端、医生端、管理端、医技端和药房端建立智能化诊疗平台。系统目标是在传统 HIS 业务基础上引入大语言模型、医学影像识别和智能调度能力，同时坚持医疗场景中的医生最终确认原则。

## 项目范围

- 患者端：智能问诊、AI 分诊、医生推荐、挂号支付、电子病历与费用查询。
- 医生端：叫号接诊、病历初稿确认、检查检验申请、影像结果查看、门诊确诊、处方开立。
- 管理端：医生工作量统计、排班规则管理、诊疗质量评估、AI 能力评估。
- 医技端：检查检验申请接收、患者录入、影像上传、AI 辅助识别、结果录入。
- 药房端：发药、退药、药品库存、交易记录。

## 技术方向

- 前端：Vue 3、Element Plus、Pinia、Axios。
- 后端：Java 17、Spring Boot 3.4、MyBatis / MyBatis-Plus、Spring AI、Spring Cloud Alibaba。
- AI 服务：FastAPI、LangChain、医学影像识别模型。
- 数据库：PostgreSQL，预留 pgvector 扩展能力。
- 版本管理：Git + GitHub。

## 仓库结构

```text
SmartBrainClinic/
  docs/                         项目需求、架构和协作文档
  frontend/                     前端工程
  services/
    his-common/                 公共模块
    his-outpatient/             门诊核心服务
    his-drugstore/              药房服务
    his-ai-service/             大模型与 AI 编排服务
    his-algorithm-service/      医学影像算法服务
  database/                     数据库脚本与迁移文件
  scripts/                      项目辅助脚本
```

## 快速开始

当前仓库处于项目初始化阶段。建议先完成以下事项：

1. 在 GitHub 创建私有仓库。
2. 邀请组员加入仓库，并分配权限。
3. 按 `docs/GitHub协作规范.md` 约定分支和提交方式。
4. 确认后端采用 Java 微服务为主、Python AI 服务为辅的实现路线。
5. 为前端、后端、AI 服务分别建立初始工程。

## 重要文档

- [需求文档](docs/智慧云脑诊疗平台_流程与需求文档.md)
- [项目规划](docs/项目规划.md)
- [GitHub 协作规范](docs/GitHub协作规范.md)

