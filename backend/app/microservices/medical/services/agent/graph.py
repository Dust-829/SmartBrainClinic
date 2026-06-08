"""
医生智能助理 Agent - LangGraph 状态图定义

核心架构：
    ┌──────────┐
    │  START   │
    └────┬─────┘
         │
         ▼
    ┌──────────┐    有 tool_calls    ┌──────────┐
    │  Agent   │ ─────────────────▶ │  Tools   │
    │  (LLM)   │ ◀───────────────── │ (执行工具) │
    └────┬─────┘   工具结果回传      └──────────┘
         │
         │ 无 tool_calls (最终回答)
         ▼
    ┌──────────┐
    │   END    │
    └──────────┘
"""

import uuid as uuid_pkg
import traceback
import logging
from typing import Optional
from app.common.ai_embedding import get_embedding
from app.common.clients import PatientClient
from app.microservices.medical.models.medical import MedicalRecord

from langchain_openai import ChatOpenAI
from langchain_core.messages import SystemMessage, HumanMessage
from langgraph.graph import StateGraph, END
from langgraph.prebuilt import ToolNode
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.microservices.medical.config import settings
from .state import AgentState
from .tools import create_agent_tools

logger = logging.getLogger("medical.agent")


async def _retrieve_patient_context(
    session: AsyncSession,
    patient_uuid: str,
    question: str,
    top_k: int = 5
) -> str:
    """
    RAG 预检索：在 Agent 启动前，提前将当前患者的相关历史病历
    注入到 SystemPrompt 中，确保简单的患者问题在第一轮就能回答，
    无需额外的工具调用开销。
    """
    if not patient_uuid or str(patient_uuid).lower() == "none":
        return ""


    registers = await PatientClient.get_patient_registers(patient_uuid)
    if not registers:
        return ""

    register_uuids = [r["uuid"] for r in registers]
    query_vec = await get_embedding(question)
    reg_uuids_parsed = [uuid_pkg.UUID(u) for u in register_uuids]

    stmt = select(MedicalRecord).where(
        MedicalRecord.register_uuid.in_(reg_uuids_parsed),
        MedicalRecord.dialog_vector.is_not(None)
    ).order_by(
        MedicalRecord.dialog_vector.cosine_distance(query_vec)
    ).limit(top_k)

    result = await session.execute(stmt)
    records = result.scalars().all()

    if not records:
        return ""

    context_parts = []
    for idx, rec in enumerate(records):
        context_parts.append(
            f"--- 病历 {idx+1} ---\n"
            f"主诉: {rec.readme}\n"
            f"现病史: {rec.present}\n"
            f"既往史: {rec.history}\n"
            f"过敏史: {rec.allergy}\n"
            f"诊断: {rec.diagnosis}\n"
            f"处置: {rec.cure}"
        )
    return "\n\n".join(context_parts)


def _build_system_prompt(patient_context: str) -> str:
    """构建系统提示词"""
    from datetime import date
    today_str = date.today().strftime("%Y-%m-%d")
    weekday_str = ["星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日"][date.today().weekday()]
    
    base = (
        f"你是一个专业的医生智能助理（Agent）。今天的日期是 {today_str} ({weekday_str})。\n"
        "你拥有以下工具能力：\n"
        "1. search_similar_cases - 在全院病历库中检索类似病例的诊疗方案\n"
        "2. submit_scheduling_application - 帮医生提交排班调整申请给管理员审批\n"
        "3. get_doctor_queue - 查看今天的候诊患者队列\n"
        "4. get_doctor_schedule - 查看未来排班安排\n\n"
        "工作原则：\n"
        "- 当医生询问患者病情时，优先参考已提供的历史病历上下文\n"
        "- 当需要查找其他科室或其他患者的类似病例时，调用 search_similar_cases\n"
        "- 当医生要求调整排班时，务必调用 submit_scheduling_application\n"
        "- 遇到相对日期（如“明天”、“下周一”）时，请结合今天日期计算出具体日期再提交。\n"
        "- 你可以在一次对话中连续调用多个工具来完成复杂的组合任务\n"
        "- 始终用中文回答，保持专业、严谨的医疗用语\n"
    )

    if patient_context:
        base += f"\n【当前患者历史病历】:\n{patient_context}\n"
    else:
        base += (
            "\n当前未关联具体患者。如果医生提出的是日常门诊事务、"
            "知识问答、或排班管理等诉求，请直接作为私人助理回应。\n"
        )

    return base


