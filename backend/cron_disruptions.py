import asyncio
import sys
import os

# Add backend dir to path so we can import app modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

from app.microservices.patient.config import settings as patient_settings
from app.microservices.patient.services.patient_service import auto_resolve_expired_disruptions

async def run_disruption_check():
    engine = create_async_engine(patient_settings.get_db_url(), echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as session:
        resolved_count = await auto_resolve_expired_disruptions(session, threshold_hours=12)
        if resolved_count > 0:
            await session.commit()
            print(f"✅ Auto-resolved {resolved_count} expired disruptions.")

async def daemon_loop():
    print("🛡️ Disruption Auto-Resolution Daemon Started. Checking every 10 minutes...")
    while True:
        try:
            await run_disruption_check()
        except Exception as e:
            print(f"❌ Error during disruption check: {e}")
        
        # wait 10 minutes
        await asyncio.sleep(600)

if __name__ == "__main__":
    try:
        asyncio.run(daemon_loop())
    except KeyboardInterrupt:
        print("🛑 Disruption Daemon stopped.")
