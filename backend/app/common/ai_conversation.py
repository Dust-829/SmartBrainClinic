import uuid as uuid_pkg
from datetime import datetime
from typing import Any, Iterable, Optional

from sqlalchemy import Column, DateTime, Text, func, select
from sqlalchemy.dialects.postgresql import JSONB
from sqlmodel import Field, SQLModel
from sqlalchemy.ext.asyncio import AsyncSession

_UNSET = object()


class AIConversationSession(SQLModel, table=True):
    __tablename__ = "ai_conversation_session"

    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(default_factory=uuid_pkg.uuid4, unique=True, nullable=False, index=True)
    surface: str = Field(max_length=64, nullable=False)
    module_name: str = Field(max_length=128, nullable=False)
    patient_uuid: Optional[uuid_pkg.UUID] = Field(default=None, index=True)
    register_uuid: Optional[uuid_pkg.UUID] = Field(default=None, index=True)
    employee_uuid: Optional[uuid_pkg.UUID] = Field(default=None, index=True)
    status: str = Field(default="draft", max_length=32, nullable=False, index=True)
    profile_snapshot_json: Optional[Any] = Field(default=None, sa_column=Column(JSONB))
    latest_result_json: Optional[Any] = Field(default=None, sa_column=Column(JSONB))
    summary_text: Optional[str] = Field(default=None, sa_column=Column(Text))
    source: Optional[str] = Field(default=None, max_length=32)
    model: Optional[str] = Field(default=None, max_length=128)
    validated: bool = Field(default=False, nullable=False)
    created_at: datetime = Field(
        default_factory=datetime.now,
        sa_column=Column(DateTime, default=datetime.now, nullable=False),
    )
    updated_at: datetime = Field(
        default_factory=datetime.now,
        sa_column=Column(DateTime, default=datetime.now, nullable=False),
    )


class AIConversationMessage(SQLModel, table=True):
    __tablename__ = "ai_conversation_message"

    id: Optional[int] = Field(default=None, primary_key=True)
    uuid: uuid_pkg.UUID = Field(default_factory=uuid_pkg.uuid4, unique=True, nullable=False, index=True)
    session_uuid: uuid_pkg.UUID = Field(nullable=False, index=True)
    turn_index: int = Field(nullable=False)
    role: str = Field(max_length=32, nullable=False)
    content: str = Field(sa_column=Column(Text, nullable=False))
    created_at: datetime = Field(
        default_factory=datetime.now,
        sa_column=Column(DateTime, default=datetime.now, nullable=False),
    )


async def create_ai_conversation_session(
    session: AsyncSession,
    *,
    surface: str,
    module_name: str,
    patient_uuid: uuid_pkg.UUID | str | None = None,
    register_uuid: uuid_pkg.UUID | str | None = None,
    employee_uuid: uuid_pkg.UUID | str | None = None,
    status: str = "draft",
    profile_snapshot_json: Any = None,
    latest_result_json: Any = None,
    summary_text: str | None = None,
    source: str | None = None,
    model: str | None = None,
    validated: bool = False,
) -> AIConversationSession:
    record = AIConversationSession(
        surface=surface,
        module_name=module_name,
        patient_uuid=_coerce_uuid(patient_uuid),
        register_uuid=_coerce_uuid(register_uuid),
        employee_uuid=_coerce_uuid(employee_uuid),
        status=status,
        profile_snapshot_json=profile_snapshot_json,
        latest_result_json=latest_result_json,
        summary_text=summary_text,
        source=source,
        model=model,
        validated=validated,
    )
    session.add(record)
    await session.flush()
    return record


async def get_ai_conversation_session(
    session: AsyncSession,
    session_uuid: uuid_pkg.UUID | str,
) -> AIConversationSession | None:
    stmt = select(AIConversationSession).where(AIConversationSession.uuid == _coerce_uuid(session_uuid))
    result = await session.execute(stmt)
    return result.scalar_one_or_none()


async def list_ai_conversation_messages(
    session: AsyncSession,
    session_uuid: uuid_pkg.UUID | str,
) -> list[AIConversationMessage]:
    stmt = (
        select(AIConversationMessage)
        .where(AIConversationMessage.session_uuid == _coerce_uuid(session_uuid))
        .order_by(AIConversationMessage.turn_index.asc(), AIConversationMessage.id.asc())
    )
    result = await session.execute(stmt)
    return list(result.scalars().all())


async def append_ai_conversation_messages(
    session: AsyncSession,
    session_uuid: uuid_pkg.UUID | str,
    messages: Iterable[dict[str, Any]],
    *,
    start_turn_index: int | None = None,
) -> list[AIConversationMessage]:
    normalized_session_uuid = _coerce_uuid(session_uuid)
    next_turn_index = start_turn_index
    if next_turn_index is None:
        next_turn_index = await _get_next_turn_index(session, normalized_session_uuid)

    created: list[AIConversationMessage] = []
    for offset, message in enumerate(messages):
        role = str(message.get("role") or "user")
        content = str(message.get("content") or "")
        row = AIConversationMessage(
            session_uuid=normalized_session_uuid,
            turn_index=next_turn_index + offset,
            role=role,
            content=content,
        )
        session.add(row)
        created.append(row)

    if created:
        await session.flush()
    return created


async def update_ai_conversation_session(
    session: AsyncSession,
    session_uuid: uuid_pkg.UUID | str,
    *,
    patient_uuid: uuid_pkg.UUID | str | None | object = _UNSET,
    register_uuid: uuid_pkg.UUID | str | None | object = _UNSET,
    employee_uuid: uuid_pkg.UUID | str | None | object = _UNSET,
    status: str | object = _UNSET,
    profile_snapshot_json: Any | object = _UNSET,
    latest_result_json: Any | object = _UNSET,
    summary_text: str | None | object = _UNSET,
    source: str | None | object = _UNSET,
    model: str | None | object = _UNSET,
    validated: bool | object = _UNSET,
) -> AIConversationSession:
    record = await get_ai_conversation_session(session, session_uuid)
    if not record:
        raise ValueError("AI conversation session not found")

    if patient_uuid is not _UNSET:
        record.patient_uuid = _coerce_uuid(patient_uuid)
    if register_uuid is not _UNSET:
        record.register_uuid = _coerce_uuid(register_uuid)
    if employee_uuid is not _UNSET:
        record.employee_uuid = _coerce_uuid(employee_uuid)
    if status is not _UNSET:
        record.status = str(status)
    if profile_snapshot_json is not _UNSET:
        record.profile_snapshot_json = profile_snapshot_json
    if latest_result_json is not _UNSET:
        record.latest_result_json = latest_result_json
    if summary_text is not _UNSET:
        record.summary_text = summary_text
    if source is not _UNSET:
        record.source = source
    if model is not _UNSET:
        record.model = model
    if validated is not _UNSET:
        record.validated = bool(validated)

    record.updated_at = datetime.now()
    session.add(record)
    await session.flush()
    return record


async def _get_next_turn_index(session: AsyncSession, session_uuid: uuid_pkg.UUID) -> int:
    stmt = select(func.max(AIConversationMessage.turn_index)).where(
        AIConversationMessage.session_uuid == session_uuid
    )
    result = await session.execute(stmt)
    current_max = result.scalar_one_or_none()
    return int(current_max or 0) + 1


def _coerce_uuid(value: uuid_pkg.UUID | str | None) -> uuid_pkg.UUID | None:
    if value in (None, ""):
        return None
    if isinstance(value, uuid_pkg.UUID):
        return value
    return uuid_pkg.UUID(str(value))

