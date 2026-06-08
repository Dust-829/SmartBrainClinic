import uuid as uuid_pkg
from typing import Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from ..models.auth import Employee, Department, RegistLevel, SettleCategory, ClinicRoom
import json
from ..models.auth import OutboxEvent
import bcrypt
from sqlalchemy.exc import IntegrityError
from decimal import Decimal

async def get_employee_by_uuid(session: AsyncSession, uuid: uuid_pkg.UUID) -> Optional[dict]:
    stmt = (
        select(Employee, Department.uuid, RegistLevel.uuid)
        .outerjoin(Department, Employee.dept_id == Department.id)
        .outerjoin(RegistLevel, Employee.regist_level_id == RegistLevel.id)
        .where(Employee.uuid == uuid)
    )
    result = await session.execute(stmt)
    row = result.first()
    if not row:
        return None
    emp, d_uuid, r_uuid = row
    emp_dict = emp.model_dump(exclude={"password", "expertise_vector"}, mode="json")
    emp_dict["dept_uuid"] = str(d_uuid) if d_uuid else None
    emp_dict["regist_level_uuid"] = str(r_uuid) if r_uuid else None
    return emp_dict

async def get_department_by_uuid(session: AsyncSession, uuid: str) -> Optional[Department]:
    result = await session.execute(select(Department).where(Department.uuid == uuid_pkg.UUID(uuid)))
    return result.scalar_one_or_none()

async def get_regist_level_by_uuid(session: AsyncSession, uuid: str) -> Optional[RegistLevel]:
    result = await session.execute(select(RegistLevel).where(RegistLevel.uuid == uuid_pkg.UUID(uuid)))
    return result.scalar_one_or_none()


async def get_settle_category_by_uuid(session: AsyncSession, uuid: str) -> Optional[SettleCategory]:
    result = await session.execute(select(SettleCategory).where(SettleCategory.uuid == uuid_pkg.UUID(uuid)))
    return result.scalar_one_or_none()

async def get_settle_category_by_code(session: AsyncSession, code: str) -> Optional[SettleCategory]:
    result = await session.execute(select(SettleCategory).where(SettleCategory.settle_code == code))
    return result.scalar_one_or_none()

async def get_department_by_code(session: AsyncSession, dept_code: str) -> Optional[Department]:
    result = await session.execute(select(Department).where(Department.dept_code == dept_code))
    return result.scalar_one_or_none()

async def get_clinic_room_by_uuid(session: AsyncSession, uuid: str) -> Optional[ClinicRoom]:
    result = await session.execute(select(ClinicRoom).where(ClinicRoom.uuid == uuid_pkg.UUID(uuid)))
    return result.scalar_one_or_none()

async def get_clinic_room_by_name(session: AsyncSession, name: str) -> Optional[ClinicRoom]:
    result = await session.execute(select(ClinicRoom).where(ClinicRoom.room_name == name, ClinicRoom.delmark == 1))
    return result.scalar_one_or_none()

async def get_doctors_by_dept(session: AsyncSession, dept_id: int) -> list:

    stmt = (
        select(Employee, RegistLevel.uuid)
        .outerjoin(RegistLevel, Employee.regist_level_id == RegistLevel.id)
        .where(
            Employee.dept_id == dept_id,
            Employee.regist_level_id.isnot(None),
            Employee.delmark == 1
        )
    )
    result = await session.execute(stmt)
    docs = []
    for emp, r_uuid in result.all():
        doc_dict = emp.model_dump(exclude={"password", "expertise_vector"}, mode="json")
        doc_dict["regist_level_uuid"] = str(r_uuid) if r_uuid else None
        docs.append(doc_dict)
    return docs

async def get_employees_by_dept_type(session: AsyncSession, dept_type: str) -> list:
    stmt = (
        select(Employee)
        .join(Department, Employee.dept_id == Department.id)
        .where(
            Department.dept_type == dept_type,
            Employee.delmark == 1
        )
    )
    result = await session.execute(stmt)
    emps = []
    for emp in result.scalars().all():
        emp_dict = emp.model_dump(exclude={"password", "expertise_vector"}, mode="json")
        emps.append(emp_dict)
    return emps

