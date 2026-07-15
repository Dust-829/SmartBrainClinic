import uuid as uuid_pkg
from typing import List, Optional

from fastapi import APIRouter, Depends, Header, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.common.response import success
from app.common.security import AdminPrincipal, create_admin_access_token, require_admin

from ..database import get_session
from ..services import auth_service as svc

router = APIRouter(prefix="/api/v1/auth", tags=["基础鉴权服务"])


class SearchSimilarDoctorRequest(BaseModel):
    dept_id: int
    gender_preference: str = "不限"
    query_vector: Optional[List[float]] = None
    limit: int = 5


class EmployeeCreate(BaseModel):
    realname: str
    staff_code: Optional[str] = Field(default=None, max_length=64)
    password: str = Field(min_length=8, max_length=128)
    dept_code: Optional[str] = None
    regist_level_code: Optional[str] = None
    gender: Optional[str] = None
    expertise: Optional[str] = None
    ai_eval_score: Optional[float] = 5.0


class EmployeeProfileUpdate(BaseModel):
    realname: str
    dept_code: Optional[str] = None
    regist_level_code: Optional[str] = None
    gender: Optional[str] = None
    expertise: Optional[str] = None


class ExpertiseUpdate(BaseModel):
    expertise: str


class ScoreAdjustRequest(BaseModel):
    adjustment: float


class EmployeePasswordResetRequest(BaseModel):
    new_password: str = Field(min_length=8, max_length=128)


class EmployeeActiveStatusUpdate(BaseModel):
    is_active: bool


class AdminLoginRequest(BaseModel):
    staff_code: str
    password: str


class DoctorLoginRequest(BaseModel):
    staff_code: str
    password: str


@router.post("/admin/login", summary="管理员登录")
async def admin_login(data: AdminLoginRequest, session: AsyncSession = Depends(get_session)):
    admin = await svc.authenticate_admin(session, data.staff_code, data.password)
    if not admin:
        raise HTTPException(status_code=401, detail="管理员工号或密码错误")

    access_token, expires_in = create_admin_access_token(
        admin_uuid=str(admin.uuid),
        staff_code=admin.staff_code,
        display_name=admin.display_name,
    )
    return success(
        {
            "access_token": access_token,
            "token_type": "Bearer",
            "expires_in": expires_in,
            "staff": {
                "uuid": str(admin.uuid),
                "staff_code": admin.staff_code,
                "display_name": admin.display_name,
            },
        }
    )


@router.post("/doctor/login", summary="医生登录")
async def doctor_login(data: DoctorLoginRequest, session: AsyncSession = Depends(get_session)):
    doctor = await svc.authenticate_doctor(session, data.staff_code, data.password)
    if not doctor:
        raise HTTPException(status_code=401, detail="医生工号或密码错误")
    return success({"staff": doctor})


@router.get("/employee/{uuid}", summary="获取员工信息")
async def get_employee(uuid: uuid_pkg.UUID, session: AsyncSession = Depends(get_session)):
    emp = await svc.get_employee_by_uuid(session, uuid)
    if not emp:
        raise HTTPException(status_code=404, detail="员工不存在")
    return success(emp)


@router.post("/employee", summary="新增医生", status_code=201)
async def create_employee(
    data: EmployeeCreate,
    session: AsyncSession = Depends(get_session),
    admin: AdminPrincipal = Depends(require_admin),
):
    try:
        emp = await svc.create_employee(session, data.model_dump(), uuid_pkg.UUID(admin.uuid))
        return success(emp.model_dump(exclude={"password", "expertise_vector"}, mode="json"))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.put("/employee/{uuid}/profile", summary="更新医生基础资料")
async def update_employee_profile(
    uuid: uuid_pkg.UUID,
    data: EmployeeProfileUpdate,
    session: AsyncSession = Depends(get_session),
    admin: AdminPrincipal = Depends(require_admin),
):
    try:
        result = await svc.update_employee_profile(session, uuid, data.model_dump(), uuid_pkg.UUID(admin.uuid))
        return success(result)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.put("/employee/{uuid}/expertise", summary="修改医生专长")