def _should_continue(state: AgentState) -> str:
    """
    条件路由函数：检查 LLM 的最新回复中是否包含 tool_calls。
    - 如果有 tool_calls → 路由到 "tools" 节点执行工具
    - 如果没有 → 路由到 END，结束 Agent 循环
    """
    last_message = state["messages"][-1]
    if hasattr(last_message, "tool_calls") and last_message.tool_calls:
        return "tools"
    return END


async def build_and_run_agent(
    session: AsyncSession,
    patient_uuid: Optional[str],
    question: str,
    employee_uuid: Optional[str] = None,
    top_k: int = 5,
) -> str:
    """
    构建并运行医生智能助理 Agent

    流程：
    1. RAG 预检索当前患者的历史病历，注入到 SystemPrompt
    2. 创建绑定当前 session 的工具集（闭包模式）
    3. 初始化 LLM（SiliconFlow OpenAI 兼容 API）并绑定工具
    4. 构建 LangGraph 状态图（Agent 节点 ↔ Tool 节点 循环）
    5. 执行 Agent 并返回最终回答
    """
    # ── 1. RAG 预检索 ──────────────────────────────────────
    patient_context = await _retrieve_patient_context(
        session, patient_uuid, question, top_k
    )

    # ── 2. 创建工具集 ──────────────────────────────────────
    tools = create_agent_tools(session, patient_uuid, employee_uuid)

    # ── 3. 初始化 LLM 并绑定工具 ───────────────────────────
    llm = ChatOpenAI(
        model=settings.LLM_MODEL,
        api_key=settings.LLM_API_KEY,
        base_url=settings.LLM_API_BASE,
        temperature=0.2,
        request_timeout=120,
    )
    llm_with_tools = llm.bind_tools(tools)

    # ── 4. 定义 Agent 节点 ─────────────────────────────────
    async def agent_node(state: AgentState):
        """Agent 推理节点：将当前消息列表送入 LLM，获取回复（可能包含 tool_calls）"""
        response = await llm_with_tools.ainvoke(state["messages"])
        return {"messages": [response]}

    # ── 5. 构建 LangGraph 状态图 ───────────────────────────
    graph = StateGraph(AgentState)

    graph.add_node("agent", agent_node)
    graph.add_node("tools", ToolNode(tools))

    graph.set_entry_point("agent")
    graph.add_conditional_edges("agent", _should_continue, {"tools": "tools", END: END})
    graph.add_edge("tools", "agent")  # 工具执行完毕 → 回到 Agent 继续推理

    app = graph.compile()

    # ── 6. 构建初始消息并执行 ──────────────────────────────
    system_prompt = _build_system_prompt(patient_context)
    initial_state = {
        "messages": [
            SystemMessage(content=system_prompt),
            HumanMessage(content=f"医生的话: {question}"),
        ]
    }

    try:
        # recursion_limit 防止 Agent 陷入无限工具调用循环（最多 10 轮）
        final_state = await app.ainvoke(
            initial_state,
            config={"recursion_limit": 10}
        )
        last_message = final_state["messages"][-1]
        answer = last_message.content or "抱歉，系统未能理解您的意图。"
        logger.info(f"✅ [Agent] 执行完成，共 {len(final_state['messages'])} 轮消息")
        return answer
    except Exception as e:
        traceback.print_exc()
        logger.error(f"❌ [Agent] 执行出错: {e}")
        return f"智能助理执行出错: {str(e)}"
