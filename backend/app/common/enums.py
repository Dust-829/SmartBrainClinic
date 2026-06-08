from enum import Enum, IntEnum

class VisitState(IntEnum):
    UNPAID = 0          # 待支付
    REGISTERED = 1      # 已挂号
    RECEPTION = 2       # 接诊中
    FINISHED = 3        # 已结束
    CANCELLED = 4       # 已退号

class CheckState(str, Enum):
    UNPAID = "未缴费"
    PAID = "已缴费"
    EXECUTED = "已执行"
    REFUNDED = "已退费"

class InspectionState(str, Enum):
    UNPAID = "未缴费"
    PAID = "已缴费"
    EXECUTED = "已执行"
    REFUNDED = "已退费"

class DisposalState(str, Enum):
    UNPAID = "未缴费"
    PAID = "已缴费"
    EXECUTED = "已执行"
    REFUNDED = "已退费"

class DrugState(str, Enum):
    PRESCRIBED = "开立"
    PAID = "已缴费"
    DISPENSED = "已发药"
    REFUNDED = "已退费"
