import { http, type ApiEnvelope } from './http'

export interface MedicalRecordDraft {
  uuid: string
  register_uuid: string
  readme?: string | null
  present?: string | null
  history?: string | null
  allergy?: string | null
  physique?: string | null
  proposal?: string | null
  diagnosis?: string | null
  cure?: string | null
  is_doctor_confirmed?: boolean
}

export interface MedicalRecordDraftConfirmPayload {
  readme: string
  present: string
  history: string
  physique: string
  diagnosis: string
  allergy?: string
  proposal?: string
  cure?: string
}

export interface MedicalRecordCreatePayload {
  register_uuid: string
  readme?: string
  present?: string
}

export interface SimilarMedicalRecord {
  uuid: string
  register_uuid: string
  present?: string | null
  history?: string | null
  diagnosis?: string | null
  similarity_score: number
  cosine_distance: number
}

export interface MedicalAIAssistantPayload {
  patient_uuid?: string
  employee_uuid?: string
  question: string
  top_k?: number
  confirm_action?: boolean
}

export interface MedicalAIAssistantResult {
  answer: string
}

export const medicalApi = {
  createRecord(payload: MedicalRecordCreatePayload) {
    return http.post<ApiEnvelope<{ uuid: string }>>('/api/v1/medical/record', payload)
  },
  getRecordDraft(registerUuid: string) {
    return http.get<ApiEnvelope<MedicalRecordDraft>>(`/api/v1/medical/record/draft/${registerUuid}`)
  },
  confirmRecordDraft(registerUuid: string, payload: MedicalRecordDraftConfirmPayload) {
    return http.put<ApiEnvelope<{ uuid: string; is_doctor_confirmed: boolean }>>(
      `/api/v1/medical/record/draft/${registerUuid}/confirm`,
      payload,
    )
  },
  searchSimilarRecords(queryText: string, topK = 5) {
    return http.post<ApiEnvelope<SimilarMedicalRecord[]>>('/api/v1/medical/record/search-similar', {
      query_text: queryText,
      top_k: topK,
    })
  },
  askAssistant(payload: MedicalAIAssistantPayload) {
    return http.post<ApiEnvelope<MedicalAIAssistantResult>>('/api/v1/medical/record/ai-assistant', payload)
  },
}
