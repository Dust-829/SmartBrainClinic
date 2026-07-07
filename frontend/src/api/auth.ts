import { http, type ApiEnvelope } from './http'

export interface DoctorDirectoryItem {
  uuid: string
  realname: string
  gender?: string | null
  expertise?: string | null
  regist_level_uuid?: string | null
}

export const authApi = {
  listDoctorsByDepartmentCode(deptCode: string) {
    return http.get<ApiEnvelope<DoctorDirectoryItem[]>>(`/api/v1/auth/doctors/by-dept-code/${encodeURIComponent(deptCode)}`)
  },
}
