import { http, type ApiEnvelope } from './http'

export interface DepartmentOption {
  code: string
  name: string
}

export interface PatientCreatePayload {
  real_name: string
  gender: string
  card_number: string
  birthdate: string
  home_address?: string
}

export interface PatientRecord {
  uuid: string
  case_number: string
  real_name: string
  gender: string
  card_number: string
  birthdate: string
  home_address?: string
}

export interface TriageMessage {
  role: 'user' | 'assistant'
  content: string
}

export interface TriageData {
  reply: string
  dept_determined: boolean
  recommended_dept_code?: string
  symptom_summary?: string
  gender_preference?: string
}

export interface TriageResult {
  session_uuid?: string
  source?: string
  model?: string
  confidence?: number
  warnings?: string[]
  validated?: boolean
  validator_messages?: string[]
  data: TriageData
}

export interface TriagePayload {
  patient_uuid?: string
  session_uuid?: string
  messages: TriageMessage[]
}

export interface DoctorRecommendPayload {
  symptoms?: string
  dept_code: string
  gender_preference?: string
  limit?: number
}

export interface DoctorRecommendation {
  doctor_uuid: string
  doctor_name: string
  specialties: string[]
  match_score: number
  similarity_score: number
  scheduling_actual_uuid: string
  schedule_date: string
  noon: string
  earliest_time_slot: string
  regist_fee: string
  remaining_quota: number
  available_schedules: Array<{
    scheduling_actual_uuid: string
    schedule_date: string
    noon: string
    remaining_quota: number
    earliest_time_slot: string
  }>
}

export interface DoctorSchedule {
  scheduling_actual_uuid: string
  employee_uuid: string
  schedule_date: string
  noon: string
  regist_quota: number
  registered_count: number
  remaining_quota: number
  time_slots: Array<{
    uuid: string
    time_range: string
    is_booked: boolean
  }>
}

export interface OnlineRegisterPayload {
  patient_uuid: string
  employee_uuid: string
  scheduling_time_slot_uuid?: string
  triage_session_uuid?: string
  is_emergency?: boolean
  symptoms?: string
}

export interface OnlineRegisterResult {
  register_uuid: string
  regist_money: string
  visit_state: number
  visit_state_text: string
  qr_code_url: string
}

export interface PaymentPayload {
  register_uuid: string
  pay_method: string
  amount: number
  idempotency_key?: string
}

export interface PaymentResult {
  register_uuid: string
  visit_state: number
  visit_state_text: string
  queue_number: number
  transaction_id: string
}

export interface QueueStatus {
  ahead_of_you: number
  status: number
  clinic_room_name?: string | null
  clinic_room_location?: string | null
}

export interface RegisterDetail {
  uuid: string
  patient_uuid?: string
  patient_name?: string
  patient_case_number?: string
  patient_gender?: string
  visit_date?: string
  noon?: string
  regist_method?: string
  regist_money?: number
  visit_state?: number
  visit_state_str?: string
  visit_state_text?: string
  symptoms?: string
  employee_name?: string
  dept_name?: string
  actual_schedule_date?: string
  actual_time_range?: string
  clinic_room_name?: string | null
  clinic_room_location?: string | null
}

export const patientApi = {
  createPatient(payload: PatientCreatePayload) {
    return http.post<ApiEnvelope<PatientRecord>>('/api/v1/patient', payload)
  },
  getPatientByCard(cardNumber: string) {
    return http.get<ApiEnvelope<PatientRecord>>(`/api/v1/patient/card/${encodeURIComponent(cardNumber)}`)
  },
  getDepartments() {
    return http.get<ApiEnvelope<DepartmentOption[]>>('/api/v1/patient/departments')
  },
  triage(payload: TriagePayload) {
    return http.post<ApiEnvelope<TriageResult>>('/api/v1/patient/triage', payload)
  },
  recommendDoctors(payload: DoctorRecommendPayload) {
    return http.post<ApiEnvelope<DoctorRecommendation[]>>('/api/v1/patient/recommend-doctors', payload)
  },
  getDoctorSchedules(employeeUuid: string) {
    return http.get<ApiEnvelope<DoctorSchedule[]>>('/api/v1/patient/schedules', {
      params: { employee_uuid: employeeUuid },
    })
  },
  createOnlineRegister(payload: OnlineRegisterPayload) {
    return http.post<ApiEnvelope<OnlineRegisterResult>>('/api/v1/patient/online-register', payload)
  },
  payOnlineRegister(payload: PaymentPayload) {
    return http.post<ApiEnvelope<PaymentResult>>('/api/v1/patient/online-register/pay', payload, {
      headers: payload.idempotency_key ? { 'Idempotency-Key': payload.idempotency_key } : undefined,
    })
  },
  getQueueStatus(registerUuid: string) {
    return http.get<ApiEnvelope<QueueStatus>>(`/api/v1/patient/register/${registerUuid}/queue-status`)
  },
  getRegisterDetail(registerUuid: string) {
    return http.get<ApiEnvelope<RegisterDetail>>(`/api/v1/patient/register/${registerUuid}`)
  },
  getRegisterHistory(patientUuid: string) {
    return http.get<ApiEnvelope<RegisterDetail[]>>(`/api/v1/patient/${patientUuid}/registers/detail`)
  },
}
