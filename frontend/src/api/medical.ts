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

export type MedicalTechnologyType = 'check' | 'inspection' | 'disposal'

export interface MedicalTechnologyOption {
  id: number
  uuid: string
  tech_code: string
  tech_name: string
  tech_type: string
  price: string
}

export interface CheckRequestCreatePayload {
  register_uuid: string
  medical_technology_id: number
  check_info?: string
  check_position?: string
}

export interface InspectionRequestCreatePayload {
  register_uuid: string
  medical_technology_id: number
}

export interface DisposalRequestCreatePayload {
  register_uuid: string
  medical_technology_id: number
}

export interface OrderSignItemPayload {
  type: MedicalTechnologyType
  medical_technology_id: number
  check_info?: string
  check_position?: string
}

export interface OrderSignPayload {
  register_uuid: string
  items: OrderSignItemPayload[]
}

export interface OrderSignResultItem {
  uuid: string
  type: MedicalTechnologyType
  state: string
}

export interface OrderSignResult {
  count: number
  items: OrderSignResultItem[]
}

export interface MedicalRequestItem {
  uuid: string
  register_uuid: string
  item_type: MedicalTechnologyType | string
  state: string
  medical_technology_id: number
  medical_technology_uuid?: string | null
  tech_code?: string | null
  tech_name?: string | null
  tech_type?: string | null
  price: string
  creation_time?: string | null
  check_info?: string | null
  check_position?: string | null
  result?: unknown
}

export interface RegisterMedicalRequests {
  checks: MedicalRequestItem[]
  inspections: MedicalRequestItem[]
  disposals: MedicalRequestItem[]
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
  listTechnologies(techType?: MedicalTechnologyType) {
    return http.get<ApiEnvelope<MedicalTechnologyOption[]>>('/api/v1/medical/tech', {
      params: techType ? { tech_type: techType } : undefined,
    })
  },
  createCheck(payload: CheckRequestCreatePayload) {
    return http.post<ApiEnvelope<{ uuid: string }>>('/api/v1/medical/check', payload)
  },
  createInspection(payload: InspectionRequestCreatePayload) {
    return http.post<ApiEnvelope<{ uuid: string }>>('/api/v1/medical/inspection', payload)
  },
  createDisposal(payload: DisposalRequestCreatePayload) {
    return http.post<ApiEnvelope<{ uuid: string }>>('/api/v1/medical/disposal', payload)
  },
  signOrders(payload: OrderSignPayload) {
    return http.post<ApiEnvelope<OrderSignResult>>('/api/v1/medical/orders/sign', payload)
  },
  getRegisterRequests(registerUuid: string) {
    return http.get<ApiEnvelope<RegisterMedicalRequests>>(`/api/v1/medical/requests/register/${registerUuid}`)
  },
}
