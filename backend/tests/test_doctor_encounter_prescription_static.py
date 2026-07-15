from pathlib import Path


def test_doctor_encounter_keeps_ai_prescription_recommendation_separate_from_creation():
    pharmacy_api_source = Path("../frontend/src/api/pharmacy.ts").read_text(encoding="utf-8")
    encounter_source = Path("../frontend/src/views/doctor/DoctorEncounterView.vue").read_text(encoding="utf-8")

    assert "recommendPrescription(registerUuid: string)" in pharmacy_api_source
    assert "createPrescription(registerUuid: string, items: PrescriptionCreateItem[])" in pharmacy_api_source
    assert "/api/v1/pharmacy/recommend-prescription" in pharmacy_api_source
    assert "/api/v1/pharmacy/prescription" in pharmacy_api_source
    assert "async function generatePrescriptionRecommendation()" in encounter_source
    assert "async function createPrescription()" in encounter_source
    assert "isMedicalRecordConfirmed.value = true" in encounter_source
    assert "AI 处方建议" in encounter_source
    assert "医生确认并开立" in encounter_source
    assert encounter_source.index('AI 处方建议') > encounter_source.index('<aside class="doctor-encounter__sidebar">')
    assert encounter_source.index('AI 处方建议') > encounter_source.index('本次 AI 分诊')


def test_doctor_encounter_keeps_work_area_before_ai_support_on_narrow_screens():
    encounter_source = Path("../frontend/src/views/doctor/DoctorEncounterView.vue").read_text(encoding="utf-8")

    workspace_index = encounter_source.index('<div class="doctor-encounter__workspace">')
    main_index = encounter_source.index('<div class="doctor-encounter__main">')
    sidebar_index = encounter_source.index('<aside class="doctor-encounter__sidebar">')
    narrow_media_index = encounter_source.index('@media (max-width: 1180px)')
    narrow_media_source = encounter_source[narrow_media_index:]

    assert workspace_index < main_index < sidebar_index
    assert '.doctor-encounter__workspace,' in narrow_media_source
    assert 'grid-template-columns: 1fr;' in narrow_media_source


def test_doctor_encounter_keeps_ai_order_recommendations_separate_from_order_creation():
    medical_api_source = Path("../frontend/src/api/medical.ts").read_text(encoding="utf-8")
    encounter_source = Path("../frontend/src/views/doctor/DoctorEncounterView.vue").read_text(encoding="utf-8")

    assert "recommendOrderCandidates(registerUuid: string)" in medical_api_source
    assert "/api/v1/medical/orders/ai-recommendation" in medical_api_source
    assert "async function generateOrderRecommendation()" in encounter_source
    assert "function addOrderRecommendationToPending(item: PendingOrderRecommendationItem)" in encounter_source
    assert "pendingOrders.value.push({" in encounter_source
    assert "async function signPendingOrders()" in encounter_source
    assert "AI 检查检验建议" in encounter_source
    assert "加入待签清单后仍需医生统一签署才会开立" in encounter_source
    assert encounter_source.index("AI 检查检验建议") > encounter_source.index('<aside class="doctor-encounter__sidebar">')
