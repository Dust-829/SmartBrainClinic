import { http, type ApiEnvelope } from './http'

export interface DoctorDirectoryItem {
  uuid: string
  realname: string
  gender?: string | null
  expertise?: string | null
  regist_level_uuid?: string | null
  regist_level_code?: string | null
  dept_uuid?: string | null
  dept_code?: string | null
  dept_id?: number | null
  ai_eval_score?: string | number | null
}

export interface DepartmentRecord {
  uuid: string
  dept_code: string
  dept_name: string
  dept_type?: string | null
  dept_address?: string | null
  delmark?: number | null
}

export interface ClinicRoomRecord {
  uuid: string
  room_code?: string | null
  room_name: string
  dept_id?: number | null
  delmark?: number | null
}

export interface EmployeeRecord {
  uuid: string
  realname: string
  gender?: string | null
  expertise?: string | null
  dept_id?: number | null
  regist_level_id?: number | null
  ai_eval_score?: string | number | null
}

export interface DoctorProfileUpdatePayload {
  realname: string
  dept_code?: string
  regist_level_code?: string
  gender?: string
  expertise?: string
}

export const authApi = {
  listDoctorAccounts(params: { keyword?: string; limit?: number } = {}) {
    return http.get<ApiEnvelope<DoctorDirectoryItem[]>>('/api/v1/auth/admin/doctors', { params })
  },
  listDoctorsByDepartmentCode(deptCode: string) {
    return http.get<ApiEnvelope<DoctorDirectoryItem[]>>(`/api/v1/auth/doctors/by-dept-code/${encodeURIComponent(deptCode)}`)
  },
  getDepartmentByCode(deptCode: string) {
    return http.get<ApiEnvelope<DepartmentRecord>>(`/api/v1/auth/department/code/${encodeURIComponent(deptCode)}`)
  },
  getEmployeesByDeptType(deptType: string) {
    return http.get<ApiEnvelope<EmployeeRecord[]>>(`/api/v1/auth/employees/by-dept-type/${encodeURIComponent(deptType)}`)
  },
  getClinicRoom(roomUuid: string) {
    return http.get<ApiEnvelope<ClinicRoomRecord>>(`/api/v1/auth/clinic-room/${encodeURIComponent(roomUuid)}`)
  },
  getClinicRoomByName(name: string) {
    return http.get<ApiEnvelope<ClinicRoomRecord>>(`/api/v1/auth/clinic-room/name/${encodeURIComponent(name)}`)
  },
  createEmployee(payload: {
    realname: string
    password?: string
    dept_code?: string
    regist_level_code?: string
    gender?: string
    expertise?: string
    ai_eval_score?: number
  }) {
    return http.post<ApiEnvelope<EmployeeRecord>>('/api/v1/auth/employee', payload)
  },
  updateEmployeeExpertise(employeeUuid: string, expertise: string) {
    return http.put<ApiEnvelope<EmployeeRecord>>(`/api/v1/auth/employee/${employeeUuid}/expertise`, { expertise })
  },
  updateEmployeeProfile(employeeUuid: string, payload: DoctorProfileUpdatePayload) {
    return http.put<ApiEnvelope<DoctorDirectoryItem>>(`/api/v1/auth/employee/${employeeUuid}/profile`, payload)
  },
  adjustEmployeeScore(employeeUuid: string, adjustment: number) {
    return http.put<ApiEnvelope<{ uuid: string; new_score: string }>>(
      `/api/v1/auth/employee/${employeeUuid}/score/adjust`,
      { adjustment },
    )
  },
}
