import asyncio
from datetime import datetime, timedelta
from sqlalchemy import select, update
from app.common.enums import VisitState
from ..database import session_factory
from ..models.patient import Register, SchedulingActual

async def sweep_zombie_slots():
    """
    后台守护任务：定时扫描并清理超过 15 分钟未支付的“僵尸挂号单”，自动释放号源库存。
    这有效防止了恶意占号导致的 DoS 攻击。
    """
    print("🧹 [Zombie Sweeper] Started background task for zombie slot cleanup.")
    while True:
        try:
            async with session_factory() as session:
                cutoff_time = datetime.now() - timedelta(minutes=15)
                stmt = select(Register).where(
                    Register.visit_state == VisitState.UNPAID,
                    Register.visit_date < cutoff_time,
                )
                result = await session.execute(stmt)
                zombies = result.scalars().all()
                
                for zombie in zombies:
                    zombie.visit_state = VisitState.CANCELLED
                    session.add(zombie)
                    
                    if zombie.scheduling_time_slot_id:
                        from ..models.patient import SchedulingTimeSlot
                        stmt_ts = update(SchedulingTimeSlot).where(
                            SchedulingTimeSlot.id == zombie.scheduling_time_slot_id
                        ).values(is_booked=False)
                        await session.execute(stmt_ts)

                    if zombie.scheduling_actual_id:
                        stmt_update = update(SchedulingActual).where(
                            SchedulingActual.id == zombie.scheduling_actual_id,
                            SchedulingActual.registered_count > 0
                        ).values(registered_count=SchedulingActual.registered_count - 1)
                        await session.execute(stmt_update)
                        
                if zombies:
                    print(f"🧹 [Zombie Sweeper] Successfully cleaned up and released {len(zombies)} zombie registration slots.", flush=True)
                await session.commit()
        except Exception as e:
            print(f"⚠️ [Zombie Sweeper] Error during cleanup: {e}", flush=True)
        
        await asyncio.sleep(60)  # 每 60 秒轮询一次
