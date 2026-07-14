"""Create the first administrator from environment variables without persisting a plaintext password."""

import asyncio
import sys
from pathlib import Path


BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.microservices.auth.config import settings
from app.common.database import create_engine_and_session
from app.microservices.auth.services.auth_service import create_admin_account


async def main() -> None:
    required = {
        "ADMIN_BOOTSTRAP_STAFF_CODE": settings.ADMIN_BOOTSTRAP_STAFF_CODE,
        "ADMIN_BOOTSTRAP_DISPLAY_NAME": settings.ADMIN_BOOTSTRAP_DISPLAY_NAME,
        "ADMIN_BOOTSTRAP_PASSWORD": settings.ADMIN_BOOTSTRAP_PASSWORD,
    }
    missing = [name for name, value in required.items() if not str(value or "").strip()]
    if missing:
        raise SystemExit(f"Missing required bootstrap configuration: {', '.join(missing)}")

    engine, session_factory = create_engine_and_session(settings.get_db_url(), echo=False)
    try:
        async with session_factory() as session:
            admin = await create_admin_account(
                session,
                staff_code=settings.ADMIN_BOOTSTRAP_STAFF_CODE,
                display_name=settings.ADMIN_BOOTSTRAP_DISPLAY_NAME,
                password=settings.ADMIN_BOOTSTRAP_PASSWORD,
            )
    except ValueError as exc:
        raise SystemExit(str(exc))
    finally:
        await engine.dispose()
    print(f"Created administrator {admin.staff_code} ({admin.display_name}).")


if __name__ == "__main__":
    asyncio.run(main())
