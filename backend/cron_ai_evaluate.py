import asyncio
import sys
import os

# Add backend dir to path so we can import app modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select
import httpx

from app.microservices.patient.config import settings as patient_settings
from app.microservices.patient.models.patient import PatientFeedback
from app.common.clients import BaseClient

async def run_nightly_batch():
    engine = create_async_engine(patient_settings.get_db_url(), echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    print("🌙 Starting Nightly AI Doctor Evaluation Batch Job...")
    
    async with async_session() as session:
        # 1. Fetch unprocessed feedback
        stmt = select(PatientFeedback).where(PatientFeedback.is_processed == False)
        result = await session.execute(stmt)
        feedbacks = result.scalars().all()
        
        if not feedbacks:
            print("✨ No new feedback to process tonight.")
            return

        # 2. Group by doctor_uuid
        from collections import defaultdict
        doctor_feedbacks = defaultdict(list)
        for fb in feedbacks:
            doctor_feedbacks[str(fb.doctor_uuid)].append(fb)
            
        print(f"📊 Found {len(feedbacks)} unprocessed feedbacks across {len(doctor_feedbacks)} doctors.")
        
    for doc_uuid, fbs in doctor_feedbacks.items():
        combined_text = "\n".join([f"- {fb.content}" for fb in fbs])
        print(f"👨‍⚕️ Processing Dr. {doc_uuid} with {len(fbs)} feedbacks.")
        
        # 3. Call AI
        prompt = (
            "你是一个医疗服务质量评审专家。请严格根据以下患者的综合评价，判断该医生的服务态度和水平，"
            "给出一个合理的分数浮动值。\n"
            "规则：\n"
            "1. 如果普遍是好评，返回正数（例如 0.1, 0.2, 0.5）。\n"
            "2. 如果普遍是差评，返回负数（例如 -0.1, -0.2, -0.5）。\n"
            "3. 如果评价中性或一般，返回 0.0。\n"
            "4. 绝不要输出任何解释文字，只输出一个带有正负号的数字。\n"
            "【患者评价】:\n"
            f"{combined_text}"
        )
        
        payload = {
            "model": patient_settings.LLM_MODEL,
            "messages": [{"role": "user", "content": prompt}],
            "temperature": 0.1
        }
        
        headers = {
            "Authorization": f"Bearer {patient_settings.LLM_API_KEY}",
            "Content-Type": "application/json"
        }
        
        adjustment = 0.0
        try:
            async with httpx.AsyncClient() as client:
                resp = await client.post(
                    f"{patient_settings.LLM_API_BASE.rstrip('/')}/chat/completions",
                    json=payload, headers=headers, timeout=15.0
                )
                if resp.status_code == 200:
                    content = resp.json()["choices"][0]["message"]["content"].strip()
                    try:
                        adjustment = float(content)
                    except ValueError:
                        print(f"⚠️ AI returned non-float: {content}, defaulting to 0.0")
                else:
                    print(f"❌ LLM API failed: {resp.text}")
        except Exception as e:
            print(f"❌ LLM Request failed: {e}")
            
        print(f"🤖 AI suggested adjustment for {doc_uuid}: {adjustment}")
        
        # 4. Call Auth API to update score and update DB in a short transaction
        score_updated = False
        if adjustment != 0.0:
            try:
                auth_url = BaseClient.get_url('auth')
                put_url = f"{auth_url}/employee/{doc_uuid}/score/adjust"
                async with httpx.AsyncClient() as client:
                    r = await client.put(put_url, json={"adjustment": adjustment})
                    if r.status_code == 200:
                        print(f"✅ Successfully updated score for {doc_uuid}")
                        score_updated = True
                    else:
                        print(f"❌ Failed to update score for {doc_uuid}: {r.text}")
            except Exception as e:
                print(f"❌ Auth API call failed: {e}")
        else:
            # Adjustment is 0, no need to call Auth API, but we still mark as processed
            score_updated = True
        
        # 5. Mark as processed ONLY if we successfully dealt with the score
        # Open a short transaction per doctor
        if score_updated:
            async with async_session() as session:
                for fb in fbs:
                    fb.is_processed = True
                # Use merge to update detached objects
                for fb in fbs:
                    await session.merge(fb)
                await session.commit()
                print(f"📝 Marked {len(fbs)} feedbacks as processed for Dr. {doc_uuid}")
        
    print("🏁 Nightly batch job completed successfully.")

async def daemon_loop():
    from datetime import datetime, timedelta
    print("🌙 Nightly Batch Daemon Started. Waiting for 2:00 AM to process evaluations...")
    while True:
        now = datetime.now()
        target = now.replace(hour=2, minute=0, second=0, microsecond=0)
        
        # If it's already past 2:00 AM today, schedule for tomorrow 2:00 AM
        if now >= target:
            target += timedelta(days=1)
            
        sleep_seconds = (target - now).total_seconds()
        print(f"⏳ Next evaluation batch scheduled at {target} (in {sleep_seconds:.1f} seconds).")
        
        await asyncio.sleep(sleep_seconds)
        
        print(f"⏰ [{datetime.now()}] Waking up to run nightly batch!")
        await run_nightly_batch()

if __name__ == "__main__":
    try:
        asyncio.run(daemon_loop())
    except KeyboardInterrupt:
        print("🛑 Nightly Batch Daemon stopped.")
