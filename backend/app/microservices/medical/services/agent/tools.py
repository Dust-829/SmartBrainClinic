"""
医生智能助理 Agent - 工具定义
使用工厂函数模式，将数据库 Session 和上下文信息通过闭包绑定到每个工具中，
使 LangGraph 的 ToolNode 能够直接调用这些异步工具。
"""

import uuid as uuid_pkg
from langchain_core.tools import tool
from sqlalchemy.ext.asyncio import AsyncSession
from app.common.clients import BaseClient
from app.common.clients import PatientClient

def create_agent_tools(session: AsyncSession, patient_uuid: str = None, employee_uuid: str = None):
    """
    工具工厂：根据当前请求的数据库 session 和上下文信息，
    生成一组绑定了运行时依赖的工具实例。

    为什么用闭包？
    LangGraph 的 ToolNode 要求工具是独立的 callable，
    但我们的工具需要访问当前请求的数据库 session。
    通过闭包捕获 session，既保持了工具函数签名的简洁，
    又避免了全局变量或 ContextVar 的复杂性。
    """

    @tool
    async def search_similar_cases(query: str) -> str:
        """在全院历史病历库中，根据描述语义检索最相似的已确诊病历案例。适用于医生想参考类似病例时调用。"""
        # 复用底层的 Service 方法，消除代码冗余
        from app.microservices.medical.services.medical_service import search_similar_records

        records = await search_similar_records(session, query, top_k=5)

        if not records:
            return "未找到相似病历记录。"

        parts = []
        for idx, rec in enumerate(records):
            parts.append(
                f"【相似病例 {idx+1}】\n"
                f"主诉: {rec.readme}\n"
                f"现病史: {rec.present}\n"
                f"诊断: {rec.diagnosis}\n"
                f"处置: {rec.cure}"
            )
        return "\n\n".join(parts)

    @tool
    async def submit_scheduling_application(prompt: str) -> str:
        """当且仅当医生主动要求修改自己的排班规律（停诊、加诊、调休、调整限额等）时，调用此工具将申请提交给管理员审核。参数 prompt 是医生排班修改诉求的详细描述。"""

        if not employee_uuid:
            return "错误：无法识别当前医生身份，无法提交排班申请。"

        try:
            await PatientClient.submit_scheduling_application(str(employee_uuid), prompt)
            return f"已成功为您向管理员提交排班申请，申请内容：'{prompt}'。请等待管理员审核。"
        except Exception as e:
            return f"提交排班申请失败：{e}"

    @tool
    async def get_doctor_queue() -> str:
        """查询当前医生今天的候诊患者队列，包括患者姓名、症状、等候状态等信息。"""

        if not employee_uuid:
            return "错误：无法识别当前医生身份。"

        try:
            url = f"{BaseClient.get_url('patient')}/doctor/{employee_uuid}/queue"
            result = await BaseClient.get(url)

            if not result:
                return "今天暂无候诊患者。"

            parts = []
            room_set = set()
            for idx, p in enumerate(result):
                room_name = p.get('clinic_room_name', '未指定诊室')
                room_set.add(room_name)
                parts.append(
                    f"{idx+1}. {p['patient_name']}（{p.get('gender', '未知')}）"
                    f" - 症状: {p.get('symptoms', '未填写')}"
                    f" - 状态: {p.get('visit_state_text', '未知')}"
                    f" - 诊室: {room_name}"
                )
                
            rooms_str = "、".join(list(room_set))
            return f"[{rooms_str}] 今日候诊队列共 {len(result)} 人:\n" + "\n".join(parts)
        except Exception as e:
            return f"查询候诊队列失败：{e}"

    @tool
    async def get_doctor_schedule() -> str:
        """查询当前医生未来的排班安排，包括日期、时段、限额和剩余号源。"""

        if not employee_uuid:
            return "错误：无法识别当前医生身份。"

        try:
            url = f"{BaseClient.get_url('patient')}/schedules?employee_uuid={employee_uuid}"
            result = await BaseClient.get(url)

            if not result:
                return "未查询到未来排班记录。"

            parts = []
            for s in result[:10]:
                parts.append(
                    f"- {s['schedule_date']} {s['noon']}: "
                    f"限额 {s['regist_quota']} | 已挂 {s['registered_count']} | 剩余 {s['remaining_quota']}"
                )
            return f"未来排班安排:\n" + "\n".join(parts)
        except Exception as e:
            return f"查询排班失败：{e}"

    return [search_similar_cases, submit_scheduling_application, get_doctor_queue, get_doctor_schedule]
