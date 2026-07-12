import { http, type ApiEnvelope } from './http'
import type { PatientCreatePayload, PatientRecord } from './patient'

export interface SchedulingApplicationRecord {
  uuid: string
  employee_uuid: string
  employee_name?: string | null
  dept_name?: string | null
  prompt: string
  prompt_display?: string
  prompt_title?: string
  prompt_excerpt?: string
  time_hint?: string | null
  status: string
  status_text?: string
  reject_reason?: string | null
  created_at?: string | null
  processed_at?: string | null
}

export interface ScheduleGeneratePayload {
  start_date: string
  end_date: string
}

export interface ScheduleGenerateResult {
  start_date: string
  end_date: string
  generated_count: number
  skipped_count: number
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
  slot_duration_minutes?: number
  clinic_room_uuid?: string
}

export interface ScheduleRuleResult {
  employee_uuid: string
  week_rule?: string
  regist_quota?: number
  slot_duration_minutes?: number
  clinic_room_uuid?: string | null
  success: boolean
}

export interface ScheduleActualPayload {
  employee_uuid: string
  schedule_date: string
  noon: string
  regist_quota: number
  slot_duration_minutes?: number
  clinic_room_uuid?: string
}

export interface ScheduleActualResult {
  employee_uuid: string
  schedule_date?: string
  noon?: string
  regist_quota?: number
  slot_duration_minutes?: number
  registered_count?: number
  disruptions_created?: number
  status?: string
  clinic_room_uuid?: string | null
  success: boolean
}

export interface ScheduleAiActionSummary {
  action_type: string
  target_date: string
  noon: string
  status: string
  changed: boolean
  final_regist_quota: number
  registered_count: number
  disruptions_created: number
  clinic_room_uuid?: string | null
  clamped_to_registered_count?: boolean
}

export interface ScheduleAiAdjustResult {
  employee_uuid: string
  employee_name?: string
  llm_text_rule: string
  actions_applied: number
  disruptions_created: number
  action_summaries: ScheduleAiActionSummary[]
  success: boolean
}

export interface ApprovalResult {
  uuid: string
  status: string
  reason?: string
  reject_reason?: string | null
  processed_at?: string | null
  ai_result?: ScheduleAiAdjustResult | Record<string, unknown>
}