async def search_similar_doctors(session: AsyncSession, dept_id: int, gender_preference: str, query_vector: list[float], limit: int = 5) -> list:

    
    # 构建基础查询
    if query_vector:
        # 计算余弦距离并作为列返回（距离越小越相似）
        distance_col = Employee.expertise_vector.cosine_distance(query_vector).label("cosine_dist")
        stmt = (
            select(Employee, RegistLevel.uuid, distance_col)
            .outerjoin(RegistLevel, Employee.regist_level_id == RegistLevel.id)
            .where(
                Employee.dept_id == dept_id,
                Employee.regist_level_id.isnot(None),
                Employee.delmark == 1
            )
        )
    else:
        stmt = (
            select(Employee, RegistLevel.uuid)
            .outerjoin(RegistLevel, Employee.regist_level_id == RegistLevel.id)
            .where(
                Employee.dept_id == dept_id,
                Employee.regist_level_id.isnot(None),
                Employee.delmark == 1
            )
        )
    
    # 向量排序
    if query_vector:
        stmt = stmt.order_by(distance_col).limit(limit)
    else:
        stmt = stmt.limit(limit)

    result = await session.execute(stmt)
    docs = []
    for row in result.all():
        if query_vector:
            emp, r_uuid, cosine_dist = row
        else:
            emp, r_uuid = row
            cosine_dist = None
            
        doc_dict = emp.model_dump(exclude={"password", "expertise_vector"}, mode="json")
        doc_dict["regist_level_uuid"] = str(r_uuid) if r_uuid else None
        
        # 将余弦距离转为 0~100 的相似度分数
        # cosine_distance 范围 [0, 2]，0=完全一致，2=完全相反
        if cosine_dist is not None:
            similarity = max(0.0, (1.0 - float(cosine_dist)) * 100.0)
            doc_dict["similarity_score"] = round(similarity, 1)
        else:
            doc_dict["similarity_score"] = 50.0  # 无向量时给中性分
        
        # 顺便获取挂号费
        if emp.regist_level_id:
            rl = await session.get(RegistLevel, emp.regist_level_id)
            doc_dict["regist_fee"] = float(rl.regist_fee) if rl else 0.0
            
        docs.append(doc_dict)
    return docs



async def create_employee(session: AsyncSession, data: dict) -> Employee:
    """
    新建医生，并在存库后抛出消息进行后台异步向量化
    """

    
    # 默认密码加密
    raw_password = data.get("password", "123456")
    hashed_password = bcrypt.hashpw(raw_password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    
    dept_id = None
    if data.get("dept_code"):
        dept = await get_department_by_code(session, data["dept_code"])
        if not dept:
            raise ValueError(f"科室编码 {data['dept_code']} 不存在")
        dept_id = dept.id

    regist_level_id = None
    if data.get("regist_level_code"):
        # Import select if not already (it is at the top)
        result = await session.execute(select(RegistLevel).where(RegistLevel.regist_code == data["regist_level_code"]))
        level = result.scalar_one_or_none()
        if not level:
            raise ValueError(f"挂号等级编码 {data['regist_level_code']} 不存在")
        regist_level_id = level.id
        
    emp = Employee(
        realname=data["realname"],
        password=hashed_password,
        dept_id=dept_id,
        regist_level_id=regist_level_id,
        gender=data.get("gender"),
        expertise=data.get("expertise"),
        ai_eval_score=data.get("ai_eval_score", 5.0)
    )
    
    session.add(emp)
    
    # 存库和发件箱记录在同一个本地事务中原子提交
    if emp.expertise:
        evt = OutboxEvent(
            topic="employee_vector_sync",
            payload=json.dumps({
                "employee_uuid": str(emp.uuid),
                "expertise": emp.expertise
            })
        )
        session.add(evt)

    try:
        await session.commit()
        await session.refresh(emp)
    except IntegrityError:
        await session.rollback()
        raise ValueError("数据库完整性错误，可能存在冲突记录")
        
    return emp

async def update_employee_expertise(session: AsyncSession, emp_uuid: uuid_pkg.UUID, expertise: str) -> dict:
    """
    更新现有医生的专长，并抛出向量同步消息
    """
    stmt = select(Employee).where(Employee.uuid == emp_uuid)
    res = await session.execute(stmt)
    emp = res.scalar_one_or_none()
    
    if not emp:
        raise ValueError("医生不存在")
        
    emp.expertise = expertise
    
    # 发件箱模式，记录 MQ 事件
    evt = OutboxEvent(
        topic="employee_vector_sync",
        payload=json.dumps({
            "employee_uuid": str(emp.uuid),
            "expertise": expertise
        })
    )
    session.add(evt)
    
    await session.commit()
    
    return emp.model_dump(exclude={"password", "expertise_vector"}, mode="json")

async def adjust_employee_score(session: AsyncSession, employee_uuid: uuid_pkg.UUID, adjustment: float) -> dict:
    # 使用 with_for_update() 增加行级排他锁，防止并发请求导致的评分“丢失更新”漏洞
    stmt = select(Employee).where(Employee.uuid == employee_uuid).with_for_update()
    result = await session.execute(stmt)
    emp = result.scalar_one_or_none()
    if not emp:
        raise ValueError("Employee not found")
        
    current_score = float(emp.ai_eval_score) if emp.ai_eval_score is not None else 3.0
    new_score = current_score + adjustment
    # Clamp between 0.0 and 5.0
    new_score = max(0.0, min(5.0, new_score))
    
    emp.ai_eval_score = Decimal(str(round(new_score, 1)))
    session.add(emp)
    await session.commit()
    
    return {"uuid": str(emp.uuid), "new_score": str(emp.ai_eval_score)}
