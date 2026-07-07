import { http, type ApiEnvelope } from './http'

export interface DoctorQueueItem {
  register_uuid: string
  patient_uuid: string
  patient_name: string
  patient_case_number: string
  gender?: string | null
  symptoms?: string | null
  visit_state: number
  visit_state_text: string
  visit_date: string
  time_range?: string | null
  clinic_room_name?: string | null
}

export interface DoctorCallNextResult {
  called: boolean
  message?: string
  register_uuid?: string
  patient_uuid?: string
  patient_name?: string
  patient_case_number?: string
  visit_state?: number
  visit_state_text?: string
  time_range?: string | null
  clinic_room_uuid?: string | null
}

export interface DoctorVisitTransitionResult {
  uuid: string
  visit_state: number
  visit_state_text: string
}

export const doctorApi = {
  getQueue(employeeUuid: string) {
    return http.get<ApiEnvelope<DoctorQueueItem[]>>(`/api/v1/patient/doctor/${employeeUuid}/queue`)
  },
  callNext(employeeUuid: string) {
    return http.post<ApiEnvelope<DoctorCallNextResult>>(`/api/v1/patient/doctor/${employeeUuid}/queue/call-next`)
  },
  startReception(registerUuid: string) {
    return http.put<ApiEnvelope<DoctorVisitTransitionResult>>(`/api/v1/patient/register/${registerUuid}/start-reception`)
  },
}
