import uuid as uuid_pkg
from fastapi import APIRouter, Depends, Header, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from ..database import get_session
from ..services import pharmacy_service as svc
from app.common.response import success, created
from pydantic import BaseModel
from typing import List

router = APIRouter(prefix="/api/v1/pharmacy", tags=["药房服务"])

class PrescriptionItemCreate(BaseModel):
    drug_id: int
    drug_usage: str
    drug_number: int

class PrescriptionCreate(BaseModel):
    register_uuid: uuid_pkg.UUID
    items: List[PrescriptionItemCreate]

@router.post("/prescription", summary="开立处方")
async def create_prescription(data: PrescriptionCreate, session: AsyncSession = Depends(get_session)):
    try:
        result = await svc.create_prescription(session, data.model_dump())
        return created(result)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/drug/{uuid}", summary="获取药品信息")
async def get_drug(uuid: str, session: AsyncSession = Depends(get_session)):
    drug = await svc.get_drug_by_uuid(session, uuid)
    if not drug:
        raise HTTPException(status_code=404, detail="药品不存在")
    return success(drug.model_dump(mode="json"))

@router.get("/prescription-item/{uuid}", summary="获取处方单明细")
async def get_prescription_item(uuid: str, session: AsyncSession = Depends(get_session)):
    item = await svc.get_prescription_item_by_uuid(session, uuid)
    if not item:
        raise HTTPException(status_code=404, detail="处方明细不存在")
    return success(item)

@router.put("/prescription-item/{item_uuid}/state", summary="根据处方项UUID更新处方发药状态")
async def update_prescription_state(item_uuid: str, state: str, session: AsyncSession = Depends(get_session)):
    prescription = await svc.update_prescription_state_by_item(session, item_uuid, state)
    if not prescription:
        raise HTTPException(status_code=404, detail="处方明细或处方不存在")
    return success({"uuid": str(prescription.uuid), "prescription_code": prescription.prescription_code, "drug_state": prescription.drug_state})

@router.put("/prescription/{uuid}/dispense", summary="执行处方发药与库存扣减")
async def dispense_drugs(
    uuid: str,
    session: AsyncSession = Depends(get_session),
    idempotency_key: str = Header(default=None, alias="Idempotency-Key"),
):
    try:
        result = await svc.dispense_drugs(session, uuid, idempotency_key=idempotency_key)
        return success(result)
    except ValueError as e:
        # 库存不足或状态不对均返回 400 Bad Request
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/prescription/{uuid}/return", summary="执行退药与恢复库存")
async def return_drugs(
    uuid: str,
    session: AsyncSession = Depends(get_session),
    idempotency_key: str = Header(default=None, alias="Idempotency-Key"),
):
    try:
        result = await svc.return_drugs(session, uuid, idempotency_key=idempotency_key)
        return success(result)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class RecommendPrescriptionRequest(BaseModel):
    register_uuid: uuid_pkg.UUID

@router.post("/recommend-prescription", summary="AI 智能处方推荐")
async def recommend_prescription(data: RecommendPrescriptionRequest, session: AsyncSession = Depends(get_session)):
    try:
        result = await svc.recommend_prescription(session, data.register_uuid)
        return success(result)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class BatchItemsRequest(BaseModel):
    item_uuids: List[str]

@router.post("/prescription-items/batch", summary="批量获取处方单明细及药品价格")
async def get_prescription_items_batch(data: BatchItemsRequest, session: AsyncSession = Depends(get_session)):
    items = await svc.get_prescription_items_batch(session, data.item_uuids)
    return success(items)

@router.post("/prescription-items/billing-batch", summary="批量获取整张处方收费明细")
async def get_prescription_items_for_billing(data: BatchItemsRequest, session: AsyncSession = Depends(get_session)):
    items = await svc.get_prescription_items_for_billing(session, data.item_uuids)
    return success(items)

@router.post("/refund-items", summary="内部原子退费处方项目")
async def refund_prescription_items(data: BatchItemsRequest, session: AsyncSession = Depends(get_session)):
    try:
        result = await svc.refund_prescription_items(session, data.item_uuids)
        return success(result)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class DrugImportInput(BaseModel):
    drug_code: str
    drug_name: str
    specification: str
    unit: str
    price: float
    stock: int
    min_stock_limit: int = 10

class BatchImportDrugsRequest(BaseModel):
    drugs: List[DrugImportInput]

@router.post("/drugs/batch-import", summary="批量入库药品并自动生成向量")
async def batch_import_drugs(data: BatchImportDrugsRequest, session: AsyncSession = Depends(get_session)):
    try:
        result = await svc.batch_import_drugs(session, [d.model_dump() for d in data.drugs])
        return success(result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
