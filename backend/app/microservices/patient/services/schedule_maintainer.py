import asyncio
import logging
from datetime import date, timedelta

from ..database import session_factory
from .patient_service import generate_scheduling_actuals


logger = logging.getLogger("patient.schedule_maintainer")

ROLLING_SCHEDULE_HORIZON_DAYS = 7
ROLLING_SCHEDULE_REFRESH_SECONDS = 6 * 60 * 60


async def ensure_rolling_schedules() -> dict:
    """补齐从今天开始的预约窗口，已有班次保持不变。"""
    start_date = date.today()
    end_date = start_date + timedelta(days=ROLLING_SCHEDULE_HORIZON_DAYS)

    async with session_factory() as session:
        result = await generate_scheduling_actuals(
            session,
            start_date.isoformat(),
            end_date.isoformat(),
        )
        await session.commit()

    if result["generated_count"]:
        logger.info(
            "Generated %s schedule blocks for %s through %s.",
            result["generated_count"],
            result["start_date"],
            result["end_date"],
        )
    return result


async def maintain_rolling_schedules() -> None:
    """定期补齐未来预约窗口，防止排班随日期自然过期。"""
    while True:
        await asyncio.sleep(ROLLING_SCHEDULE_REFRESH_SECONDS)
        try:
            await ensure_rolling_schedules()
        except Exception:
            logger.exception("Unable to refresh the rolling schedule window.")
