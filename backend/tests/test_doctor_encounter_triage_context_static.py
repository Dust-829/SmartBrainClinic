from pathlib import Path


def test_doctor_encounter_reads_and_renders_triage_context_without_mutating_draft():
    patient_api_source = Path("../frontend/src/api/patient.ts").read_text(encoding="utf-8")
    encounter_source = Path("../frontend/src/views/doctor/DoctorEncounterView.vue").read_text(encoding="utf-8")

    assert "export interface RegisterAIContext" in patient_api_source
    assert "getRegisterAIContext(registerUuid: string)" in patient_api_source
    assert "/register/${registerUuid}/ai-context" in patient_api_source
    assert "async function loadTriageContext()" in encounter_source
    assert "await Promise.all([loadMedicalTechnologies(), loadRequestQueue(), loadArtifactSources(), loadTriageContext()])" in encounter_source
    assert 'SectionCard title="本次 AI 分诊"' in encounter_source
    assert "AI 内容仅用于辅助了解本次情况" in encounter_source
    assert "resetEncounterForm(detail, draftResponse.data.data)" in encounter_source
