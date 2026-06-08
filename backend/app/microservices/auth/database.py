from app.common.database import create_engine_and_session, get_session_factory
from .config import settings

engine, session_factory = create_engine_and_session(settings.get_db_url(), echo=settings.APP_DEBUG)

async def get_session():
    async for session in get_session_factory(session_factory):
        yield session
