from app.microservices.medical.services.ai_order_recommendation import (
    build_rule_order_candidates,
    select_validated_llm_order_candidates,
)


CATALOG = [
    {"id": 1, "tech_code": "DEMO_CT_HEAD", "tech_name": "头颅CT", "tech_type": "check", "price": "180.00"},
    {"id": 2, "tech_code": "DEMO_MRI_HEAD", "tech_name": "头颅MRI", "tech_type": "check", "price": "680.00"},
    {"id": 3, "tech_code": "DEMO_CTA_HEAD", "tech_name": "头颈CTA", "tech_type": "check", "price": "520.00"},
    {"id": 4, "tech_code": "DEMO_ELECTROLYTE", "tech_name": "电解质", "tech_type": "inspection", "price": "52.00"},
    {"id": 5, "tech_code": "DEMO_REHAB", "tech_name": "康复训练", "tech_type": "disposal", "price": "120.00"},
]


def test_rule_candidates_use_only_available_check_and_inspection_catalog_items():
    candidates = build_rule_order_candidates(
        clinical_text="突发头痛伴眩晕，需要排除急性颅内问题",
        technologies=CATALOG,
        ordered_technology_ids=[],
    )

    assert candidates
    assert {item["type"] for item in candidates} <= {"check", "inspection"}
    assert all(item["medical_technology_id"] != 5 for item in candidates)
    assert all(item["reason"] for item in candidates)
    assert all(item["check_position"] == "头部" for item in candidates if item["type"] == "check")


def test_rule_candidates_exclude_orders_already_created_for_the_register():
    candidates = build_rule_order_candidates(
        clinical_text="突发头痛伴眩晕，需要排除急性颅内问题",
        technologies=CATALOG,
        ordered_technology_ids=[1, 2, 3],
    )

    assert all(item["medical_technology_id"] not in {1, 2, 3} for item in candidates)


def test_rule_candidates_do_not_guess_without_a_supported_clinical_trigger():
    candidates = build_rule_order_candidates(
        clinical_text="患者要求复诊咨询",
        technologies=CATALOG,
        ordered_technology_ids=[],
    )

    assert candidates == []


def test_llm_ranking_keeps_only_catalog_whitelist_fields_and_reason():
    rule_candidates = build_rule_order_candidates(
        clinical_text="突发头痛伴眩晕，需要排除急性颅内问题",
        technologies=CATALOG,
        ordered_technology_ids=[],
    )

    selected, warnings = select_validated_llm_order_candidates(
        rule_candidates=rule_candidates,
        llm_items=[
            {
                "medical_technology_id": 1,
                "reason": "需由医生结合查体判断是否优先排除急性颅内病变。",
                "type": "disposal",
                "price": "0.01",
                "check_position": "全身",
            },
        ],
    )

    assert warnings == []
    assert [item["medical_technology_id"] for item in selected] == [1]
    assert selected[0]["type"] == "check"
    assert selected[0]["price"] == "180.00"
    assert selected[0]["check_position"] == "头部"


def test_llm_ranking_discards_catalog_mismatch_and_falls_back_to_rule_candidates():
    rule_candidates = build_rule_order_candidates(
        clinical_text="突发头痛伴眩晕，需要排除急性颅内问题",
        technologies=CATALOG,
        ordered_technology_ids=[],
    )

    selected, warnings = select_validated_llm_order_candidates(
        rule_candidates=rule_candidates,
        llm_items=[
            {"medical_technology_id": 999, "reason": "目录外项目"},
            {"medical_technology_id": 1, "reason": ""},
        ],
    )

    assert selected == rule_candidates
    assert "llm_order_catalog_mismatch_discarded" in warnings
    assert "llm_order_reason_missing_discarded" in warnings
    assert "llm_order_no_valid_result_fallback" in warnings
