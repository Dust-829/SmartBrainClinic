import { http, type ApiEnvelope } from './http'
import type { PatientCreatePayload, PatientRecord } from './patient'

function getAdminAuthHeaders() {
  const token = import.meta.env.VITE_ADMIN_API_TOKEN?.trim()
  return token
    ? {
        'X-AI-Audit-Token': token,
      }
    : undefined
}

export interface SchedulingApplicationRecord {
  uuid: string
  employee_uuid: string
  prompt: string
  status: string
  created_at?: string | null
}

export interface ScheduleGeneratePayload {
  start_date: string
  end_date: string
}

export interface ScheduleGenerateResult {
  start_date: string
  end_date: string
  generated_count: number
  success: boolean
}

export interface ScheduleAiAdjustPayload {
  employee_uuid: string
  prompt: string
}

export interface ScheduleRulePayload {
  employee_uuid: string
  rule_name?: string
  week_rule?: string
  llm_text_rule?: string
  regist_quota?: number
  clinic_room_uuid?: string
}

export interface ScheduleRuleResult {
  employee_uuid: string
  success: boolean
}

export interface ScheduleActualPayload {
  employee_uuid: string
  schedule_date: string
  noon: string
  regist_quota: number
  clinic_room_uuid?: string
}

export interface ScheduleActualResult {
  employee_uuid: string
  schedule_date?: string
  noon?: string
  regist_quota?: number
  success: boolean
}

export interface ApprovalResult {
  uuid: string
  status: string
  reason?: string
  ai_result?: unknown
}

export interface AuditQuery {
  module_name?: string
  source?: string
  validated?: boolean
  limit?: number
  offset?: number
}

export interface AuditLogRecord {
  uuid: string
  module_name: string
  source?: string | null
  model?: string | null
  input_summary?: string | null
  output_summary?: string | null
  warnings: string[] | string
  validated: boolean
  validator_messages: string[] | string
  latency_ms?: number | null
  context?: Record<string, unknown> | unknown[]
  created_at?: string | null
}

export interface DrugImportDraft {
  drug_code: string
  drug_name: string
  specification: string
  unit: string
  price: number
  stock: number
  min_stock_limit: number
}

export interface DrugImportResult {
  uuid: string
  drug_name: string
  drug_code: string
}

export interface DrugListItem {
  uuid: string
  drug_code: string
  drug_name: string
  specification: string
  unit: string
  price: string
  stock: number
  min_stock_limit?: number | null
  is_low_stock: boolean
}

export interface PrescriptionListItem {
  uuid: string
  register_uuid: string
  prescription_code: string
  creation_time?: string | null
  is_ai_recommended: boolean
  drug_state: string
}

export interface DispenseResult {
  prescription_uuid: string
  prescription_code: string
  drug_state: string
  items_count?: number
  returned_items?: number
  stock_warnings?: string[]
}

export interface BillRecord {
  uuid: string
  register_uuid?: string
  bill_code: string
  total_amount: string
  bill_state: string
  pay_method?: string | null
  transaction_id?: string | null
  fee_status: number
  pay_time?: string | null
}

export interface BillRefundResult {
  bill_code: string
  bill_state: string
  refund_amount: string
}

export interface PatientAdminListItem {
  uuid: string
  case_number: string
  real_name: string
  gender: string
  card_number: string
  birthdate: string
  home_address?: string | null
  created_at?: string | null
}

export interface PatientAdminUpdatePayload {
  real_name: string
  gender: string
  birthdate: string
  home_address?: string
}

export const adminApi = {
  generateSchedule(payload: ScheduleGeneratePayload) {
    return http.post<ApiEnvelope<ScheduleGenerateResult>>('/api/v1/patient/schedule/generate', payload)
  },
  adjustScheduleWithAi(payload: ScheduleAiAdjustPayload) {
    return http.post<ApiEnvelope<Record<string, unknown>>>('/api/v1/patient/ai-schedule', payload)
  },
  updateSchedulingRule(payload: ScheduleRulePayload) {
    return http.post<ApiEnvelope<ScheduleRuleResult>>('/api/v1/patient/admin/scheduling-rules', payload)
  },
  updateSchedulingActual(payload: ScheduleActualPayload) {
    return http.put<ApiEnvelope<ScheduleActualResult>>('/api/v1/patient/admin/scheduling-actuals', payload)
  },
  listPendingApplications() {
    return http.get<ApiEnvelope<SchedulingApplicationRecord[]>>('/api/v1/patient/admin/scheduling-applications')
  },
  approveSchedulingApplication(uuid: string) {
    return http.post<ApiEnvelope<ApprovalResult>>(`/api/v1/patient/admin/scheduling-applications/${uuid}/approve`)
  },
  rejectSchedulingApplication(uuid: string, reason: string) {
    return http.post<ApiEnvelope<ApprovalResult>>(`/api/v1/patient/admin/scheduling-applications/${uuid}/reject`, { reason })
  },
  listAiAudits(query: AuditQuery = {}) {
    return http.get<ApiEnvelope<AuditLogRecord[]>>('/api/v1/patient/admin/ai-audits', {
      params: query,
      headers: getAdminAuthHeaders(),
    })
  },
  batchImportDrugs(drugs: DrugImportDraft[]) {
    return http.post<ApiEnvelope<DrugImportResult[]>>('/api/v1/pharmacy/drugs/batch-import', { drugs })
  },
  listDrugs(params: { keyword?: string; low_stock_only?: boolean; limit?: number } = {}) {
    return http.get<ApiEnvelope<DrugListItem[]>>('/api/v1/pharmacy/drugs', { params })
  },
  listPrescriptions(params: { state?: string; limit?: number } = {}) {
    return http.get<ApiEnvelope<PrescriptionListItem[]>>('/api/v1/pharmacy/prescriptions', { params })
  },
  dispensePrescription(prescriptionUuid: string) {
    return http.put<ApiEnvelope<DispenseResult>>(`/api/v1/pharmacy/prescription/${prescriptionUuid}/dispense`)
  },
  returnPrescription(prescriptionUuid: string) {
    return http.put<ApiEnvelope<DispenseResult>>(`/api/v1/pharmacy/prescription/${prescriptionUuid}/return`)
  },
  getBillsByRegister(registerUuid: string) {
    return http.get<ApiEnvelope<BillRecord[]>>(`/api/v1/bill/register/${registerUuid}`)
  },
  listBills(params: { state?: string; limit?: number } = {}) {
    return http.get<ApiEnvelope<BillRecord[]>>('/api/v1/bill/list', { params })
  },
  refundBill(billCode: string) {
    return http.put<ApiEnvelope<BillRefundResult>>(`/api/v1/bill/${encodeURIComponent(billCode)}/refund`)
  },
  listPatients(params: { keyword?: string; limit?: number } = {}) {
    return http.get<ApiEnvelope<PatientAdminListItem[]>>('/api/v1/patient/admin/patients', { params })
  },
  createPatient(payload: PatientCreatePayload) {
    return http.post<ApiEnvelope<PatientRecord>>('/api/v1/patient', payload)
  },
  updatePatient(patientUuid: string, payload: PatientAdminUpdatePayload) {
    return http.put<ApiEnvelope<PatientAdminListItem>>(`/api/v1/patient/admin/patients/${encodeURIComponent(patientUuid)}`, payload)
  },
}
