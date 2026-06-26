"""
AI 病历初稿生成引擎 (Medical 微服务专用)

根据患者与分诊AI的完整对话历史，提取关键医学信息生成病历初稿。
严格遵循"有则提取，无则标注未详细说明"原则，禁止凭空编造。
"""

import json
import logging
from typing import Dict, Any
from app.common.ai_client import AIClient
from app.common.ai_schema import AISource, MedicalDraftData, build_ai_result
logger = logging.getLogger("medical.ai_draft")

SYSTEM_PROMPT = """你是一个专业的电子病历初稿生成AI。你将收到一段患者与AI分诊助手的历史对话记录。

【你的任务】
从对话中提取有价值的医学信息，填充到病历初稿的各个字段中。

【核心原则 —— 禁止编造】
1. 只能从对话内容中提取患者确实提到过的信息。
2. 对于患者未提及的信息，对应字段必须填写"未详细说明"。
3. 禁止根据症状推测诊断结论、用药方案或检查建议。
4. 所有字段均为辅助医生参考的初稿，医生会在此基础上修改确认。

【输出格式要求】
请严格输出一个JSON对象，不要包含任何markdown代码块包裹：
{
  "readme": "主诉：用一句话概括患者的核心症状和持续时间。如果对话中未提及具体症状，填'未详细说明'",
  "present": "现病史：按时间线整理患者描述的症状发展过程。只记录患者明确说过的内容",
  "history": "既往史：患者提及的既往疾病、手术史等。未提及则填'未详细说明'",
  "allergy": "过敏史：患者提及的药物或食物过敏。未提及则填'未详细说明'",
  "proposal": "初步建议：仅当对话中有明确线索时给出方向性建议，否则填'待医生问诊后补充'",
  "cure": "处置意见：填'待医生问诊后确定'"
}

请只返回原始JSON字符串，不要有任何额外文字。"""


async def run_ai_medical_draft(
    conversation_json: str,
    api_key: str = None,
    api_base: str = None,
    model: str = None,
) -> Dict[str, Any]:
    """
    根据对话历史生成病历初稿。
    
    Args:
        conversation_json: 对话历史的JSON字符串 (list of {role, content})
        api_key, api_base, model: LLM配置
    
    Returns:
        dict with keys: readme, present, history, allergy, proposal, cure
    """
    from app.microservices.medical.config import settings
    api_key = api_key or settings.LLM_API_KEY
    api_base = api_base or settings.LLM_API_BASE
    model = model or getattr(settings, "LLM_MODEL", "deepseek-ai/DeepSeek-V4-Flash")

    # 默认空白初稿（当无有效对话时使用）
    default_draft = {
        "readme": "未详细说明",
        "present": "未详细说明",
        "history": "未详细说明",
        "allergy": "未详细说明",
        "proposal": "待医生问诊后补充",
        "cure": "待医生问诊后确定"
    }

    # 解析对话历史
    try:
        messages = json.loads(conversation_json) if isinstance(conversation_json, str) else conversation_json
        if not isinstance(messages, list):
            messages = [{"role": "user", "content": str(conversation_json)}]
    except (json.JSONDecodeError, TypeError):
        if conversation_json and str(conversation_json).strip() not in ["", "无"]:
            messages = [{"role": "user", "content": str(conversation_json)}]
        else:
            messages = None

    # 如果没有有效对话或对话无实质内容，直接返回空白初稿
    if not messages or not isinstance(messages, list):
        logger.info("📝 [AI Draft] No valid conversation history, returning blank draft")
        data = MedicalDraftData(**default_draft).model_dump(mode="json")
        return build_ai_result(
            data,
            source=AISource.FALLBACK,
            model="no-conversation",
            confidence=0.0,
            warnings=["no_valid_conversation"],
            validated=True,
        )

    user_texts = [m.get("content", "") for m in messages if m.get("role") == "user"]
    if not user_texts or all(not t.strip() for t in user_texts):
        logger.info("📝 [AI Draft] No user messages in conversation, returning blank draft")
        data = MedicalDraftData(**default_draft).model_dump(mode="json")
        return build_ai_result(
            data,
            source=AISource.FALLBACK,
            model="no-user-message",
            confidence=0.0,
            warnings=["no_user_message"],
            validated=True,
        )

    # 1. 尝试真实大模型
    if api_key and api_key.strip():
        logger.info("🤖 [AI Draft] Invoking LLM to generate medical record draft...")
        try:
            # 将对话历史格式化为可读文本
            conversation_text = ""
            for msg in messages:
                role_label = "患者" if msg.get("role") == "user" else "AI分诊助手"
                conversation_text += f"{role_label}：{msg.get('content', '')}\n"

            data = await AIClient(api_key=api_key, api_base=api_base).chat_json(
                model=model,
                messages=[
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {"role": "user", "content": f"以下是患者与AI分诊助手的对话记录：\n\n{conversation_text}\n\n请根据以上对话生成病历初稿。"}
                ],
                temperature=0.1,
                timeout=10.0,
            )
            if data:
                # 确保所有必要字段存在
                for key in default_draft:
                    if key not in data or not data[key]:
                        data[key] = default_draft[key]
                data = MedicalDraftData(**data).model_dump(mode="json")
                
                logger.info(f"✅ [AI Draft] LLM draft generated successfully")
                return build_ai_result(
                    data,
                    source=AISource.LLM,
                    model=model,
                    confidence=0.8,
                    validated=True,
                )
        except Exception as e:
            logger.error(f"⚠️ [AI Draft] LLM invocation failed: {e}. Falling back to extraction...")

    # 2. 离线提取引擎（Mock / 降级）
    logger.info("🔌 [AI Draft] Running offline extraction engine...")
    data = MedicalDraftData(**_extract_from_conversation(messages, default_draft)).model_dump(mode="json")
    return build_ai_result(
        data,
        source=AISource.FALLBACK,
        model="rule-draft-extractor",
        confidence=0.5,
        warnings=["using_rule_based_draft_extractor"],
        validated=True,
    )


def _extract_from_conversation(messages: list, default_draft: dict) -> dict:
    """
    简单的关键词提取引擎，从对话历史中尽可能提取信息。
    未提取到的一律填"未详细说明"。
    """
    user_texts = " ".join([m.get("content", "") for m in messages if m.get("role") == "user"])

    draft = dict(default_draft)

    # 如果用户有实质性描述，提取主诉
    if len(user_texts.strip()) > 2:
        # 截取用户的核心描述作为主诉
        first_user_msg = ""
        for m in messages:
            if m.get("role") == "user" and len(m.get("content", "").strip()) > 2:
                first_user_msg = m["content"].strip()
                break
        if first_user_msg:
            draft["readme"] = f"患者自诉：{first_user_msg[:100]}"
            draft["present"] = f"现病史：患者自诉{user_texts[:200]}。"

    # 尝试提取过敏史
    for m in messages:
        content = m.get("content", "")
        if "过敏" in content and m.get("role") == "user":
            if any(k in content for k in ["没有", "无", "不"]):
                draft["allergy"] = "患者自述无过敏史"
            else:
                draft["allergy"] = f"患者提及过敏相关：{content[:100]}"
            break

    return draft
