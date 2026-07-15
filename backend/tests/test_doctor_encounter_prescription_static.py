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