async def update_expertise(
    uuid: uuid_pkg.UUID,
    data: ExpertiseUpdate,
    session: AsyncSession = Depends(get_session),
    _: AdminPrincipal = Depends(require_admin),
):
    try:
        emp = await svc.update_employee_expertise(session, uuid, data.expertise)
        return success(emp)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.put("/employee/{uuid}/score/adjust", summary="调整医生 AI 评分")
async def adjust_employee_score(
    uuid: str,
    data: ScoreAdjustRequest,
    session: AsyncSession = Depends(get_session),
    _: AdminPrincipal = Depends(require_admin),
):
    try:
        res = await svc.adjust_employee_score(session, uuid_pkg.UUID(uuid), data.adjustment)
        return success(res)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/employee/{uuid}/credentials/reset", summary="重置医生登录凭据")
async def reset_employee_credentials(
    uuid: uuid_pkg.UUID,
    data: EmployeePasswordResetRequest,
    session: AsyncSession = Depends(get_session),
    admin: AdminPrincipal = Depends(require_admin),
):
    try:
        return success(await svc.reset_employee_password(session, uuid, data.new_password, uuid_pkg.UUID(admin.uuid)))
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.get("/employee/{uuid}/deactivation-check", summary="检查医生是否可停用")
async def get_employee_deactivation_check(
    uuid: uuid_pkg.UUID,
    authorization: Optional[str] = Header(default=None),
    _: AdminPrincipal = Depends(require_admin),
):
    try:
        return success(await svc.get_employee_deactivation_check(uuid, authorization))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.put("/employee/{uuid}/active", summary="启用或停用医生")
async def update_employee_active_status(
    uuid: uuid_pkg.UUID,
    data: EmployeeActiveStatusUpdate,
    session: AsyncSession = Depends(get_session),
    authorization: Optional[str] = Header(default=None),
    admin: AdminPrincipal = Depends(require_admin),
):
    try:
        return success(
            await svc.update_employee_active_status(
                session,
                uuid,
                data.is_active,
                authorization,
                uuid_pkg.UUID(admin.uuid),
            )
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/admin/doctors", summary="管理员查询医生账号")
async def list_doctor_accounts(
    keyword: str = "",
    limit: int = 20,
    offset: int = 0,
    session: AsyncSession = Depends(get_session),
    _: AdminPrincipal = Depends(require_admin),
):
    try:
        doctors = await svc.list_doctor_accounts(session, keyword=keyword, limit=limit, offset=offset)
        return success(doctors)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


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
        raise HTTPException(status_code=404, detail="挂号级别不存在")
    return success(level.model_dump())


@router.get("/settle-category/{uuid}", summary="获取结算类别")
async def get_settle_category(uuid: str, session: AsyncSession = Depends(get_session)):
    settle = await svc.get_settle_category_by_uuid(session, uuid)
    if not settle:
        raise HTTPException(status_code=404, detail="结算类别不存在")
    return success(settle.model_dump())


@router.get("/settle-category/code/{code}", summary="通过代码获取结算类别")
async def get_settle_category_by_code(code: str, session: AsyncSession = Depends(get_session)):
    settle = await svc.get_settle_category_by_code(session, code)
    if not settle:
        raise HTTPException(status_code=404, detail="结算类别不存在")
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
        raise HTTPException(status_code=400, detail="必须提供 dept_uuid")
    dept = await svc.get_department_by_uuid(session, dept_uuid)
    if not dept:
        raise HTTPException(status_code=404, detail="科室不存在")
    docs = await svc.get_doctors_by_dept(session, dept.id)
    return success(docs)


@router.get("/admin/resource-stats", summary="管理员首页资源统计")
async def get_admin_resource_stats(session: AsyncSession = Depends(get_session)):
    try:
        stats = await svc.get_admin_resource_stats(session)
        return success(stats)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


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
        data.limit,
    )
    return success(docs)
