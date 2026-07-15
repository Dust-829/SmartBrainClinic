import { http, type ApiEnvelope } from './http'

export interface PrescriptionRecommendationItem {
  drug_id: number
  drug_name: string
  drug_usage: string
  drug_number: number
  reason: string
}

export interface PrescriptionRecommendationResult {
  register_uuid: string
  patient_allergy: string
  diagnosis: string
  recommendations: PrescriptionRecommendationItem[]
}

export interface PrescriptionCreateItem {
  drug_id: number
  drug_usage: string
  drug_number: number
}

export interface PrescriptionCreateResult {
  uuid: string
  prescription_code: string
  total_amount: string
  items: Array<{ uuid: string }>
}

export const pharmacyApi = {
  recommendPrescription(registerUuid: string) {
    return http.post<ApiEnvelope<PrescriptionRecommendationResult>>('/api/v1/pharmacy/recommend-prescription', {
      register_uuid: registerUuid,
    })
  },
  createPrescription(registerUuid: string, items: PrescriptionCreateItem[]) {
    return http.post<ApiEnvelope<PrescriptionCreateResult>>('/api/v1/pharmacy/prescription', {
      register_uuid: registerUuid,
      items,
    })
  },
}
