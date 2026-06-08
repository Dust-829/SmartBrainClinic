"""
医生智能助理 Agent - 状态定义
LangGraph 的 Agent 状态采用 TypedDict + add_messages 注解，
保证消息列表在每一轮推理中自动追加而非覆盖。
"""

from typing import Annotated
from typing_extensions import TypedDict
from langgraph.graph.message import add_messages


class AgentState(TypedDict):
    """
    Agent 图的全局状态
    - messages: 完整的对话消息列表（SystemMessage + HumanMessage + AIMessage + ToolMessage）
                使用 add_messages 注解确保每个节点返回的新消息自动追加到列表末尾
    """
    messages: Annotated[list, add_messages]
