import uuid as uuid_pkg
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from ..database import get_session
from ..services import billing_service as svc
from app.common.response import success, created
from pydantic import BaseModel
from typing import List

router = APIRouter(prefix="/api/v1/bill", tags=["财务收费服务"])

class BillItem(BaseModel):
    type: str # 检查/检验/处置/药品
    id: str # 来源单据UUID
    tech_uuid: str = None # 医技项目 UUID (针对检查/检验/处置)
    drug_uuid: str = None # 药品 UUID (针对药品)
    number: int = 1 # 数量 (针对药品)

class BillPayCreate(BaseModel):
    register_uuid: uuid_pkg.UUID
    item_ids: List[BillItem]
    pay_method: str = "微信"

@router.post("/pay", summary="合并缴费")
async def create_bill(data: BillPayCreate, session: AsyncSession = Depends(get_session)):
    try:
        result = await svc.create_bill(session, data.model_dump())
        return created(result)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.put("/{bill_code}/refund", summary="执行账单退费")
async def refund_bill(bill_code: str, session: AsyncSession = Depends(get_session)):
    try:
        result = await svc.refund_bill(session, bill_code)
        return success(result)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/register/{register_uuid}", summary="获取挂号单下的所有账单")
async def get_bills_by_register(register_uuid: uuid_pkg.UUID, session: AsyncSession = Depends(get_session)):
    try:
        bills = await svc.get_bills_by_register(session, register_uuid)
        return success(bills)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
