import { http, type ApiEnvelope } from './http'

export interface DepartmentOption {
  code: string
  name: string
}

export const patientApi = {
  getDepartments() {
    return http.get<ApiEnvelope<DepartmentOption[]>>('/api/v1/patient/departments')
  },
}
