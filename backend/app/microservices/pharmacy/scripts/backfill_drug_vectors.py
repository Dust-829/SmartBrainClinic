import sys
import os
import asyncio
from sqlalchemy import text
from sqlmodel import select

# 添加项目根目录到 sys.path
current_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(current_dir, "../../../../"))
sys.path.append(project_root)

from app.microservices.pharmacy.database import session_factory, engine
from app.microservices.pharmacy.models.drug import DrugInfo
from app.common.ai_embedding import get_embedding

async def main():
    print("🚀 [Backfill] Starting drug vector backfill script...")
    
    # 1. 首先确保 pgvector 扩展和字段存在
    async with engine.begin() as conn:
        print("⚙️ [Backfill] Checking pgvector extension and column...")
        await conn.execute(text("CREATE EXTENSION IF NOT EXISTS vector;"))
        try:
            await conn.execute(text("ALTER TABLE drug_info ADD COLUMN vector vector(1024);"))
            print("✅ [Backfill] Added 'vector' column to 'drug_info' table.")
        except Exception as e:
            if "already exists" in str(e):
                print("✅ [Backfill] 'vector' column already exists.")
            else:
                print(f"⚠️ [Backfill] Alter table note: {e}")

    # 2. 检索需要回填的数据
    async with session_factory() as session:
        stmt = select(DrugInfo).where(DrugInfo.vector.is_(None))
        res = await session.execute(stmt)
        drugs = res.scalars().all()
        
        if not drugs:
            print("✅ [Backfill] All drugs already have vectors. Nothing to do.")
            return
            
        print(f"🔍 [Backfill] Found {len(drugs)} drugs requiring embedding.")
        
        for idx, drug in enumerate(drugs, 1):
            text_to_embed = f"药品名称: {drug.drug_name}, 规格/适应症: {drug.specification}"
            print(f"🧬 [{idx}/{len(drugs)}] Embedding: {drug.drug_name}...")
            
            try:
                vector = await get_embedding(text_to_embed)
                if vector:
                    drug.vector = vector
                else:
                    print(f"❌ Failed to generate embedding for {drug.drug_name}")
            except Exception as e:
                print(f"❌ Error embedding {drug.drug_name}: {e}")
                
            # 每 50 条 commit 一次
            if idx % 50 == 0:
                await session.commit()
                print(f"💾 Committed up to {idx}")
                
        # 最后的 commit
        await session.commit()
        print("🎉 [Backfill] Finished backfilling all drug vectors!")

if __name__ == "__main__":
    asyncio.run(main())
