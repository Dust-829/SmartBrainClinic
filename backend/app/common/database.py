"""
通用数据库引擎与会话管理
支持多数据库 URL 注入
"""

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker

def create_engine_and_session(db_url: str, echo: bool = True):
    engine = create_async_engine(
        db_url,
        echo=echo,
        pool_size=10,
        max_overflow=20,
    )
    session_factory = async_sessionmaker(
        bind=engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )
    return engine, session_factory

async def get_session_factory(session_factory):
    async with session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
