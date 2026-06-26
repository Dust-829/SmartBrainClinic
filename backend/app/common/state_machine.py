"""
Centralized business state transitions.

Service modules should call these helpers before mutating persisted business
state. This keeps workflow rules in one place and prevents ad-hoc string state
updates from bypassing core medical billing constraints.
"""

from enum import Enum
from typing import Any, TypeVar

from app.common.enums import (
    BillState,
    CheckState,
    DisposalState,
    DrugState,
    InspectionState,
    VisitState,
)

StateEnum = TypeVar("StateEnum", bound=Enum)


class StateTransitionError(ValueError):
    pass


VISIT_TRANSITIONS = {
    VisitState.UNPAID: (VisitState.REGISTERED, VisitState.CANCELLED),
    VisitState.REGISTERED: (VisitState.RECEPTION, VisitState.CANCELLED),
    VisitState.RECEPTION: (VisitState.FINISHED,),
    VisitState.FINISHED: (),
    VisitState.CANCELLED: (),
}

MEDICAL_ITEM_TRANSITIONS = {
    CheckState.UNPAID: (CheckState.PAID,),
    CheckState.PAID: (CheckState.EXECUTED, CheckState.REFUNDED),
    CheckState.EXECUTED: (),
    CheckState.REFUNDED: (),
}

INSPECTION_TRANSITIONS = {
    InspectionState.UNPAID: (InspectionState.PAID,),
    InspectionState.PAID: (InspectionState.EXECUTED, InspectionState.REFUNDED),
    InspectionState.EXECUTED: (),
    InspectionState.REFUNDED: (),
}

DISPOSAL_TRANSITIONS = {
    DisposalState.UNPAID: (DisposalState.PAID,),
    DisposalState.PAID: (DisposalState.EXECUTED, DisposalState.REFUNDED),
    DisposalState.EXECUTED: (),
    DisposalState.REFUNDED: (),
}

DRUG_TRANSITIONS = {
    DrugState.PRESCRIBED: (DrugState.PAID,),
    DrugState.PAID: (DrugState.DISPENSED, DrugState.REFUNDED),
    DrugState.DISPENSED: (DrugState.REFUNDED,),
    DrugState.REFUNDED: (),
}

BILL_TRANSITIONS = {
    BillState.PAID: (BillState.REFUNDING,),
    BillState.REFUNDING: (BillState.REFUNDED, BillState.REFUND_FAILED),
    BillState.REFUND_FAILED: (BillState.REFUNDING,),
    BillState.REFUNDED: (),
}


def normalize_visit_state(state: Any) -> VisitState:
    return _normalize_state(VisitState, state, "挂号单")


def normalize_check_state(state: Any) -> CheckState:
    return _normalize_state(CheckState, state, "检查单")


def normalize_inspection_state(state: Any) -> InspectionState:
    return _normalize_state(InspectionState, state, "检验单")


def normalize_disposal_state(state: Any) -> DisposalState:
    return _normalize_state(DisposalState, state, "处置单")


def normalize_drug_state(state: Any) -> DrugState:
    return _normalize_state(DrugState, state, "处方单")


def normalize_bill_state(state: Any) -> BillState:
    return _normalize_state(BillState, state, "收费单")


def ensure_visit_transition(current: Any, target: Any) -> VisitState:
    return _ensure_transition(VisitState, current, target, VISIT_TRANSITIONS, "挂号单")


def ensure_check_transition(current: Any, target: Any) -> CheckState:
    return _ensure_transition(CheckState, current, target, MEDICAL_ITEM_TRANSITIONS, "检查单")


def ensure_inspection_transition(current: Any, target: Any) -> InspectionState:
    return _ensure_transition(InspectionState, current, target, INSPECTION_TRANSITIONS, "检验单")


def ensure_disposal_transition(current: Any, target: Any) -> DisposalState:
    return _ensure_transition(DisposalState, current, target, DISPOSAL_TRANSITIONS, "处置单")


def ensure_drug_transition(current: Any, target: Any) -> DrugState:
    return _ensure_transition(DrugState, current, target, DRUG_TRANSITIONS, "处方单")


def ensure_bill_transition(current: Any, target: Any) -> BillState:
    return _ensure_transition(BillState, current, target, BILL_TRANSITIONS, "收费单")


def can_check_transition(current: Any, target: Any) -> bool:
    return _can_transition(CheckState, current, target, MEDICAL_ITEM_TRANSITIONS, "检查单")


def can_inspection_transition(current: Any, target: Any) -> bool:
    return _can_transition(InspectionState, current, target, INSPECTION_TRANSITIONS, "检验单")


def can_disposal_transition(current: Any, target: Any) -> bool:
    return _can_transition(DisposalState, current, target, DISPOSAL_TRANSITIONS, "处置单")


def can_drug_transition(current: Any, target: Any) -> bool:
    return _can_transition(DrugState, current, target, DRUG_TRANSITIONS, "处方单")


def _can_transition(
    enum_cls: type[StateEnum],
    current: Any,
    target: Any,
    transitions: dict[StateEnum, tuple[StateEnum, ...]],
    entity_name: str,
) -> bool:
    try:
        _ensure_transition(enum_cls, current, target, transitions, entity_name)
        return True
    except StateTransitionError:
        return False


def _ensure_transition(
    enum_cls: type[StateEnum],
    current: Any,
    target: Any,
    transitions: dict[StateEnum, tuple[StateEnum, ...]],
    entity_name: str,
) -> StateEnum:
    current_state = _normalize_state(enum_cls, current, entity_name)
    target_state = _normalize_state(enum_cls, target, entity_name)

    if current_state == target_state:
        return target_state

    if target_state not in transitions.get(current_state, ()):
        raise StateTransitionError(
            f"{entity_name}状态不允许从 '{_state_label(current_state)}' "
            f"变更为 '{_state_label(target_state)}'"
        )

    return target_state


def _normalize_state(enum_cls: type[StateEnum], state: Any, entity_name: str) -> StateEnum:
    if isinstance(state, enum_cls):
        return state

    for member in enum_cls:
        if state == member.value or state == member.name:
            return member

        if isinstance(member.value, int):
            try:
                if int(state) == member.value:
                    return member
            except (TypeError, ValueError):
                pass

    raise StateTransitionError(f"{entity_name}状态值无效: {state}")


def _state_label(state: Enum) -> str:
    return str(state.value)