export interface AuditQuery {
  module_name?: string
  source?: string
  validated?: boolean
  review_status?: 'pending' | 'approved' | 'rejected' | 'none'
  created_from?: string
  created_to?: string
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
  review_status?: 'pending' | 'approved' | 'rejected' | null
  review_note?: string | null
  reviewer?: string | null
  reviewed_at?: string | null
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

export interface DrugImportFailure {
  drug_code: string
  reason: string
}

export interface DrugImportResponse {
  successes: DrugImportResult[]
  failures: DrugImportFailure[]
}

export interface WorkbenchPagination {
  total: number
  limit: number
  offset: number
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

export interface PharmacyWorkbenchPrescriptionListItem extends PrescriptionListItem {
  patient_name?: string | null
  patient_case_number?: string | null
  employee_name?: string | null
  dept_name?: string | null
  actual_time_range?: string | null
  clinic_room_name?: string | null
  items_count: number
  can_dispense: boolean
  can_return: boolean
}

export interface PharmacyWorkbenchPrescriptionPage {
  items: PharmacyWorkbenchPrescriptionListItem[]
  pagination: WorkbenchPagination
}

export interface PharmacyWorkbenchPrescriptionDetailItem {
  uuid: string
  drug_uuid?: string | null
  drug_code?: string | null
  drug_name?: string | null
  specification?: string | null
  unit?: string | null
  price: string
  stock?: number | null
  min_stock_limit?: number | null
  drug_usage: string
  drug_number: number
}

export interface PharmacyWorkbenchPrescriptionDetail {
  header: PrescriptionListItem
  register_context: {
    patient_name?: string | null
    patient_case_number?: string | null
    employee_name?: string | null
    dept_name?: string | null
    actual_time_range?: string | null
    clinic_room_name?: string | null
    visit_state_text?: string | null
  }
  items: PharmacyWorkbenchPrescriptionDetailItem[]
  actions: {
    can_dispense: boolean
    can_return: boolean
    primary_action?: 'dispense' | 'return' | null
  }
}

export interface PharmacyWorkbenchDrugPage {
  items: DrugListItem[]
  pagination: WorkbenchPagination
}

export interface PharmacyWorkbenchOverview {
  paid_prescription_count: number
  dispensed_prescription_count: number
  low_stock_drug_count: number
  total_drug_count: number
  low_stock_drugs: DrugListItem[]
  actionable_prescriptions: PharmacyWorkbenchPrescriptionListItem[]
}

export interface DrugStockAdjustmentPayload {
  mode: 'increase' | 'set'
  quantity: number
}

export interface DrugStockAdjustmentResult {
  drug_uuid: string
  previous_stock: number
  current_stock: number
  mode: 'increase' | 'set'
  quantity: number
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

export interface AdminBillQuery {
  keyword?: string
  state?: string
  limit?: number
  offset?: number
}

export interface AdminBillSummary {
  total_count: number
  paid_count: number
  refunding_count: number
  refunded_count: number
  refund_failed_count: number
  state_counts: Record<string, number>
  total_amount: string
  refunded_amount: string
}

export interface AdminBillListItem extends BillRecord {
  patient_name?: string | null
  case_number?: string | null
  card_number_masked?: string | null
  visit_date?: string | null
  detail_count: number
}

export interface AdminBillPage {
  items: AdminBillListItem[]
  pagination: {
    total: number
    limit: number
    offset: number
  }
  summary: AdminBillSummary
}

export interface AdminBillDetailItem {
  uuid: string
  item_type: string
  item_source_id: string
  amount: string
}

export interface AdminBillRefundStep {
  step_name: string
  status: string
  error_message?: string | null
  request_payload?: Record<string, unknown> | unknown[] | string | null
  response_payload?: Record<string, unknown> | unknown[] | string | null
  updated_at?: string | null
}

export interface AdminBillDetail extends BillRecord {
  patient_uuid?: string | null
  patient_name?: string | null
  case_number?: string | null
  card_number_masked?: string | null
  visit_date?: string | null
  visit_state?: number | null
  visit_state_label?: string | null
  details: AdminBillDetailItem[]
  refund_steps: AdminBillRefundStep[]
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

export interface AuditPagination {
  total: number
  limit: number
  offset: number
}

export interface AuditSummary {
  total_count: number
  validated_count: number
  pending_count: number
  not_queued_count: number
  review_pending_count: number
  review_approved_count: number
  review_rejected_count: number
}

export interface AuditLogPage {
  items: AuditLogRecord[]
  pagination: AuditPagination
  summary: AuditSummary
}

export interface AuditReviewPayload {
  review_status: 'approved' | 'rejected'
  review_note?: string
  reviewer?: string
}

export interface PatientAdminUpdatePayload {
  real_name: string
  gender: string
  birthdate: string
  home_address?: string
}

export interface PatientAdminStats {
  patient_total: number
}

export const adminApi = {
  generateSchedule(payload: ScheduleGeneratePayload) {
    return http.post<ApiEnvelope<ScheduleGenerateResult>>('/api/v1/patient/schedule/generate', payload)
  },
  adjustScheduleWithAi(payload: ScheduleAiAdjustPayload) {
    return http.post<ApiEnvelope<ScheduleAiAdjustResult>>('/api/v1/patient/ai-schedule', payload)
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
    return http.get<ApiEnvelope<AuditLogPage>>('/api/v1/patient/admin/ai-audits', {
      params: query,
    })
  },
  getAiAuditDetail(auditUuid: string) {
    return http.get<ApiEnvelope<AuditLogRecord>>(`/api/v1/patient/admin/ai-audits/${encodeURIComponent(auditUuid)}`)
  },
  reviewAiAudit(auditUuid: string, payload: AuditReviewPayload) {
    return http.post<ApiEnvelope<AuditLogRecord>>(`/api/v1/patient/admin/ai-audits/${encodeURIComponent(auditUuid)}/review`, payload)
  },
  exportAiAudits(query: AuditQuery = {}) {
    return http.get<Blob>('/api/v1/patient/admin/ai-audits/export', {
      params: query,
      responseType: 'blob',
    })
  },
  getPharmacyWorkbenchOverview() {
    return http.get<ApiEnvelope<PharmacyWorkbenchOverview>>('/api/v1/pharmacy/admin/workbench/overview')
  },
  listPharmacyWorkbenchPrescriptions(
    params: { state?: string; limit?: number; offset?: number; prescription_code?: string } = {},
  ) {
    return http.get<ApiEnvelope<PharmacyWorkbenchPrescriptionPage>>('/api/v1/pharmacy/admin/workbench/prescriptions', {
      params,
    })
  },
  getPharmacyWorkbenchPrescriptionDetail(prescriptionUuid: string) {
    return http.get<ApiEnvelope<PharmacyWorkbenchPrescriptionDetail>>(
      `/api/v1/pharmacy/admin/workbench/prescriptions/${encodeURIComponent(prescriptionUuid)}`,
    )
  },
  listPharmacyWorkbenchDrugs(
    params: { keyword?: string; low_stock_only?: boolean; limit?: number; offset?: number } = {},
  ) {
    return http.get<ApiEnvelope<PharmacyWorkbenchDrugPage>>('/api/v1/pharmacy/admin/workbench/drugs', {
      params,
    })
  },
  batchImportDrugs(drugs: DrugImportDraft[]) {
    return http.post<ApiEnvelope<DrugImportResponse>>('/api/v1/pharmacy/drugs/batch-import', { drugs })
  },
  adjustDrugStock(drugUuid: string, payload: DrugStockAdjustmentPayload) {
    return http.post<ApiEnvelope<DrugStockAdjustmentResult>>(
      `/api/v1/pharmacy/admin/workbench/drugs/${encodeURIComponent(drugUuid)}/stock-adjustments`,
      payload,
    )
  },
  listDrugs(params: { keyword?: string; low_stock_only?: boolean; limit?: number } = {}) {
    return http.get<ApiEnvelope<DrugListItem[]>>('/api/v1/pharmacy/drugs', { params })
  },
  listPrescriptions(params: { state?: string; limit?: number } = {}) {
    return http.get<ApiEnvelope<PrescriptionListItem[]>>('/api/v1/pharmacy/prescriptions', { params })
  },
  dispensePrescription(prescriptionUuid: string, options: { idempotencyKey?: string } = {}) {
    return http.put<ApiEnvelope<DispenseResult>>(
      `/api/v1/pharmacy/prescription/${prescriptionUuid}/dispense`,
      undefined,
      {
        headers: options.idempotencyKey ? { 'Idempotency-Key': options.idempotencyKey } : undefined,
      },
    )
  },
  returnPrescription(prescriptionUuid: string, options: { idempotencyKey?: string } = {}) {
    return http.put<ApiEnvelope<DispenseResult>>(
      `/api/v1/pharmacy/prescription/${prescriptionUuid}/return`,
      undefined,
      {
        headers: options.idempotencyKey ? { 'Idempotency-Key': options.idempotencyKey } : undefined,
      },
    )
  },
  getBillsByRegister(registerUuid: string) {
    return http.get<ApiEnvelope<BillRecord[]>>(`/api/v1/bill/register/${registerUuid}`)
  },
  listBills(params: { state?: string; limit?: number } = {}) {
    return http.get<ApiEnvelope<BillRecord[]>>('/api/v1/bill/list', { params })
  },
  refundBill(billCode: string, options: { idempotencyKey?: string } = {}) {
    return http.put<ApiEnvelope<BillRefundResult>>(
      `/api/v1/bill/${encodeURIComponent(billCode)}/refund`,
      undefined,
      {
        headers: options.idempotencyKey ? { 'Idempotency-Key': options.idempotencyKey } : undefined,
      },
    )
  },
  getAdminBillsPage(params: AdminBillQuery = {}) {
    return http.get<ApiEnvelope<AdminBillPage>>('/api/v1/bill/admin/page', { params })
  },
  getAdminBillDetail(billCode: string) {
    return http.get<ApiEnvelope<AdminBillDetail>>(`/api/v1/bill/${encodeURIComponent(billCode)}/detail`)
  },
  listPatients(params: { keyword?: string; limit?: number } = {}) {
    return http.get<ApiEnvelope<PatientAdminListItem[]>>('/api/v1/patient/admin/patients', { params })
  },
  getPatientAdminStats() {
    return http.get<ApiEnvelope<PatientAdminStats>>('/api/v1/patient/admin/stats')
  },
  createPatient(payload: PatientCreatePayload) {
    return http.post<ApiEnvelope<PatientRecord>>('/api/v1/patient', payload)
  },
  updatePatient(patientUuid: string, payload: PatientAdminUpdatePayload) {
    return http.put<ApiEnvelope<PatientAdminListItem>>(`/api/v1/patient/admin/patients/${encodeURIComponent(patientUuid)}`, payload)
  },
}
