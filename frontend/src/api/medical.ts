import { apiBaseUrl, http, type ApiEnvelope } from './http'

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

export type ArtifactSourceFormat = 'dicom' | 'nifti'
export type ArtifactInferenceTaskState = 'queued' | 'running' | 'succeeded' | 'failed'

export interface ArtifactInputSource {
  source_ref: string
  source_format: ArtifactSourceFormat
}

export interface ArtifactInferenceTask {
  uuid: string
  check_uuid: string
  register_uuid: string
  source_format: ArtifactSourceFormat | null
  task_state: ArtifactInferenceTaskState
  model_name: string
  model_version?: string | null
  model_weight_sha256?: string | null
  threshold?: string | null
  mask_object_ref?: string | null
  overlay_object_ref?: string | null
  result_metadata?: {
    artifact_pixel_count?: number
    selected_slice?: number
    selected_slice_artifact_pixel_count?: number
    image_size?: number[]
    image_spacing?: number[]
  } | null
  error_code?: string | null
  created_at?: string | null
  started_at?: string | null
  completed_at?: string | null
}

export interface ArtifactInferenceSubmitPayload {
  source_image_ref: string
  source_format: ArtifactSourceFormat
  submitted_by_employee_uuid: string
}

export type MedicalReportState = 'draft' | 'published'

export interface MedicalReport {
  uuid: string
  register_uuid: string
  source_request_uuid: string
  report_type: string
  report_state: MedicalReportState
  conclusion?: string | null
  structured_result?: InspectionReportResultItem[] | null
  artifact_task_uuid?: string | null
  reviewer_employee_uuid?: string | null
  reviewed_at?: string | null
  published_at?: string | null
  version: number
  supersedes_report_uuid?: string | null
  created_at?: string | null
  updated_at?: string | null
}

export interface CheckReportDraftPayload {
  conclusion: string
  artifact_task_uuid?: string
  author_employee_uuid: string
}

export interface InspectionReportResultItem {
  item_name: string
  value: string
  unit?: string | null
  reference_range?: string | null
}

export interface InspectionReportDraftPayload {
  conclusion: string
  structured_result: InspectionReportResultItem[]
  author_employee_uuid: string
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
  listArtifactInputSources() {
    return http.get<ApiEnvelope<ArtifactInputSource[]>>('/api/v1/medical/artifact-inference/input-sources')
  },
  submitArtifactInferenceTask(checkUuid: string, payload: ArtifactInferenceSubmitPayload) {
    return http.post<ApiEnvelope<ArtifactInferenceTask>>(`/api/v1/medical/check/${checkUuid}/artifact-inference`, payload)
  },
  getLatestArtifactInferenceTask(checkUuid: string) {
    return http.get<ApiEnvelope<ArtifactInferenceTask>>(`/api/v1/medical/check/${checkUuid}/artifact-inference/latest`)
  },
  getArtifactInferenceOverlayUrl(taskUuid: string) {
    return `${apiBaseUrl}/api/v1/medical/artifact-inference/${encodeURIComponent(taskUuid)}/overlay`
  },
  getLatestCheckReport(checkUuid: string) {
    return http.get<ApiEnvelope<MedicalReport>>(`/api/v1/medical/check/${checkUuid}/report/latest`)
  },
  saveCheckReportDraft(checkUuid: string, payload: CheckReportDraftPayload) {
    return http.put<ApiEnvelope<MedicalReport>>(`/api/v1/medical/check/${checkUuid}/report`, payload)
  },
  publishCheckReport(reportUuid: string, reviewerEmployeeUuid: string) {
    return http.post<ApiEnvelope<MedicalReport>>(`/api/v1/medical/report/${reportUuid}/publish`, {
      reviewer_employee_uuid: reviewerEmployeeUuid,
    })
  },
  createCheckReportCorrectionDraft(reportUuid: string, authorEmployeeUuid: string) {
    return http.post<ApiEnvelope<MedicalReport>>(`/api/v1/medical/report/${reportUuid}/correction-draft`, {
      author_employee_uuid: authorEmployeeUuid,
    })
  },
  getLatestInspectionReport(inspectionUuid: string) {
    return http.get<ApiEnvelope<MedicalReport>>(`/api/v1/medical/inspection/${inspectionUuid}/report/latest`)
  },
  saveInspectionReportDraft(inspectionUuid: string, payload: InspectionReportDraftPayload) {
    return http.put<ApiEnvelope<MedicalReport>>(`/api/v1/medical/inspection/${inspectionUuid}/report`, payload)
  },
  publishInspectionReport(reportUuid: string, reviewerEmployeeUuid: string) {
    return http.post<ApiEnvelope<MedicalReport>>(`/api/v1/medical/inspection-report/${reportUuid}/publish`, {
      reviewer_employee_uuid: reviewerEmployeeUuid,
    })
  },
  createInspectionReportCorrectionDraft(reportUuid: string, authorEmployeeUuid: string) {
    return http.post<ApiEnvelope<MedicalReport>>(`/api/v1/medical/inspection-report/${reportUuid}/correction-draft`, {
      author_employee_uuid: authorEmployeeUuid,
    })
  },
}
