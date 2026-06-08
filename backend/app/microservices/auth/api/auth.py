import uuid as uuid_pkg
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from ..database import get_session
from ..services import auth_service as svc
from app.common.response import success

router = APIRouter(prefix="/api/v1/auth", tags=["基础鉴权服务"])

class SearchSimilarDoctorRequest(BaseModel):
    dept_id: int
    gender_preference: str = "不限"
    query_vector: Optional[List[float]] = None
    limit: int = 5

class EmployeeCreate(BaseModel):
    realname: str
    password: Optional[str] = "123456"
    dept_code: Optional[str] = None
    regist_level_code: Optional[str] = None
    gender: Optional[str] = None
    expertise: Optional[str] = None
    ai_eval_score: Optional[float] = 5.0

@router.get("/employee/{uuid}", summary="获取员工信息")
async def get_employee(uuid: uuid_pkg.UUID, session: AsyncSession = Depends(get_session)):
    emp = await svc.get_employee_by_uuid(session, uuid)
    if not emp:
        raise HTTPException(status_code=404, detail="员工不存在")
    return success(emp)

@router.post("/employee", summary="新增医生(含后台向量化)", status_code=201)
async def create_employee(data: EmployeeCreate, session: AsyncSession = Depends(get_session)):
    try:
        emp = await svc.create_employee(session, data.model_dump())
        return success(emp.model_dump(exclude={"password", "expertise_vector"}, mode="json"))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

class ExpertiseUpdate(BaseModel):
    expertise: str

@router.put("/employee/{uuid}/expertise", summary="修改医生专长(触发向量重算)")
async def update_expertise(uuid: uuid_pkg.UUID, data: ExpertiseUpdate, session: AsyncSession = Depends(get_session)):
    try:
        emp = await svc.update_employee_expertise(session, uuid, data.expertise)
        return success(emp)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.get("/department/{uuid}", summary="获取科室信息")
async def get_department(uuid: str, session: AsyncSession = Depends(get_session)):
    dept = await svc.get_department_by_uuid(session, uuid)
    if not dept:
        raise HTTPException(status_code=404, detail="科室不存在")
    return success(dept.model_dump())

@router.get("/clinic-room/{uuid}", summary="获取诊室信息")
async def get_clinic_room(uuid: str, session: AsyncSession = Depends(get_session)):
    room = await svc.get_clinic_room_by_uuid(session, uuid)
    if not room:
        raise HTTPException(status_code=404, detail="诊室不存在")
    return success(room.model_dump())

@router.get("/clinic-room/name/{name}", summary="通过名称获取诊室信息")
async def get_clinic_room_by_name(name: str, session: AsyncSession = Depends(get_session)):
    room = await svc.get_clinic_room_by_name(session, name)
    if not room:
        raise HTTPException(status_code=404, detail="诊室不存在")
    return success(room.model_dump())

@router.get("/employees/by-dept-type/{dept_type}", summary="按科室类型获取员工")
async def get_employees_by_dept_type(dept_type: str, session: AsyncSession = Depends(get_session)):
    emps = await svc.get_employees_by_dept_type(session, dept_type)
    return success(emps)



@router.get("/regist-level/{uuid}", summary="获取挂号级别")
async def get_regist_level(uuid: str, session: AsyncSession = Depends(get_session)):
    level = await svc.get_regist_level_by_uuid(session, uuid)
    if not level:
        raise HTTPException(status_code=404, detail="级别不存在")
    return success(level.model_dump())



@router.get("/settle-category/{uuid}", summary="获取结算类别")
async def get_settle_category(uuid: str, session: AsyncSession = Depends(get_session)):
    settle = await svc.get_settle_category_by_uuid(session, uuid)
    if not settle:
        raise HTTPException(status_code=404, detail="类别不存在")
    return success(settle.model_dump())

@router.get("/settle-category/code/{code}", summary="通过代码获取结算类别")
async def get_settle_category_by_code(code: str, session: AsyncSession = Depends(get_session)):
    settle = await svc.get_settle_category_by_code(session, code)
    if not settle:
        raise HTTPException(status_code=404, detail="类别不存在")
    return success(settle.model_dump())



@router.get("/department/code/{code}", summary="通过科室编码获取科室")
async def get_department_by_code(code: str, session: AsyncSession = Depends(get_session)):
    dept = await svc.get_department_by_code(session, code)
    if not dept:
        raise HTTPException(status_code=404, detail="科室不存在")
    return success(dept.model_dump())

@router.get("/doctors", summary="获取医生列表")
async def list_doctors(dept_uuid: str = None, session: AsyncSession = Depends(get_session)):
    if not dept_uuid:
        raise HTTPException(status_code=400, detail="必须提供dept_uuid")
    dept = await svc.get_department_by_uuid(session, dept_uuid)
    if not dept:
        raise HTTPException(status_code=404, detail="科室不存在")
    docs = await svc.get_doctors_by_dept(session, dept.id)
    return success(docs)

@router.get("/doctors/by-dept-code/{code}", summary="通过科室编码获取医生列表")
async def list_doctors_by_dept_code(code: str, session: AsyncSession = Depends(get_session)):
    dept = await svc.get_department_by_code(session, code)
    if not dept:
        raise HTTPException(status_code=404, detail="科室不存在")
    docs = await svc.get_doctors_by_dept(session, dept.id)
    return success(docs)


@router.post("/doctors/search-similar", summary="向量检索相似医生")
async def search_similar_doctors(data: SearchSimilarDoctorRequest, session: AsyncSession = Depends(get_session)):
    docs = await svc.search_similar_doctors(
        session, 
        data.dept_id, 
        data.gender_preference, 
        data.query_vector, 
        data.limit
    )
    return success(docs)

class ScoreAdjustRequest(BaseModel):
    adjustment: float

@router.put("/employee/{uuid}/score/adjust", summary="内部接口:调整医生AI评分")
async def adjust_employee_score(uuid: str, data: ScoreAdjustRequest, session: AsyncSession = Depends(get_session)):
    try:
        res = await svc.adjust_employee_score(session, uuid_pkg.UUID(uuid), data.adjustment)
        return success(res)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
